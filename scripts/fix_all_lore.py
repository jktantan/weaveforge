"""批量修复所有 lore 文件：格式 + 污染清除"""
import re, glob

# 猎魔人污染词替换表
witcher_words = {
    "猎魔人世界": "",
    "猎魔人": "",
    "芬达贝": "",
    "水鬼": "低阶生物",
    "花谷": "",
    "百花谷": "",
    "中世纪守卫": "未开化世界守卫",
}

fixes = {
    "non-lethal-gear.md": [
        (r'> "[^"]*" ——古月', '> "审问需要活的。" ——古月'),
        (r'中世纪守卫', '未开化世界守卫'),
    ],
    "survival-kit.md": [
        (r'> "你有基因优化，没有再生能力。.*', '> "你有基因优化，没有再生能力。没有抗生素的地方一个小伤口就能要你的命。" ——极光'),
    ],
}

for fname in sorted(glob.glob("*.md")):
    if fname == "ark-battleship.md":
        continue  # already fixed
    
    with open(fname, "r", encoding="utf-8") as f:
        raw = f.read()
    
    changed = raw
    
    # Step 1: Fix markdown adhesion
    # Split `|` followed by heading/blockquote/hr on same line
    changed = re.sub(r'\|\s+###\s', '|\n\n### ', changed)
    changed = re.sub(r'\|\s+##\s', '|\n\n## ', changed)
    changed = re.sub(r'\|\s+>\s', '|\n\n> ', changed)
    changed = re.sub(r'\|\s+---\s+##', '|\n\n---\n\n##', changed)
    changed = re.sub(r'\)\s+---\s+##', ')\n\n---\n\n##', changed)
    changed = re.sub(r'\)\s+---\s+###', ')\n\n---\n\n###', changed)
    
    # Fix `>` followed by heading on same continuous line
    changed = re.sub(r'>\s+[^"]+?\n\s*##', '>\n\n##', changed)
    
    # Fix table line that blends into next content
    changed = re.sub(r'\|\s+$', '|\n', changed, flags=re.MULTILINE)
    
    # Ensure blank line before headings
    changed = re.sub(r'([^\n])\n(## |### )', r'\1\n\n\2', changed)
    
    # Ensure blank line after blockquotes
    changed = re.sub(r'(> [^\n]+)\n(## )', r'\1\n\n\2', changed)
    changed = re.sub(r'(> [^\n]+)\n(### )', r'\1\n\n\2', changed)
    
    # Step 2: Remove witcher contamination
    for old_w, new_w in witcher_words.items():
        changed = changed.replace(old_w, new_w)
    
    # Step 3: Apply file-specific fixes
    if fname in fixes:
        for pattern, replacement in fixes[fname]:
            changed = re.sub(pattern, replacement, changed)
    
    # Step 4: Clean up double spaces and triple newlines
    changed = re.sub(r'\s{3,}', '  ', changed)
    changed = re.sub(r'\n{4,}', '\n\n\n', changed)
    
    if changed != raw:
        with open(fname, "w", encoding="utf-8") as f:
            f.write(changed)
        print(f"FIXED: {fname}")
    else:
        print(f"OK:    {fname}")

print("\n=== Verify ===")
for fname in sorted(glob.glob("*.md")):
    if fname == "ark-battleship.md":
        print(f"  {fname}: skipped (manually fixed)")
        continue
    with open(fname, "r", encoding="utf-8") as f:
        c = f.read()
    lines = len(c.split("\n"))
    witcher = sum(c.count(w) for w in ["猎魔人", "芬达贝", "水鬼", "百花谷"])
    problems = 0
    for line in c.split("\n"):
        s = line.strip()
        if s and not s.startswith(("#", "|", ">", "-", "*", "1.", ":", "【")):
            if any(x in s for x in ["## ", "### ", "--- "]):
                problems += 1
    print(f"  {fname}: {lines} lines, witcher_refs={witcher}, fmt_issues={problems}")
