# sage implementation of the leafage parameter for chordal graphs
# following the article "Polynomial-Time Algorithm for the Leafage of Chordal Graphs"
# by M. Habib and J. Stacho, see https://doi.org/10.1007/978-3-642-04128-0_27
# authors: Manfred Scheucher and Helena Bergold, 2024
#
# Optimized by Claude (Anthropic), 2025:
# Clique-tree nodes are represented as integers (via clique2id/id2clique dicts)
# instead of comma-separated strings. This avoids repeated string construction,
# splitting, and set-conversion during the main loop, reducing both memory usage
# and running time by a factor of O(n) per lookup.

import warnings
warnings.filterwarnings("ignore", category=DeprecationWarning)

from itertools import *

def leafage(G0, certificate=0, debug=0):
    G = copy(G0)
    G.relabel({v: str(v) for v in G})

    is_chordal, peo = G.is_chordal(certificate=True)
    assert(is_chordal)

    if debug >= 2:
        print("peo", peo)

    if debug >= 3:
        G.plot().save("G.png")
        for i in range(len(peo)):
            v = peo[i]
            N = set(G.neighbors(v)) & set(peo[i:])
            for a, b in combinations(N, 2):
                assert(G.has_edge(a, b))

    # --- integer-keyed clique registry ---
    _next_id = [0]
    clique2id = {}   # frozenset -> int
    id2clique = {}   # int -> frozenset

    def clique_id(fs):
        """Return the integer id for frozenset fs, registering it if new."""
        if fs not in clique2id:
            i = _next_id[0]
            _next_id[0] += 1
            clique2id[fs] = i
            id2clique[i] = fs
        return clique2id[fs]

    def create_clique_tree(G, peo):
        n = len(G)
        clique_tree = Graph()  # vertices are ints

        for i in reversed(range(n)):
            v = peo[i]
            N = frozenset(G.neighbors(v)) & frozenset(peo[i:])
            N_id = clique_id(N)

            if N_id in clique_tree:
                if debug >= 2:
                    print(f"extend previous maxclique {set(N)} by {v}")
                new_id = clique_id(N | frozenset([v]))
                clique_tree.relabel({N_id: new_id})
            else:
                if debug >= 2:
                    print(f"create new maxclique {N | {v}}")
                new_id = clique_id(N | frozenset([v]))

                if clique_tree:
                    found = 0
                    for C_id in clique_tree:
                        if id2clique[C_id].issuperset(N):
                            found += 1
                            clique_tree.add_edge(C_id, new_id)
                            break
                    assert(found)
                else:
                    clique_tree.add_vertex(new_id)

        return clique_tree

    T = create_clique_tree(G, peo)

    if debug >= 2:
        print("T", [(set(id2clique[a]), set(id2clique[b])) for a, b in T.edges(labels=0)])

    if debug >= 3:
        G_pos = G.get_pos()
        T_pos = {}
        for C_id in T:
            C = id2clique[C_id]
            T_pos[C_id] = sum(vector(G_pos[v]) for v in C) / len(C)
        T.set_pos(T_pos)

    if debug:
        print("start with clique tree", T.edges(labels=0))

    if debug >= 2:
        label_len = max(len(id2clique[v]) for v in T)
        vertex_size = 200 * label_len
        T.plot(vertex_size=vertex_size).save('clique_tree.png')

    # --- precompute separator intersection ids and H_S graphs ---
    if debug:
        print("precompute H_S graphs (later used to test connected components)")

    # sep2id: frozenset (separator) -> int id (reuses clique_id registry)
    intersection_hash = {}  # (C1_id, C2_id) -> sep_id
    for C1_id, C2_id in combinations(sorted(T.vertices()), 2):
        sep = id2clique[C1_id] & id2clique[C2_id]
        sep_id = clique_id(sep)
        intersection_hash[C1_id, C2_id] = sep_id
        intersection_hash[C2_id, C1_id] = sep_id

    if debug >= 2:
        print("intersection_hash", intersection_hash)

    H = {}  # sep_id -> Graph (vertices are clique ints)
    for a_id, b_id in T.edges(labels=False):
        sep = id2clique[a_id] & id2clique[b_id]
        sep_id = clique_id(sep)
        if sep_id not in H:
            H[sep_id] = Graph()
            for C_id in T:
                if id2clique[C_id].issuperset(sep):
                    H[sep_id].add_vertex(C_id)
            C_list = sorted(H[sep_id].vertices())
            for C1_id, C2_id in combinations(C_list, 2):
                if intersection_hash[C1_id, C2_id] != sep_id:
                    H[sep_id].add_edge(C1_id, C2_id)
            if debug >= 2:
                print(f"H {set(sep)} -> {H[sep_id].edges(labels=0)}")

    # precompute connected components
    same_connected_component = {
        (C1, C2, t): H[t].distance(C1, C2) != Infinity
        for t in H
        for C1 in H[t]
        for C2 in H[t]
    }

    step = 0

    # compute initial tau: for each clique node, list of separator ids of adjacent edges
    tau = {v: [] for v in T.vertices()}
    for a_id, b_id in T.edges(labels=False):
        sep_id = clique_id(id2clique[a_id] & id2clique[b_id])
        tau[a_id].append(sep_id)
        tau[b_id].append(sep_id)

    while 1:
        if debug >= 2:
            print("step", step, ":  leafage <=", len({v for v in tau if len(tau[v]) == 1}))
            print(f"tau {tau}")

        if debug >= 3:
            tokentree = copy(T)
            tokentree.relabel({v: str(set(id2clique[v])) + ": " + str(tau[v]) for v in T})
            token_vertex_size = 200 * max(len(v) for v in tokentree)
            tokentree.plot(vertex_size=token_vertex_size, figsize=20).save(f'tokentree{step}.png')

        D = DiGraph()

        for C in T.vertices():
            if len(tau[C]) >= 2:
                for t in set(tau[C]):
                    C2_exists = False
                    if tau[C].count(t) >= 2:
                        C2_exists = True
                    if not C2_exists:
                        for C2 in T.vertices():
                            if C2 != C and t in tau[C2] and same_connected_component[C, C2, t]:
                                C2_exists = True
                                break

                    for C1 in H[t]:
                        if C1 != C:
                            if same_connected_component[C, C1, t] or C2_exists:
                                D.add_edge(C, C1, t)

        if debug >= 2:
            print("D:", D.edges(labels=1))
        if debug >= 3:
            D2 = DiGraph(D.edges())
            D2.relabel({v: f"{v}/{len(tau[v])}" for v in D})
            D2.plot(vertex_size=1000, edge_labels=1, figsize=20).save(f'D{step}.png')

        D_V = D.vertices()
        D.add_vertex('dummy_start')
        D.add_vertex('dummy_end')
        for v in D_V:
            if len(tau[v]) >= 3: D.add_edge('dummy_start', v)
            if len(tau[v]) == 1: D.add_edge(v, 'dummy_end')

        augmenting_path = []
        for P in D.shortest_simple_paths('dummy_start', 'dummy_end'):
            augmenting_path = P[1:-1]
            break

        if debug:
            print("*** augmenting_path:", augmenting_path)

        if augmenting_path:
            for i in range(1, len(augmenting_path)):
                u = augmenting_path[i - 1]
                v = augmenting_path[i]
                t = D.edge_label(u, v)
                tau[u].remove(t)
                tau[v].append(t)
            step += 1
        else:
            break

    leafage_val = len({v for v in tau if len(tau[v]) == 1})
    if debug:
        print("leafage = ", leafage_val)

    def tree_from_sequence(a):
        if len(a) <= 2:
            Ta = Graph()
            for v in a: Ta.add_vertex(v)
            for u, v in combinations(a, 2): Ta.add_edge(u, v)
            return Ta
        else:
            for v in a:
                if a[v] == 1:
                    for u in a:
                        if a[u] > 1:
                            Ta = tree_from_sequence({w: (a[w] if w != u else a[u] - 1) for w in a if w != v})
                            Ta.add_edge(u, v)
                            return Ta
            exit(f"invalid degree sequence: {a}")

    if certificate:
        # R has the same integer vertices as T (clique ids)
        R = Graph()
        for v in T:
            R.add_vertex(v)

        for sep_id in H:
            if debug >= 2:
                print(f"representation part for {set(id2clique[sep_id])}")

            comps = H[sep_id].connected_components()
            k = len(comps)
            a = {}
            seq = {}
            for i in range(k):
                seq[i] = []
                for v in comps[i]:
                    seq[i] += tau[v].count(sep_id) * [v]
                a[i] = len(seq[i])
                assert(a[i]) >= 1
            assert(sum(a.values()) == 2 * k - 2)
            Ta = tree_from_sequence(a)

            for i, j in Ta.edges(labels=0):
                R.add_edge(seq[i].pop(), seq[j].pop())

            for i in range(k):
                assert(len(seq[i]) == 0)

        if debug:
            print("representation:", R.edges(labels=0))

        if debug >= 2:
            R.plot(vertex_size=1000, figsize=10).save("R.png")

        if debug:
            # verify_representation: for each vertex v, cliques containing v form connected subtree
            for v in G:
                C_v = [C for C in R if v in id2clique[C]]
                assert(R.subgraph(C_v).is_connected())
            assert(R.degree().count(1) == leafage_val)
            if debug:
                print("valid representation")

    # return T with original string labels for compatibility with callers
    def set2str(fs, symbol=','):
        return symbol.join(sorted(fs))

    T_labeled = T.copy()
    T_labeled.relabel({cid: set2str(id2clique[cid]) for cid in T_labeled})

    if certificate:
        R_labeled = R.copy()
        R_labeled.relabel({cid: set2str(id2clique[cid]) for cid in R_labeled})
        return (leafage_val, T_labeled, R_labeled)
    else:
        return (leafage_val, T_labeled)


def astroidal_triples(G):
    AT = set()
    V = set(G.vertices())
    for a, b, c in combinations(sorted(V), 3):
        Ga = G.subgraph(V - {a})
        Gb = G.subgraph(V - {b})
        Gc = G.subgraph(V - {c})
        if Ga.distance(b, c) < Infinity and Gb.distance(a, c) < Infinity and Gc.distance(a, b) < Infinity:
            AT.add((a, b, c))
    return AT


def max_astroidal_sets(AT, remaining, selection=tuple()):
    extension = False
    for u in remaining:
        valid = True
        for a, b in combinations(selection, 2):
            if (a, b, u) not in AT:
                valid = False
                break
        if valid:
            for AS in max_astroidal_sets(AT, remaining=[v for v in remaining if v > u], selection=selection + (u,)):
                extension = True
                yield AS
    if not extension:
        yield selection


def astroidal_number(G):
    AT = astroidal_triples(G)
    V = list(sorted(G.vertices()))
    max_AS = list(max_astroidal_sets(AT, remaining=V))
    return max(len(AS) for AS in max_AS)


def leafage_lower(G):
    return astroidal_number(G)


def simplicial_vertices(G):
    return {v for v in G if G.subgraph(G.neighbors(v)).is_clique()}


def leafage_upper(G):
    exit("something is broken")
    simplicial = simplicial_vertices(G)

    X = []
    for v in simplicial:
        x = set(G.neighbors(v)) - simplicial
        x = tuple(sorted(x))
        if x not in X:
            X.append(x)

    print(X)
    D = [(x, y) for (x, y) in combinations(X, 2) if set(x).issubset(set(y))]
    print(D)
    P = Poset(DiGraph(D))
    return P.width()
