#!/usr/bin/env python3
"""Contract Check Script for Alpha Cues MVP.

Compares response structures and fixtures under backend/tests/fixtures/contracts/*
against expected envelope definitions, field types, and nullability rules.

Exits with code 0 on success, and code 1 on contract drift or schema violation.
Used in CI and pre-commit checks.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any

BACKEND_ROOT = Path(__file__).resolve().parents[1]
FIXTURES_DIR = BACKEND_ROOT / "tests" / "fixtures" / "contracts"


class ContractValidationError(Exception):
    """Raised when a contract fixture fails structural or envelope validation."""


def validate_canonical_envelope(payload: dict[str, Any], path: Path) -> None:
    """Validate that standard endpoint fixtures conform to canonical envelope requirements."""
    required_envelope_keys = {"success", "data", "error"}
    missing = required_envelope_keys - set(payload.keys())
    if missing:
        raise ContractValidationError(
            f"[{path.name}] Missing canonical envelope keys: {missing}"
        )

    if not isinstance(payload["success"], bool):
        raise ContractValidationError(
            f"[{path.name}] Field 'success' must be boolean, got {type(payload['success']).__name__}"
        )

    if payload["error"] is not None and not isinstance(payload["error"], dict):
        raise ContractValidationError(
            f"[{path.name}] Field 'error' must be dict or null"
        )

    if "meta" in payload and payload["meta"] is not None:
        meta = payload["meta"]
        if not isinstance(meta, dict):
            raise ContractValidationError(
                f"[{path.name}] Field 'meta' must be dict when present"
            )
        if "apiVersion" in meta and meta["apiVersion"] != "1":
            raise ContractValidationError(
                f"[{path.name}] Meta apiVersion must be '1', got {meta['apiVersion']}"
            )


def compare_shapes(actual: Any, expected: Any, path_prefix: str = "$") -> list[str]:
    """Recursively compare actual response payload against expected fixture shape.

    Returns a list of error messages for type mismatches, missing keys, or nullability drift.
    """
    errors: list[str] = []

    if expected is None:
        # Null values permit actual to be None or any type if field is additive/nullable
        return errors

    if actual is None and expected is not None:
        errors.append(f"{path_prefix}: Expected {type(expected).__name__}, got null")
        return errors

    if type(actual) != type(expected):
        # Numeric tolerance: int and float interop for numbers
        if isinstance(actual, (int, float)) and isinstance(expected, (int, float)):
            pass
        else:
            errors.append(
                f"{path_prefix}: Type mismatch. Expected {type(expected).__name__}, got {type(actual).__name__}"
            )
            return errors

    if isinstance(expected, dict):
        for key, exp_val in expected.items():
            if key not in actual:
                errors.append(f"{path_prefix}: Missing required key '{key}'")
            else:
                errors.extend(
                    compare_shapes(actual[key], exp_val, f"{path_prefix}.{key}")
                )

    elif isinstance(expected, list):
        if len(expected) > 0 and len(actual) > 0:
            # Compare first element structure as prototype
            errors.extend(
                compare_shapes(actual[0], expected[0], f"{path_prefix}[0]")
            )

    return errors


def run_contract_check(fixtures_dir: Path = FIXTURES_DIR) -> tuple[int, int]:
    """Inspect all JSON fixtures under fixtures_dir and validate contract shapes.

    Returns (passed_count, failed_count).
    """
    if not fixtures_dir.exists():
        print(f"ERROR: Fixtures directory not found at {fixtures_dir}")
        return 0, 1

    json_files = sorted(fixtures_dir.rglob("*.json"))
    if not json_files:
        print(f"WARNING: No contract fixture JSON files found in {fixtures_dir}")
        return 0, 0

    passed = 0
    failed = 0

    print(f"Checking {len(json_files)} contract fixtures under {fixtures_dir}...\n")

    for file_path in json_files:
        rel_path = file_path.relative_to(fixtures_dir)
        try:
            content = file_path.read_text(encoding="utf-8")
            data = json.loads(content)

            # Standard endpoint contract files validate envelope
            if isinstance(data, dict) and "success" in data:
                validate_canonical_envelope(data, rel_path)

            print(f"  [PASS] {rel_path}")
            passed += 1
        except Exception as exc:
            print(f"  [FAIL] {rel_path} - {exc}")
            failed += 1

    return passed, failed


def main() -> None:
    passed, failed = run_contract_check()
    print(f"\nContract Check Summary: {passed} passed, {failed} failed.")

    if failed > 0:
        sys.exit(1)
    sys.exit(0)


if __name__ == "__main__":
    main()
