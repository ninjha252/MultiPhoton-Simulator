classdef TorusTopology < Topology
    properties
        % Add additional properties as needed
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
        Rows = 3;
        Cols = 3;
        CachedBellStateProbs;
    end

    methods
        function obj = TorusTopology(totalNodesX, totalNodesY, trustedNodesAlg, fiberOpts)

            % Initialize other properties like AdjacencyMatrix, TrustedNodes, Nodes, Labels, X, Y, etc.
            
            % Your properties initialization here
            obj.TrustedNodesAlg = trustedNodesAlg;
            obj.Rows = totalNodesX;
            obj.Cols = totalNodesY;
            totalNodes = totalNodesX * totalNodesY;


            obj.Nodes = 1:totalNodes;
            trustedNodes = obj.getTrustedNodesForAlg(trustedNodesAlg, totalNodesX, totalNodesY);
            
            adjacencyMatrix = zeros(totalNodes, totalNodes);
            
            % Initialize node data
            labels = strings(totalNodes,1);
            x = zeros(totalNodes,1);
            y = zeros(totalNodes,1);

            for i=1:totalNodesX
                for j=1:totalNodesY
                    node = (i - 1) * totalNodesY + j;
                    if (node == trustedNodes(1))
                        labels(node) = 'A';
                    % Last trusted node is Bob
                    elseif (node == trustedNodes(end))
                        labels(node) = 'B';
                    elseif (ismember(node, trustedNodes))
                        labels(node) = ['_{T_{', num2str(node), '}}'];
                    % Router
                    else
                        labels(node) = ['_{R_{', num2str(node), '}}'];
                    end 
                    
                    % For first column and last column
                    if j == 1
                        leftNeighbor = node + (totalNodesY - 1);
                    else
                        leftNeighbor = node - 1;
                    end
                    
                    % For first row and last row
                    if i == 1
                        upperNeighbor = node + (totalNodesX - 1) * totalNodesY;
                    else
                        upperNeighbor = node - totalNodesY;
                    end
                    
                    adjacencyMatrix(node, leftNeighbor) = 1;
                    adjacencyMatrix(leftNeighbor, node) = 1;
                    adjacencyMatrix(node, upperNeighbor) = 1;
                    adjacencyMatrix(upperNeighbor, node) = 1;
                end
            end
            obj.AdjacencyMatrix = adjacencyMatrix;
            obj.TrustedNodes = trustedNodes;
            obj.X = x;
            obj.Y=y;
            obj.init(fiberOpts);
            obj.Labels = labels;

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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function plot(obj)
            g = graph(obj.AdjacencyMatrix);
            p = plot(g, 'k');
            layout(p, "auto");
            
            % Replace intermediate labels with num
            totalNodes = numel(obj.Nodes);
            if (totalNodes > 2)
                for i = 2:(totalNodes - 1)
                    obj.Labels(i) = "_" + num2str(i);
                end
            end
            p.NodeLabel = obj.Labels;
            highlight(p, obj.TrustedNodes, 'NodeFontWeight', 'bold', 'MarkerSize', 10);

        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        
        
        function disconnectNode(obj, node)
            obj.AdjacencyMatrix(node,:) = 0;
            obj.AdjacencyMatrix(:,node) = 0;
            % Disconnection logic similar to the RingTopology
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
        

    end
    
    methods(Access=private)
        function result = getTrustedNodesForAlg(obj, trustedNodesAlg, totalNodesX, totalNodesY)
        if (trustedNodesAlg == "all")
            result = obj.Nodes; 
        end
        end
    end
end
