extension EString on String? {
  bool get isNullOrEmpty => this == null || (this?.isEmpty ?? false);
}