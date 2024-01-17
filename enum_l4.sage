from sys import *

load("leafage.sage")

n = int(argv[1])
# chordal = https://oeis.org/A048193 : 	1, 2, 4, 10, 27, 94, 393, 2119
# interval = https://oeis.org/A005975 : 1, 2, 4, 10, 27, 92, 369, 1807

ct = 0
for g in graphs.nauty_geng(f"{n} -c"):
	gs = g.sparse6_string()
	if not g.is_chordal(): continue
	if g.is_interval(): continue
	if len(simplicial_vertices(g)) < 4: continue
	#if leafage_upper(g) < 4: continue
	#print("test graph",gs)
	l,representation = leafage(g,certificate=1)
	if l >= 4:
		ct += 1
		print(gs)
		if 0: 
			g.plot().save(f"_graph_n{n}_{ct}.png")

		if 0:	
			subdivision_of_star = len([v for v in g if g.degree(v) >= 3]) <= 1
			if not subdivision_of_star:
				print("not subdivision_of_star!")
				exit()
