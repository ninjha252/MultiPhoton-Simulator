classdef Network < matlab.mixin.Heterogeneous & handle
    % Representation of a network used for Quantum Key Distribution    
    properties
        Topology;
        TrustedNodePairs = [];
        Routers = [];
        KeyPools = [];
        ErrorKeyPools = [];
        Rounds = 0;
        SuccessfulEdgeUsage;
        RouteEdgeUsage;
        ShannonEntropyValues = [];
        % Bell measurement success
        B = 0.85
        % Bell pair decoherence rate
        D = 0.02
        % Burst size (number of photons sent along fiber)
        BURST = 1;
    end
    
    methods
        function obj = Network(topology, routers, opts)
            % Network Construct an instance of this class
            if (nargin == 3)
                
                if (isfield(opts, 'L'))
                    raise 'L is not longer a valid network option. Specify on the topology.';
                end
                if (isfield(opts, 'B'))
                    obj.B = opts.B;
                end
                if (isfield(opts, 'D'))
                    obj.D = opts.D;
                end
                if (isfield(opts, 'BURST'))
                    obj.BURST = opts.BURST;
                end
                
                
                obj.Topology = topology;
                
                % Keep trusted nodes sorted so KeyPool keys are sorted
                obj.TrustedNodePairs = nchoosek(sort(obj.Topology.TrustedNodes), 2);

                obj.Routers = routers;
                obj.KeyPools = cell(size(routers, 1));
                obj.ErrorKeyPools = cell(size(routers, 1));
                for i = 1:size(routers,1)
                    obj.KeyPools{i} = obj.createKeyPool();
                    obj.ErrorKeyPools{i} = obj.createKeyPool();
                end
                
                obj.SuccessfulEdgeUsage = containers.Map('KeyType','char','ValueType','double'); 
                obj.RouteEdgeUsage = containers.Map('KeyType','char','ValueType','double');
            end
        end
        
        function runRound(obj)
            % runRound Run an entire round of the network
            %   Bell states are created, routes determined, and a E91 run
            %   (for one qubit) between all trusted nodes
            % STEP 1
            obj.Rounds = obj.Rounds + 1;
            connectedNodes = obj.createBellStates();
                        
            for i = 1:size(obj.Routers, 1)
                router = obj.Routers(i);
                % STEP 2
                links = router.route(obj, connectedNodes);
                completeLinks = obj.performEntanglementSwapping(links);
                % STEP 3
                obj.performKeyExchange(completeLinks, i);
            end
        end
        
        function keyRates = calculateKeyRates(obj, doErrorCorrection)
            if nargin < 2
                doErrorCorrection = true;
            end
            
            keyRates = zeros(size(obj.Routers));
            
            for routerIdx = 1:numel(obj.Routers)
                rawKeyPool = obj.KeyPools{routerIdx};
                keyPool = containers.Map(keys(rawKeyPool), values(rawKeyPool));

                if (doErrorCorrection)
                    rawErrorPool = obj.ErrorKeyPools{routerIdx};
                    errorPool = containers.Map(keys(rawErrorPool), values(rawErrorPool));
                    % Reduce raw key pools via error correction
                    for k = convertCharsToStrings(keys(keyPool))
                        totalKeyPoolQubits = keyPool(k);
                        errorQubits = errorPool(k);
                        if (totalKeyPoolQubits > 0)
                            Q = errorQubits / totalKeyPoolQubits;
                            obj.ShannonEntropyValues(obj.Rounds) = shannonEntropy(Q);
                        else
                            Q = 0;
                            obj.ShannonEntropyValues(obj.Rounds) = shannonEntropy(Q);
                        end

                        e = (1 - 2 * shannonEntropy(Q));
                
                        keyPool(k) = max([0, floor(totalKeyPoolQubits * e)]);
                    end
                end

                alice = obj.Topology.TrustedNodes(1);
                bob = obj.Topology.TrustedNodes(end);
                aliceAndBobKey = obj.getNodePairKey([alice, bob]);
                % If only Alice and Bob, there is only one key pool
                if (numel(obj.Topology.TrustedNodes) == 2)
                    totalQubits = keyPool(aliceAndBobKey);
                % If only Alice, Bob, and one other TM, include min bits of shared keys
                elseif (numel(obj.Topology.TrustedNodes) == 3)
                    minBitsFromOther = Inf;
                    for k = convertCharsToStrings(keys(keyPool))
                        if (k ~= aliceAndBobKey)
                            minBitsFromOther = min([minBitsFromOther, keyPool(k)]);
                        end
                    end
                    totalQubits = keyPool(aliceAndBobKey) + minBitsFromOther;
                else
                    s = zeros(size(keys(keyPool)));
                    t = zeros(size(keys(keyPool)));
                    w = zeros(size(keys(keyPool)));
                    tnPairs = convertCharsToStrings(keys(keyPool));
                    for i = 1:numel(tnPairs)
                        sp = split(tnPairs(i), ',');
                        s(i) = str2double(sp{1});
                        t(i) = str2double(sp{2});
                        w(i) = keyPool(tnPairs(i));
                    end
                    g = digraph(s,t,w);
                    totalQubits = maxflow(g,alice,bob);
                end
                keyRates(routerIdx) = totalQubits / obj.Rounds;
            end
        end
        
        function result = calculateAvgErrorRate(obj)
            result = zeros(size(obj.Routers));
            for routerIdx = 1:numel(obj.Routers)
                rawKeyPool = obj.KeyPools{routerIdx};
                rawErrorPool = obj.ErrorKeyPools{routerIdx};
                
                tnPairs = keys(rawKeyPool);
                % Loop over all pools
                i = 1;
                routerResult = zeros(1, numel(tnPairs));
                for k = convertCharsToStrings(tnPairs)
                    totalKeyPoolQubits = rawKeyPool(k);
                    errorQubits = rawErrorPool(k);
                    if (totalKeyPoolQubits > 0)
                        Q = errorQubits / totalKeyPoolQubits;

                    else
                        Q = 0;
                    end
                    routerResult(i) = shannonEntropy(Q);
                    i = i + 1;
                end
                result(routerIdx) = mean(routerResult, 'all');
            end
            result = mean(result, 'all');
        end
    end
    
    methods (Access=private)
        function result = createKeyPool(obj)
            % Create mapping from trusted node pairs to counters
            keys = strings([size(obj.TrustedNodePairs, 1), 1]);
            for i = 1:size(obj.TrustedNodePairs)
                keys(i) = obj.getNodePairKey(obj.TrustedNodePairs(i, :));
            end
            result = containers.Map(keys, zeros(size(keys)));
        end
        % Step 1: Create Bell/Transmit States
        function connectedNodes = createBellStates(obj)
            % createBellStates
            %   Neighbors attempt to create entangled Bell states
            connectedNodes = obj.Topology.AdjacencyMatrix;
            for node1 = 1:size(connectedNodes,1)
                for node2 = node1:size(connectedNodes,1)
                    % Number of fiber segments from node1 to node2 is
                    % assumed to be the same (this is the numerical value
                    % in the adjacency matrix - the weight)
                    fiberSegments = connectedNodes(node1, node2); 
                    if (fiberSegments == 0)
                        continue;
                    end
                    % Failed to share a Bell state
                    if(~obj.isTransmissionSuccessful(node1, node2))
                        % Remove connection from both sides
                        connectedNodes(node1, node2) = 0;
                        connectedNodes(node2, node1) = 0;
                    end
                end
            end
        end
        function completeLinks = performEntanglementSwapping(obj, links)
            completeLinks = cell(size(links));
            completeLinkIdx = 1;
            % For each link
             for i = 1:size(links,1)
                link = links{i};
                
                % Shutting off usage recording for performance
                % obj.recordLinkUsage(obj.RouteEdgeUsage, link);
                
                % Probability of successful Bell measurements along all
                % repeaters (subtract trusted nodes from start and end)
                p = obj.B ^ (length(link) - 2);
                if (doesEventHappen(p))
                    completeLinks{completeLinkIdx} = link;
                    completeLinkIdx = completeLinkIdx + 1;
                end
             end
             completeLinks = removeEmptyCells(completeLinks);
        end
        
        % Step 3: Key Exchange
        function performKeyExchange(obj, links, routerIdx)    
            for i = 1:size(links,1)
                link = links{i};
                
                if (obj.isKeyExchangeSuccessful(link))
                    key = obj.getNodePairKey(link([1 end]));
                    obj.KeyPools{routerIdx}(key) = obj.KeyPools{routerIdx}(key) + 1;
                    
                    % If link was lost due to decoherence
                    if (~doesEventHappen(obj.noDecoherenceProb(link)))
                        obj.ErrorKeyPools{routerIdx}(key) = obj.ErrorKeyPools{routerIdx}(key) + 1;
                    else
                        % Shutting off usage recording for performance
                        % obj.recordLinkUsage(obj.SuccessfulEdgeUsage, link);
                    end
                end
            end
        end
    end
    methods(Access=protected)
        % Determine if transmission from one node to another (over fiber)
        % is successful
        function [result, transferredQubits] = isTransmissionSuccessful(obj, node1, node2)
            singleQubitProb = obj.Topology.fiberProb(node1, node2);
            
            % Get number of qubits from burst (children can set obj.BURST
            % before delegating to the BurstNetwork)
            probForEachQubit = singleQubitProb * ones(1, obj.BURST);
            % Get number of qubits successfully transferred
            transferredQubits = sum(doEventsHappen(probForEachQubit));
            
            % Transmission succeeds as long as 1 or more qubits remain from
            % burst
            result = transferredQubits > 0;
        end
        function result = noDecoherenceProb(obj, link)
            % Probability the whole link didn't lose Bell states to dechoherence
            p = (1 - obj.D) ^ (length(link) - 1);
            % And now account for accidentally decohering to
            % expected state
            result = p + (1 - p) / 2;
        end
    end
    methods(Abstract)
        name = getName(obj);
    end
    methods (Abstract,Access=protected)
        % Provides ability to override and determine if KEX is successful
        result = isKeyExchangeSuccessful(obj, link);
    end
    methods(Static)
        function result = create(topology, routers, opts)
            if (~isfield(opts, "type") || opts.type == "E91")
                result = E91Network(topology, routers, opts);
            elseif (opts.type == "3-Stage")
                result = ThreeStageNetwork(topology, routers, opts);
            elseif (opts.type == "Decoy")
                result = DecoyStateNetwork(topology, routers, opts);
            else
                result = E91Network(topology, routers, opts);
            end
        end
        % Helper Method
        function result = getNodePairKey(pair)
            % getNodePairKey
            %   get string key for an array of two trusted node IDs
            result = join(string(sort(pair)), ',');
        end
        function [node1,node2] = getNodePair(key)
            sp = split(key, ',');
            node1 = str2double(sp{1});
            node2 = str2double(sp{2});
        end
    end
    methods(Static,Access=private)
        function recordLinkUsage(map,link)
            for i = 1:(numel(link) - 1)
                Network.recordEdgeUsage(map,link(i), link(i + 1));
            end
        end
        function recordEdgeUsage(map, node1, node2)
            key = Network.getNodePairKey([node1, node2]);
            if (~map.isKey(key)) 
                map(key) = 0;
            end
            map(key) = map(key) + 1;
        end
    end
end

