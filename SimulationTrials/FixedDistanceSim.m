addpath topologies;
addpath routers;
addpath networks;
addpath utils;

generateMultiProbabilitiesTradeoffPlot(30:20:150);
% generateProbabilitiesTradeoffPlot(50,1,'D');
generateProbabilitiesTradeoffPlot(50,2, 'L');
% generatePlot("2-corners", distanceBetweenTrustedNodes, true, 2);
%generatePlot("2-corners", d, false, 2);
 
function generatePlot(trustedNodeAlg, distanceBetweenTrustedNodes, isSquare, fig)
    TOTAL_ROUNDS = 100000;
    
    % Number of points to calculate
    numOfPoints = 10;
    
    partialDistance = min(distanceBetweenTrustedNodes / 6, 10);
    % How much to increment in range
    inc = max([floor(partialDistance / numOfPoints), 1]);
    X = 1:inc:partialDistance;
    
    [routers, lineStyles] = getRouters();
    maxKeyRate = 0;
    allKeyRates = zeros(size(X, 2), size(routers,2));
    
    if (isSquare)
        maxDim = num2str(X(end) + 1) + "x" + num2str(X(end) + 1);
    else
        maxDim = "1x" + num2str(X(end) + 2);
    end
    
    for i = 1:numel(X)
        repeaters = X(i);
        opts = struct;
        fiberOpts = struct;
        % topology = SmallWorldTopology(repeaters + 2, trustedNodeAlg);
        if (isSquare)
            fiberOpts.L = distanceBetweenTrustedNodes / sqrt(2) / repeaters;
            topology = RectTopology(repeaters + 1, repeaters + 1, trustedNodeAlg, fiberOpts);
        else
            fiberOpts.L = distanceBetweenTrustedNodes / (repeaters + 1);
            topology = RectTopology(1, repeaters + 2, trustedNodeAlg, fiberOpts);
        end
        disp("(" + datestr(now,'HH:MM:SS') + ") " + "... running scenario '" + num2str(repeaters) + "' repeaters...");                
          
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
    figure(fig);
    plot(plotArgs{:});
    legend(routerNames);
    
    
    chartTitle = "Fixed Distance Sim";
    chartSubTitle = "Max Dim : " + maxDim;
    chartSubTitle = chartSubTitle + " | Distance: " + distanceBetweenTrustedNodes;
    chartSubTitle = chartSubTitle + " | Trusted Nodes: " + trustedNodeAlg;
    chartSubTitle = chartSubTitle + " | Rounds: " + TOTAL_ROUNDS;
    
    title(chartTitle, chartSubTitle);
    
    topologyLabel = "square_";
    if (~isSquare)
        topologyLabel = "line_";
    end
    % saveas(gcf,"figures/fixed/"+distanceBetweenTrustedNodes + "km-apart_" + "T-" + trustedNodeAlg + "_" + topologyLabel + ".png");
end


function generateProbabilitiesTradeoffPlot(distanceBetweenTrustedNodes, fig, xAxisChoice)    
    dimensions = 2:min(distanceBetweenTrustedNodes, 8);
    
    repeaters = dimensions - 1;
    segLengths = distanceBetweenTrustedNodes ./  sqrt(2) ./ repeaters;
    
    if (xAxisChoice == 'L')
        xAxis = segLengths;
    else
        xAxis = dimensions;
    end
    
    fiberLenProb = 10 .^ ((-0.15 .* segLengths / 10));
    lengthOfBestPath = repeaters .* 2;
    for i = 1:numel(fiberLenProb)
        % Best path is probability of 1 segment ^ (repeaters * 2)
        bestPathProbOfFailure = 1 - (fiberLenProb(i) ^ lengthOfBestPath(i));
        % Number of best paths
        numOfBestPaths = nchoosek(repeaters(i) * 2, repeaters(i));
        fiberLenProb(i) = 1 - (bestPathProbOfFailure ^ numOfBestPaths);
    end
    B = 0.85;
    D = 0.02;
    bsmProb1 =  (B) .^ max(lengthOfBestPath - 2, 0);
    noDecProb1 = (1 - D) .^ (lengthOfBestPath - 1);
    % And now account for accidentally decohering to expected state
    noDecProb1 = noDecProb1 + (1 - noDecProb1) / 2;
    hopProb1 = bsmProb1 .* noDecProb1;
    
    
    B = 0.99;
    D = 0.02;
    bsmProb2 =  (B) .^ max(lengthOfBestPath - 2, 0);
    noDecProb2 = (1 - D) .^ (lengthOfBestPath - 1);
    % And now account for accidentally decohering to expected state
    noDecProb2 = noDecProb2 + (1 - noDecProb2) / 2;
    hopProb2 = bsmProb2 .* noDecProb2;
    
    figure(fig);
    plot(xAxis, fiberLenProb, xAxis, hopProb1, xAxis, hopProb2);
    ylim([0 1]);
    legend(["Step 1", "Step 2 (B=0.85)", "Step 2 (B=0.99)"]);
    
    % chartTitle = "Prob. of at least 1 shortest path available vs prob. of path len failure";
    % chartSubTitle = "Distance: " + distanceBetweenTrustedNodes;
    % title(chartTitle, chartSubTitle);
    
    % title("Fiber vs. Dimension Tradeoff");
    
    if (xAxisChoice == 'L')
        xlabel("Segment Length (L)");
        set(gca, 'XDir','reverse');
    else
        xlabel("Network Dimension");
    end
    
    ylabel("Probability of Success");
    styleGraphPlot();
    % saveas(gcf,"figures/fixed/"+ distanceBetweenTrustedNodes + "km-apart_optimal-repeaters-prob_" + ".png");
end

function generateMultiProbabilitiesTradeoffPlot(distancesBetweenTrustedNodes)
    dimensions = 3:2:15;
    results = zeros(size(dimensions, 2),size(distancesBetweenTrustedNodes, 2));
    
    lineStyles = [
        "--o",
        "--+",
        "--*",
        "-->",
        "--x",
        "--v",
        "--s",
        "--^",
        "--|",
        "--<"
    ];
    plotArgs = cell(1, size(distancesBetweenTrustedNodes, 2) * 2);
    for i = 1:numel(distancesBetweenTrustedNodes)
        distanceBetweenTrustedNodes = distancesBetweenTrustedNodes(i);
        repeaters = dimensions - 1;
        segLengths = distanceBetweenTrustedNodes ./  sqrt(2) ./ repeaters;
        fiberLenProb = 10 .^ ((-0.15 .* segLengths / 10));
        lengthOfBestPath = repeaters .* 2;
        for i2 = 1:numel(fiberLenProb)
            % Best path is probability of 1 segment ^ (repeaters * 2)
            bestPathProbOfFailure = 1 - (fiberLenProb(i2) ^ lengthOfBestPath(i2));
            % Number of best paths
            numOfBestPaths = nchoosek(repeaters(i2) * 2, repeaters(i2));
            fiberLenProb(i2) = 1 - (bestPathProbOfFailure ^ numOfBestPaths);
        end
        bsmProb =  (0.85) .^ max(lengthOfBestPath - 2, 0);
        noDecProb = (1 - 0.2) .^ (lengthOfBestPath - 1);
        % And now account for accidentally decohering to
        % expected state
        noDecProb = noDecProb + (1 - noDecProb) / 2;
        hopProb = bsmProb .* noDecProb;
        overall = fiberLenProb .* hopProb;
        
        plotArgIdx = (i - 1) * 2 + 1;
        plotArgs(1, plotArgIdx:(plotArgIdx + 1)) = {dimensions, overall};
        results(:,i) = overall;
    end
    disp(dimensions);
    disp(results);
    plot(plotArgs{:});
    legend(strcat(num2str(distancesBetweenTrustedNodes'), " km"));
    
    % chartTitle = "Prob. of at least 1 shortest path available vs prob. of path len failure";
    % chartSubTitle = "Distance: " + distanceBetweenTrustedNodes;
    % title(chartTitle, chartSubTitle);
    
    % title("Fiber vs. Dimension Tradeoff");
    xlabel("Network Dimension");
    ylabel("Probability of Success");
    styleGraphPlot();
    
    % saveas(gcf,"figures/fixed/"+ distanceBetweenTrustedNodes + "km-apart_optimal-repeaters-prob_" + ".png");
end

function [routers, lineStyles] = getRouters()
    % routers = [GlobalRouter; LocalRouter(true); LocalRouter];
    % lineStyles = ["--r*", "--bo", "--m+"];
    routers = [GlobalRouter];
    lineStyles = ["--r*"];
end