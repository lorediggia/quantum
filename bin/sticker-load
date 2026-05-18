#!/usr/bin/env bash
f="$HOME/.cache/sidebar_stickers.json"
[[ -f $f ]] || exit 0

python3 - "$f" <<'PY'
import json, os, sys
fp = sys.argv[1]
with open(fp) as f:
    data = json.load(f)
before = len(data.get("stickers", []))
data["stickers"] = [
    s for s in data.get("stickers", [])
    if os.path.exists(s["imgSrc"].replace("file://", ""))
]
if len(data["stickers"]) != before:
    with open(fp, "w") as f:
        json.dump(data, f)
print(json.dumps(data))
PY
