# tests/test_simulation.py

import unittest
import simpy
from src.routing import setup_simulation, nodes

class TestSimulation(unittest.TestCase):
    def setUp(self):
        # Clear the global nodes list before each test
        del nodes[:]
        self.env = simpy.Environment()
        setup_simulation(self.env)
        
    def test_nodes_created(self):
        # Verify that at least one node has been created
        self.assertGreater(len(nodes), 0, "No nodes were created in the simulation.")
        
    def test_simulation_runs_without_errors(self):
        # Run the simulation for a short period to ensure it executes without errors
        try:
            self.env.run(until=10)
        except Exception as e:
            self.fail(f"Simulation raised an exception: {e}")

if __name__ == "__main__":
    unittest.main()
