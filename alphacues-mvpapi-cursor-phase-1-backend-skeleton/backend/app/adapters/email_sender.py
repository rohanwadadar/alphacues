from __future__ import annotations

import logging
import smtplib
from email.message import EmailMessage
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from flask import Flask

logger = logging.getLogger(__name__)


class ConsoleEmailSender:
    def send_otp(self, to_email: str, otp_code: str) -> None:
        print(f"[alphacues-otp] email={to_email} otp={otp_code}", flush=True)
        with open("otp.txt", "w") as f:
            f.write(f"email={to_email} otp={otp_code}")


class SMTPEmailSender:
    def __init__(self, *, host: str, port: int, from_email: str) -> None:
        self._host = host
        self._port = port
        self._from_email = from_email

    def send_otp(self, to_email: str, otp_code: str) -> None:
        message = EmailMessage()
        message["Subject"] = "Your Alpha Cues verification code"
        message["From"] = self._from_email
        message["To"] = to_email
        message.set_content(
            f"Your verification code is {otp_code}. It expires in 5 minutes."
        )
        with smtplib.SMTP(self._host, self._port, timeout=10) as smtp:
            smtp.send_message(message)


class SendGridEmailSender:
    def __init__(self, *, api_key: str, from_email: str) -> None:
        self._api_key = api_key
        self._from_email = from_email

    def send_otp(self, to_email: str, otp_code: str) -> None:
        if not self._api_key:
            raise RuntimeError("SENDGRID_API_KEY is not configured.")

        import json
        import urllib.error
        import urllib.request

        payload = {
            "personalizations": [{"to": [{"email": to_email}]}],
            "from": {"email": self._from_email},
            "subject": "Your Alpha Cues verification code",
            "content": [
                {
                    "type": "text/plain",
                    "value": (
                        f"Your verification code is {otp_code}. "
                        "It expires in 5 minutes."
                    ),
                }
            ],
        }
        request = urllib.request.Request(
            "https://api.sendgrid.com/v3/mail/send",
            data=json.dumps(payload).encode("utf-8"),
            headers={
                "Authorization": f"Bearer {self._api_key}",
                "Content-Type": "application/json",
            },
            method="POST",
        )
        try:
            with urllib.request.urlopen(request, timeout=10) as response:
                if response.status >= 400:
                    raise RuntimeError(f"SendGrid returned status {response.status}")
        except urllib.error.HTTPError as exc:
            raise RuntimeError(f"SendGrid request failed: {exc}") from exc


def create_email_sender(app: Flask):
    if app.config.get("MOCK_EXTERNAL_SERVICES"):
        return ConsoleEmailSender()

    backend = (app.config.get("EMAIL_BACKEND") or "sendgrid").lower()
    if backend == "smtp":
        return SMTPEmailSender(
            host=app.config["SMTP_HOST"],
            port=app.config["SMTP_PORT"],
            from_email=app.config["SENDGRID_FROM_EMAIL"],
        )
    if backend in {"console", "fake"}:
        return ConsoleEmailSender()
    return SendGridEmailSender(
        api_key=app.config.get("SENDGRID_API_KEY", ""),
        from_email=app.config.get("SENDGRID_FROM_EMAIL", "alerts@alphacues.local"),
    )
