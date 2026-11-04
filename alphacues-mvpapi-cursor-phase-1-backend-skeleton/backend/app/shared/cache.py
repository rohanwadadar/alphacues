from __future__ import annotations

import json
import logging
from typing import Any

from redis import Redis

logger = logging.getLogger(__name__)

_redis_client: Redis | None = None


def get_redis() -> Redis:
    if _redis_client is None:
        raise RuntimeError("Redis client is not initialized")
    return _redis_client


def init_redis(redis_url: str) -> Redis:
    global _redis_client
    _redis_client = Redis.from_url(
        redis_url,
        decode_responses=True,
        socket_timeout=1.0,
        socket_connect_timeout=1.0,
    )
    return _redis_client


# Redis cache TTLs (seconds) per plan reliability design.
TTL_QUOTES_MIN = 3
TTL_QUOTES_MAX = 5
TTL_WATCHLIST_SUMMARY_MIN = 15
TTL_WATCHLIST_SUMMARY_MAX = 30
TTL_CHART_BARS_MIN = 60
TTL_CHART_BARS_MAX = 300
TTL_FUNDAMENTALS_MIN = 3600
TTL_FUNDAMENTALS_MAX = 21600


import time

_memory_cache: dict[str, tuple[float, str]] = {}
_redis_last_check_time = 0.0
_redis_is_online = False

class CacheService:
    """Redis-backed cache with fast in-memory fallback when Redis is unavailable."""

    def __init__(self, client: Redis | None = None) -> None:
        self._client = client
        self._cache_hits = 0
        self._cache_misses = 0
        self._cache_bypasses = 0
        self._stale_cache_hits = 0

    @property
    def client(self) -> Redis:
        if self._client is None:
            return get_redis()
        return self._client

    def _available(self) -> bool:
        global _redis_last_check_time, _redis_is_online
        from flask import current_app
        now = time.time()
        try:
            if current_app and (current_app.config.get("MOCK_EXTERNAL_SERVICES") or current_app.config.get("TESTING")):
                return False
            # Check Redis connection at most once every 5 seconds to avoid connection spam
            if now - _redis_last_check_time < 5.0:
                return _redis_is_online
            _redis_last_check_time = now
            _redis_is_online = bool(self.client.ping())
            return _redis_is_online
        except Exception:
            _redis_last_check_time = now
            _redis_is_online = False
            return False

    def get(self, key: str) -> str | None:
        if not self._available():
            # In-memory cache fallback
            item = _memory_cache.get(key)
            if item is not None:
                expire_at, val = item
                if time.time() < expire_at:
                    self._cache_hits += 1
                    return val
                else:
                    _memory_cache.pop(key, None)
            self._cache_misses += 1
            return None
        try:
            val = self.client.get(key)
            if val is not None:
                self._cache_hits += 1
            else:
                self._cache_misses += 1
            return val
        except Exception:
            self._cache_bypasses += 1
            return None

    def set(self, key: str, value: str, *, ttl_seconds: int) -> bool:
        if not self._available():
            # In-memory cache fallback
            _memory_cache[key] = (time.time() + ttl_seconds, value)
            return True
        try:
            self.client.setex(key, ttl_seconds, value)
            return True
        except Exception:
            _memory_cache[key] = (time.time() + ttl_seconds, value)
            return True

    def delete(self, key: str) -> bool:
        _memory_cache.pop(key, None)
        if not self._available():
            return True
        try:
            self.client.delete(key)
            return True
        except Exception:
            return False

    def get_json(self, key: str) -> Any | None:
        raw = self.get(key)
        if raw is None:
            return None
        try:
            return json.loads(raw)
        except json.JSONDecodeError:
            logger.warning("Redis cache JSON decode failed for key=%s", key)
            return None

    def set_json(self, key: str, value: Any, *, ttl_seconds: int) -> bool:
        return self.set(key, json.dumps(value), ttl_seconds=ttl_seconds)

    def acquire_lock(self, key: str, *, ttl_seconds: int) -> bool:
        if not self._available():
            return True
        try:
            return bool(self.client.set(key, "1", nx=True, ex=ttl_seconds))
        except Exception:
            logger.warning("Redis lock acquire failed for key=%s", key, exc_info=True)
            return True

    def release_lock(self, key: str) -> bool:
        return self.delete(key)

    def get_stale_cache_metrics(self) -> dict[str, Any]:
        """Returns observable metric metrics for cache degradation and usage."""
        redis_available = False
        try:
            redis_available = self._available()
        except Exception:
            redis_available = False

        return {
            "redisAvailable": redis_available,
            "cacheHits": self._cache_hits,
            "cacheMisses": self._cache_misses,
            "cacheBypasses": self._cache_bypasses,
            "staleCacheHits": self._stale_cache_hits,
            "degradedModeActive": not redis_available,
        }

