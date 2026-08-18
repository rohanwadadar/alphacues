from __future__ import annotations

import json
from pathlib import Path

from scripts.contract_check import compare_shapes, validate_canonical_envelope

CONTRACTS_DIR = Path(__file__).resolve().parents[1] / "fixtures" / "contracts"


def test_additive_alert_model_migration_backwards_compatible():
    """Verify that adding an optional/nullable field to alerts preserves compatibility."""
    fixture_path = CONTRACTS_DIR / "alerts" / "alert_list.json"
    baseline = json.loads(fixture_path.read_text())

    # Baseline envelope validation
    validate_canonical_envelope(baseline, fixture_path)

    # Construct additive response payload with a new nullable 'notes' field on items
    additive_payload = json.loads(fixture_path.read_text())
    for item in additive_payload["data"]["items"]:
        item["notes"] = "User custom note"  # Additive field

    # Comparing additive response shape against baseline contract
    errors = compare_shapes(additive_payload["data"], baseline["data"])
    assert errors == [], f"Additive field generated contract errors: {errors}"


def test_alert_model_type_and_nullability_mismatch_detected():
    """Verify that type alterations or missing required fields in alerts trigger contract violations."""
    fixture_path = CONTRACTS_DIR / "alerts" / "alert_list.json"
    baseline = json.loads(fixture_path.read_text())

    # Scenario 1: Field type mismatch (symbol as int instead of str)
    invalid_type_payload = json.loads(fixture_path.read_text())
    invalid_type_payload["data"]["items"][0]["symbol"] = 12345

    errors = compare_shapes(invalid_type_payload["data"], baseline["data"])
    assert len(errors) > 0
    assert any("Type mismatch" in err for err in errors)

    # Scenario 2: Missing required field (alertId removed)
    missing_key_payload = json.loads(fixture_path.read_text())
    del missing_key_payload["data"]["items"][0]["alertId"]

    errors_missing = compare_shapes(missing_key_payload["data"], baseline["data"])
    assert len(errors_missing) > 0
    assert any("Missing required key 'alertId'" in err for err in errors_missing)
