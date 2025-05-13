addpath topologies;
addpath routers;
addpath networks;
addpath utils;

% opts = struct;
% opts.L = 30 / sqrt(2) / (5 - 1);
% [~, network] = runScenario(1000000, SmallWorldTopology.load(5, "2-corners"), [GlobalRouter], opts);
% writeFile("results/5by5-corners-rewired-route-edges.csv", edgeUsageToCSV(network.RouteEdgeUsage, network));
% writeFile("results/5by5-corners-rewired-successful-edges.csv", edgeUsageToCSV(network.SuccessfulEdgeUsage,network));

% generatePlot("2-corners", 'L', [1,3,5,10,15]);
generatePlot("2-corners", 'B', [0.65, 0.75, 0.85, 0.95, 1], 1);
generatePlot("2-corners", 'D', [0, 0.02, 0.035, 0.05, 0.065], 2);
% todo -generatePlot("2-corners", 'S', [5,7,9,11,13]);
%generatePlot("3-diagonal", 'L', [1,3,5,10,15]);
% generatePlot("3-diagonal", 'D', [0, 0.02, 0.035, 0.05, 0.065], 1);
% generatePlot("3-diagonal", 'B', [0.65, 0.75, 0.85, 0.95, 1], 2);
%generatePlot("3-diagonal", 'S', [5,7,9,11,13]);

% generatePlot("2-corners", 'L', [1,3,5,10,15]);

function generatePlot(trustedNodeAlg, optField, X, fig)
    TOTAL_ROUNDS = 10000;
    dimension = 5;

    [topologies, lineNames] = getTopologies(dimension, trustedNodeAlg);
        
    [routers, lineStyles] = getRouters();
    plotArgs = plotScenarios(TOTAL_ROUNDS, fig, X, optField, topologies, routers, [struct; struct; struct], lineNames, lineStyles);

    fileName = "T-" + trustedNodeAlg + "_local-router_" + string(optField);
   
    writecell(plotArgs, "results/small-world/" + fileName + ".csv");
    
    saveas(gcf,"figures/small-world/" + fileName + ".png");
end

function fiberOpts = getFiberOpts(dimension)
    fiberOpts = [
        regular3by3Opts; rewired5by5Opts; regular5by5Opts
    ];
end

function [topologies, lineNames] = getTopologies(dimension, trustedNodeAlg)
    
    distanceBetweenAandB = 30;
    regular3by3Opts = struct;
    regular3by3Opts.L = distanceBetweenAandB / sqrt(2) / (3 - 1);
    rewired5by5Opts = struct;
    rewired5by5Opts.L = distanceBetweenAandB / sqrt(2) / (dimension - 1);
    regular5by5Opts = struct;
    regular5by5Opts.L = distanceBetweenAandB / sqrt(2) / (dimension - 1);
    topologies = [
        SquareTopology(3, trustedNodeAlg, regular3by3Opts);
        SmallWorldTopology.load(dimension, trustedNodeAlg, rewired5by5Opts);
        SquareTopology(dimension, trustedNodeAlg, regular5by5Opts)
    ];
    lineNames = ["3x3 Regular"; "5x5 Rewired"; "5x5 Regular"];
end

function [routers, lineStyles] = getRouters()
    routers = [LocalRouter; LocalRouter; LocalRouter];
    lineStyles = ["--r*"; "--bo"; "--m+"];
end