import argparse
import json
import os
import time
from typing import Any
import requests  # type: ignore[import-untyped]
from dotenv import load_dotenv  # type: ignore[import-untyped]

load_dotenv()

parser = argparse.ArgumentParser()
parser.add_argument("--rebuild-toydetails", action="store_true", help="Fetch toy details from the API and rebuild toy_details.json")
parser.add_argument("--rebuild-itemdetails", action="store_true", help="Fetch item details from the API and rebuild toy_item_details.json")
args = parser.parse_args()

# ---------------------------------------------------------------------------
# Configuration — loaded from .env file
# ---------------------------------------------------------------------------
CLIENT_ID: str = os.environ.get("BNET_CLIENT_ID", "")
CLIENT_SECRET: str = os.environ.get("BNET_CLIENT_SECRET", "")
TOKEN_URL: str = "https://oauth.battle.net/token"
TOY_API_URL: str = "https://us.api.blizzard.com/data/wow/toy/{id}?namespace=static-us&:region=us"
ITEM_API_URL: str = "https://us.api.blizzard.com/data/wow/item/{itemid}?namespace=static-us&:region=us"
# Refresh the token this many seconds before it actually expires
TOKEN_REFRESH_BUFFER: int = 60

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


# ---------------------------------------------------------------------------
# Step 1: Extract IDs from toys.json into memory
# ---------------------------------------------------------------------------
print("[Step 1] Extracting toy IDs from toys.json...")
with open("toys.json", "r") as f:
    source: dict[str, Any] = json.load(f)

ids: list[int] = sorted({int(toy["id"]) for toy in source["toys"]})

print(f"[Step 1] Extracted {len(ids)} toy IDs (in memory)")

# ---------------------------------------------------------------------------
# Step 2: Fetch full toy details for every ID (only when --rebuild-toydetails)
# ---------------------------------------------------------------------------
print("[Step 2] Fetching toy details from API...")
if args.rebuild_toydetails:
    toy_details: list[dict[str, Any]] = []

    for i, toy_id in enumerate(ids, start=1):
        token = get_token()
        url = TOY_API_URL.format(id=toy_id)
        resp = requests.get(url, headers={"Authorization": f"Bearer {token}"}, timeout=10)
        if resp.status_code == 200:
            toy_details.append(resp.json())
        else:
            print(f"  ✗ {toy_id} — HTTP {resp.status_code}")
        if i % 500 == 0:
            print(f"  Processed Records {i}")

    remainder = len(ids) % 500
    if remainder > 0:
        print(f"  Processed Records {remainder}")

    with open("toy_details.json", "w") as f:
        json.dump(toy_details, f, indent=2)

    print(f"[Step 2] Done. {len(toy_details)}/{len(ids)} toys fetched → toy_details.json")
else:
    print("[Step 2] Skipping. Pass --rebuild-toydetails to rebuild toy_details.json.")

# ---------------------------------------------------------------------------
# Step 3: Read toy_details.json and extract item IDs
# ---------------------------------------------------------------------------
print("[Step 3] Reading toy_details.json and extracting item IDs...")
try:
    with open("toy_details.json", "r") as f:
        toy_details_raw: list[dict[str, Any]] = json.load(f)
except FileNotFoundError:
    print("[Step 3] Error: toy_details.json not found. Run with --rebuild-toydetails to generate it.")
    raise SystemExit(1)

item_ids: list[int] = [int(toy["item"]["id"]) for toy in toy_details_raw if "item" in toy]

print(f"[Step 3] Extracted {len(item_ids)} item IDs from toy details (in memory)")

# ---------------------------------------------------------------------------
# Step 4: Fetch item details for every item ID (only when --rebuild-itemdetails)
# ---------------------------------------------------------------------------
print("[Step 4] Fetching item details from API...")
if args.rebuild_itemdetails:
    toy_item_details: list[dict[str, Any]] = []

    for i, item_id in enumerate(item_ids, start=1):
        token = get_token()
        url = ITEM_API_URL.format(itemid=item_id)
        resp = requests.get(url, headers={"Authorization": f"Bearer {token}"}, timeout=10)
        if resp.status_code == 200:
            toy_item_details.append(resp.json())
        else:
            print(f"  ✗ {item_id} — HTTP {resp.status_code}")
        if i % 500 == 0:
            print(f"  Processed Records {i}")

    remainder = len(item_ids) % 500
    if remainder > 0:
        print(f"  Processed Records {remainder}")

    with open("toy_item_details.json", "w") as f:
        json.dump(toy_item_details, f, indent=2)

    print(f"[Step 4] Done. {len(toy_item_details)}/{len(item_ids)} items fetched → toy_item_details.json")
else:
    print("[Step 4] Skipping. Pass --rebuild-itemdetails to rebuild toy_item_details.json.")

# ---------------------------------------------------------------------------
# Step 5: Read toy_item_details.json and extract item IDs
# ---------------------------------------------------------------------------
print("[Step 5] Reading toy_item_details.json and extracting item IDs...")
try:
    with open("toy_item_details.json", "r") as f:
        toy_item_details_raw: list[dict[str, Any]] = json.load(f)
except FileNotFoundError:
    print("[Step 5] Error: toy_item_details.json not found. Run with --rebuild-itemdetails to generate it.")
    raise SystemExit(1)

toy_item_ids: list[int] = [int(item["id"]) for item in toy_item_details_raw if "id" in item]

print(f"[Step 5] Extracted {len(toy_item_ids)} item IDs from toy item details (in memory)")
