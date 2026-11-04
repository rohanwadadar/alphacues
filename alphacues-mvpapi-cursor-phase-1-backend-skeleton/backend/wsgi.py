import eventlet
eventlet.monkey_patch()

from app import create_app
from app.extensions import socketio

app = create_app()

def _alert_monitoring_loop():
    import eventlet
    while True:
        eventlet.sleep(8)
        try:
            with app.app_context():
                from app.modules.alerts.service import AlertEvaluationService
                from app.modules.notifications.service import NotificationService
                AlertEvaluationService.evaluate_all_active_alerts()
                NotificationService.process_pending_outbox_events()
        except Exception:
            pass

eventlet.spawn(_alert_monitoring_loop)

if __name__ == "__main__":
    socketio.run(app, host="127.0.0.1", port=5000, use_reloader=False)
