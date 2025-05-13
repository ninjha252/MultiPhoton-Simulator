# MultiPhoton-Simulator
# Quantum Network Simulator

A hybrid MATLAB & Python framework for simulating and analyzing quantum key distribution (QKD) protocols over a variety of network topologies and under different failure scenarios. This toolkit allows you to:

- Compare key‐rate performance across topologies (grid, torus, ring, star, small-world, etc.).
- Evaluate multiple QKD protocols (E91, Decoy-State, Three‐Stage, Walter, etc.).
- Test routing strategies (Global vs. Local routing) and assess their impact.
- Study the resilience of trusted‐node networks under random node failures.
- Generate publication-quality plots and CSV reports.

---

---

## Features

- **Topologies:** Square, torus, ring, star, small‐world, custom rewired networks  
- **Protocols:**  
  - **E91** (entanglement‐based)  
  - **Decoy-State BB84**  
  - **Three-Stage** quantum routing  
  - **Walter** protocol and custom trial scripts  
- **Routing Algorithms:**  
  - **GlobalRouter** (network-wide shortest paths)  
  - **LocalRouter** (node-local greedy / interference-aware)  
- **Failure Modeling:** Random node drops, link outages, trusted‐node failures  
- **Metrics:** Secret key rates per round, Shannon entropy of error pools, edge usage statistics  
- **Output:** CSV exports, Excel spreadsheets, PNG figures, MATLAB plots  

---


