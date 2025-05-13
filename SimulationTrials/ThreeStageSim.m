addpath topologies;
addpath routers;
addpath networks;
addpath utils;

generatePlot("2-corners", 'L', [1,3,5,10,15], true);
% generatePlot("2-corners", 'D', [0, 0.02, 0.035, 0.05, 0.065], true);
% generatePlot("2-corners", 'BURST', [1, 2, 3, 4, 5, 6], true);

% generatePlot("2-corners", 'L', [1,3,5,10,15], false);
% generatePlot("2-corners", 'D', [0, 0.02, 0.035, 0.05, 0.065], false);
% generatePlot("2-corners", 'BURST', [1, 2, 3, 4, 5, 6], false);

% t = RectTopology(1, 2, "2-corners");
% disp(runScenario(10000, t, [GlobalRouter], struct));
 
function generatePlot(trustedNodeAlg, optField, X, isQKD)
    disp("(" + datestr(now,'HH:MM:SS') + ") " + "generating plot '" + trustedNodeAlg + " " + optField + "'");
    TOTAL_ROUNDS = 100000;
    
    [routers, lineStyles] = getRouters();
        maxKeyRate = 0;
    allKeyRates = zeros(size(X, 2), size(routers,2));
    
    XLabels = string(size(X));
    for i = 1:numel(X)
        opts = struct;
        opts.type = "Three-Stage";
        opts.QKD = isQKD;
        fiberOpts = struct;
         
        topology = RectTopology(1, 2, trustedNodeAlg, fiberOpts);
        if (strcmp(optField,"S") || strcmp(optField,"B"))
            error('Invalid variable for three stage network');
            % topology = SquareTopology(X(i), trustedNodeAlg);
        elseif (optField == 'L')
            % Convert normal L to direct Euclidian distance
            fiberOpts.(optField) = sqrt(2 * ((5 - 1) * X(i)) ^ 2); 
            XLabels(i) = num2str(fiberOpts.(optField)) + " (" + num2str(X(i) + ")");
            % Overwrite topology
            topology = RectTopology(1, 2, trustedNodeAlg, fiberOpts);
        else
            opts.(optField) = X(i);
            % Convert default L to direct Euclidian distance
            opts.L = sqrt(2 * ((5 - 1) * 1) ^ 2); 
            XLabels(i) = num2str(X(i));
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
    xticklabels(XLabels);
    legend(routerNames);
    
    chartTitle = "3-Stage Sim";
    
    if (isQKD)
        chartSubTitle = "QKD ";
    else
        chartSubTitle = "Raw";
    end
    
    chartSubTitle = chartSubTitle + "Trusted Nodes: " + trustedNodeAlg;

    if (optField == 'S')
        topologyLabel = "";
    else
        topologyLabel = string(topology.getName()) + "_";
        chartSubTitle = chartSubTitle + ", Topology: " + topologyLabel;
    end
    chartSubTitle = chartSubTitle + ", Variable: " + optField;
    title(chartTitle, chartSubTitle);
    if (isQKD)
        fileName = "qkd_";
    else
        fileName = "raw_";
    end
    fileName = fileName + "T-" + trustedNodeAlg + "_" + topologyLabel + string(optField) + ".png";
    saveas(gcf,"figures/three-stage/" + fileName);
end

function [routers, lineStyles] = getRouters()
    % routers = [GlobalRouter; LocalRouter(true); LocalRouter];
    % lineStyles = ["--r*", "--bo", "--m+"];
    routers = [GlobalRouter];
    lineStyles = ["--r*"];
end