"""Process-local, in-memory authentication rate limiter (Sprint 2, Task 3, D10).

Approved MVP: **10 requests/minute** per client, stored only in this process's
memory. No Redis, no external service, no middleware affecting other endpoints.

Design notes
------------
- Fixed-window counters keyed by a caller-supplied client identifier
  (e.g. ``request.client.host``). The window slides: entries older than
  ``window_seconds`` are pruned before counting, so a client may send up to
  ``max_requests`` within any rolling window.
- The clock is **injectable** (a ``Callable[[], float]`` returning seconds) so
  tests can advance time deterministically instead of sleeping 60 seconds.
  Production uses ``time.monotonic``.
- Thread-safe via a lock (FastAPI may serve requests concurrently).
- Completely isolated from the rest of the application: nothing here imports
  FastAPI, and only the auth dependency wiring in ``app.api.deps`` consumes it.
"""

import threading
import time
from typing import Callable, Dict, List, Optional


class RateLimiter:
    """Fixed-window in-memory rate limiter with an injectable clock.

    ``allow(key)`` records one request for ``key`` and returns ``True`` if the
    request is within the rolling window budget, ``False`` when the budget is
    exhausted. ``reset(key=None)`` clears state (useful in tests/teardown).
    """

    def __init__(
        self,
        max_requests: int = 10,
        window_seconds: int = 60,
        clock: Optional[Callable[[], float]] = None,
    ) -> None:
        if max_requests < 1:
            raise ValueError("max_requests must be >= 1")
        if window_seconds < 1:
            raise ValueError("window_seconds must be >= 1")
        self.max_requests = max_requests
        self.window_seconds = window_seconds
        self._clock: Callable[[], float] = clock or time.monotonic
        self._entries: Dict[str, List[float]] = {}
        self._lock = threading.Lock()

    def allow(self, key: str) -> bool:
        """Record one request for ``key``; return whether it is within budget."""
        now = self._clock()
        cutoff = now - self.window_seconds
        with self._lock:
            entries = self._entries.get(key)
            if entries is None:
                self._entries[key] = [now]
                return True
            # Prune entries that fell out of the rolling window.
            entries[:] = [ts for ts in entries if ts > cutoff]
            if len(entries) >= self.max_requests:
                return False
            entries.append(now)
            return True

    def reset(self, key: Optional[str] = None) -> None:
        """Clear the budget for one ``key`` (or all keys when ``None``)."""
        with self._lock:
            if key is None:
                self._entries.clear()
            else:
                self._entries.pop(key, None)