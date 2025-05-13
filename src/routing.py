# src/routing.py

import networkx as nx
import random
from .packet import Packet
from .link import Link

# Global lists to store nodes and links for the simulation
nodes = []
links = []

def routing_engine(current_node, packet, risk_weight=1.0):
    """
    Compute a route from the current node to the packet's destination using a composite cost:
    cost = latency + (risk_weight * risk)
    """
    # Build a directed graph of the network topology
    graph = nx.DiGraph()
    for node in nodes:
        graph.add_node(node.name)
    for link in links:
        cost = link.latency + risk_weight * link.risk
        graph.add_edge(link.source.name, link.dest.name, weight=cost, link_obj=link)
    try:
        path = nx.dijkstra_path(graph, current_node.name, packet.destination.name, weight='weight')
        if len(path) < 2:
            return None
        next_node_name = path[1]
        # Find the link from the current node to the next hop
        for link in current_node.neighbors:
            if link.dest.name == next_node_name:
                return link
    except nx.NetworkXNoPath:
        return None

def send_packet(env, packet, link):
    """
    Simulate transmission delay over a link and forward the packet.
    """
    yield env.timeout(link.latency)
    packet.path.append(link)
    yield link.dest.queue.put(packet)
    print(f"{env.now}: {packet} transmitted via {link}")

def packet_generator(env, source, destination, sensitivity):
    """
    Generate packets at random intervals from source to destination.
    """
    while True:
        yield env.timeout(random.expovariate(1))
        packet = Packet(source, destination, sensitivity, creation_time=env.now)
        print(f"{env.now}: Generated {packet}")
        yield source.queue.put(packet)

def setup_simulation(env):
    """
    Set up the network topology, initialize nodes, links, and start processes.
    """
    # Import Node locally to avoid circular import issues
    from .node import Node

    # Create nodes
    node_A = Node(env, "A")
    node_B = Node(env, "B")
    node_C = Node(env, "C")
    node_D = Node(env, "D")
    nodes.extend([node_A, node_B, node_C, node_D])
    
    # Create links between nodes
    link_AB = Link(env, node_A, node_B, latency=2, bandwidth=10, risk=1)
    link_BC = Link(env, node_B, node_C, latency=2, bandwidth=10, risk=2)
    link_CD = Link(env, node_C, node_D, latency=2, bandwidth=10, risk=1)
    link_AD = Link(env, node_A, node_D, latency=5, bandwidth=10, risk=3)
    link_BD = Link(env, node_B, node_D, latency=3, bandwidth=10, risk=2)
    links.extend([link_AB, link_BC, link_CD, link_AD, link_BD])
    
    # Associate nodes with their outgoing links
    node_A.add_link(link_AB)
    node_A.add_link(link_AD)
    node_B.add_link(link_BC)
    node_B.add_link(link_BD)
    node_C.add_link(link_CD)
    
    # Start the packet processing for each node
    for node in nodes:
        env.process(node.process_packets())
    
    # Start the packet generator process (packets from node A to node D)
    env.process(packet_generator(env, node_A, node_D, sensitivity=5))
