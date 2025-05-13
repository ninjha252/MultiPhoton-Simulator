# src/link.py

class Link:
    def __init__(self, env, source, dest, latency, bandwidth, risk=0):
        self.env = env
        self.source = source
        self.dest = dest
        self.latency = latency      # Transmission delay (in time units)
        self.bandwidth = bandwidth  # Placeholder for future extension
        self.risk = risk            # Risk metric for this link

    def __repr__(self):
        return f"Link({self.source.name} -> {self.dest.name}, latency={self.latency}, risk={self.risk})"
