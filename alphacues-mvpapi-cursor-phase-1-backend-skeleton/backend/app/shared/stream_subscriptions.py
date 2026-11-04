from __future__ import annotations

from collections.abc import Iterable
from typing import Any

ACTIVE_STREAM_SYMBOLS_KEY = "alphacues:stream:active_symbols"
_CLIENT_KEY_PREFIX = "alphacues:stream:client:"
_SYMBOL_CLIENTS_KEY_PREFIX = "alphacues:stream:symbol_clients:"

_SUBSCRIBE_SCRIPT = """
if redis.call('SADD', KEYS[1], ARGV[2]) == 0 then return 0 end
redis.call('SADD', KEYS[3], ARGV[1])
return redis.call('SADD', KEYS[2], ARGV[2])
"""

_UNSUBSCRIBE_SCRIPT = """
if redis.call('SREM', KEYS[1], ARGV[2]) == 0 then return 0 end
redis.call('SREM', KEYS[3], ARGV[1])
if redis.call('SCARD', KEYS[3]) > 0 then return 0 end
redis.call('DEL', KEYS[3])
return redis.call('SREM', KEYS[2], ARGV[2])
"""


def update_client_subscriptions(
    redis_client: Any,
    socket_id: str,
    *,
    subscribe: Iterable[str] = (),
    unsubscribe: Iterable[str] = (),
) -> tuple[set[str], set[str]]:
    """Update symbol reference counts and return global subscribe/unsubscribe deltas."""
    client_key = f"{_CLIENT_KEY_PREFIX}{socket_id}"
    added: set[str] = set()
    removed: set[str] = set()

    for symbol in set(subscribe):
        changed = redis_client.eval(
            _SUBSCRIBE_SCRIPT,
            3,
            client_key,
            ACTIVE_STREAM_SYMBOLS_KEY,
            f"{_SYMBOL_CLIENTS_KEY_PREFIX}{symbol}",
            socket_id,
            symbol,
        )
        if changed:
            added.add(symbol)

    for symbol in set(unsubscribe):
        changed = redis_client.eval(
            _UNSUBSCRIBE_SCRIPT,
            3,
            client_key,
            ACTIVE_STREAM_SYMBOLS_KEY,
            f"{_SYMBOL_CLIENTS_KEY_PREFIX}{symbol}",
            socket_id,
            symbol,
        )
        if changed:
            removed.add(symbol)

    return added, removed


def remove_client_subscriptions(redis_client: Any, socket_id: str) -> set[str]:
    client_key = f"{_CLIENT_KEY_PREFIX}{socket_id}"
    symbols = redis_client.smembers(client_key)
    _, removed = update_client_subscriptions(
        redis_client,
        socket_id,
        unsubscribe=symbols,
    )
    redis_client.delete(client_key)
    return removed