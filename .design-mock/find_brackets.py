from pathlib import Path

path = Path("lib/features/home/presentation/widgets/mobile/mobile_home_canvas.dart")
text = path.read_text(encoding="utf-8")
depth = 0
line_no = 1
i = 0
in_str = None
triple = False
esc = False
while i < len(text):
    c = text[i]
    nxt = text[i + 1] if i + 1 < len(text) else ""
    if c == "\n":
        line_no += 1
        i += 1
        continue
    if in_str:
        if triple:
            if text[i : i + 3] == in_str:
                in_str = None
                triple = False
                i += 3
                continue
            i += 1
            continue
        if esc:
            esc = False
            i += 1
            continue
        if c == "\\":
            esc = True
            i += 1
            continue
        if c == in_str:
            in_str = None
        i += 1
        continue
    if c == "/" and nxt == "/":
        while i < len(text) and text[i] != "\n":
            i += 1
        continue
    if c in ("'", '"'):
        if text[i : i + 3] == c * 3:
            in_str = c * 3
            triple = True
            i += 3
            continue
        in_str = c
        i += 1
        continue
    if c == "[":
        depth += 1
    elif c == "]":
        depth -= 1
        if depth < 0:
            print(f"extra ] line {line_no}")
            depth = 0
    i += 1
print("final", depth)
