classdef StarTopology < Topology
    %RingTopology Create a ring topology
    properties
        AdjacencyMatrix = [];
        TrustedNodes = [];
        Nodes = [];
        Labels = [];
        X = [];
        Y = [];
        
        % Logical array to cache and quickly answer if a node is trusted
        trustedNodeQuery = [];
        
        % FIBER Opts
        % Fiber length (1 km)
        L = 1;
        % Fiber attenuation coefficient
        ALPHA = 0.15;
    end
    properties(Access=private)
        TrustedNodesAlg = [];
        CachedBellStateProbs;
    end
   
    methods
        
        function result = isTrustedNode(obj, node)
            result = obj.trustedNodeQuery(node);
        end
        
        function obj = StarTopology(totalNodes, trustedNodesAlg, fiberOpts)
            obj.TrustedNodesAlg = trustedNodesAlg;
            
            obj.Nodes = 1:totalNodes;
            trustedNodes = obj.getTrustedNodesForAlg(trustedNodesAlg, totalNodes);
            
            adjacencyMatrix = zeros(totalNodes, totalNodes);
            
            % Initialize node data
            labels = strings(totalNodes,1);
            x = zeros(totalNodes,1);
            y = zeros(totalNodes,1);
            
            % Subtract last node (central node) when calculating theta
            theta = 2 * pi / (totalNodes - 1);
            radius = 1;
            for node = 1:totalNodes
                
                % First trusted node is Alice
                if (node == trustedNodes(1))
                    labels(node) = 'A';
                % Last trusted node is Bob
                elseif (node == trustedNodes(end))
                    labels(node) = 'B';
                % Trusted Node
                elseif (ismember(node, trustedNodes))
                    labels(node) = ['T_{', num2str(node), '}'];
                % Repeater
                else
                    labels(node) = ['R_{', num2str(node), '}'];
                end
                
                % Last node is central node
                if (node == totalNodes)
                    x(node) = 0;
                    y(node) = 0;
                else
                    % Place in coords to layout nodes in a ring
                    x(node) = radius * sin(theta * (node - 1));
                    y(node) = radius * cos(theta * (node - 1));

                    % All nodes connect to central node (last node)
                    adjacencyMatrix(totalNodes, node) = 1;
                    adjacencyMatrix(node, totalNodes) = 1;
                end
                
            end
            obj.AdjacencyMatrix = adjacencyMatrix;
            obj.TrustedNodes = trustedNodes;
            obj.trustedNodeQuery = ismember(obj.Nodes, obj.TrustedNodes);
            obj.Labels = labels;
            obj.X = x;
            obj.Y = y;
            
            % Mirror adjacency matrix but store probability of
            % successful fiber length transfer from node to node
            obj.CachedBellStateProbs = zeros(size(adjacencyMatrix));
               
            if (isfield(fiberOpts, 'L'))
                obj.L = fiberOpts.L;
            end
            if (isfield(fiberOpts, 'ALPHA'))
                obj.ALPHA = fiberOpts.ALPHA;
            end
            
            for node1 = 1:size(adjacencyMatrix,1)
                for node2 = node1:size(adjacencyMatrix,1)
                    % Number of fiber segments from node1 to node2 is
                    % assumed to be the same (this is the numerical value
                    % in the adjacency matrix - the weight)
                    fiberSegments = adjacencyMatrix(node1, node2); 
                    if (fiberSegments == 0)
                        continue;
                    end
                    % Probability of successful entanglement despite Fiber loss
                    p = 10 ^ ((-obj.ALPHA * obj.L * fiberSegments) / 10);
                    % Add probability of connection to both sides
                    obj.CachedBellStateProbs(node1, node2) = p;
                    obj.CachedBellStateProbs(node2, node1) = p;
                end
            end
        end
        
        function disconnectNode(obj, node)
            obj.AdjacencyMatrix(node,:) = 0;
            obj.AdjacencyMatrix(:,node) = 0;
        end
        
        function result = getName(obj)
            result = "T-" + obj.TrustedNodesAlg + "_" + string(length(obj.Nodes)) + "-node-star";
        end
        
        function prob = fiberProb(obj, node1, node2)
            prob = obj.CachedBellStateProbs(node1, node2);
        end
        
        function plot(obj)
            g = graph(obj.AdjacencyMatrix);
            p = plot(g, 'k');
            layout(p, 'layered');
            
            for i = 2:4
                obj.Labels(i) = "U_" + num2str(i);
            end
            for i = 6:8
                obj.Labels(i) = "U_" + num2str(i);
            end
            obj.Labels(9) = "_{9}";
            p.NodeLabel = obj.Labels;
            edgeWeights = g.Edges.Weight;
            edgeLabels = strings(size(edgeWeights));
            for i = 1:numel(edgeWeights)
                if edgeWeights(i)  > 1
                    edgeLabels(i) = num2str(edgeWeights(i));
                else
                    edgeLabels(i) = "";
                end
            end
            p.EdgeLabel = edgeLabels;
            p.XData = obj.X;
            p.YData = obj.Y;
            highlight(p, obj.Nodes, 'NodeFontWeight', 'bold', 'MarkerSize', 10);
            p.LineWidth = 1;
            p.NodeFontSize = 16;
            
            %Line
            %width=600;
            %height=350;
            % Square
            % width=600;
            % height=500;
            % screenSize = get(0,'ScreenSize');
            % center = screenSize(3:4) ./ 2;
            % x0 = center(1) - width / 2;
            % y0 = center(2);
            % set(gcf,'position',[x0,y0,width,height]);
        end
        
        function getNodesJSON(obj)
            disp("[");
            numNodes = size(obj.Nodes,2);
            for node = 1:numNodes
                disp("    {");
                disp("        'id':" + num2str(node) + ",");
                if (ismember(node, obj.TrustedNodes))
                    disp("        'label':" + " '" + obj.Labels(node) + "',");
                    disp("        'trusted':" + " true");
                else
                    disp("        'label':" + " '" + node + "',");
                    disp("        'trusted':" + " false");
                end
                suffix = ",";
                if (node == numNodes)
                    suffix = "";
                end
                disp("    }" + suffix);
            end
            disp("];");
        end
        
        function getEdgesJSON(obj)
            g = graph(obj.AdjacencyMatrix);
            disp("const fiberLinks = [");
            numEdges = height(g.Edges);
            for edge = 1:numEdges
                nodes = g.Edges(edge,1);
                from = nodes{1,1}(1);
                to = nodes{1,1}(2);
                suffix = ",";
                if (edge == numEdges)
                    suffix = "";
                end
                disp("    {'from':" + num2str(from) + ",'to':" + num2str(to)+"}" + suffix);
            end
            disp("];");
        end
        
        function plotAdjacencyMatrix(obj, adjacencyMatrix)
            p = plot(graph(adjacencyMatrix));
            layout(p, 'layered');
            p.NodeLabel = obj.Labels;
            p.XData = obj.X;
            p.YData = obj.Y;
            highlight(p, obj.TrustedNodes, 'NodeFontWeight', 'bold', 'MarkerSize', 6);
        end
    end
        
     methods(Access=private)
         function result = getTrustedNodesForAlg(obj, trustedNodesAlg, totalNodes)
             % Subtract the central node (the last node)
             exteriorNodes = totalNodes - 1;
             halfway = round((exteriorNodes + 1) / 2);
             if (trustedNodesAlg == "2-corners")
                 result = [1, halfway];
             elseif (trustedNodesAlg == "4-corners")
                 result = [1, round(halfway / 2), halfway, round(3 * halfway / 2)];  
             elseif (trustedNodesAlg == "all")
                 % result = zeros(size(obj.Nodes));
                 % result(1:halfway + 1) = obj.Nodes(1:halfway + 1);
                 % result(halfway:totalNodes) = flip(obj.Nodes(halfway:totalNodes));
                 % Just include the central node rather than having all
                 % other nodes (dead ends) be considered trusted
                 result = [1, totalNodes, halfway];
             else
                 error("Invalid trusted node algorithm '" + trustedNodesAlg + "'");
             end
         end
     end
end