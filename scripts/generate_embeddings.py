#!/usr/bin/env python3
"""Generate embeddings for LoreDocument and SessionLog content."""
import requests, json, sys

OLLAMA = "http://localhost:11434/api/embed"
BASE = "http://192.168.88.10:2480"
AUTH = ("root", "12345678")
DB = "weaverforge"

def cmd(sql):
    r = requests.post(f"{BASE}/api/v1/command/{DB}", auth=AUTH,
        json={"language": "sql", "command": sql}, timeout=15)
    return r.json() if r.status_code < 300 else None

def embed(texts):
    r = requests.post(OLLAMA, json={"model": "bge-m3", "input": texts}, timeout=60)
    if r.status_code < 300:
        return r.json().get("embeddings", [])
    return []

# Get documents without embeddings
result = cmd("SELECT @rid, world_id, content FROM LoreDocument WHERE embedding IS NULL")
if not result:
    print("No documents to embed")
    sys.exit(0)

docs = result.get("result", [])
print(f"Documents to embed: {len(docs)}")

# Batch embed
texts = [d.get("content", "") for d in docs]
vecs = embed(texts)

if not vecs:
    print("Ollama embedding failed. Is bge-m3 pulled?")
    print("Run: ollama pull bge-m3")
    sys.exit(1)

print(f"Got {len(vecs)} embeddings (dim={len(vecs[0])})")

# Update each document
for doc, vec in zip(docs, vecs):
    rid = doc["@rid"]
    vec_str = json.dumps(vec)
    cmd(f"UPDATE LoreDocument SET embedding = {vec_str} WHERE @rid = {rid}")

print("Embeddings saved to LoreDocument")
