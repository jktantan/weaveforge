"""ArcadeDB HTTP client wrapper."""
import os, requests, json
from dotenv import load_dotenv

load_dotenv()

_URL = os.getenv("ARCADEDB_URL", "http://192.168.88.10:2480")
_USER = os.getenv("ARCADEDB_USER", "root")
_PASS = os.getenv("ARCADEDB_PASS", "12345678")
_DB = os.getenv("ARCADEDB_DB", "weaverforge")
_AUTH = (_USER, _PASS)

def command(sql, db=None):
    """Execute a SQL command against ArcadeDB."""
    db = db or _DB
    r = requests.post(f"{_URL}/api/v1/command/{db}", auth=_AUTH,
        json={"language": "sql", "command": sql}, timeout=30)
    r.raise_for_status()
    return r.json().get("result", [])

def query(sql, db=None):
    """Alias for command."""
    return command(sql, db)
