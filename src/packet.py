# src/packet.py

class Packet:
    def __init__(self, source, destination, sensitivity=0, creation_time=0):
        self.source = source
        self.destination = destination
        self.sensitivity = sensitivity  # Higher value indicates more sensitive data
        self.creation_time = creation_time
        self.path = []  # Records the links traversed

    def __repr__(self):
        return f"Packet({self.source.name} -> {self.destination.name}, sensitivity={self.sensitivity})"
