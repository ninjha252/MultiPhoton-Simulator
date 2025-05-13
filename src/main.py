# src/main.py

import simpy
from .routing import setup_simulation

def main():
    run_time = 50  # Simulation run time (in time units)
    env = simpy.Environment()
    setup_simulation(env)
    env.run(until=run_time)

if __name__ == '__main__':
    main()
