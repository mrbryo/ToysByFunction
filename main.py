import argparse
import collections
import json
import os
import sqlite3
import time
from typing import Any
import requests  # type: ignore[import-untyped]
from dotenv import load_dotenv  # type: ignore[import-untyped]

load_dotenv()

parser = argparse.ArgumentParser()
parser.add_argument("--rebuild-toydetails", action="store_true", help="Fetch toy details from the API and repopulate the toys table")
parser.add_argument("--rebuild-itemdetails", action="store_true", help="Fetch item details from the API and repopulate the items/item_spells tables")
args = parser.parse_args()

# ---------------------------------------------------------------------------
# Configuration — loaded from .env file
# ---------------------------------------------------------------------------
CLIENT_ID: str = os.environ.get("BNET_CLIENT_ID", "")
CLIENT_SECRET: str = os.environ.get("BNET_CLIENT_SECRET", "")
TOKEN_URL: str = "https://oauth.battle.net/token"
TOY_API_URL: str = "https://us.api.blizzard.com/data/wow/toy/{id}?namespace=static-us&:region=us"
ITEM_API_URL: str = "https://us.api.blizzard.com/data/wow/item/{itemid}?namespace=static-us&:region=us"
DB_PATH: str = "toys.db"
# Refresh the token this many seconds before it actually expires
TOKEN_REFRESH_BUFFER: int = 60

# ---------------------------------------------------------------------------
# Rate limiter — 100 req/s and 36,000 req/hr
# ---------------------------------------------------------------------------
_PER_SECOND_LIMIT: int = 100
_PER_HOUR_LIMIT: int = 36_000
_MAX_RETRIES: int = 5

# Sliding windows: store the timestamp of each request
_second_window: collections.deque[float] = collections.deque()
_hour_window: collections.deque[float] = collections.deque()


def _throttle() -> None:
    """Block until it is safe to issue the next request."""
    now = time.monotonic()

    # Evict timestamps outside the 1-second and 3600-second windows
    while _second_window and now - _second_window[0] >= 1.0:
        _second_window.popleft()
    while _hour_window and now - _hour_window[0] >= 3600.0:
        _hour_window.popleft()

    # If at the per-second cap, sleep until the oldest request in the window ages out
    if len(_second_window) >= _PER_SECOND_LIMIT:
        sleep_for = 1.0 - (now - _second_window[0]) + 0.001
        if sleep_for > 0:
            time.sleep(sleep_for)
        now = time.monotonic()
        while _second_window and now - _second_window[0] >= 1.0:
            _second_window.popleft()

    # If at the hourly cap, sleep until the oldest request in the window ages out
    if len(_hour_window) >= _PER_HOUR_LIMIT:
        sleep_for = 3600.0 - (now - _hour_window[0]) + 0.001
        print(f"  [throttle] Hourly quota reached. Sleeping {sleep_for:.1f}s...")
        time.sleep(sleep_for)
        now = time.monotonic()
        while _hour_window and now - _hour_window[0] >= 3600.0:
            _hour_window.popleft()

    _second_window.append(time.monotonic())
    _hour_window.append(time.monotonic())


def api_get(url: str, headers: dict[str, str]) -> requests.Response:
    """GET with automatic throttling and 429 retry."""
    resp: requests.Response | None = None
    for attempt in range(1, _MAX_RETRIES + 1):
        _throttle()
        resp = requests.get(url, headers=headers, timeout=10)
        if resp.status_code != 429:
            return resp
        # 429 — wait out the remainder of the current second then retry
        retry_after = float(resp.headers.get("Retry-After", "1"))
        print(f"  [throttle] 429 received, waiting {retry_after:.2f}s (attempt {attempt}/{_MAX_RETRIES})...")
        time.sleep(retry_after)
    if resp is None:
        raise RuntimeError("api_get: no response after retries")
    return resp  # return final response even if still 429

# ---------------------------------------------------------------------------
# Bearer token state
# ---------------------------------------------------------------------------
_token: str = ""
_token_expires_at: float = 0.0


def fetch_token() -> None:
    """Fetch a new bearer token from Battle.net and cache it."""
    global _token, _token_expires_at
    response = requests.post(
        TOKEN_URL,
        data={"grant_type": "client_credentials"},
        auth=(CLIENT_ID, CLIENT_SECRET),
        timeout=10,
    )
    response.raise_for_status()
    payload: dict[str, Any] = response.json()
    _token = str(payload["access_token"])
    expires_in: int = int(payload.get("expires_in", 86400))
    _token_expires_at = time.time() + expires_in - TOKEN_REFRESH_BUFFER
    print(f"Token fetched. Expires in ~{expires_in}s.")


def get_token() -> str:
    """Return a valid bearer token, refreshing if it is about to expire."""
    if not _token or time.time() >= _token_expires_at:
        fetch_token()
    return _token


def loc(obj: Any, key: str = "en_US") -> str:
    """Safely pull a localized string from a localization dict."""
    if not isinstance(obj, dict):
        return ""
    val = obj.get(key) or obj.get("en_US")  # type: ignore[union-attr]
    return str(val) if val is not None else ""  # type: ignore[arg-type]


# ---------------------------------------------------------------------------
# Database setup
# ---------------------------------------------------------------------------
print("[DB] Initializing SQLite database...")
db: sqlite3.Connection = sqlite3.connect(DB_PATH)
db.execute("PRAGMA foreign_keys = ON")
db.executescript("""
    CREATE TABLE IF NOT EXISTS toys (
        id                      INTEGER PRIMARY KEY,
        item_id                 INTEGER NOT NULL,
        item_name               TEXT,
        source_type             TEXT,
        source_name             TEXT,
        source_description      TEXT,
        media_id                INTEGER
    );

    CREATE TABLE IF NOT EXISTS items (
        id                      INTEGER PRIMARY KEY,
        name                    TEXT,
        quality_type            TEXT,
        level                   INTEGER,
        required_level          INTEGER,
        media_id                INTEGER,
        item_class_id           INTEGER,
        item_class_name         TEXT,
        item_subclass_id        INTEGER,
        item_subclass_name      TEXT,
        inventory_type          TEXT,
        purchase_price          INTEGER,
        sell_price              INTEGER,
        max_count               INTEGER,
        is_equippable           INTEGER,
        is_stackable            INTEGER,
        purchase_quantity       INTEGER,
        binding_type            TEXT,
        binding_name            TEXT
    );

    CREATE TABLE IF NOT EXISTS item_spells (
        id                      INTEGER PRIMARY KEY AUTOINCREMENT,
        item_id                 INTEGER NOT NULL REFERENCES items(id),
        spell_id                INTEGER,
        spell_name              TEXT,
        description             TEXT
    );
""")
db.commit()
print("[DB] Schema ready.")

# ---------------------------------------------------------------------------
# Step 1: Extract IDs from toys.json into memory
# ---------------------------------------------------------------------------
print("[Step 1] Extracting toy IDs from toys.json...")
with open("toys.json", "r") as f:
    source: dict[str, Any] = json.load(f)

ids: list[int] = sorted({int(toy["id"]) for toy in source["toys"]})

print(f"[Step 1] Extracted {len(ids)} toy IDs (in memory)")

# ---------------------------------------------------------------------------
# Step 2: Fetch full toy details for every ID → store in toys table
# ---------------------------------------------------------------------------
print("[Step 2] Fetching toy details from API...")
if args.rebuild_toydetails:
    db.execute("DELETE FROM toys")
    db.commit()

    for i, toy_id in enumerate(ids, start=1):
        token = get_token()
        resp = api_get(TOY_API_URL.format(id=toy_id), headers={"Authorization": f"Bearer {token}"})
        if resp.status_code == 200:
            t: dict[str, Any] = resp.json()
            item: dict[str, Any] = t.get("item", {})
            source_obj: dict[str, Any] = t.get("source", {})
            db.execute(
                "INSERT OR REPLACE INTO toys VALUES (?,?,?,?,?,?,?)",
                (
                    int(t["id"]),
                    int(item.get("id", 0)),
                    loc(item.get("name")),
                    source_obj.get("type"),
                    loc(source_obj.get("name")),
                    loc(t.get("source_description")),
                    int(t.get("media", {}).get("id", 0)) or None,
                ),
            )
        else:
            print(f"  ✗ {toy_id} — HTTP {resp.status_code}")
        if i % 500 == 0:
            db.commit()
            print(f"  Processed Records {i}")

    remainder = len(ids) % 500
    if remainder > 0:
        print(f"  Processed Records {remainder}")
    db.commit()
    print(f"[Step 2] Done. Toys stored in database.")
else:
    print("[Step 2] Skipping. Pass --rebuild-toydetails to repopulate the toys table.")

# ---------------------------------------------------------------------------
# Step 3: Read item IDs from toys table
# ---------------------------------------------------------------------------
print("[Step 3] Reading item IDs from toys table...")
rows = db.execute("SELECT DISTINCT item_id FROM toys WHERE item_id > 0").fetchall()
if not rows:
    print("[Step 3] Error: toys table is empty. Run with --rebuild-toydetails to populate it.")
    raise SystemExit(1)

item_ids: list[int] = [int(row[0]) for row in rows]
print(f"[Step 3] Extracted {len(item_ids)} item IDs from toys table (in memory)")

# ---------------------------------------------------------------------------
# Step 4: Fetch item details for every item ID → store in items/item_spells tables
# ---------------------------------------------------------------------------
print("[Step 4] Fetching item details from API...")
if args.rebuild_itemdetails:
    db.execute("DELETE FROM item_spells")
    db.execute("DELETE FROM items")
    db.commit()

    for i, item_id in enumerate(item_ids, start=1):
        token = get_token()
        resp = api_get(ITEM_API_URL.format(itemid=item_id), headers={"Authorization": f"Bearer {token}"})
        if resp.status_code == 200:
            it: dict[str, Any] = resp.json()
            preview: dict[str, Any] = it.get("preview_item", {})
            binding: dict[str, Any] = preview.get("binding", {})
            db.execute(
                "INSERT OR REPLACE INTO items VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)",
                (
                    int(it["id"]),
                    loc(it.get("name")),
                    it.get("quality", {}).get("type"),
                    it.get("level"),
                    it.get("required_level"),
                    int(it.get("media", {}).get("id", 0)) or None,
                    int(it.get("item_class", {}).get("id", 0)) or None,
                    loc(it.get("item_class", {}).get("name")),
                    int(it.get("item_subclass", {}).get("id", 0)) or None,
                    loc(it.get("item_subclass", {}).get("name")),
                    it.get("inventory_type", {}).get("type"),
                    it.get("purchase_price"),
                    it.get("sell_price"),
                    it.get("max_count"),
                    int(it.get("is_equippable", False)),
                    int(it.get("is_stackable", False)),
                    it.get("purchase_quantity"),
                    binding.get("type"),
                    loc(binding.get("name")),
                ),
            )
            for spell_entry in preview.get("spells", []):
                spell: dict[str, Any] = spell_entry.get("spell", {})
                db.execute(
                    "INSERT INTO item_spells (item_id, spell_id, spell_name, description) VALUES (?,?,?,?)",
                    (
                        int(it["id"]),
                        int(spell.get("id", 0)) or None,
                        loc(spell.get("name")),
                        loc(spell_entry.get("description")),
                    ),
                )
        else:
            print(f"  ✗ {item_id} — HTTP {resp.status_code}")
        if i % 500 == 0:
            db.commit()
            print(f"  Processed Records {i}")

    remainder = len(item_ids) % 500
    if remainder > 0:
        print(f"  Processed Records {remainder}")
    db.commit()
    print(f"[Step 4] Done. Items stored in database.")
else:
    print("[Step 4] Skipping. Pass --rebuild-itemdetails to repopulate the items/item_spells tables.")

# ---------------------------------------------------------------------------
# Step 5: Read item IDs from items table
# ---------------------------------------------------------------------------
print("[Step 5] Reading item IDs from items table...")
item_rows = db.execute("SELECT id FROM items").fetchall()
if not item_rows:
    print("[Step 5] Error: items table is empty. Run with --rebuild-itemdetails to populate it.")
    raise SystemExit(1)

toy_item_ids: list[int] = [int(row[0]) for row in item_rows]
print(f"[Step 5] Extracted {len(toy_item_ids)} item IDs from items table (in memory)")

db.close()
