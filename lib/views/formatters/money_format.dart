String formatMoney(int cents) {
  final absolute = cents.abs();
  final pesos = (absolute ~/ 100).toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+$)'),
    (_) => '.',
  );
  final decimals = (absolute % 100).toString().padLeft(2, '0');
  return '\$$pesos,$decimals';
}
