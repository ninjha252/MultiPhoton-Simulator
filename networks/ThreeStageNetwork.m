classdef ThreeStageNetwork < Network
    %ThreeStageNetwork Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        % Number of stages in QKD transmission
        STAGES = 3;
        
        % Provides ability to spread stages over network rounds (or do all
        % in one "network" round)
        ONE_STAGE_PER_ROUND = false;
    
    end
    properties(Access=private)
        % Original BURST argument (we have to override BURST during the protocol)
        OriginalBurst;
        % Adjacency matrix to keep track of current stages of every link between
        % trusted nodes
        AvailalbeQubits = [];
        
        % Map to keep track of current stages of every link between
        % trusted nodes
        LinkStages = [];
        
        % Map to keep track of the decoherence probability of qubits as
        % they are transmitted back and fourth
        LinkDecoherence = [];
    end
    
    methods
        function obj = ThreeStageNetwork(topology, routers, opts)
            obj = obj@Network(topology, routers, opts);
            
            % Default BURST=10 (otherwise, this would fall back on Network)
            % N=10 Shown by Fig 2 in original paper
            if (~isfield(opts, "BURST"))
                obj.BURST = 10;
            end
            obj.OriginalBurst = obj.BURST;
            if (isfield(opts, "ONE_STAGE_PER_ROUND"))
                obj.ONE_STAGE_PER_ROUND = opts.ONE_STAGE_PER_ROUND;
            end
            
            % If stages spread over multiple rounds, we have to keep track
            % in between rounds
            if (obj.ONE_STAGE_PER_ROUND)
                obj.AvailableQubits = topology.AdjacencyMatrix * obj.BURST;
                obj.LinkStages = containers.Map('KeyType','char','ValueType','double');
                obj.LinkDecoherence = containers.Map('KeyType','char','ValueType','double');
            end
        end
        
        function name = getName(~)
            name = "3-Stage";
        end
        
        % Override the runRound to check conditions before and after
        function runRound(obj)
            % If stages not spread over multiple rounds, just run
            % round normally
            if (~obj.ONE_STAGE_PER_ROUND)
                runRound@Network(obj);
                return;
            end
            
            % Otherwise, we have to do the following to keep track of
            % stages over multipe rounds
            
            % Store previous stages
            if (obj.LinkStages.Count == 0)
                previousStages = containers.Map('KeyType','char','ValueType','double');
            else
                previousStages = containers.Map(keys(obj.LinkStages), values(obj.LinkStages));
            end
            
            % RUN ROUND
            runRound@Network(obj);
            
            % Look for stage changes
            for k = keys(obj.LinkStages)
                tnPair = k{1};
                % If we did not make it to the next stage for a given pair
                if (isKey(previousStages, tnPair) && previousStages(tnPair) == obj.LinkStages(tnPair))
                    % Restart KEX
                    obj.clearKEXState(tnPair);
                end
            end
        end
    end
    methods(Access=protected)
        function [result, transferredQubits] = isTransmissionSuccessful(obj, node1, node2)
            % If spreading stages over multiple rounds... no change
            if (obj.ONE_STAGE_PER_ROUND)
                % Set to available qubits from previous round
                obj.BURST = obj.AvailableQubits(node1, node2);
                [result, transferredQubits] = isTransmissionSuccessful@Network(obj, node1, node2);
           
            % Otherwise, we will attempt all stages in one network round
            else
                % Start with full BURST 
                obj.BURST = obj.OriginalBurst;
                % Try the transmission for each stage
                for i = 1:obj.STAGES
                    [result, transferredQubits] = isTransmissionSuccessful@Network(obj, node1, node2);
                    obj.BURST = transferredQubits;
                    % A failure in one stage results in immediate overall failure 
                    if (~result)
                        return;
                    end
                end
            end
        end
        function result = isKeyExchangeSuccessful(obj, link)
            result = false;
            % If spreading stages over multiple rounds... hande next stage
            if (obj.ONE_STAGE_PER_ROUND)
                tn1 = link(1);
                tn2 = link(end);
                tnPairKey = Network.getNodePairKey([tn1, tn2]);

                % If we've never started the QKD protocol between these trusted
                % nodes
                if(~isKey(obj.LinkStages, tnPairKey))
                    obj.LinkStages(tnPairKey) = 1;
                end

                % If this is the final stage
                if (obj.LinkStages(tnPairKey) == obj.STAGES)
                    obj.clearKEXState(tnPairKey);
                    result = true;
                end
                % Increment stage. The obj.Available qubits entry
                % remains the same so we can send back the same number of
                % qubits that were successfully transmitted in the previous
                % stage
                obj.LinkStages(tnPairKey) = obj.LinkStages(tnPairKey) + 1;

                % Accumulate decoherence probabilities
                if(isKey(obj.LinkDecoherence, tnPairKey))
                    noDecProb = obj.LinkDecoherence(tnPairKey);
                else
                    noDecProb = 1;
                end
                % Include new stage in decoherence prob
                noDecProb = noDecProb * obj.noDecoherenceProb(link, true);
                % Store for next stage
                obj.LinkDecoherence(tnPairKey) = noDecProb;
            
            % Otherwise, if we've made it this far (and we're not spreading
            % over multiple rounds), we have successfully exchanged a
            % key bit!
            else
                result = true;
            end
            
            
            % NOTE - We could consider further variables that reduce raw
            % key pool here (ex: authentication)
        end
        
        % NOTE - This only gets called at the end of the KEX when we've
        % successfully reached the third stage
        function result = noDecoherenceProb(obj, link, callParent)
            if (nargin <= 2)
                % Default to false so that we supply overriden logic when
                % called outside of this class
                callParent = false;
            end
            % If spreading stages over multiple rounds
            if (obj.ONE_STAGE_PER_ROUND)
                if (callParent)
                    result = noDecoherenceProb@Network(obj, link);
                else
                    tnPairKey = Network.getNodePairKey(link([1, end]));
                    % Override to get the decoherence probability accumulated from
                    % all stages
                    result = obj.LinkDecoherence(tnPairKey);
                end
            % Otherwise, calculate probability of not decoherence
            % across every stage
            else
                result = noDecoherenceProb@Network(obj, link) ^ obj.STAGES;
            end
        end
    end
    methods(Access=private)
        % Clean up the state we store for KEX between two trusted nodes
        function clearKEXState(obj, tnPairKey)
            % Reset the QKD stage
            obj.LinkStages(tnPairKey) = 1;
            % Remove cached decoherence from last stage
            if (isKey(obj.LinkDecoherence, tnPairKey))
                remove(obj.LinkDecoherence, tnPairKey);
            end
            % Reset available qubits between trusted nodes
            [node1,node2] = str2double(regexp(tnPairKey,'\d*','match')');
            obj.AvailableQubits(node1, node2) = value;
            obj.AvailableQubits(node2, node1) = value;
        end
    end
end

