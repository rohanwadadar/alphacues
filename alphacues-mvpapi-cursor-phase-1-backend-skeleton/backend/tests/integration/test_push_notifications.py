import pytest
import json
import uuid
from app.modules.user.models import DevicePushToken
from app.modules.notifications.models import OutboxEvent
from app.shared.db import db

@pytest.fixture
def auth_headers(client, fake_email_sender):
    send = client.post(
        "/api/v1/auth/send-otp",
        json={"email": "push-user@example.com"},
    )
    challenge_id = send.get_json()["data"]["otpChallengeId"]
    otp_code = fake_email_sender.last_otp_for("push-user@example.com")
    verify = client.post(
        "/api/v1/auth/verify-otp",
        json={
            "email": "push-user@example.com",
            "otpChallengeId": challenge_id,
            "otpCode": otp_code,
        },
    )
    token = verify.get_json()["data"]["accessToken"]
    return {"Authorization": f"Bearer {token}"}

def test_register_device_token(client, auth_headers):
    device_id = str(uuid.uuid4())
    fcm_token = f"fcm_token_{uuid.uuid4()}"
    response = client.post(
        "/api/v1/devices/register",
        headers=auth_headers,
        json={
            "fcmToken": fcm_token,
            "platform": "ios",
            "deviceId": device_id,
            "appVersion": "1.0.0"
        }
    )
    
    assert response.status_code == 200
    data = response.json
    assert data["data"]["deviceId"] == device_id
    assert data["data"]["isActive"] is True

    # Verify it was saved to DB
    token = db.session.query(DevicePushToken).filter_by(device_id=device_id).first()
    assert token is not None
    assert token.fcm_token == fcm_token
    assert token.platform == "ios"

def test_unregister_device_token(client, auth_headers):
    device_id = str(uuid.uuid4())
    fcm_token = f"fcm_token_{uuid.uuid4()}"
    # First register
    client.post(
        "/api/v1/devices/register",
        headers=auth_headers,
        json={
            "fcmToken": fcm_token,
            "platform": "ios",
            "deviceId": device_id
        }
    )
    
    # Then unregister
    response = client.delete(f"/api/v1/devices/{device_id}", headers=auth_headers)
    assert response.status_code == 204
    
    # Verify removal
    token = db.session.query(DevicePushToken).filter_by(device_id=device_id).first()
    assert token is None

def test_process_outbox_event_with_push(app, client, auth_headers, monkeypatch):
    device_id = str(uuid.uuid4())
    fcm_token = f"fcm_token_{uuid.uuid4()}"
    # Register a token so there is a recipient
    reg_res = client.post(
        "/api/v1/devices/register",
        headers=auth_headers,
        json={
            "fcmToken": fcm_token,
            "platform": "android",
            "deviceId": device_id
        }
    )
    assert reg_res.status_code == 200
    
    # Get created user ID
    token_obj = db.session.query(DevicePushToken).filter_by(device_id=device_id).first()
    assert token_obj is not None
    user_id = token_obj.user_id

    # Insert an outbox event
    event_payload = {
        "userId": user_id,
        "notificationId": 999,
        "alertId": 100,
        "title": "Stock Alert",
        "body": "AAPL is above $150",
        "createdAt": "2026-08-05T00:00:00Z"
    }
    
    event = OutboxEvent(
        event_type="alert_triggered",
        payload=event_payload,
        status="pending"
    )
    db.session.add(event)
    db.session.commit()
    
    # Mock firebase-admin so we don't actually hit Google servers
    class MockResponse:
        failure_count = 0
        responses = []
        
    def mock_send_each_for_multicast(*args, **kwargs):
        return MockResponse()

    import firebase_admin.messaging
    monkeypatch.setattr(firebase_admin.messaging, "send_each_for_multicast", mock_send_each_for_multicast)
    
    from app.modules.notifications.service import NotificationService
    
    with app.app_context():
        processed_count = NotificationService.process_pending_outbox_events()
        
    assert processed_count == 1
    
    # Check event status
    event = db.session.query(OutboxEvent).filter_by(id=event.id).first()
    assert event.status == "delivered"


