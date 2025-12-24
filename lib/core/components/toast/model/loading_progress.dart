class LoadingProgress {
  final bool isLoading;
  final int current;
  final int total;
  final String? fileName;

  const LoadingProgress({
    required this.isLoading,
    required this.current,
    required this.total,
    this.fileName,
  });

  double get ratio => total == 0 ? 0 : current / total;

  static const idle = LoadingProgress(isLoading: false, current: 0, total: 0);
}
