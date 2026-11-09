class AppFormatters {
  const AppFormatters._();

  static const _months = [
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

  static String date(DateTime value) =>
      '${value.day} ${_months[value.month - 1]} ${value.year}';

  static String time(DateTime value) {
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${value.hour < 12 ? 'AM' : 'PM'}';
  }

  static String dateTime(DateTime value) => '${date(value)} at ${time(value)}';

  static String rating(double? value) => value?.toStringAsFixed(1) ?? 'New';

  static String signedCredits(int amount) =>
      amount >= 0 ? '+$amount' : '$amount';
}
