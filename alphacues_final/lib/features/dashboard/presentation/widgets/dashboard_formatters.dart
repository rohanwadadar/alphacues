import '../../../../core/utils/us_market_time.dart';

String formatPrice(double value, {int fractionDigits = 2}) {
  return value.toStringAsFixed(fractionDigits);
}

String formatPercent(double value) {
  final sign = value >= 0 ? '+' : '';
  return '$sign${value.toStringAsFixed(2)}%';
}

String formatSignedAmount(double value) {
  final sign = value >= 0 ? '+' : '';
  return '$sign${formatPrice(value)}';
}

String formatAsOfTimestamp(String asOf) {
  final raw = DateTime.tryParse(asOf);
  if (raw == null) {
    return asOf;
  }
  final parsed = toUsEastern(raw);
  final hour = parsed.hour % 12 == 0 ? 12 : parsed.hour % 12;
  final minute = parsed.minute.toString().padLeft(2, '0');
  final period = parsed.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $period ET';
}
