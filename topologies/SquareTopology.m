classdef SquareTopology < RectTopology
    %SquareTopology Create a square topology
   
    methods
        function obj = SquareTopology(dimension, trustedNodesAlg, fiberOpts)
            obj = obj@RectTopology(dimension,dimension,trustedNodesAlg, fiberOpts);
        end
    end
end

