from __future__ import annotations

import os
from flask import Blueprint, request, send_file, current_app
from sqlalchemy import inspect, text

from app.modules.admin.service import AdminFlagService
from app.shared.auth import require_admin
from app.shared.db import db
from app.shared.exceptions import ValidationError, NotFoundError
from app.shared.response import json_response

from app.modules.user.models import User, OtpToken, UserSession, DevicePushToken
from app.modules.portfolio.models import Position, PortfolioEvent, PortfolioSnapshot
from app.modules.watchlist.models import Watchlist, WatchlistItem
from app.modules.alerts.models import Alert, AlertTriggerEvent
from app.modules.notifications.models import Notification
from app.modules.screener.models import ScreenerStrategy
from app.modules.market.models import StockTick

admin_bp = Blueprint("admin", __name__, url_prefix="/api/v1/admin")


@admin_bp.get("/overview")
def get_admin_overview():
    """GET /api/v1/admin/overview — real system metrics from DB."""
    try:
        user_count = db.session.query(User).count()
        position_count = db.session.query(Position).count()
        alert_count = db.session.query(Alert).count()
        watchlist_count = db.session.query(Watchlist).count()
        otp_token_count = db.session.query(OtpToken).count()
        device_count = db.session.query(DevicePushToken).count()
        session_count = db.session.query(UserSession).count()
    except Exception as e:
        return json_response({"error": str(e)}, status_code=500)

    db_engine_name = db.engine.name
    
    return json_response({
        "total_users": user_count,
        "total_positions": position_count,
        "total_alerts": alert_count,
        "total_watchlists": watchlist_count,
        "total_otp_tokens": otp_token_count,
        "total_devices": device_count,
        "total_sessions": session_count,
        "database_engine": db_engine_name,
    })


@admin_bp.get("/users")
def list_admin_users():
    """GET /api/v1/admin/users — list all actual database users."""
    users = db.session.query(User).order_by(User.created_at.desc()).all()
    result = []
    for u in users:
        pos_cnt = db.session.query(Position).filter_by(user_id=u.user_id).count()
        wl_cnt = db.session.query(Watchlist).filter_by(user_id=u.user_id).count()
        alert_cnt = db.session.query(Alert).filter_by(user_id=u.user_id).count()
        sess_cnt = db.session.query(UserSession).filter_by(user_id=u.user_id).count()
        dev_cnt = db.session.query(DevicePushToken).filter_by(user_id=u.user_id).count()

        result.append({
            "user_id": u.user_id,
            "email": u.email,
            "name": u.name or "N/A",
            "avatar_url": u.avatar_url,
            "is_active": u.is_active,
            "created_at": u.created_at.isoformat() if u.created_at else None,
            "updated_at": u.updated_at.isoformat() if u.updated_at else None,
            "stats": {
                "positions": pos_cnt,
                "watchlists": wl_cnt,
                "alerts": alert_cnt,
                "sessions": sess_cnt,
                "devices": dev_cnt,
            }
        })
    return json_response({"users": result})


@admin_bp.get("/users/<int:user_id>")
def get_admin_user_detail(user_id: int):
    """GET /api/v1/admin/users/<id> — get per-user specific data."""
    u = db.session.get(User, user_id)
    if not u:
        raise NotFoundError(message=f"User {user_id} not found.")

    positions = db.session.query(Position).filter_by(user_id=user_id).all()
    events = db.session.query(PortfolioEvent).filter_by(user_id=user_id).order_by(PortfolioEvent.time_stamp.desc()).limit(20).all()
    watchlists = db.session.query(Watchlist).filter_by(user_id=user_id).all()
    alerts = db.session.query(Alert).filter_by(user_id=user_id).all()
    sessions = db.session.query(UserSession).filter_by(user_id=user_id).all()
    devices = db.session.query(DevicePushToken).filter_by(user_id=user_id).all()
    otp_tokens = db.session.query(OtpToken).filter_by(user_id=user_id).order_by(OtpToken.created_at.desc()).limit(10).all()

    wl_data = []
    for wl in watchlists:
        items = db.session.query(WatchlistItem).filter_by(watchlist_id=wl.watchlist_id).all()
        wl_data.append({
            "watchlist_id": str(wl.watchlist_id),
            "name": wl.name,
            "items": [{"symbol": item.symbol, "added_at": item.added_at.isoformat() if item.added_at else None} for item in items]
        })

    return json_response({
        "user": {
            "user_id": u.user_id,
            "email": u.email,
            "name": u.name or "N/A",
            "avatar_url": u.avatar_url,
            "is_active": u.is_active,
            "created_at": u.created_at.isoformat() if u.created_at else None,
        },
        "positions": [
            {
                "id": f"{p.user_id}_{p.symbol}",
                "symbol": p.symbol,
                "quantity": float(p.volume) if p.volume is not None else 0.0,
                "average_price": round(float(p.total_price / p.volume), 2) if (p.volume and p.volume > 0) else 0.0,
            } for p in positions
        ],
        "events": [
            {
                "id": str(e.event_id),
                "event_type": e.action,
                "asset_symbol": e.symbol,
                "quantity": float(e.volume) if e.volume is not None else 0.0,
                "price": float(e.price) if e.price is not None else 0.0,
                "timestamp": e.time_stamp.isoformat() if e.time_stamp else None,
            } for e in events
        ],
        "watchlists": wl_data,
        "alerts": [
            {
                "id": str(a.alert_id),
                "symbol": a.symbol,
                "condition": f"{a.condition} {a.target}",
                "is_active": a.is_active,
                "created_at": a.created_at.isoformat() if a.created_at else None,
            } for a in alerts
        ],
        "sessions": [
            {
                "session_id": str(s.session_id),
                "expires_at": s.expires_at.isoformat() if s.expires_at else None,
                "revoked_at": s.revoked_at.isoformat() if s.revoked_at else None,
                "created_at": s.created_at.isoformat() if s.created_at else None,
            } for s in sessions
        ],
        "devices": [
            {
                "device_id": str(d.device_id),
                "platform": d.platform,
                "app_version": d.app_version,
                "is_active": d.is_active,
                "last_seen_at": d.last_seen_at.isoformat() if d.last_seen_at else None,
            } for d in devices
        ],
        "otp_history": [
            {
                "challenge_id": str(o.challenge_id),
                "email": o.email,
                "expires_at": o.expires_at.isoformat() if o.expires_at else None,
                "used": o.used,
                "failed_attempts": o.failed_attempts,
                "created_at": o.created_at.isoformat() if o.created_at else None,
            } for o in otp_tokens
        ]
    })


@admin_bp.get("/tables")
def get_admin_tables():
    """GET /api/v1/admin/tables — inspection of actual DB tables and row counts."""
    inspector = inspect(db.engine)
    table_names = inspector.get_table_names()
    tables_data = []

    for name in table_names:
        columns = inspector.get_columns(name)
        pk = inspector.get_pk_constraint(name)
        pk_cols = pk.get("constrained_columns", []) if pk else []
        
        try:
            res = db.session.execute(text(f"SELECT COUNT(*) FROM {name}")).scalar()
            row_count = int(res) if res is not None else 0
        except Exception:
            row_count = 0

        cols_info = []
        for col in columns:
            cols_info.append({
                "name": col["name"],
                "type": str(col["type"]),
                "nullable": col.get("nullable", True),
                "is_pk": col["name"] in pk_cols
            })

        tables_data.append({
            "name": name,
            "row_count": row_count,
            "columns": cols_info
        })

    return json_response({"tables": tables_data})


@admin_bp.get("/otp")
def get_admin_otp():
    """GET /api/v1/admin/otp — fetch actual console OTP from otp.txt or latest DB token."""
    otp_code = None
    email = None
    source = None

    possible_paths = ["otp.txt", "../otp.txt", "backend/otp.txt"]
    for path in possible_paths:
        if os.path.exists(path):
            try:
                with open(path, "r") as f:
                    content = f.read().strip()
                if content:
                    source = f"File: {path}"
                    if "otp=" in content:
                        parts = content.split()
                        for p in parts:
                            if p.startswith("email="):
                                email = p.split("=", 1)[1]
                            elif p.startswith("otp="):
                                otp_code = p.split("=", 1)[1]
                    else:
                        otp_code = content
                    break
            except Exception:
                pass

    if not otp_code:
        latest_otp = db.session.query(OtpToken).order_by(OtpToken.created_at.desc()).first()
        if latest_otp:
            source = "Database (OtpToken)"
            email = latest_otp.email
            otp_code = f"[Hash: {latest_otp.otp_hash[:10]}...]"

    if not otp_code:
        return json_response({
            "active": False,
            "otp": None,
            "email": None,
            "message": "No active OTP currently in console or file."
        })

    return json_response({
        "active": True,
        "otp": otp_code,
        "email": email,
        "source": source
    })


@admin_bp.get("/flags")
@require_admin
def list_flags():
    """GET /api/v1/admin/flags — list all feature flags."""
    flags = AdminFlagService.list_flags()
    return json_response(
        {"flags": [AdminFlagService.flag_to_dict(f) for f in flags]}
    )


@admin_bp.get("/flags/<string:flag_key>")
@require_admin
def get_flag(flag_key: str):
    """GET /api/v1/admin/flags/<flag_key> — retrieve a single flag."""
    flag = AdminFlagService.get_flag(flag_key)
    return json_response(AdminFlagService.flag_to_dict(flag))


@admin_bp.patch("/flags/<string:flag_key>")
@require_admin
def update_flag(flag_key: str):
    """PATCH /api/v1/admin/flags/<flag_key> — toggle is_enabled."""
    body = request.get_json(silent=True) or {}

    if "is_enabled" not in body:
        raise ValidationError(
            message="Missing required field: is_enabled.",
            details={"is_enabled": ["Field is required."]},
        )

    is_enabled_raw = body["is_enabled"]
    if not isinstance(is_enabled_raw, bool):
        raise ValidationError(
            message="Field 'is_enabled' must be a boolean.",
            details={"is_enabled": ["Must be true or false."]},
        )

    flag = AdminFlagService.update_flag(flag_key, is_enabled=is_enabled_raw)
    return json_response(AdminFlagService.flag_to_dict(flag))


@admin_bp.post("/notifications/send")
def send_admin_test_notification():
    """POST /api/v1/admin/notifications/send — create and broadcast a test notification."""
    from datetime import datetime, timezone
    from app.extensions import socketio
    from app.shared.websocket import STREAM_NAMESPACE, _user_room

    body = request.get_json(silent=True) or {}
    email = body.get("email") or "rwadadar@gmail.com"
    title = body.get("title") or "Price Target Reached: $NVDA +4.8%"
    notif_body = body.get("body") or "NVIDIA ($NVDA) crossed $128.50 target price alert."

    user = db.session.query(User).filter(User.email == email).first()
    if not user:
        user = db.session.query(User).first()
    if not user:
        raise NotFoundError("No users exist in the database.")

    notif = Notification(
        user_id=user.user_id,
        title=title,
        body=notif_body,
        is_read=False,
        created_at=datetime.now(timezone.utc),
    )
    db.session.add(notif)
    db.session.commit()

    payload = {
        "notificationId": str(notif.notification_id),
        "userId": str(user.user_id),
        "title": notif.title,
        "body": notif.body,
        "isRead": notif.is_read,
        "createdAt": notif.created_at.strftime("%Y-%m-%dT%H:%M:%SZ"),
    }

    try:
        socketio.emit(
            "notification_new",
            payload,
            room=_user_room(str(user.user_id)),
            namespace=STREAM_NAMESPACE,
        )
    except Exception:
        pass

    return json_response(payload, status_code=201)


@admin_bp.post("/notifications/seed-dummy")
def seed_dummy_notifications():
    """POST /api/v1/admin/notifications/seed-dummy — insert a rich set of dummy notifications."""
    from datetime import datetime, timezone, timedelta
    from app.extensions import socketio
    from app.shared.websocket import STREAM_NAMESPACE, _user_room

    body = request.get_json(silent=True) or {}
    email = body.get("email") or "rwadadar@gmail.com"

    user = db.session.query(User).filter(User.email == email).first()
    if not user:
        user = db.session.query(User).first()
    if not user:
        raise NotFoundError("No users exist in the database.")

    samples = [
        {
            "title": "Price Alert Triggered: $AAPL crossed $225.00",
            "body": "Apple Inc. reached $226.15 (+2.4% today). Your upper price target has been met.",
            "minutes_ago": 5,
        },
        {
            "title": "Earnings Alert: $NVDA Q2 Results Beat Estimates",
            "body": "NVIDIA reported revenue of $30.0B vs $28.7B consensus. EPS came in at $0.68 vs $0.64 est.",
            "minutes_ago": 30,
        },
        {
            "title": "Strategy Scan: 4 High Momentum Tech Stocks Found",
            "body": "Your 'Tech Growth Leaders' strategy scanner detected 4 matching symbols: AMD, MSFT, GOOGL, KLAC.",
            "minutes_ago": 120,
        },
        {
            "title": "Market News: Fed Signals Interest Rate Decision",
            "body": "Federal Reserve maintains interest rate outlook; tech sectors rally across major exchanges.",
            "minutes_ago": 360,
        },
        {
            "title": "Price Drop Warning: $TSLA -3.2%",
            "body": "Tesla fell below your stop-loss support level at $210.00. Current price is $208.40.",
            "minutes_ago": 720,
        },
    ]

    created = []
    now = datetime.now(timezone.utc)
    for s in samples:
        notif = Notification(
            user_id=user.user_id,
            title=s["title"],
            body=s["body"],
            is_read=False,
            created_at=now - timedelta(minutes=s["minutes_ago"]),
        )
        db.session.add(notif)
        created.append(notif)

    db.session.commit()

    for notif in created:
        try:
            socketio.emit(
                "notification_new",
                {
                    "notificationId": str(notif.notification_id),
                    "userId": str(user.user_id),
                    "title": notif.title,
                    "body": notif.body,
                    "isRead": notif.is_read,
                    "createdAt": notif.created_at.strftime("%Y-%m-%dT%H:%M:%SZ"),
                },
                room=_user_room(str(user.user_id)),
                namespace=STREAM_NAMESPACE,
            )
        except Exception:
            pass

    return json_response({
        "message": f"Successfully created {len(created)} test notifications for {user.email}!",
        "count": len(created),
    }, status_code=201)


