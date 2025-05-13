classdef RectTopology < Topology
    %RectTopology Create a rectangular topology
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
        TrustedNodesAlg = []
        Rows = 1;
        Cols = 1;
        CachedBellStateProbs;
    end
   
    methods
        function obj = RectTopology(rows, cols, trustedNodesAlg, fiberOpts)
            obj.TrustedNodesAlg = trustedNodesAlg;
            obj.Rows = rows;
            obj.Cols = cols;
            totalNodes = rows * cols;
            
            obj.Nodes = 1:totalNodes;
            trustedNodes = obj.getTrustedNodesForAlg(trustedNodesAlg, rows, cols);
            
            adjacencyMatrix = zeros(totalNodes, totalNodes);
            
            % Initialize node data
            labels = strings(totalNodes,1);
            x = zeros(totalNodes,1);
            y = zeros(totalNodes,1);
            
            for node = 1:totalNodes
                row = ceil(node / cols);
                col = mod(node - 1, cols) + 1;
                
                % First trusted node is Alice
                if (node == trustedNodes(1))
                    labels(node) = 'A';
                % Last trusted node is Bob
                elseif (node == trustedNodes(end))
                    labels(node) = 'B';
                % Trusted Node
                elseif (ismember(node, trustedNodes))
                    labels(node) = ['_{T_{', num2str(node), '}}'];
                % Router
                else
                    labels(node) = ['_{R_{', num2str(node), '}}'];
                end
                
                % Place in coords to layout nodes in a rectangle
                x(node) = col;
                y(node) = rows - row;

                % Prev in row
                if (col > 1)
                    adjacencyMatrix(node - 1, node) = 1;
                end
                % Next in row
                if(col < cols)
                    adjacencyMatrix(node + 1, node) = 1;
                end
                % Prev in col
                if (row > 1)
                    adjacencyMatrix(node - cols, node) = 1;
                end
                % Next in col
                if(row < rows)
                    adjacencyMatrix(node + cols, node) = 1;
                end
            end
            obj.AdjacencyMatrix = adjacencyMatrix;
            obj.TrustedNodes = trustedNodes;
            obj.Labels = labels;
            obj.X = x;
            obj.Y = y;
               
            obj.init(fiberOpts);
        end
        
        function init(obj, fiberOpts)
            
            if (isfield(fiberOpts, 'L'))
                obj.L = fiberOpts.L;
            end
            if (isfield(fiberOpts, 'ALPHA'))
                obj.ALPHA = fiberOpts.ALPHA;
            end
            obj.trustedNodeQuery = ismember(obj.Nodes, obj.TrustedNodes);
            
            % Mirror adjacency matrix but store probability of
            % successful fiber length transfer from node to node
            obj.CachedBellStateProbs = zeros(size(obj.AdjacencyMatrix));
            
            for node1 = 1:size(obj.AdjacencyMatrix,1)
                for node2 = node1:size(obj.AdjacencyMatrix,1)
                    % Number of fiber segments from node1 to node2 is
                    % assumed to be the same (this is the numerical value
                    % in the adjacency matrix - the weight)
                    fiberSegments = obj.AdjacencyMatrix(node1, node2); 
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
            result = "T-" + obj.TrustedNodesAlg + "_" + string(obj.Rows) + "-by-" + string(obj.Cols);
        end
        
        function prob = fiberProb(obj, node1, node2)
            prob = obj.CachedBellStateProbs(node1, node2);
        end
        
        function result = isTrustedNode(obj, node)
            result = obj.trustedNodeQuery(node);
        end
        
        function plot(obj)
            g = graph(obj.AdjacencyMatrix);
            p = plot(g, 'k');
            layout(p, 'layered');
            
            % Replace intermediate labels with num
            totalNodes = numel(obj.Nodes);
            if (totalNodes > 2)
                for i = 2:(totalNodes - 1)
                    obj.Labels(i) = "_" + num2str(i);
                end
            end
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
            highlight(p, obj.TrustedNodes, 'NodeFontWeight', 'bold', 'MarkerSize', 10);
            p.LineWidth = 1;
            p.NodeFontSize = 16;
            
            %Line
            if (obj.Rows == 1)
                width=600;
                height= 500 / 2;
            else
                % Square
                width=600;
                height=500;
            end
            % screenSize = get(0,'ScreenSize');
           % center = screenSize(3:4) ./ 2;
            %x0 = center(1) - width / 2;
           % y0 = center(2);
            %set(gcf,'position',[x0,y0,width,height]);
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
         function result = getTrustedNodesForAlg(obj, trustedNodesAlg, rows, cols)
             topRightCorner = cols;
             bottomLeftCorner = rows * cols - cols + 1;
             bottomRightCorner = rows * cols;
             if (trustedNodesAlg == "2-corners")
                 result = [1, bottomRightCorner];
             elseif (trustedNodesAlg == "3-diagonal")
                 result = [1, floor(rows / 2) * cols + round(cols / 2), bottomRightCorner];
             elseif (trustedNodesAlg == "4-corners")
                 result = [1, topRightCorner, bottomLeftCorner, bottomRightCorner];  
             elseif (trustedNodesAlg == "all")
                 result = obj.Nodes;
             else
                 error("Invalid trusted node algorithm '" + trustedNodesAlg + "'");
             end
         end
     end
end