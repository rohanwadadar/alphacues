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
    with op.batch_alter_table("portfolio_event", schema=None) as batch_op:
        batch_op.create_check_constraint(
            "ck_portfolio_event_price_positive",
            "price > 0",
        )
        batch_op.create_check_constraint(
            "ck_portfolio_event_volume_positive",
            "volume > 0",
        )


def downgrade():
    with op.batch_alter_table("portfolio_event", schema=None) as batch_op:
        batch_op.drop_constraint(
            "ck_portfolio_event_volume_positive",
            type_="check",
        )
        batch_op.drop_constraint(
            "ck_portfolio_event_price_positive",
            type_="check",
        )
