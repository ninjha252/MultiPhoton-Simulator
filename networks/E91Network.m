classdef E91Network < Network
    methods
        function obj = E91Network(topology, routers, opts)
            obj = obj@Network(topology, routers, opts);
            % Default BURST=5 (otherwise, this would fall back on Network)
            if (~isfield(opts, "BURST"))
                obj.BURST = 1;
            end
        end
        function name = getName(~)
            name = "E91";
        end
    end
    methods(Access=protected)
        function result = isKeyExchangeSuccessful(~, ~)  
            % Chance that both trusted nodes choose pX and pZ
            pX = 0.5 * 0.5;
            pZ = 0.5 * 0.5;
            result = doesEventHappen(pX + pZ);
        end
    end     
end

