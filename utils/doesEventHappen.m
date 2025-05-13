% Determine if the event with given probability happened
function result = doesEventHappen(probability)
    if (rand() <= probability)
        result = true;
    else
        result = false;
    end
end

