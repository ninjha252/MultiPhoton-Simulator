function result = randomlyChoose(probabilityDistribution)
    result = sum(rand >= cumsum([0, probabilityDistribution]));
end

