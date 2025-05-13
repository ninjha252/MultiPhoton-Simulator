# src/node.py

import simpy

class Node:
    def __init__(self, env, name):
        self.env = env
        self.name = name
        self.queue = simpy.Store(env)
        self.neighbors = []  # Outgoing links

    def add_link(self, link):
        self.neighbors.append(link)

    def process_packets(self):
        # Import routing functions locally to avoid circular dependencies
        from .routing import routing_engine, send_packet
        while True:
            packet = yield self.queue.get()
            print(f"{self.env.now}: Node {self.name} received {packet}")
            if self == packet.destination:
                print(f"{self.env.now}: Node {self.name} delivered {packet}")
            else:
                next_link = routing_engine(self, packet)
                if next_link:
                    print(f"{self.env.now}: Node {self.name} forwarding {packet} via {next_link}")
                    yield self.env.process(send_packet(self.env, packet, next_link))
                else:
                    print(f"{self.env.now}: Node {self.name} found no route for {packet}")
