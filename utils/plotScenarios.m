function [plotArgs, allKeyRates] = plotScenarios(TOTAL_ROUNDS, fig, X, optField, topologies, routers, networkOpts, lineNames, lineStyles)
    assert(numel(topologies) == numel(routers), "Number of topologies and routers must be the same");
    assert(numel(topologies) == numel(networkOpts), "Number of topologies and networkOpts must be the same");

    disp("(" + datestr(now,'HH:MM:SS') + ") " + "generating plot '" + optField + "'");
    allKeyRates = zeros(numel(topologies), size(X, 2), size(routers,2));
    
    for i = 1:numel(topologies)
        for j = 1:numel(X)
            opts = networkOpts(i);
            opts.(optField) = X(j);

            topology = topologies(i);
            router = routers(i);
            disp("(" + datestr(now,'HH:MM:SS') + ") " + "... running scenario '" + num2str(X(j)) + "' " + topology.getName());                
            [keyRates, network] = runScenario(TOTAL_ROUNDS, topology, router, opts);
            
            for k = 1:numel(keyRates)
                keyRate = keyRates(k);
                allKeyRates(i, j, k) = keyRate;
            end
        end
    end
        
    plotArgs = cell(1, size(routers,1) * size(routers,2) * 3);
    for row = 1:size(routers,1)
        routerRow = routers(row,:);
        for j = 1:numel(routerRow)
            cellIdx = (row * 3) * ((j - 1) * 3 + 1);
            plotArgs(1, cellIdx:(cellIdx + 2)) = {X, allKeyRates(row, :,j), lineStyles(row, j)};
        end
    end

    figure(fig);
    plot(plotArgs{:});
    styleGraphPlot();
    legend(lineNames);
    
    xlabel(optField);
    ylabel("Key Rate");
end

