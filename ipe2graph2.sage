#!/usr/bin/python
from sys import argv
import xml.etree.ElementTree as ET

if len(argv)==1:
    print ("usage:",argv[0],"ipe-file")
    print ("description: read the graph from an ipe file")
    exit()

path = argv[1]
tree = ET.parse(path)
root = tree.getroot()
page = root.find('page')

P = []
for u in page.iterfind('use'):
	attr = u.attrib
	if attr['name']=='mark/disk(sx)':
		x,y = [float(t) for t in attr['pos'].split(" ")]

		if 'matrix' in attr:
			M = [float(t) for t in attr['matrix'].split(" ")]
			x0 = x
			y0 = y
			x = M[0]*x0+M[2]*y0+M[4]
			y = M[1]*x0+M[3]*y0+M[5]

		x = round(x,1)
		y = round(y,1)
		p = (x,y)
		assert(p not in P) # valid embedding
		P.append(p)

E = []
for u in page.iterfind('path'):
	attr = u.attrib
	if 'matrix' in attr:
		M = [float(t) for t in attr['matrix'].split(" ")]

	lines = u.text.split("\n")
	pts = []
	for l in lines:
		if l == '': continue
		x,y = [float(z) for z in l.split()[:2]]
		if 'matrix' in attr:
			x0 = x
			y0 = y
			x = M[0]*x0+M[2]*y0+M[4]
			y = M[1]*x0+M[3]*y0+M[5]
		x = round(x,1)
		y = round(y,1)
		p = (x,y)
		if p not in P:
			print ("WARNING:",p,"not a point of",P )
			continue
		i = P.index(p)
		pts.append(i)
	print ("points",pts)
	assert(len(pts) == 2) # no hypergraph

	pts.sort()
	e = tuple(pts)
	if e not in E:
		E.append(e)


G = Graph(E)
pos = {i:p for i,p in enumerate(P)}
print("pos",pos)
print("E",E)
G.set_pos(pos)
G.plot().save("foo.png")
print(G.edges(labels=0))
