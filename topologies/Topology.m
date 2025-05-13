classdef Topology < matlab.mixin.Heterogeneous & handle
    properties (Abstract)
        AdjacencyMatrix
        TrustedNodes
        Nodes
        Labels
        X
        Y
    end
    methods (Abstract)
        name = getName(obj);
        plot(obj);
        prob = fiberProb(obj,node1,node2);
        result = isTrustedNode(obj, node);
    end
    methods (Static, Sealed, Access = protected)
      function default_object = getDefaultScalarElement
         default_object = RectTopology(0, 0, "2-corners");
      end
   end
end

