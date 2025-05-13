function [keyRates, network] = runScenario(TOTAL_ROUNDS, topology, routers, opts)
    network = Network.create(topology, routers, opts);
    for i = 1:TOTAL_ROUNDS
        network.runRound();
    end
    keyRates = network.calculateKeyRates();
end