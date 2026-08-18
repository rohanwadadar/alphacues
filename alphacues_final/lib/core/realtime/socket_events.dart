// Client → Server
const kSubscribeQuotes = 'subscribe_quotes';
const kUnsubscribeQuotes = 'unsubscribe_quotes';
const kSubscribeNotifications = 'subscribe_notifications';
const kResumeSession = 'resume_session';

// Server → Client
const kQuoteUpdate = 'quote_update';
const kNotificationNew = 'notification_new';
const kAlertTriggered = 'alert_triggered';
const kConnectionState = 'connection_state';
const kSocketError = 'error';

class QuoteUpdatePayload {
  const QuoteUpdatePayload({
    required this.symbol,
    required this.lastPrice,
    required this.changeAmount,
    required this.changePercent,
    required this.asOf,
  });

  final String symbol;
  final double lastPrice;
  final double changeAmount;
  final double changePercent;
  final String asOf;

  factory QuoteUpdatePayload.fromJson(Map<String, dynamic> json) {
    return QuoteUpdatePayload(
      symbol: json['symbol'] as String,
      lastPrice: (json['lastPrice'] as num).toDouble(),
      changeAmount: (json['changeAmount'] as num).toDouble(),
      changePercent: (json['changePercent'] as num).toDouble(),
      asOf: json['asOf'] as String,
    );
  }
}

class NotificationNewPayload {
  const NotificationNewPayload({
    required this.notificationId,
    required this.alertId,
    required this.title,
    required this.body,
    required this.createdAt,
  });

  final String notificationId;
  final String alertId;
  final String title;
  final String body;
  final String createdAt;

  factory NotificationNewPayload.fromJson(Map<String, dynamic> json) {
    return NotificationNewPayload(
      notificationId: json['notificationId'] as String,
      alertId: json['alertId'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      createdAt: json['createdAt'] as String,
    );
  }
}
