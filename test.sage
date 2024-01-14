# sage implementation of the leafage parameter for chordal graphs
# following the article "Polynomial-Time Algorithm for the Leafage of Chordal Graphs" 
# by M. Habib and J. Stacho, see https://doi.org/10.1007/978-3-642-04128-0_27
# authors: Manfred Scheucher and Helena Bergold, 2024

import warnings
warnings.filterwarnings("ignore", category=DeprecationWarning)

from sys import argv
from itertools import *
from ast import literal_eval

debug = 0
example = 1
representation = 1
verify_representation = 1


if example:
	G = Graph([(0, 1), (1, 2), (1, 3), (1, 4), (1, 5), (2, 4), (3, 5), (4, 5), (4, 6), (4, 9), (4, 10), (5, 6), (5, 7), (5, 8), (6, 7)])
	G.set_pos({0: (192.0, 640.0), 1: (256.0, 640.0), 2: (256.0, 688.0), 3: (256.0, 592.0), 4: (304.0, 672.0), 5: (304.0, 608.0), 6: (352.0, 640.0), 7: (352.0, 576.0), 8: (304.0, 544.0), 9: (304.0, 720.0), 10: (352.0, 704.0)})
	G.relabel({0:'a',1:'c',2:'b',3:'d',4:'f',5:'g',6:'j',7:'k',8:'h',9:'e',10:'i'})

else:
	G = None # TODO: read from input


is_chordal,peo = G.is_chordal(certificate=True)
assert(is_chordal)


if debug:
	G.plot().save("G.png")
	print("peo",peo)

	for i in range(len(peo)):
		v = peo[i]
		N = set(G.neighbors(v))&set(peo[i:])
		for a,b in combinations(N,2):
			assert(G.has_edge(a,b)) # assert chordal
	

def set2str(x,symbol=','): return symbol.join(sorted(x))
def str2set(x,symbol=','): return {y for y in x.split(symbol)}
#def set2str(x): return str(x)
#def str2set(x): return literal_eval(x)


def create_clique_tree(G,peo):
	n = len(G)
	clique_tree = Graph()

	for i in reversed(range(n)):
		v = peo[i]
		N = set(G.neighbors(v))&set(peo[i:])

		if set2str(N) in clique_tree:
			if debug: print(f"extend previous maxclique {N} by {v}")
			clique_tree.relabel({set2str(N):set2str(N|{v})})
			
		else:
			if debug: print(f"create new maxclique {N|{v}}")

			if clique_tree:
				found = 0
				for C_str in clique_tree:
					if str2set(C_str).issuperset(N):
						found += 1
						clique_tree.add_edge(C_str,set2str(N|{v}))
						break
				assert(found)

			else:
				clique_tree.add_vertex(set2str(N|{v}))

	return clique_tree



T = create_clique_tree(G,peo)

if example:
	# use this particular clique tree
	T = Graph([('a,c', 'b,c,f'), 
		('b,c,f', 'c,f,g'), 
		('f,g,j', 'f,i'), 
		('c,d,g', 'c,f,g'), 
		('c,f,g', 'f,g,j'), 
		('g,j,k', 'g,h'), 
		('e,f', 'f,g,j'), 
		('f,g,j', 'g,j,k')])


if debug:
	G_pos = G.get_pos()
	T_pos = {}
	for C_str in T:
		C = str2set(C_str)
		T_pos[C_str] = sum(vector(G_pos[v]) for v in C)/len(C)
	T.set_pos(T_pos)



print("start with clique tree",T.edges(labels=0))

if debug: 
	vertex_size = 200*max(len(v) for v in T) # only for plotting
	T.plot(vertex_size=vertex_size).save(f'clique_tree.png')



if 0:
	print("compute full clique graph (not used in the following, for redundancy only)")
	CG = Graph()
	#for v in T.vertices(): CG.add_vertex(v)
	for C1str,C2str in combinations(T.vertices(),2):
		C1 = str2set(C1str)
		C2 = str2set(C2str)
		for a in C1-C2:
			for b in C2-C1:
				if G.subgraph(set(G.vertices())-(C1&C2)).distance(a,b) == Infinity:
					CG.add_edge(C1str,C2str)
				break
			break
	CG.plot(vertex_size=vertex_size).save(f'full_clique_graph.png')



if 1:
	print("precompute H_S graphs (later used to test connected components)")
	H = {}
	for a,b in T.edges(labels=False):
		S = str2set(a)&str2set(b) # intersections are minimal separators
		S_str = set2str(S)
		if S_str not in H:
			H[S_str] = Graph()
			for v in T:
				if str2set(v).issuperset(S):
					H[S_str].add_vertex(v)
			for C,C1 in combinations(H[S_str],2):
				if str2set(C)&str2set(C1) != S:
					H[S_str].add_edge(C,C1)
			if debug:
				H[S_str].plot(vertex_size=vertex_size).save(f'H_{S_str}.png')

	# precompute connected components
	same_connected_component = {(C1,C2,t): H[t].distance(C1,C2) != Infinity for t in H for C1 in H[t] for C2 in H[t]}


step = 0

# compute initial tau
tau = {v:[] for v in T.vertices()}

for a,b in T.edges(labels=False):
	ab = set2str(str2set(a)&str2set(b)) # intersection
	tau[a].append(ab)
	tau[b].append(ab)

while 1:
	print()
	print("step",step,":  leafage <=",len({v for v in tau if len(tau[v])==1}))
	if debug: print(f"tau {tau}")

	if debug:
		tokentree = copy(T)
		tokentree.relabel({v:v+": "+set2str(tau[v],symbol=" ") for v in T})
		token_vertex_size = 200*max(len(v) for v in tokentree) # only for plotting
		tokentree.plot(vertex_size=token_vertex_size,figsize=20).save(f'tokentree{step}.png')

	D = DiGraph()
	#for v in T.vertices(): D.add_vertex(v)

	for C in T.vertices():
		if len(tau[C])>= 2: 
			# we can only shift from degree 2+ vertices 

			for t in set(tau[C]): 
				# there exist only 2n-2 many pairs (C,t) because T is a tree

				# precompute whether C2 exists
				C2_exists = False
				if tau[C].count(t) >= 2:
					C2_exists = True
				for C2 in T.vertices():
					if C2 != C and t in tau[C2] and same_connected_component[C,C2,t]:
						C2_exists = True
						break

				for C1 in H[t]:
					if C1 != C:
						if same_connected_component[C,C1,t] or C2_exists:
							D.add_edge(C,C1,t)

	if debug:
		print("D:",D.edges(labels=1))
		D2 = DiGraph(D.edges())
		#D2.set_pos(T_pos)
		D2.relabel({v:f"{v}/{len(tau[v])}" for v in D})
		D2.plot(vertex_size=1000,edge_labels=1,figsize=20).save(f'D{step}.png')
	
	# compute augmented path
	D_V = D.vertices()
	D.add_vertex('dummy_start')
	D.add_vertex('dummy_end')
	for u in D_V:
		if len(tau[u]) >= 3: D.add_edge('dummy_start',v)
		if len(tau[v]) == 1: D.add_edge(v,'dummy_end')

	for P in D.shortest_simple_paths('dummy_start','dummy_end'): 
		augmenting_path = P[1:-1]
		print(P,"->",augmenting_path) 
		break

	if example:
		if step == 0: augmenting_path = ['f,g,j','b,c,f','c,d,g']
		if step == 1: augmenting_path = ['f,g,j', 'e,f']
		
	if debug:
		print("*** augmenting_path:",augmenting_path)

	if augmenting_path:
		for i in range(1,len(augmenting_path)):
			u = augmenting_path[i-1]
			v = augmenting_path[i]
			t = D.edge_label(u,v)
			tau[u].remove(t)
			tau[v].append(t)

		step += 1
		# repeat with new tau
	else:
		break # minimal


leafage = len({v for v in tau if len(tau[v])==1})
print("leafage = ",leafage)


def tree_from_sequence(a):
	if len(a) <= 2:
		Ta = Graph()
		for v in a: Ta.add_vertex(v)
		for u,v in combinations(a,2): Ta.add_edge(u,v)
		return Ta
	else:
		for v in a:
			if a[v] == 1:
				for u in a:
					if a[u] > 1:
						Ta = tree_from_sequence({w:(a[w] if w != u else a[u]-1) for w in a if w != v})
						Ta.add_edge(u,v)
						return Ta
		exit(f"invalid degree sequence: {a}")



if representation:
	R = Graph()
	for v in T: 
		R.add_vertex(v)

	for t in H:
		if debug: print(f"representation part for {t}")

		if debug:
			H2 = Graph()
			for v in H[t]: H2.add_vertex(v)
			for u,v in H[t].edges(labels=0): H2.add_edge(u,v)	
			H2.relabel({v:v+": "+set2str(tau[v],symbol=" ") for v in T})
			H2.plot(vertex_size=1000,figsize=10).save("foo.png")
		
		comps = H[t].connected_components()
		k = len(comps)
		a = {}
		seq = {}
		for i in range(k):
			seq[i] = []
			for v in comps[i]:
				seq[i] += (tau[v].count(t))*[v]
			a[i] = len(seq[i])
			assert(a[i]) >= 1
		assert(sum(a.values()) == 2*k-2)
		Ta = tree_from_sequence(a)

		for i,j in Ta.edges(labels=0):
			R.add_edge(seq[i].pop(),seq[j].pop())

		for i in range(k):
			assert(len(seq[i]) == 0)
	
	print("representation:",R.edges(labels=0))

	if debug:
		R.plot(vertex_size=1000,figsize=10).save("R.png")

	if verify_representation:
		for v in G:
			C_v = [C for C in R if v in str2set(C)]
			assert(R.subgraph(C_v).is_connected())
		assert(R.degree().count(1) == leafage)
		print("valid representation")
