# Leafage – SageMath Implementation

This repository provides a **SageMath implementation** of the *leafage* algorithm for chordal graphs,
based on the paper *"Polynomial-Time Algorithm for the Leafage of Chordal Graphs"* by **Michel Habib** and **Juraj Stacho**,
DOI: [10.1007/978-3-642-04128-0_27](https://doi.org/10.1007/978-3-642-04128-0_27).

## Content

* `leafage.sage` — main implementation of the leafage algorithm
* `leafage_optimized.sage` — performance-optimized variant (integer-keyed cliques, see below)
* `enumerate.sage` — enumerate chordal graphs by leafage (see below)
* `ipe2graph/` — git submodule: [manfredscheucher/ipe2graph](https://github.com/manfredscheucher/ipe2graph), provides `ipe2graph()` function
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
load("ipe2graph/ipe2graph2.sage")
load("leafage.sage")

G = ipe2graph("example.ipe")
L, T = leafage(G)
print("Leafage:", L)
```

### Enumerating chordal graphs by leafage

`enumerate.sage` enumerates chordal graphs on `n` vertices and prints them in sparse6 format (stdout), with status info on stderr.

```bash
# all chordal graphs on 7 vertices (cf. https://oeis.org/A048193)
sage enumerate.sage -n 7

# connected only, leafage >= 4
sage enumerate.sage -n 7 -c -llow 4

# interval graphs (leafage <= 2, cf. http://oeis.org/A005975)
sage enumerate.sage -n 7  -ig

# interval graphs (leafage <= 2), connected
sage enumerate.sage -n 7 -c -ig

# save matching graphs as PNGs
sage enumerate.sage -n 6 -c -llow 3 --plot
```

**Options:**

| Flag | Description |
|------|-------------|
| `-n N` | number of vertices (required) |
| `-c`, `--connected` | connected graphs only |
| `-llow L` | leafage ≥ L |
| `-lupp U` | leafage ≤ U |
| `-ig`, `--interval-graph` | interval graphs only (sets `-lupp 2`) |
| `-opt`, `--optimized` | use `leafage_optimized.sage` instead of `leafage.sage` |
| `--plot` | save each match as `graph_n<n>_<i>.png` |

**OEIS references** for connected chordal graphs on n vertices:
* all chordal: [A048193](https://oeis.org/A048193) — 1, 2, 4, 10, 27, 94, 393, 2119, …
* interval (leafage ≤ 2): [A005975](https://oeis.org/A005975) — 1, 2, 4, 10, 27, 92, 369, 1807, …

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

### `ipe2graph(path)`

Reads an IPE drawing from `path` and returns a SageMath `Graph`.

## Notes

* The algorithm assumes the input graph is **chordal**.
* `leafage_optimized.sage` provides a performance-optimized variant (see below).

## Performance-optimized variant

`leafage_optimized.sage` is a drop-in replacement for `leafage.sage` with the same API: In `leafage.sage`, clique-tree nodes are represented as comma-separated strings (e.g. `"0,1,2"`), which are repeatedly constructed, split, and converted to sets throughout the algorithm — costing O(n) per operation. In `leafage_optimized.sage`, each unique clique (and separator) is registered once in a `clique2id`/`id2clique` dictionary and identified by an integer thereafter. All internal data structures (`tau`, `H`, `same_connected_component`, etc.) work exclusively with these integers. The string labels are only reconstructed at the very end for the return values, preserving full compatibility with existing callers.

---

*Implementation by Manfred Scheucher and Helena Bergold, 2024. Revised with Claude (Anthropic), 2025.*
