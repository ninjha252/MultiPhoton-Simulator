% Determine if the events with given probabilities happened
function result = doEventsHappen(probabilities)
    result = rand(size(probabilities)) <= probabilities;
end

