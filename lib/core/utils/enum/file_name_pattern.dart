enum FileNamePattern {
  /// Pattern: 'DDMMYY.json' (e.g., '280126.json')
  dailyReport,

  /// Pattern: 'hhmmDDMMYY_hhmmDDMMYY.json' (e.g., '0000290126_0900290126.json')
  timeRange,

  /// Unknown pattern
  unknown,
}