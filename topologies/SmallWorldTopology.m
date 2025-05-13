classdef SmallWorldTopology < SquareTopology
    
    properties
        RegularAdjacencyMatrix = [];
    end
    
    methods(Static)
        function result = load(size, trustedNodeAlgorithm, fiberOpts)
            file = "topologies/SmallWorldTopology_T-" + string(trustedNodeAlgorithm) + "-" + string(size) + "-by-" + string(size) + ".mat";
            if (isfile(file))
                data = load(file);
                result = data.t;
                result.init(fiberOpts);
            else
                t = SmallWorldTopology(size, trustedNodeAlgorithm, fiberOpts);
                save(file, 't');
                result = t;
            end
        end
    end
    
    methods
        function obj = SmallWorldTopology(dimension, trustedNodesAlg,fiberOpts)
           obj = obj@SquareTopology(dimension,trustedNodesAlg,fiberOpts);
           obj.RegularAdjacencyMatrix = obj.AdjacencyMatrix;
           obj.convertToSmallWorld();
        end
        
        function result = getName(obj)
            result = getName@SquareTopology(obj) + "-small-world-";
        end
        
        function result = getAvgEdgeLength(obj)
            g = grapn(obj.AdjacencyMatrix);
            result = mean(g.Edges.Weight(:));
        end
        
        function result = getAvgHopsFromAtoB(obj, nodeA, nodeB)
            g = graph(obj.AdjacencyMatrix);
            paths = allpaths(g, nodeA, nodeB);
            [~, lengths] = cellfun(@size, paths, 'UniformOutput', false);
            result = mean(cellfun(@(x) x(1), lengths));
        end
        
        function result = getAvgPathLength(obj)
            result = zeros(size(obj.AdjacencyMatrix,1));
            g = graph(obj.AdjacencyMatrix);
            for node1 = 1:size(obj.AdjacencyMatrix,1)
                for node2=1:size(obj.AdjacencyMatrix,1)
                    if(node1~=node2)
                        [~,d] = shortestpath(g,node1,node2);
                        if (~isinf(d))
                            result(node1) = d;
                        end
                    end
                end
            end
            result = mean(result);
            result = result(1);
        end
        
        function result = getAvgPathHops(obj)
            result = zeros(size(obj.AdjacencyMatrix,1));
            g = graph(obj.AdjacencyMatrix);
            for node1 = 1:size(obj.AdjacencyMatrix,1)
                for node2=1:size(obj.AdjacencyMatrix,1)
                    if( node1 ~= node2)
                        [~,d] = shortestpath(g ,node1, node2, 'Method', 'Unweighted');
                        if (~isinf(d))
                            result(node1) = d;
                        end
                    end
                end
            end
            result = mean(result);
            result = result(1);
        end
        
        function result = getAvgClusteringCoefficient(obj)
            result = zeros(size(obj.AdjacencyMatrix,1), 1);
            for node1 = 1:size(obj.AdjacencyMatrix,1)                
                originalNeighbors = transpose(find(obj.RegularAdjacencyMatrix(:,node1) > 0));
                neighbors = transpose(find(obj.AdjacencyMatrix(:,node1) > 0));
                totalConnections = 0;
                for i=1:numel(neighbors)
                    neighbor1 = neighbors(i);
                    if(neighbor1==node1)
                        continue;
                    end
                    for j=i:numel(neighbors)
                        neighbor2 = neighbors(j);
                        if(neighbor1==neighbor2)
                            continue;
                        end
                        if (obj.AdjacencyMatrix(neighbor1, neighbor2) > 0)
                            totalConnections = totalConnections + 1;
                        end
                    end
                end
                kv = numel(originalNeighbors);
                result(node1) = totalConnections / (kv * (kv - 1) / 2);
            end
            result = mean(result);
            result = result(1);
        end
    end
    methods (Access=private)
        function convertToSmallWorld(obj)
            allNodes = 1:size(obj.AdjacencyMatrix,1);

            smallWorldConnectedNodes = obj.AdjacencyMatrix;
            for node = allNodes
                if (obj.isTrustedNode(node))
                    continue;
                end
                nodeRelations = smallWorldConnectedNodes(:,node);
                neighbors = transpose(find(nodeRelations > 0));
                neighbors = neighbors(~obj.isTrustedNode(neighbors));
                
                randomIdx = randi(numel(neighbors));
                oldNeighbor = neighbors(randomIdx);
                slope = calculateSlope(obj, node, oldNeighbor);
                
                % Is vertical
                if (isinf(slope))
                    possNewNeighbors = find(obj.X == obj.X(node));
                else
                    possNewNeighbors = find(obj.Y == obj.Y(node));
                end
                possNewNeighbors = possNewNeighbors(possNewNeighbors ~= node);
                
                if (numel(possNewNeighbors) == 0)
                    continue;
                end
                
                randomIdx = randi(numel(possNewNeighbors));
                newNeighbor = possNewNeighbors(randomIdx);
                
                if (smallWorldConnectedNodes(node, newNeighbor) > 0)
                    continue;
                end
                
                x1 = obj.X(node);
                y1 = obj.Y(node);
                x2 = obj.X(newNeighbor);
                y2 = obj.Y(newNeighbor);
                % Maintain the same physical distance (calculated using
                % coords of two points)
                newFiberSegments = norm([x1, y1] - [x2, y2]);
                
                smallWorldConnectedNodes(node, oldNeighbor) = 0;
                smallWorldConnectedNodes(oldNeighbor, node) = 0;
                smallWorldConnectedNodes(node, newNeighbor) = newFiberSegments;
                smallWorldConnectedNodes(newNeighbor, node) = newFiberSegments;
            end
            obj.AdjacencyMatrix = smallWorldConnectedNodes;
            obj.cacheBellStateProbs();
        end
    end
end
