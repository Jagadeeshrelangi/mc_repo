/// Formats an amount as an Indian-rupee string with grouping (e.g.
/// `formatINR(3499)` → `₹3,499`). Kept local so the module has zero external
/// format dependencies (Sprint 2 can swap in `intl` without touching widgets).
String formatINR(num amount, {int decimals = 0}) {
  final fixed = amount.toStringAsFixed(decimals);
  final parts = fixed.split('.');
  var intPart = parts[0];
  final isNegative = intPart.startsWith('-');
  if (isNegative) intPart = intPart.substring(1);

  String grouped;
  if (intPart.length > 3) {
    final last3 = intPart.substring(intPart.length - 3);
    var rest = intPart.substring(0, intPart.length - 3);
    final groups = <String>[last3];
    while (rest.length > 2) {
      groups.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) groups.insert(0, rest);
    grouped = groups.join(',');
  } else {
    grouped = intPart;
  }

  final decimalsPart = parts.length > 1 ? '.${parts[1]}' : '';
  return '₹${isNegative ? '-' : ''}$grouped$decimalsPart';
}
