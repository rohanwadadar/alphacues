"""add portfolio_event positive price and volume checks

Revision ID: e9f6a4b13c5d
Revises: d8e5f3a02b4c
Create Date: 2026-06-17 12:00:00.000000

"""
from alembic import op


revision = "e9f6a4b13c5d"
down_revision = "d8e5f3a02b4c"
branch_labels = None
depends_on = None


def upgrade():
    op.create_check_constraint(
        "ck_portfolio_event_price_positive",
        "portfolio_event",
        "price > 0",
    )
    op.create_check_constraint(
        "ck_portfolio_event_volume_positive",
        "portfolio_event",
        "volume > 0",
    )


def downgrade():
    op.drop_constraint(
        "ck_portfolio_event_volume_positive",
        "portfolio_event",
        type_="check",
    )
    op.drop_constraint(
        "ck_portfolio_event_price_positive",
        "portfolio_event",
        type_="check",
    )
