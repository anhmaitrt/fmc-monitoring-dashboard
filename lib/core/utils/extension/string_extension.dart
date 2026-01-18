extension EString on String? {
  bool get isNullOrEmpty => this == null || (this?.isEmpty ?? false);

  /// Mask phone number by keeping [keepStart] and [keepEnd] characters.
  /// Example: +84904056886 -> +84*****886 (keepStart=3, keepEnd=3)
  String maskPhone({int keepStart = 3, int keepEnd = 4, String mask = '*****'}) {
    final s = this;
    if (s == null || s.isEmpty) return '';

    // If too short, just return masked (or original if you prefer)
    if (s.length <= keepStart + keepEnd) {
      return s;
    }

    return s.replaceRange(keepStart, s.length - keepEnd, mask);
  }

  String maskUuid({String prefix = 'xxxxx-xxxxx-', int keepLast = 12}) {
    final s = this;
    if (s == null || s.isEmpty) return '';

    if (s.length <= keepLast) return s;
    return '$prefix${s.substring(s.length - keepLast)}';
  }

  String? approxIosFromDarwinKernel() {
    if(this == null) return null;

    final m = RegExp(r'Darwin Kernel Version (\d+)\.(\d+)\.(\d+)')
        .firstMatch(this!);
    if (m == null) return null;

    final darwinMajor = int.parse(m.group(1)!);
    final darwinMinor = int.parse(m.group(2)!);

    final iosMajor = darwinMajor - 6;
    if (iosMajor <= 0) return null;

    // Minor often *looks* aligned, but not officially guaranteed
    return 'iOS $iosMajor.$darwinMinor (approx)';
  }
}
