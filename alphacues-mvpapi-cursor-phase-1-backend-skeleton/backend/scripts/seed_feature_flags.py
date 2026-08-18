#!/usr/bin/env python3
"""Seed required feature flags into the feature_flags table."""

from __future__ import annotations

import sys
from pathlib import Path

_BACKEND_ROOT = Path(__file__).resolve().parents[1]
if str(_BACKEND_ROOT) not in sys.path:
    sys.path.insert(0, str(_BACKEND_ROOT))

from app import create_app
from app.shared.db import db
from app.shared.feature_flags import REQUIRED_FEATURE_FLAGS, FeatureFlag


def seed_feature_flags() -> int:
    app = create_app()
    with app.app_context():
        for flag_key in REQUIRED_FEATURE_FLAGS:
            row = db.session.get(FeatureFlag, flag_key)
            if row is None:
                db.session.add(
                    FeatureFlag(
                        flag_key=flag_key,
                        is_enabled=False,
                        description=None,
                    )
                )
        db.session.commit()
    return 0


if __name__ == "__main__":
    raise SystemExit(seed_feature_flags())
