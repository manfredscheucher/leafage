from sys import *

load("leafage.sage")

n = int(argv[1])
# chordal = https://oeis.org/A048193 : 	1, 2, 4, 10, 27, 94, 393, 2119
# interval = https://oeis.org/A005975 : 1, 2, 4, 10, 27, 92, 369, 1807

for g in graphs.nauty_geng(f"{n}"):
	gs = g.sparse6_string()
	if not g.is_chordal(): continue
	if g.is_interval(): continue
	if leafage_upper(g) < 4: continue
	#print("test graph",gs)
	l = leafage(g)
	if l > 3:
		print(gs)
