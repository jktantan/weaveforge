import re, glob

for fname in sorted(glob.glob("*.md")):
    with open(fname, "r", encoding="utf-8") as f:
        raw = f.read()
    
    c = raw
    
    # Step 1: Normalize line endings
    c = c.replace("\r\n", "\n")
    
    # Step 2: Break before all markdown structural markers
    # Insert newline before headings
    c = re.sub(r'(?<!\n)\n?(## |### |#### )', r'\n\n\1', c)
    
    # Insert newline before horizontal rules that are inline
    c = re.sub(r'([^\n])(---)', r'\1\n\2', c)
    c = re.sub(r'(---)([^\n])', r'\1\n\2', c)
    
    # Insert newline before blockquotes
    c = re.sub(r'([^\n])>\s', r'\1\n> ', c)
    
    # Insert newline before table separator rows
    c = re.sub(r'([^\n])\|:----', r'\1\n|:----', c)
    
    # Insert newline before table header rows (after content, not within a table)
    c = re.sub(r'([^\n])\n(\| \*\*)', r'\1\n\n\2', c)
    
    # Insert newline before "| **" that follows inline content  
    c = re.sub(r'([。；：\?\!])\| ', r'\1\n| ', c)
    
    # Step 3: Split lines that contain multiple `##` markers
    lines = c.split("\n")
    new_lines = []
    for line in lines:
        # If line has multiple structural elements, split further
        parts = re.split(r'(?=\n?---|(?<=\n)## |(?<=\n)### |\n> )', line)
        for part in parts:
            if part.strip():
                new_lines.append(part)
    c = "\n".join(new_lines)
    
    # Step 4: Clean up excessive blank lines
    c = re.sub(r'\n{4,}', r'\n\n\n', c)
    
    # Step 5: Remove witcher pollution
    for w in ["猎魔人", "猎魔人世界", "芬达贝", "百花谷", "花谷"]:
        c = c.replace(w, "")
    
    # Step 6: File-specific fixes
    if fname == "survival-kit.md":
        c = c.replace("水鬼", "未知生物")
        c = c.replace("猫眼药水", "夜视药剂")
    if fname == "non-lethal-gear.md":
        c = c.replace("中世纪守卫", "普通守卫")
    
    if c != raw:
        with open(fname, "w", encoding="utf-8") as f:
            f.write(c)
        print(f"FIXED: {fname} ({len(c.split(chr(10)))} lines)")
    else:
        print(f"OK:    {fname}")

print("\n=== VERIFY ===")
for fname in sorted(glob.glob("*.md")):
    with open(fname, "r", encoding="utf-8") as f:
        lines = f.readlines()
    wc = 0
    for w in ["猎魔人", "芬达贝", "水鬼", "百花谷"]:
        for line in lines:
            wc += line.count(w)
    
    # Count structural elements per line
    multi = 0
    for line in lines:
        s = line.strip()
        markers = sum(1 for m in ["## ", "### ", "---"] if s.startswith(m))
        if markers > 1:
            multi += 1
    
    print(f"  {fname}: {len(lines)} lines, witcher={wc}, multi_markers={multi}")
