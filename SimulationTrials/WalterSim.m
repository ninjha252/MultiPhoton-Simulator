addpath topologies;
addpath routers;
addpath networks;
addpath utils;

% generatePlot("2-corners", 'L', [1,3,5,10,15]);
% generatePlot("2-corners", 'D', [0, 0.02, 0.035, 0.05, 0.065]);
% generatePlot("2-corners", 'B', [0.65, 0.75, 0.85, 0.95, 1]);
% generatePlot("2-corners", 'S', [5,7,9,11,13]);
% generatePlot("3-diagonal", 'L', [1,3,5,10,15]);
% generatePlot("3-diagonal", 'D', [0, 0.02, 0.035, 0.05, 0.065]);
% generatePlot("3-diagonal", 'B', [0.65, 0.75, 0.85, 0.95, 1]);
% generatePlot("3-diagonal", 'S', [5,7,9,11,13]);

% disp(runScenario(10000, SquareTopology(7, "4-corners"), [GlobalRouter], struct));
 
function generatePlot(trustedNodeAlg, optField, X)
    disp("(" + datestr(now,'HH:MM:SS') + ") " + "generating plot '" + trustedNodeAlg + " " + optField + "'");
    TOTAL_ROUNDS = 100000;

    fiberOpts = struct;
    topology = SquareTopology(5, trustedNodeAlg, fiberOpts);
    
    [routers, lineStyles] = getRouters();
        maxKeyRate = 0;
    allKeyRates = zeros(size(X, 2), size(routers,2));
    
    for i = 1:numel(X)
        opts = struct;
        opts.type = "E91";
        if (optField == 'S')
            topology = SquareTopology(X(i), trustedNodeAlg, fiberOpts);
        elseif (optField == 'L')
            fiberOpts.(optField) = X(i); 
            topology = SquareTopology(5, trustedNodeAlg, fiberOpts);
        else
            opts.(optField) = X(i);
        end
        disp("(" + datestr(now,'HH:MM:SS') + ") " + "... running scenario '" + num2str(X(i)) + "'");            
        keyRates = runScenario(TOTAL_ROUNDS, topology, routers, opts);
        for j = 1:numel(keyRates)
            keyRate = keyRates(j);
            allKeyRates(i,j) = keyRate;
            if (keyRate > maxKeyRate)
                maxKeyRate = keyRate;
            end
        end
    end
    disp(allKeyRates);
    
    routerNames = strings(size(routers));
    
    plotArgs = cell(1, size(routers,1) * 3);
    for i = 1:numel(routers)
        cellIdx = (i - 1) * 3 + 1;
        plotArgs(1, cellIdx:(cellIdx + 2)) = {X, allKeyRates(:,i), lineStyles(i)};
        routerNames(i) = routers(i).getName();
    end
    plot(plotArgs{:});
    legend(routerNames);
    
    chartTitle = "Walter Sim";
    chartSubTitle = "Trusted Nodes: " + trustedNodeAlg;

    if (optField == 'S')
        topologyLabel = "";
    else
        topologyLabel = string(topology.getName()) + "_";
        chartSubTitle = chartSubTitle + ", Topology: " + topologyLabel;
    end
    chartSubTitle = chartSubTitle + ", Variable: " + optField;
    title(chartTitle, chartSubTitle);
    saveas(gcf,"figures/walter/T-" + trustedNodeAlg + "_" + topologyLabel + string(optField) + ".png");
end

function [routers, lineStyles] = getRouters()
    % routers = [GlobalRouter; LocalRouter(true); LocalRouter];
    routers = [GlobalRouter; LocalRouter];
    % lineStyles = ["--r*", "--bo", "--m+"];
    lineStyles = ["--r*", "--m+"];
end