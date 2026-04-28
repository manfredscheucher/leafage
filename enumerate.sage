import argparse
import sys

# Known OEIS sequences for connected chordal graphs on n vertices:
#   chordal graphs: https://oeis.org/A048193 : 1, 2, 4, 10, 27, 94, 393, 2119
#   interval graphs: https://oeis.org/A005975 : 1, 2, 4, 10, 27, 92, 369, 1807

parser = argparse.ArgumentParser(
    description="Enumerate connected chordal graphs by leafage (outputs sparse6)",
    epilog=(
        "OEIS references for connected chordal graphs on n vertices:\n"
        "  all chordal: A048193 -- 1, 2, 4, 10, 27, 94, 393, 2119\n"
        "  interval    (leafage <= 2): A005975 -- 1, 2, 4, 10, 27, 92, 369, 1807\n"
    ),
    formatter_class=argparse.RawDescriptionHelpFormatter,
)
parser.add_argument("-n", type=int, required=True, help="number of vertices")
parser.add_argument("-llow", type=int, default=None, metavar="L", help="leafage >= L")
parser.add_argument("-lupp", type=int, default=None, metavar="U", help="leafage <= U")
parser.add_argument("-ig", "--interval-graph", action="store_true",
                    help="interval graphs only (equivalent to -lupp 2, see OEIS A005975)")
parser.add_argument("-c", "--connected", action="store_true",
                    help="connected graphs only")
parser.add_argument("--plot", action="store_true",
                    help="save each matching graph as PNG (graph_n<n>_<i>.png)")
args = parser.parse_args()

load("leafage.sage")

n = args.n
llow = args.llow
lupp = args.lupp

if args.interval_graph:
    lupp = 2

# Print run info to stderr so stdout stays clean (sparse6 only)
filters = []
if args.connected: filters.append("connected")
if llow is not None: filters.append(f"leafage >= {llow}")
if lupp is not None: filters.append(f"leafage <= {lupp}")
filter_str = ", ".join(filters) if filters else "no filter"
print(f"# enumerating chordal graphs on n={n} vertices ({filter_str})", file=sys.stderr)

nauty_flags = "-c" if args.connected else ""
ct = 0
for g in graphs.nauty_geng(f"{n} {nauty_flags}".strip()):
    gs = g.sparse6_string()
    if not g.is_chordal():
        continue
    l, _, representation = leafage(g, certificate=1)
    if llow is not None and l < llow:
        continue
    if lupp is not None and l > lupp:
        continue
    ct += 1
    print(gs)
    if args.plot:
        fname = f"graph_n{n}_{ct}.png"
        g.plot(title=f"leafage={l}").save(fname)
        print(f"# saved {fname}", file=sys.stderr)

print(f"# total: {ct} graphs", file=sys.stderr)
