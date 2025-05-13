addpath topologies;
addpath routers;
addpath networks;
addpath utils;

generatePlot(0.1:0.05:0.5, 1);

function generatePlot(failureRange, fig)
    TOTAL_NETWORKS = 1000; % Number of randomly dropped networks
    TOTAL_ROUNDS = 1000; % Rounds per network
    trustedNodeAlg = "2-corners";

    networkOpts = struct;
    
    [topologies, lineNames] = getTopologies(trustedNodeAlg);
    [routers, lineStyles] = getRouters();
    
    allKeyRates = zeros(numel(topologies), numel(failureRange));
    
    for lineIdx = 1:numel(topologies)
        topology = topologies(lineIdx);
        for failureIdx = 1:numel(failureRange)
            probOfFailure = failureRange(failureIdx);
            disp("(" + datestr(now,'HH:MM:SS') + ") " + "... running scenario '" + lineNames(lineIdx) + "' '" + num2str(failureRange(failureIdx))  + "' ");
            keyRates = zeros(size(1, TOTAL_NETWORKS));
            % Store original adjaceny matrix
            originalAdjacencyMatrix = topology.AdjacencyMatrix;
            for networkIdx = 1:TOTAL_NETWORKS
                % Remove adjacencies for random nodes
                removeNodes(topology, probOfFailure);     
                keyRate = runScenario(TOTAL_ROUNDS, topology, routers(lineIdx), networkOpts);
                keyRates(networkIdx) = keyRate;
                % Restore adjacency matrix
                topology.AdjacencyMatrix = originalAdjacencyMatrix;
            end
            allKeyRates(lineIdx, failureIdx) = mean(keyRates);
        end
    end
    disp(allKeyRates);
    
    plotArgs = cell(1, size(topologies,1) * size(topologies,2) * 3);
    for lindeIdx = 1:size(topologies,1)
        line = topologies(lindeIdx,:);
        for j = 1:numel(line) 
            cellIdx = (lindeIdx * 3) * ((j - 1) * 3 + 1);
            plotArgs(1, cellIdx:(cellIdx + 2)) = {failureRange, allKeyRates(lindeIdx, :,j), lineStyles(lindeIdx, j)};
        end
    end
    
    figure(fig);
    plot(plotArgs{:});
    styleGraphPlot();
    legend(lineNames);
    
    xlabel("Probability of Node Failure");
    ylabel("Key Rate");

   fileName = "T-" + trustedNodeAlg + "_global-router_50";
   
   writecell(plotArgs, "results/node-failures/" + fileName + ".csv");
    
   saveas(gcf,"figures/node-failures/" + fileName + ".png");
end

function [topologies, lineNames] = getTopologies(trustedNodeAlg)
    fiberOpts = [
        struct;
        struct;
        struct
    ];
    fiberOpts(1).L = 50 / sqrt(2) / (3 - 1);
    fiberOpts(2).L = 50 / sqrt(2) / (5 - 1);
    fiberOpts(3).L = 50 / sqrt(2) / (5 - 1);
    topologies = [
        SquareTopology(3, trustedNodeAlg, fiberOpts(1));
        SmallWorldTopology.load(5, trustedNodeAlg, fiberOpts(2));
        SquareTopology(5, trustedNodeAlg, fiberOpts(3))
    ];
    lineNames = ["3x3 Regular"; "5x5 Rewired"; "5x5 Regular"];
end

function [routers, lineStyles] = getRouters()
    routers = [GlobalRouter; GlobalRouter; GlobalRouter];
    lineStyles = ["--r*"; "--bo"; "--m+"];
end

function removeNodes(topology, probabilityOfFailure)
    for node = topology.Nodes
        if(doesEventHappen(probabilityOfFailure))
            topology.disconnectNode(node);
        end
    end
end