using HTTP
using Gumbo
using AbstractTrees

espn_fbs_html = HTTP.get("https://www.espn.com/college-football/schedule")

espn_fbs = parsehtml(String(espn_fbs_html.body))

espn_root = espn_fbs.root
# for elem in PreOrderDFS(espn_root)
#     println(elem)
# end
espn_root