"""Database connectivity/readiness check for the Mecha Connect backend.

Usage (from backend/):
    python scripts/db_check.py

Connects to the database described by DATABASE_URL and runs `SELECT 1`.

Exit codes:
    0 - database reachable and responds
    1 - database not configured (DATABASE_URL empty)
    2 - connection/setup failure (Postgres not running, wrong creds, etc.)
"""

import asyncio
import os
import sys

# Ensure backend/ is importable when run as `python scripts/db_check.py`.
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.core.config import settings
from app.core.database import configure_database, dispose_engine, check_database


async def _main() -> int:
    if not settings.DATABASE_URL:
        print("DATABASE_URL is not set. DB check skipped (LIVE DATABASE TEST: NOT AVAILABLE).")
        return 1

    url = settings.DATABASE_URL
    # Mask credentials in any output.
    masked = url.split("@")[-1]
    print(f"Checking database connectivity ... url tail: {masked}")

    try:
        configure_database()
        ok = await check_database()
    except Exception as exc:  # noqa: BLE001
        print(f"Database connection failed: {type(exc).__name__}: {exc}")
        return 2
    finally:
        dispose_engine()

    if ok:
        print("Database connectivity: OK (SELECT 1 succeeded).")
        return 0

    print("Database connectivity: FAILED (SELECT 1 returned unexpected result).")
    return 2


if __name__ == "__main__":
    sys.exit(asyncio.run(_main()))