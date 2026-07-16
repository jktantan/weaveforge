#!/usr/bin/env python3
"""Insert lore documents into ArcadeDB, handling special chars."""
import requests, json, re

BASE = "http://192.168.88.10:2480"
AUTH = ("root", "12345678")
DB = "weaverforge"

def cmd(sql):
    r = requests.post(f"{BASE}/api/v1/command/{DB}", auth=AUTH,
        json={"language": "sql", "command": sql}, timeout=15)
    if r.status_code >= 300:
        print(f"  FAIL: {r.text[:100]}")
    return r.status_code < 300

# 1. Clean old
cmd("DELETE FROM LoreDocument WHERE world_id='earth-modern'")

# 2. Read lore and store each non-empty line
with open("seed/earth-modern/lore.md", "r", encoding="utf-8") as f:
    content = f.read()

lines = [l.strip() for l in content.split("\n") if l.strip()]
stored = 0
for line in lines:
    # Escape single quote for SQL
    safe = line.replace("'", "''")
    if cmd(f"INSERT INTO LoreDocument (world_id, content) VALUES ('earth-modern', '{safe}')"):
        stored += 1

print(f"Stored {stored}/{len(lines)} lines as LoreDocument")

# 3. Verify
r = requests.post(f"{BASE}/api/v1/command/{DB}", auth=AUTH,
    json={"language": "sql", "command": "SELECT world_id, COUNT(*) as c FROM LoreDocument GROUP BY world_id"})
for d in r.json().get('result', []):
    print(f"  {d.get('world_id')}: {d.get('c')} records")
