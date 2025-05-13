classdef LocalRouter < Router
    properties
        isIA = false;
    end
    properties(Access=private)
        Distances;
        CachedTopologyAdjacencyMatrix;
    end
    
    methods
        function obj = LocalRouter(isIA)
            if (nargin == 1)
                obj.isIA = isIA;
            end
        end
        function name = getName(obj)
            name = 'Local - NIA';
            if (obj.isIA)
                name = 'Local - IA';
            end
        end
        function links = route(obj, network, connectedNodes)
            if (obj.isDistanceCalculationRequired(network))
                obj.CachedTopologyAdjacencyMatrix = network.Topology.AdjacencyMatrix;
                physicalTopologyGraph = graph(network.Topology.AdjacencyMatrix);
                % Calculate distances in hops (physical distance only
                % matters for initial Bell State transmission success. By
                % now, we have entangled pairs
                obj.Distances = distances(physicalTopologyGraph, network.Topology.Nodes, network.Topology.TrustedNodes, 'Method', 'unweighted');
            end
            % Pre-allocate a large space for links
            links = cell([size(connectedNodes, 1), 1]);
            % Get all 1..N nodes
            allNodes = 1:size(connectedNodes,1);
            for node = allNodes
                % Skip trusted nodes
                if (network.Topology.isTrustedNode(node))
                    continue;
                end
                neighbors = transpose(find(connectedNodes(:,node) > 0));
                
                s = numel(neighbors);
                if (s < 2)
                    continue
                elseif (s > 2)
                    trustedNodes = network.Topology.TrustedNodes;
                    % Find neighbor closest to any trusted node
                    [closeNeighbors1, closeTrustNodes1, dist1] = obj.findClosestNeighborsToTrustedNode(network, neighbors, trustedNodes);
                    randomIdx = randi(numel(closeNeighbors1));
                    closestNeighbor1 = closeNeighbors1(randomIdx);
                    closestTrustedNode1 = closeTrustNodes1(randomIdx);
                    
                    % Find neighbor 2nd closest to remaining trusted nodes
                    trustedNodes2 = trustedNodes(trustedNodes ~= closestTrustedNode1);
                    [closeNeighbors2, closeTrustNodes2, dist2] = obj.findClosestNeighborsToTrustedNode(network, neighbors, trustedNodes2);
                    randomIdx = randi(numel(closeNeighbors2));
                    
                    % If we are Intersection Avoident mode and have
                    % multiple 2nd closest nodes
                    if (obj.isIA && numel(closeNeighbors2) > 1)
                        nodeX = network.Topology.X(node);
                        nodeY = network.Topology.Y(node);
                        n1X = network.Topology.X(closestNeighbor1);
                        n1Y = network.Topology.Y(closestNeighbor1);
                        slope1 = (n1Y - nodeY) / (n1X - nodeX);
                        
                        for i = 1:numel(closeNeighbors2)
                            if (abs(node - closeNeighbors2(i)) == abs(node - closestNeighbor1)) 
                                possN2X = network.Topology.X(closeNeighbors2(i));
                                possN2Y = network.Topology.Y(closeNeighbors2(i));
                                possSlope2 = (possN2Y - nodeY) / (possN2X - nodeX);
                                % disp(possSlope2);
                                % disp(abs(slope1 - possSlope2));
                                randomIdx = i;
                                break;
                            end
                        end
                    end
                    closestNeighbor2 = closeNeighbors2(randomIdx);
                    closestTrustedNode2 = closeTrustNodes2(randomIdx);
                    
                    if (closestNeighbor1 == closestNeighbor2)
                        neighbors3 = neighbors(neighbors ~= closestNeighbor1);
                        trustedNodes3 = trustedNodes(trustedNodes ~= closestTrustedNode2);
                        [closeNeighbors3, ~, dist3] = obj.findClosestNeighborsToTrustedNode(network, neighbors3, trustedNodes3);
                        randomIdx = randi(numel(closeNeighbors3));
                        closestNeighbor3 = closeNeighbors3(randomIdx);
                        
                        neighbors4 = neighbors(neighbors ~= closestNeighbor2);
                        trustedNodes4 = trustedNodes2(trustedNodes2 ~= closestTrustedNode1);
                        [closeNeighbors4, ~, dist4] = obj.findClosestNeighborsToTrustedNode(network, neighbors4, trustedNodes4);
                        randomIdx = randi(numel(closeNeighbors4));
                        closestNeighbor4 = closeNeighbors4(randomIdx);

                        if (dist1 + dist4 < dist2 + dist3)
                            closestNeighbor2 = closestNeighbor4;
                        elseif(dist1 + dist4 > dist2 + dist3)
                            closestNeighbor1 = closestNeighbor3;
                        else
                            if (randi(2) == 1)
                                closestNeighbor1 = closestNeighbor3;
                            else
                                closestNeighbor2 = closestNeighbor4;
                            end
                        end
                        
                        if (closestNeighbor1 == closestNeighbor2)
                            error("Tried to link node to itself!");
                        end
                    end
                    
                    links = obj.addLink(links, [closestNeighbor1, node, closestNeighbor2]);
                    % Remove used up node neighbors
                    neighbors = neighbors(neighbors ~= closestNeighbor1 & neighbors ~= closestNeighbor2);
                    s = numel(neighbors);
                end
                % If originally only 2 neighbors or 2 left over (from 4)
                if (s == 2)
                    links = obj.addLink(links, [node, neighbors]);
                end
            end
            for i = 1:size(links,1)
                link = links{i};
                if (size(link, 1) == 0)
                    continue;
                end
                % If either end is not a trusted node, delete this link
                if (~network.Topology.isTrustedNode(link(1)) || ~network.Topology.isTrustedNode(link(end)))
                    links{i} = [];
                end
            end
            
            links = removeEmptyCells(links);
        end
    end
    methods(Access=private)
        function links = addLink(~, links, linkToAdd)
            added = false;
            sortedLinkToAdd = sort(linkToAdd);
            node1 = sortedLinkToAdd(1);
            node2 = sortedLinkToAdd(2);
            node3 = sortedLinkToAdd(3);
            firstEmptyIdx = length(links) + 1;
            for i = 1:length(links)
                link = links{i};
                if (size(link,1) == 0)
                    firstEmptyIdx = i;
                    break;
                end
                if (link(end - 1) == node1 && link(end) == node2)
                    added = true;
                    links{i} = [links{i}, node3];
                end
            end
            if (~added)
                links{firstEmptyIdx} = [node1, node2, node3];
            end
        end
        function result = isDistanceCalculationRequired(obj, network)
            try
                result = ~isequal(obj.CachedTopologyAdjacencyMatrix, network.Topology.AdjacencyMatrix);
            catch
                result = true;
            end
        end
        function [closestNeighbors, closestTrustedNodes, dist] = findClosestNeighborsToTrustedNode(obj, network, neighbors, trustedNodesSelection)
            % NOTE: ismembc is a helper method that requires the arguments
            % to be sorted
            d = obj.Distances(neighbors, ismembc(network.Topology.TrustedNodes, trustedNodesSelection));
            minDist = min(d, [], 'all');
            [rows, cols] = ind2sub(size(d), find(d == minDist));
            closestNeighbors = neighbors(rows);
            closestTrustedNodes = network.Topology.TrustedNodes(cols);
            dist = minDist;
        end
    end
end
