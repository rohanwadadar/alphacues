// Utilities to strictly convert and format timestamps in US Eastern Time (ET / US Market Time).

DateTime toUsEastern(DateTime dt) {
  final utc = dt.isUtc ? dt : dt.toUtc();
  final isDst = isUsEasternDst(utc);
  final offsetHours = isDst ? -4 : -5;
  return utc.add(Duration(hours: offsetHours));
}

bool isUsEasternDst(DateTime utc) {
  final year = utc.year;
  DateTime secondSundayMarch = DateTime.utc(year, 3, 8);
  while (secondSundayMarch.weekday != DateTime.sunday) {
    secondSundayMarch = secondSundayMarch.add(const Duration(days: 1));
  }
  final dstStart = DateTime.utc(year, 3, secondSundayMarch.day, 7, 0);

  DateTime firstSundayNov = DateTime.utc(year, 11, 1);
  while (firstSundayNov.weekday != DateTime.sunday) {
    firstSundayNov = firstSundayNov.add(const Duration(days: 1));
  }
  final dstEnd = DateTime.utc(year, 11, firstSundayNov.day, 6, 0);

  return utc.isAfter(dstStart) && utc.isBefore(dstEnd);
}

String formatUsMarketTimestamp(String isoStamp, {String range = '1D'}) {
  if (isoStamp.isEmpty) return '';
  try {
    final rawDt = DateTime.parse(isoStamp);
    final dt = toUsEastern(rawDt);
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final monthStr = months[dt.month - 1];
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');

    if (range == '1D') {
      return '$hour12:$minute $period ET';
    } else if (range == '5D' || range == '1W' || range == '1M') {
      return '$monthStr ${dt.day}, $hour12:$minute $period ET';
    }
    return '$monthStr ${dt.day}, ${dt.year}';
  } catch (_) {
    return isoStamp;
  }
}
