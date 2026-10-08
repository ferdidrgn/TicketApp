import re
import pathlib

paths = [
    pathlib.Path(r"lib/features/home/presentation/widgets/mobile/mobile_home_canvas.dart"),
    pathlib.Path(r"lib/features/search/presentation/pages/search_page.dart"),
]
root = pathlib.Path(r"C:\Users\ferdi\OneDrive\Belgeler\GitHub\TicketApp")
for p in paths:
    t = (root / p).read_text(encoding="utf-8")
    s = re.sub(r"'''[\s\S]*?'''", "", t)
    s = re.sub(r'"""[\s\S]*?"""', "", s)
    s = re.sub(r"//.*?$", "", s, flags=re.M)
    s = re.sub(r"'(?:\\.|[^'\\])*'", "", s)
    s = re.sub(r'"(?:\\.|[^"\\])*"', "", s)
    print(p.name)
    for a, b in [("(", ")"), ("{", "}"), ("[", "]")]:
        print(f"  {a}{b}", s.count(a) - s.count(b))
