addpath topologies;
addpath routers;
addpath networks;
addpath utils;

L = 1:2:150;
L_small = 1:1:30;

% generatePlot("direct", 'L', 'key', 1:2:250);
% generateTopologyImages();

% generatePlot("3-stage-burst", 'L', "key", 1:80);
%generatePlot("3-stage-profile", 'L', "key", 1:2:150);
generatePlot("e91-burst", 'L', "all", 1:2:150);
%generatePlot("e91-profile", 'L', "key", 1:2:250);
% generatePlot("decoy-profile", 'L', "key", 1:2:150);


% generatePlot("3-stage", 'L', "key", L);
% generatePlot("line_all_trusted", 'L', 'key', L);
% generatePlot("line", 'L', 'key', L_small);


% generatePlot("square_all_trusted", 'L', 'key', L_small);
% generatePlot("square", 'L', 'key', L_small);
% generatePlot("square", 'L', 'error', L_small);
% generatePlot("ring_all_trusted", 'L', 'key', L_small);
% generatePlot("ring", 'L', 'key', L_small);
% generatePlot("star_all_trusted", 'L', 'key', L_small);
% generatePlot("star", 'L', 'key', L_small);


% generatePlot("direct", 'D', 'key', [0, 0.02, 0.035, 0.05, 0.065]);
%generatePlot("line", 'D', 'key', [0, 0.02, 0.035, 0.05, 0.065]);
%generatePlot("line", 'B', 'key', [0.65, 0.75, 0.85, 0.95, 1]);
%generatePlot("line", 'S', 'key', [3,4,5,6,7]);
% generatePlot("square", 'D', 'key', [0, 0.01, 0.015, 0.02, 0.025, 0.03, 0.035]);
% generatePlot("square", 'B', 'key', [0.65, 0.75, 0.85, 0.95, 1]);
% generatePlot("square", 'S', 'key', [3,4,5,6,7]);
% generatePlot("ring", 'D', 'key', [0, 0.02, 0.035, 0.05, 0.065]);
% generatePlot("ring", 'B', 'key', [0.65, 0.75, 0.85, 0.95, 1]);
% generatePlot("star", 'D', 'key', [0, 0.02, 0.035, 0.05, 0.065]);
% generatePlot("star", 'B', 'key', [0.65, 0.75, 0.85, 0.95, 1]);

% networkOpts = struct;
% networkOpts.type = "E91";
% [rates, network] = runScenario(1000, getTopology("e91-profile", 4, 'L', 1), [GlobalRouter], networkOpts);


function generateTopologyImages()
    %scenarios = ["direct", "line_all_trusted", "line", "square_all_trusted", "square", "ring_all_trusted", "ring", "star_all_trusted", "star"];
    scenarios = ["star_all_trusted", "star"];
    
    for i = 1:numel(scenarios)
        scenarioKey = scenarios(i);
        topo = getTopology(scenarioKey, 1, "L", 1);
        topo.plot();
        fileName = scenarioKey + "_topo";
        pause(1);
        % saveas(gcf,"figures/topologies/" + fileName + ".png");
    end
end

function generatePlot(scenarioKey, xKey, yKey, xVals)
    scenarioName = getScenarioName(scenarioKey);
    scenarioDescription = getScenarioDescription(scenarioKey, xKey);
    xName = getXName(scenarioKey, xKey);
    
    [yKeys, yNames, ySelectors] = getYSelectors(yKey);
    
    logMsg("generating plot '" + scenarioName + "' for variable " + xName);
    TOTAL_ROUNDS = 10000;
    
    [lineStyles, lineCount] = getLineStyles(scenarioKey, xKey);
    allYVals = zeros(size(xVals, 1), lineCount, size(yKeys, 2));
    
    lineNames = strings(lineCount, 1);
    
    for lineIdx = 1:lineCount
        lineNames(lineIdx) = getLineName(scenarioKey, lineIdx, xKey);
        logMsg("... " + lineNames(lineIdx));
        
        for i = 1:numel(xVals)
            networkOpts = getNetworkOpts(scenarioKey, lineIdx, xKey, xVals(i));
            topology = getTopology(scenarioKey, lineIdx, xKey, xVals(i));
            logMsg("...... running scenario '" + num2str(xVals(i)) + "'");            
            [keyRate, network] = runScenario(TOTAL_ROUNDS, topology, [GlobalRouter], networkOpts);
            for yIdx = 1:size(yKeys,2)
                ySelector = ySelectors{yIdx};
                allYVals(lineIdx,i, yIdx) = ySelector(keyRate, network);
            end
        end
    end
    
    for yIdx = 1:size(yKeys,2)
        yKey = yKeys{yIdx};
        yName = yNames{yIdx};
        yVals = allYVals(:,:,yIdx);
        disp(yName);
        disp(yVals);
        % If line styles included
        hasLineStyles = ~isempty(lineStyles);
        if (hasLineStyles)
            plotArgsBlock = 3;
        else
            plotArgsBlock = 2;
        end
        plotArgs = cell(1, lineCount * plotArgsBlock);
        for i = 1:lineCount
            cellIdx = (i - 1) * plotArgsBlock  + 1;
            
            if (hasLineStyles)
                plotArgs(1, cellIdx:(cellIdx + plotArgsBlock - 1)) = {xVals, yVals(i,:), lineStyles(i)};
            else
                plotArgs(1, cellIdx:(cellIdx + plotArgsBlock - 1)) = {xVals, yVals(i,:)};
            end
        end
        figure(yIdx);
        p = plot(plotArgs{:});
        %for i = 1:size(yVals, 1)
            % p(i).MarkerIndices = 1:length(xVals)/10:length(xVals);
        %end
        title(getScenarioName(scenarioKey));
        chartSubTitle = "";
        if (TOTAL_ROUNDS < 100000)
            chartSubTitle = "Rounds: " + TOTAL_ROUNDS;
        end
        if (length(scenarioDescription) > 1)
            chartSubTitle = chartSubTitle + ", " + scenarioDescription;
        end
        subtitle(chartSubTitle, 'Interpreter','none');
        xlabel(xName);
        ylabel(yName);
        legend(lineNames);
        styleGraphPlot();

        fileName = scenarioKey + "_" + string(xKey);
        if (yKey ~= "key")
            fileName = fileName + "_" + yKey;
        end
        fileName = fileName + "_" + TOTAL_ROUNDS;

        pause(5);
        saveas(gcf,"figures/topologies/" + fileName + ".png");

        T = array2table(transpose(yVals));
        T.Properties.VariableNames(1:numel(lineNames)) = lineNames;
        writetable(T,"results/topologies/" + fileName + ".csv");
    end
end

function xName = getXName(scenarioKey, xKey)
    if (scenarioKey == "direct" || scenarioKey == "e91-profile" || scenarioKey == "3-stage-profile" || scenarioKey == "decoy-profile" || scenarioKey == "3-stage-burst" || scenarioKey == "e91-burst")
        xName = "Distance A - B";
    else
        xName = xKey;
    end
end

function [yKeys, yNames, ySelectors] = getYSelectors(yKey)
    if (yKey == "error")
        yKeys = {yKey};
        yNames = {"Error Rate"};
        ySelectors = {@selectErrorRate};
    elseif (yKey == "key")
        yKeys = {yKey};
        yNames = {"Key Rate"};
        ySelectors = {@selectKeyRate};
    elseif (yKey == "all")
        yKeys = {"key", "error"};
        yNames = {"Key Rate", "Error Rate"};
        ySelectors = {@selectKeyRate, @selectErrorRate};
    else
        error("No ySelector for '" + yKey + "'");
    end
end

function keyRate = selectKeyRate(keyRate, ~)
end

function errorRate = selectErrorRate(~, network)
    errorRate = network.calculateAvgErrorRate();
    if (errorRate == 0)
        errorRate = nan;
    end
end

function [scenarioNames, scenarioKeys] = getScenarioName(scenarioKey)
    lookup = containers.Map('KeyType','char','ValueType','char');
    lookup("direct") = "Direct A - B";
    lookup("3-stage-burst") = "3-Stage Burst";
    lookup("3-stage-profile") = "3-Stage Profile";
    lookup("e91-burst") = "E91 Burst";
    lookup("e91-profile") = "E91 Profile";
    lookup("decoy-profile") = "Decoy Profile";
    lookup("decoy") = "Decoy";
    lookup("line") = "Line";
    lookup("line_all_trusted") = "Line (All Trusted Nodes)";
    lookup("square") = "Square";
    lookup("square_all_trusted") = "Square (All Trusted Nodes)";
    lookup("ring") = "Ring";
    lookup("ring_all_trusted") = "Ring (All Trusted Nodes)";
    lookup("star") = "Star";
    lookup("star_all_trusted") = "Star (All Trusted Nodes)";
    scenarioKeys = cell2mat(keys(lookup));
    if (isKey(lookup, scenarioKey))
        scenarioNames = lookup(scenarioKey);
    else
        error("No name for scenario '" + scenarioKey + "'");
    end
end

function description = getScenarioDescription(scenarioKey, ~)
    lookup = containers.Map('KeyType','char','ValueType','char');
    % lookup("3-stage-profile") = "Using Trusted Nodes";
    % lookup("e91-profile") = "Using Quantum Repeaters";
    % lookup("decoy-profile") = "Using Trusted Nodes";
    if (isKey(lookup, scenarioKey))
        description = lookup(scenarioKey);
    else
        description = "";
    end
end

function lineName = getLineName(scenarioKey, lineIdx, ~)
    networkOpts = getNetworkOpts(scenarioKey, lineIdx, "", 0);
    lineName = networkOpts.type;
    % Include E91 with repeater
    if (scenarioKey == "direct" && lineIdx == 4)
        lineName = "E91 (Repeater)";
    elseif (scenarioKey == "3-stage-burst" || scenarioKey == "e91-burst")
        lineName = "Burst = " + networkOpts.BURST;
    elseif (scenarioKey == "e91-profile" || scenarioKey == "3-stage-profile" || scenarioKey == "decoy-profile")
        lines = ["Line", "Square", "Ring", "Star"];
        lineName = lines(lineIdx);
        
    end
end

function [lineStyles, lineCount] = getLineStyles(scenarioKey, ~)
    if (scenarioKey == "direct")
        lineStyles = [];
        lineCount = 4;
        return;
    elseif (scenarioKey == "3-stage-burst" || scenarioKey == "e91-burst")
        % lineStyles = [ "-->", "--x", "--v"];
        % lineStyles = ["-", "--", ":"];
        lineStyles = [];
        lineCount = 5;
        return;
    elseif (scenarioKey == "e91-profile" || scenarioKey == "3-stage-profile" || scenarioKey == "decoy-profile")
        lineStyles = ["-", "--", ":", "-."];
    else
        % lineStyles = ["--r*", "--m+",  "--bo"];
        lineStyles = ["-r", "--m", ":b"];
    end
    lineCount = size(lineStyles, 2);
    lineStyles = [];
end

function networkOpts = getNetworkOpts(scenarioKey, lineIdx, xKey, xValue)
    networkOpts = struct;
    
    protocols = ["Decoy", "3-Stage", "E91"];
    
    if (scenarioKey == "3-stage-burst")
        networkOpts.type = protocols(2);
        burstValues = [1, 5, 10, 15, 20];
        networkOpts.BURST = burstValues(lineIdx);
    elseif (scenarioKey == "e91-burst")
        networkOpts.type = protocols(3);
        burstValues = [1, 5, 10, 15, 20];
        networkOpts.BURST = burstValues(lineIdx);
    elseif (scenarioKey == "e91-profile")
        networkOpts.type = protocols(3);
        % If star network, simulate quantum repeater
        if (lineIdx == 4)
            % Leave default B and D
        end
    elseif (scenarioKey == "3-stage-profile")
        networkOpts.type = protocols(2);
        % If star network, simulate switch
        if (lineIdx == 4)
            networkOpts.B = 1;
            networkOpts.D = 0.02 / 2;
        end
    elseif (scenarioKey == "decoy-profile")
        networkOpts.type = protocols(1);
        % If star network, simulate switch
        if (lineIdx == 4)
            networkOpts.B = 1;
            networkOpts.D = 0.02 / 2;
        end
    elseif (scenarioKey == "direct")
        % After plain E91, we do E91 with repeater
        if (lineIdx == 3)
            networkOpts.BURST = 1;
        elseif (lineIdx == 4)
            lineIdx = 3;
        end
        networkOpts.type = protocols(lineIdx);
        
    else
        networkOpts.type = protocols(lineIdx);
    end
    
    % networkOpts.B = 0.85;
    % networkOpts.D = 0.02;

    % Set X variable
    if (contains(xKey, {'B', 'D'}))
        networkOpts.(xKey) = xValue;
    end
end

function topology = getTopology(scenarioKey, lineIdx, xKey, xValue)
    topologyOpts = struct;
    LINE_DIM = 3;
    SQUARE_DIM = 3;
    RING_DIM = 8;
    STAR_DIM = 9;
    
    if(xKey == 'L')
        topologyOpts.(xKey) = xValue;        
    end
    
    % If scenario is "direct" or we are using the 3-Stage protocol
    if(scenarioKey == "direct")
        % Here we simulate E91 with a single repeater
        if (lineIdx == 4)
            % Single repeater divides distance
            topologyOpts.L = xValue / 2;
            topology = RectTopology(1, 3, "2-corners", topologyOpts);
        else
            topology = RectTopology(1, 2, "all", topologyOpts);
        end    
    elseif (scenarioKey == "3-stage-burst")
         topology = RectTopology(1, 2, "all", topologyOpts);
    elseif (scenarioKey == "e91-burst")
         % Single repeater divides distance
         topologyOpts.L = xValue / 2;
         topology = RectTopology(1, 3, "2-corners", topologyOpts);
    elseif (scenarioKey == "e91-profile" || scenarioKey == "3-stage-profile" || scenarioKey == "decoy-profile")
        % lines = ["Line", "3x3 Square", "Ring", "Star"];
        tnAlg = "all";
        % Use repeaters for E91
        if (scenarioKey == "e91-profile")
            tnAlg = "2-corners";
        % Simulate optical switch for Star topology
        elseif (lineIdx == 4)
            % The middle will not be a trusted node
            tnAlg = "2-corners";
        end
        if (lineIdx == 1)
            topologyOpts.L = xValue / (LINE_DIM - 1);
            topology = RectTopology(1, LINE_DIM, tnAlg, topologyOpts);
        elseif (lineIdx == 2)
            topologyOpts.L = xValue / sqrt(2) / (SQUARE_DIM - 1);
            topology = SquareTopology(SQUARE_DIM, tnAlg, topologyOpts);
        elseif (lineIdx == 3)
            radius = xValue / 2;
            theta = 2 * pi / RING_DIM;
            topologyOpts.L = radius * theta;
            topology = RingTopology(RING_DIM, tnAlg, topologyOpts); 
        elseif (lineIdx == 4)
            radius = xValue / 2;
            topologyOpts.L = radius;
            if (scenarioKey ~= "e91-profile")
                % Simulate higher loss due to switch
                topologyOpts.ALPHA = 0.4;
                % NOTE: We set B=1 and D=0 in the network to simulate an
                % internal switch (a "repeater" with no effect from bell state
                % measurement and decoherence)
            end
            topology = StarTopology(STAR_DIM, tnAlg, topologyOpts);
        else
            error("Unsupported lineIdx '" + lineIdx + "'");
        end
    elseif(scenarioKey == "line")
        if (xKey == 'S')
            LINE_DIM = xValue;
        end
         topology = RectTopology(1, LINE_DIM, "2-corners", topologyOpts);
    elseif(scenarioKey == "line_all_trusted")
        if (xKey == 'S')
            LINE_DIM = xValue;
        end
         topology = RectTopology(1, LINE_DIM, "all", topologyOpts);
    elseif (scenarioKey == "square")
        if (xKey == 'S')
            SQUARE_DIM = xValue;
        end
        topology = SquareTopology(SQUARE_DIM, "2-corners", topologyOpts);
    elseif (scenarioKey == "square_all_trusted")
        if (xKey == 'S')
            SQUARE_DIM = xValue;
        end
        topology = SquareTopology(SQUARE_DIM, "all", topologyOpts);
    elseif (scenarioKey == "ring")
        if (xKey == 'S')
            RING_DIM = xValue;
        end
        topology = RingTopology(RING_DIM, "2-corners", topologyOpts); 
    elseif (scenarioKey == "ring_all_trusted")
        if (xKey == 'S')
            RING_DIM = xValue;
        end
        topology = RingTopology(RING_DIM, "all", topologyOpts); 
    elseif (scenarioKey == "star")
        if (xKey == 'S')
            STAR_DIM = xValue;
        end
        topology = StarTopology(STAR_DIM, "2-corners", topologyOpts);
    elseif (scenarioKey == "star_all_trusted")
        if (xKey == 'S')
            STAR_DIM = xValue;
        end
        topology = StarTopology(STAR_DIM, "all", topologyOpts);
    else
        error("Unsupported scenario '" + scenarioKey + "'");
    end
end