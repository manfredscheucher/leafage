# test suite for leafage.sage
# authors: Manfred Scheucher and Helena Bergold, 2024

import warnings
warnings.filterwarnings("ignore", category=DeprecationWarning)

load("leafage.sage")

def test(G, expected_leafage):
	L, T = leafage(G)
	assert L == expected_leafage, f"expected leafage {expected_leafage}, got {L}"
	print(f"OK: leafage = {L}")

# path graph P4: leafage = 1
test(Graph({0: [1], 1: [2], 2: [3]}), 1)

# complete graph K4: leafage = 1
test(graphs.CompleteGraph(4), 1)

# the example from the paper (Habib & Stacho)
G = Graph([(0, 1), (1, 2), (1, 3), (1, 4), (1, 5), (2, 4), (3, 5), (4, 5), (4, 6), (4, 9), (4, 10), (5, 6), (5, 7), (5, 8), (6, 7)])
G.relabel({0:'a',1:'c',2:'b',3:'d',4:'f',5:'g',6:'j',7:'k',8:'h',9:'e',10:'i'})
test(G, 4)

# simple chordal graph
test(Graph({0: [1, 2], 1: [2], 2: [3], 3: []}), 1)

print("all tests passed")
