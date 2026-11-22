String dateKey(DateTime date) => date.toIso8601String().substring(0, 10);

String rupees(int paise) {
  final whole = paise ~/ 100;
  final fraction = paise % 100;
  return '₹$whole${fraction == 0 ? '' : '.${fraction.toString().padLeft(2, '0')}'}';
}

int? parseRupees(String input) {
  final parts = input.trim().split('.');
  if (!RegExp(r'^\d{1,8}(\.\d{1,2})?$').hasMatch(input.trim())) return null;
  return int.parse(parts.first) * 100 +
      (parts.length == 2 ? int.parse(parts.last.padRight(2, '0')) : 0);
}
