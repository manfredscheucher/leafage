# Leafage – SageMath Implementation

This repository provides a **SageMath implementation** of the *leafage* algorithm for chordal graphs, 
based on the paper *“Polynomial-Time Algorithm for the Leafage of Chordal Graphs”* by **Michel Habib** and **Juraj Stacho**, 
DOI: [10.1007/978-3-642-04128-0_27](https://doi.org/10.1007/978-3-642-04128-0_27). 

## Contents

* `leafage.sage` — main implementation of the leafage algorithm
* `enum_l4.sage` — auxiliary routines (e.g. enumeration)
* `ipe2graph2.sage` — converter: reads IPE (`.ipe`) drawings and builds a Sage `Graph`
* `test.sage` — test suite with example chordal graphs
* `example.ipe` — example IPE file for building a graph

## Requirements

* **SageMath** (make sure to use a compatible version)

## Usage

### Compute leafage from a Sage graph

```sage
load("leafage.sage")

G = Graph({0: [1, 2], 1: [2], 2: [3], 3: []})
L, T = leafage(G)

print("Leafage:", L)
T.show()   # visualize the clique-tree with minimal leaves
```

### Using IPE as input

```sage
load("ipe2graph2.sage")
G = ipe_to_graph("example.ipe")
L, T = leafage(G)
print("Leafage:", L)
```

### Running tests

```sage
load("test.sage")
```

Runs a set of predefined test cases to check if the implementation works correctly.

## Notes & Limitations

* The algorithm assumes the input graph is **chordal**.
* For large graphs, the runtime may become significant (the original algorithm is (O(n^3))).
* Internally, the current implementation uses strings as node labels; using integer indices instead could improve performance.
