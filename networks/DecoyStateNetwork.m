classdef DecoyStateNetwork < Network
    
    properties(Access=private)
        % Laser intensity counter (cycles through to simulate random
        % intensity choices)
        intensityCounter = 0;
        intensities = [];
        totalIntensities = 26;
    end
    
    methods
        function obj = DecoyStateNetwork(topology, routers, opts)
            obj = obj@Network(topology, routers, opts);
            
            % Default BURST=2
            if (~isfield(opts, "BURST"))
                obj.BURST = 2;
            end
            
            % Burst distributions calculated from https://arxiv.org/pdf/quant-ph/0601168.pdf
            % Avg PNS = 0.57
            % here m = 0.55, v = 0.152 and
            % N_m = 0.635, N_v = 0.203, and N_0 = 0.162
            % Using these params, I estimated the actual
            % amount of 0, 1, or multi qubit burst occurences
            
            % A multi-qubit burst occurs 1/26 = 0.038 times
            numOfMultis = 1;
            % A 1-qubit burst occurs 10/26 = 0.38 times
            numOf1s = 10;
            % A 0-qubit burst occurs 15/26 = 0.57 times
            numOf0s = obj.totalIntensities - numOfMultis - numOf1s;
            
            obj.intensityCounter = 1;
            intensities = zeros(1, obj.totalIntensities);
            start1s = numOf0s + 1;
            intensities(start1s:start1s+numOf1s) = 1;
            startMultis = start1s + numOf1s + 1;
            intensities(startMultis:startMultis+numOfMultis) = obj.BURST;
            obj.intensities = intensities;
        end
        function name = getName(~)
            name = "Decoy";
        end
        % Override the runRound to clear available qubits after
        function runRound(obj)
            % RUN ROUND
            runRound@Network(obj);
            % Cycle inensity counter to beginning
            if (obj.intensityCounter > obj.totalIntensities)
                obj.intensityCounter = 1;
            end
            % TODO - Improve this. The BURST applies for every TN pair in
            % the network, but we could make this probabilisitic
            obj.BURST = obj.intensities(obj.intensityCounter);
            obj.intensityCounter = obj.intensityCounter + 1;
        end
    end
    methods(Access=protected)
        function result = isKeyExchangeSuccessful(~, ~)
            % Chance receiver chose correct basis
            p = 0.5;
            result = doesEventHappen(p);
        end
    end     
end

