classdef GlobalRouter < Router
    methods
        function name = getName(~)
            name = 'Global';
        end
        function links = route(~, network, connectedNodes)
            trustedNodePairs = network.TrustedNodePairs;
            linkIdx = 1;
            links = cell(size(trustedNodePairs, 1) * 2, 1);
            
            while true
                connectedNodesGraph = graph(connectedNodes);
                dist = Inf;
                % For each node pair, find shortest path
                for i = 1:size(trustedNodePairs,1)
                    tNode1 = trustedNodePairs(i, 1);
                    tNode2 = trustedNodePairs(i, 2);
                    if (tNode1 == tNode2)
                        throw("Trusted node should never be paired with itself");
                    end
                    % Find shortest path between pair of nodes
                    [currPath, currDist] = shortestpath(connectedNodesGraph, tNode1, tNode2,'Method','unweighted');
                    % If new shortest path
                    if currDist < dist
                        path = currPath;
                        dist = currDist;
                    end 
                end
                % If we have a path greater than 0 (but not inf which was
                % the default value)
                if dist > 0 && ~isinf(dist)
                    links{linkIdx} = path;
                    linkIdx = linkIdx + 1;
                    % Remove used path from graph
                    for i = 1:numel(path) - 1
                        % Remove edge
                        connectedNodes(path(i), path(i + 1)) = 0;
                        connectedNodes(path(i + 1), path(i)) = 0;
                    end
                else
                    break;
                end
            end
            links = removeEmptyCells(links);
        end
    end
end

