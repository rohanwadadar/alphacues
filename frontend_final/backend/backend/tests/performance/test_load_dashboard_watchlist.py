"""Backend load test for dashboard and watchlist endpoints."""
import time

def test_dashboard_watchlist_load_performance(client, fake_email_sender):
    """Executes batched requests against dashboard and watchlist endpoints to measure response latency."""
    send = client.post(
        "/api/v1/auth/send-otp",
        json={"email": "perf-test@example.com"},
    )
    challenge_id = send.get_json()["data"]["otpChallengeId"]
    otp_code = fake_email_sender.last_otp_for("perf-test@example.com")
    verify = client.post(
        "/api/v1/auth/verify-otp",
        json={
            "email": "perf-test@example.com",
            "otpChallengeId": challenge_id,
            "otpCode": otp_code,
        },
    )
    token = verify.get_json()["data"]["accessToken"]
    auth_headers = {"Authorization": f"Bearer {token}"}

    start_time = time.monotonic()
    num_requests = 5
    responses = []

    for _ in range(num_requests):
        res_dash = client.get("/api/v1/dashboard", headers=auth_headers)
        res_watch = client.get("/api/v1/watchlist", headers=auth_headers)
        responses.append(res_dash)
        responses.append(res_watch)

    total_time = time.monotonic() - start_time
    avg_latency_ms = (total_time / (num_requests * 2)) * 1000.0

    # Validate response status and latency threshold
    for res in responses:
        assert res.status_code == 200
        data = res.get_json()
        assert data["success"] is True

    # Assert average latency is within reasonable performance limits (< 200ms per request)
    assert avg_latency_ms < 200.0, f"Average latency too high: {avg_latency_ms:.2f}ms"
