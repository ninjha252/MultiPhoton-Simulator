function result = calculateSlope(topology, node1, node2)
    nodeX = topology.X(node1);
    nodeY = topology.Y(node1);
    node2X = topology.X(node2);
    node2Y = topology.Y(node2);
    result = (node2Y - nodeY) / (node2X - nodeX);
end

