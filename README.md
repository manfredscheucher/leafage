# Leafage – SageMath Implementation

This repository provides a **SageMath implementation** of the *leafage* algorithm for chordal graphs,
based on the paper *"Polynomial-Time Algorithm for the Leafage of Chordal Graphs"* by **Michel Habib** and **Juraj Stacho**,
DOI: [10.1007/978-3-642-04128-0_27](https://doi.org/10.1007/978-3-642-04128-0_27).

## Contents

* `leafage.sage` — main implementation of the leafage algorithm
* `enum_l4.sage` — auxiliary routines (e.g. enumeration)
* `ipe2graph2.sage` — converter: reads IPE (`.ipe`) drawings and builds a Sage `Graph` (wrapper around the `ipe2graph` submodule)
* `ipe2graph/` — git submodule: [manfredscheucher/ipe2graph](https://github.com/manfredscheucher/ipe2graph)
* `test.sage` — test suite with example chordal graphs
* `example.ipe` — example IPE file for building a graph

## Requirements

* **SageMath** (tested with SageMath 10.x)

## Setup

After cloning, initialize the submodule:

```bash
git clone --recurse-submodules <repo-url>
# or if already cloned:
git submodule update --init
```

## Usage

### Compute leafage from a Sage graph

```sage
load("leafage.sage")

G = Graph({0: [1, 2], 1: [2], 2: [3], 3: []})
L, T = leafage(G)

print("Leafage:", L)
T.show()   # visualize the clique-tree with minimal leaves

# with certificate (intersection representation):
L, T, R = leafage(G, certificate=True)
```

### Using an IPE file as input

```sage
load("ipe2graph2.sage")
load("leafage.sage")

G = ipe_to_graph("example.ipe")
L, T = leafage(G)
print("Leafage:", L)
```

### Running tests

```bash
sage test.sage
```

Runs a set of predefined test cases to verify the implementation.

## API

### `leafage(G, certificate=False, debug=0)`

Computes the leafage of a chordal graph `G`.

* `G` — a SageMath `Graph` (must be chordal)
* `certificate=False` — if `True`, also returns an intersection representation
* Returns `(L, T)` where `L` is the leafage value and `T` is the clique tree
* Returns `(L, T, R)` if `certificate=True`, where `R` is the representation tree

### `ipe_to_graph(path)`

Reads an IPE drawing from `path` and returns a SageMath `Graph`.

## Notes

* The algorithm assumes the input graph is **chordal**.
* Internally, clique-tree nodes are represented as comma-separated strings of vertex labels; using integer indices could improve performance.

---

*Implementation by Manfred Scheucher and Helena Bergold, 2024. Revised with Claude (Anthropic), 2025.*
