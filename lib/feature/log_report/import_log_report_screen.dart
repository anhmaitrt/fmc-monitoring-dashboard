import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fmc_monitoring_dashboard/core/components/scaffold_widget.dart';
import 'package:fmc_monitoring_dashboard/core/utils/log_report_parser.dart';
import 'package:fmc_monitoring_dashboard/model/log_report/log_report_model.dart';
import 'package:intl/intl.dart';

class ImportLogReportScreen extends StatefulWidget {
  const ImportLogReportScreen({super.key});

  @override
  State<ImportLogReportScreen> createState() => _ImportLogReportScreenState();
}

class _ImportLogReportScreenState extends State<ImportLogReportScreen> {
  // All parsed logs
  List<ReportLogEntry> _allLogs = [];
  List<ReportLogEntry> _filteredLogs = [];
  LogReportStats _stats = LogReportStats.empty();

  // UI State
  String? _error;
  String? _loadedFileName;
  bool _isFileLoading = false;
  bool _isTableLoading = false;

  // Filters
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';
  Timer? _searchDebounce;
  LogLevel? _filterLevel;
  bool _showErrorsOnly = false; // New: quick error filter
  bool _showSyncErrorsOnly = false; // New: quick BLE sync error filter
  DateTime? _fromGenDateTime;
  DateTime? _toGenDateTime;

  // Pagination
  int _currentPage = 0;
  int _rowsPerPage = 50;
  final List<int> _pageSizeOptions = [50, 100, 200, 500];
  bool _sortAscending = false; // Default newest first

  // Scroll controller
  final ScrollController _tableScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchDebounce?.cancel();
    _tableScrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    final text = _searchController.text;

    setState(() {
      _searchText = text;
      _isTableLoading = true;
    });

    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      _rebuildFilteredLogs();
    });
  }

  Future<void> _pickAndLoadFile() async {
    setState(() {
      _error = null;
      _loadedFileName = null;
      _allLogs = [];
      _filteredLogs = [];
      _stats = LogReportStats.empty();
      _currentPage = 0;
      _fromGenDateTime = null;
      _toGenDateTime = null;
      _filterLevel = null;
      _isFileLoading = true;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        setState(() {
          _isFileLoading = false;
        });
        return;
      }

      final file = result.files.single;
      final bytes = file.bytes;
      if (bytes == null) {
        setState(() {
          _error = 'Không đọc được nội dung file (bytes null).';
          _isFileLoading = false;
        });
        return;
      }

      final content = utf8.decode(bytes);

      // Parse CSV in isolate for large files
      final parsed = await compute(parseLogCsvInIsolate, content);

      final String? error = parsed['error'] as String?;
      final List<dynamic> rawLogs = parsed['logs'] as List<dynamic>;

      if (error != null) {
        setState(() {
          _error = error;
          _isFileLoading = false;
        });
        return;
      }

      // Convert to model objects
      final logs = convertToReportEntries(rawLogs);
      final stats = calculateStats(logs);

      setState(() {
        _allLogs = logs;
        _stats = stats;
        _loadedFileName = file.name;
        _error = null;
      });

      _rebuildFilteredLogs();
    } catch (e) {
      setState(() {
        _error = 'Lỗi khi đọc file: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isFileLoading = false;
        });
      }
    }
  }

  void _rebuildFilteredLogs() {
    final searchLower = _searchText.toLowerCase();

    List<ReportLogEntry> tmp = _allLogs.where((log) {
      // Search filter
      if (searchLower.isNotEmpty) {
        final msg = log.message.toLowerCase();
        final account = log.accountId?.toLowerCase() ?? '';
        if (!msg.contains(searchLower) && !account.contains(searchLower)) {
          return false;
        }
      }

      // Level filter
      if (_filterLevel != null && log.level != _filterLevel) {
        return false;
      }

      // Errors only filter
      if (_showErrorsOnly && log.level != LogLevel.error) {
        return false;
      }

      // Sync errors filter (GATT errors, status=133, connect errors)
      if (_showSyncErrorsOnly) {
        final msgLower = log.message.toLowerCase();
        final isSyncError = msgLower.contains('gatt') ||
            msgLower.contains('status=133') ||
            msgLower.contains('status=147') ||
            msgLower.contains('connect error') ||
            msgLower.contains('gattconnectexception') ||
            msgLower.contains('timeout');
        if (!isSyncError) return false;
      }

      // Date range filter
      if (log.genTime == null) return false;
      if (_fromGenDateTime != null && log.genTime!.isBefore(_fromGenDateTime!)) {
        return false;
      }
      if (_toGenDateTime != null && log.genTime!.isAfter(_toGenDateTime!)) {
        return false;
      }

      return true;
    }).toList();

    // Sort by genTime
    tmp.sort((a, b) {
      if (a.genTime == null || b.genTime == null) return -1;
      final cmp = a.genTime!.compareTo(b.genTime!);
      return _sortAscending ? cmp : -cmp;
    });

    setState(() {
      _filteredLogs = tmp;
      _currentPage = 0;
      _isTableLoading = false;
    });

    if (_tableScrollController.hasClients) {
      _tableScrollController.jumpTo(0);
    }
  }

  Future<void> _pickFromGenDateTime() async {
    if (_isFileLoading || _isTableLoading) return;

    final now = DateTime.now();
    final initial = _fromGenDateTime ?? _stats.earliestLog ?? now;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );

    DateTime result;
    if (pickedTime != null) {
      result = DateTime(pickedDate.year, pickedDate.month, pickedDate.day,
          pickedTime.hour, pickedTime.minute);
    } else {
      result = DateTime(pickedDate.year, pickedDate.month, pickedDate.day);
    }

    setState(() {
      _fromGenDateTime = result;
      _isTableLoading = true;
    });
    _rebuildFilteredLogs();
  }

  Future<void> _pickToGenDateTime() async {
    if (_isFileLoading || _isTableLoading) return;

    final now = DateTime.now();
    final initial = _toGenDateTime ?? _stats.latestLog ?? now;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );

    DateTime result;
    if (pickedTime != null) {
      result = DateTime(pickedDate.year, pickedDate.month, pickedDate.day,
          pickedTime.hour, pickedTime.minute);
    } else {
      result = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, 23, 59);
    }

    setState(() {
      _toGenDateTime = result;
      _isTableLoading = true;
    });
    _rebuildFilteredLogs();
  }

  void _clearFilters() {
    setState(() {
      _fromGenDateTime = null;
      _toGenDateTime = null;
      _filterLevel = null;
      _showErrorsOnly = false;
      _showSyncErrorsOnly = false;
      _searchController.clear();
      _searchText = '';
      _isTableLoading = true;
    });
    _rebuildFilteredLogs();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final total = _filteredLogs.length;
    final pageCount = total == 0 ? 1 : (total / _rowsPerPage).ceil();
    final currentPage = total == 0 ? 0 : _currentPage.clamp(0, pageCount - 1);

    final int startIndex;
    final int endIndex;
    List<ReportLogEntry> pageLogs;

    if (total == 0) {
      startIndex = 0;
      endIndex = 0;
      pageLogs = [];
    } else {
      startIndex = currentPage * _rowsPerPage;
      endIndex = math.min(startIndex + _rowsPerPage, total);
      pageLogs = _filteredLogs.sublist(startIndex, endIndex);
    }

    return ScaffoldWidget(
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header with file picker
                  _buildHeader(scheme),
                  const SizedBox(height: 16),

                  // Error display
                  if (_error != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: scheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: scheme.error),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(_error!, style: TextStyle(color: scheme.error)),
                          ),
                        ],
                      ),
                    ),

                  // Stats cards (only show when data is loaded)
                  if (_allLogs.isNotEmpty) ...[
                    _buildStatsCards(scheme),
                    const SizedBox(height: 16),
                    _buildCharts(scheme),
                    const SizedBox(height: 16),
                    // Timeline histogram chart (Kibana-style)
                    _buildTimelineHistogram(scheme),
                    const SizedBox(height: 16),
                    // User recovery stats cards
                    _buildUserRecoverySection(scheme),
                    const SizedBox(height: 16),
                    _buildFilters(scheme),
                    const SizedBox(height: 8),
                  ],

                  // Log table with constrained height
                  SizedBox(
                    height: _allLogs.isEmpty ? 400 : 600,
                    child: _allLogs.isEmpty
                        ? _buildEmptyState(scheme)
                        : _buildLogTable(
                            theme: theme,
                            pageLogs: pageLogs,
                            total: total,
                            pageCount: pageCount,
                            currentPage: currentPage,
                            startIndex: startIndex,
                            endIndex: endIndex,
                          ),
                  ),
                ],
              ),
            ),
          ),

          // Loading overlay with shimmer effect
          if (_isFileLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.7),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 60,
                        height: 60,
                        child: CircularProgressIndicator(
                          strokeWidth: 4,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Đang đọc file...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Vui lòng chờ trong giây lát',
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(ColorScheme scheme) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  Colors.blueGrey.shade800.withValues(alpha: 0.5),
                  Colors.blueGrey.shade900.withValues(alpha: 0.3),
                ]
              : [
                  scheme.primaryContainer.withValues(alpha: 0.4),
                  scheme.primaryContainer.withValues(alpha: 0.2),
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: scheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          // Premium upload button with gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  scheme.primary,
                  scheme.primary.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isFileLoading ? null : _pickAndLoadFile,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.cloud_upload_rounded,
                        color: scheme.onPrimary,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Chọn file CSV',
                        style: TextStyle(
                          color: scheme.onPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          if (_loadedFileName != null)
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.check_circle_rounded,
                        size: 18,
                        color: Colors.green.shade600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _loadedFileName!,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: scheme.onSurface,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '${_allLogs.length} logs loaded',
                            style: TextStyle(
                              color: Colors.green.shade600,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Refresh button (to reload data without hot restart)
          if (_allLogs.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Tooltip(
                message: 'Làm mới dữ liệu',
                child: Material(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _rebuildFilteredLogs();
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Icon(
                        Icons.refresh_rounded,
                        color: scheme.primary,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(ColorScheme scheme) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _StatCard(
          icon: Icons.list_alt,
          label: 'Tổng logs',
          value: _stats.totalLogs.toString(),
          color: scheme.primary,
        ),
        _StatCard(
          icon: Icons.people,
          label: 'Users',
          value: _stats.uniqueUsers.length.toString(),
          color: scheme.tertiary,
        ),
        _StatCard(
          icon: Icons.error,
          label: 'Errors',
          value: _stats.errorCount.toString(),
          color: scheme.error,
        ),
        _StatCard(
          icon: Icons.warning,
          label: 'Warnings',
          value: _stats.warningCount.toString(),
          color: Colors.orange,
        ),
        _StatCard(
          icon: Icons.sync,
          label: 'Auto Sync',
          value: _stats.autoSyncCount.toString(),
          color: scheme.secondary,
        ),
        _StatCard(
          icon: Icons.bluetooth_disabled,
          label: 'GATT Errors',
          value: _stats.gattErrorCount.toString(),
          color: Colors.red.shade700,
        ),
        if (_stats.earliestLog != null)
          _StatCard(
            icon: Icons.schedule,
            label: 'Từ',
            value: dateFormat.format(_stats.earliestLog!),
            color: scheme.outline,
            wide: true,
          ),
        if (_stats.latestLog != null)
          _StatCard(
            icon: Icons.schedule,
            label: 'Đến',
            value: dateFormat.format(_stats.latestLog!),
            color: scheme.outline,
            wide: true,
          ),
      ],
    );
  }

  Widget _buildCharts(ColorScheme scheme) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SizedBox(
      height: 220,
      child: Row(
        children: [
          // Pie chart for log levels
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          Colors.blueGrey.shade800.withValues(alpha: 0.6),
                          Colors.blueGrey.shade900.withValues(alpha: 0.4),
                        ]
                      : [
                          Colors.white,
                          Colors.grey.shade50,
                        ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.pie_chart, size: 20, color: scheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Log Levels',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: PieChart(
                            PieChartData(
                              sections: [
                                PieChartSectionData(
                                  value: _stats.infoCount.toDouble(),
                                  color: Colors.blue.shade400,
                                  title: '',
                                  radius: 45,
                                  badgeWidget: _stats.infoCount > 0
                                      ? _buildBadge(Icons.info, Colors.blue)
                                      : null,
                                  badgePositionPercentageOffset: 1.2,
                                ),
                                PieChartSectionData(
                                  value: _stats.warningCount.toDouble(),
                                  color: Colors.orange.shade400,
                                  title: '',
                                  radius: 45,
                                  badgeWidget: _stats.warningCount > 0
                                      ? _buildBadge(Icons.warning, Colors.orange)
                                      : null,
                                  badgePositionPercentageOffset: 1.2,
                                ),
                                PieChartSectionData(
                                  value: _stats.errorCount.toDouble(),
                                  color: Colors.red.shade400,
                                  title: '',
                                  radius: 45,
                                  badgeWidget: _stats.errorCount > 0
                                      ? _buildBadge(Icons.error, Colors.red)
                                      : null,
                                  badgePositionPercentageOffset: 1.2,
                                ),
                              ],
                              sectionsSpace: 3,
                              centerSpaceRadius: 35,
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _EnhancedLegendItem(
                              color: Colors.blue.shade400,
                              label: 'Info',
                              count: _stats.infoCount,
                            ),
                            const SizedBox(height: 8),
                            _EnhancedLegendItem(
                              color: Colors.orange.shade400,
                              label: 'Warning',
                              count: _stats.warningCount,
                            ),
                            const SizedBox(height: 8),
                            _EnhancedLegendItem(
                              color: Colors.red.shade400,
                              label: 'Error',
                              count: _stats.errorCount,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Sync status
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          Colors.blueGrey.shade800.withValues(alpha: 0.6),
                          Colors.blueGrey.shade900.withValues(alpha: 0.4),
                        ]
                      : [
                          Colors.white,
                          Colors.grey.shade50,
                        ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.sync, size: 20, color: scheme.secondary),
                      const SizedBox(width: 8),
                      Text(
                        'Sync Status',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  _SyncStatusItem(
                    icon: Icons.check_circle_rounded,
                    color: Colors.green.shade400,
                    label: 'On time',
                    count: _stats.syncOnTimeCount,
                  ),
                  const SizedBox(height: 12),
                  _SyncStatusItem(
                    icon: Icons.schedule,
                    color: Colors.orange.shade400,
                    label: 'Not on time',
                    count: _stats.syncNotOnTimeCount,
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 14, color: color),
    );
  }

  /// Compute histogram data from logs (groups by time intervals)
  List<Map<String, dynamic>> _computeTimelineHistogram() {
    if (_filteredLogs.isEmpty) return [];

    // Find time range
    final logsWithTime = _filteredLogs.where((l) => l.genTime != null).toList();
    if (logsWithTime.isEmpty) return [];

    logsWithTime.sort((a, b) => a.genTime!.compareTo(b.genTime!));
    final startTime = logsWithTime.first.genTime!;
    final endTime = logsWithTime.last.genTime!;
    final totalDuration = endTime.difference(startTime);

    // Determine bucket size based on total duration
    Duration bucketSize;
    if (totalDuration.inHours <= 1) {
      bucketSize = const Duration(minutes: 1);
    } else if (totalDuration.inHours <= 6) {
      bucketSize = const Duration(minutes: 5);
    } else if (totalDuration.inHours <= 24) {
      bucketSize = const Duration(minutes: 15);
    } else if (totalDuration.inDays <= 7) {
      bucketSize = const Duration(hours: 1);
    } else {
      bucketSize = const Duration(hours: 6);
    }

    // Create buckets
    final Map<DateTime, Map<String, int>> buckets = {};
    for (final log in logsWithTime) {
      final bucketStart = DateTime(
        log.genTime!.year,
        log.genTime!.month,
        log.genTime!.day,
        log.genTime!.hour,
        (log.genTime!.minute ~/ bucketSize.inMinutes) * bucketSize.inMinutes,
      );

      buckets.putIfAbsent(bucketStart, () => {'info': 0, 'warning': 0, 'error': 0});
      final levelKey = log.level.name.toLowerCase();
      if (buckets[bucketStart]!.containsKey(levelKey)) {
        buckets[bucketStart]![levelKey] = buckets[bucketStart]![levelKey]! + 1;
      }
    }

    // Convert to list and sort
    final result = buckets.entries
        .map((e) => {
              'time': e.key,
              'info': e.value['info'] ?? 0,
              'warning': e.value['warning'] ?? 0,
              'error': e.value['error'] ?? 0,
              'total': (e.value['info'] ?? 0) +
                  (e.value['warning'] ?? 0) +
                  (e.value['error'] ?? 0),
            })
        .toList();
    result.sort((a, b) =>
        (a['time'] as DateTime).compareTo(b['time'] as DateTime));
    return result;
  }

  Widget _buildTimelineHistogram(ColorScheme scheme) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final histogramData = _computeTimelineHistogram();

    if (histogramData.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxValue = histogramData
        .map((e) => e['total'] as int)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  Colors.blueGrey.shade800.withValues(alpha: 0.6),
                  Colors.blueGrey.shade900.withValues(alpha: 0.4),
                ]
              : [Colors.white, Colors.grey.shade50],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timeline, size: 20, color: scheme.primary),
              const SizedBox(width: 8),
              Text(
                'Log Timeline (${histogramData.length} intervals)',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              // Legend
              _buildMiniLegend('Info', Colors.blue.shade400),
              const SizedBox(width: 12),
              _buildMiniLegend('Warn', Colors.orange.shade400),
              const SizedBox(width: 12),
              _buildMiniLegend('Error', Colors.red.shade400),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxValue * 1.1,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final data = histogramData[groupIndex];
                      final time = data['time'] as DateTime;
                      final fmt = DateFormat('HH:mm dd/MM');
                      return BarTooltipItem(
                        '${fmt.format(time)}\n'
                        'Info: ${data['info']}, Warn: ${data['warning']}, Error: ${data['error']}',
                        TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= histogramData.length) {
                          return const SizedBox.shrink();
                        }
                        // Show every Nth label to avoid crowding
                        final step = (histogramData.length / 8).ceil();
                        if (idx % step != 0) return const SizedBox.shrink();
                        final time = histogramData[idx]['time'] as DateTime;
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            DateFormat('HH:mm').format(time),
                            style: TextStyle(
                              fontSize: 10,
                              color: scheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Text(
                            value.toInt().toString(),
                            style: TextStyle(
                              fontSize: 10,
                              color: scheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxValue / 4,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: scheme.outlineVariant.withValues(alpha: 0.3),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: histogramData.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final data = entry.value;
                  return BarChartGroupData(
                    x: idx,
                    barRods: [
                      BarChartRodData(
                        toY: (data['total'] as int).toDouble(),
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.teal.shade400,
                            Colors.teal.shade300,
                          ],
                        ),
                        width: math.max(
                          2,
                          (MediaQuery.of(context).size.width - 200) /
                              histogramData.length -
                              2,
                        ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Shows detailed bottom sheet with user recovery timeline chart
  void _showUserDetailBottomSheet(Map<String, dynamic> summary) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final userId = summary['userId'] as String;
    final totalErrors = summary['totalErrors'] as int;
    final recoveredCount = summary['recoveredCount'] as int;
    final recoveryRate = summary['recoveryRate'] as double;
    final avgRecoveryTime = summary['avgRecoveryTime'] as Duration?;
    final deviceModel = summary['deviceModel'] as String?;
    final appVersion = summary['appVersion'] as String?;
    final androidVersion = summary['androidVersion'] as String?;
    final sdkVersion = summary['sdkVersion'] as String?;
    final totalLogs = summary['totalLogs'] as int;

    // Compute error timeline data (errors per hour)
    final errorsByHour = _computeErrorTimeline();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [scheme.primary, scheme.secondary],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.person, color: scheme.onPrimary, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'User Detail',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            userId,
                            style: TextStyle(
                              fontSize: 12,
                              color: scheme.onSurface.withValues(alpha: 0.7),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: scheme.onSurface),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Device info card
                      _buildDetailInfoCard(
                        scheme: scheme,
                        isDark: isDark,
                        title: 'Device Info',
                        icon: Icons.phone_android,
                        items: [
                          if (deviceModel != null) 'Model: $deviceModel',
                          if (androidVersion != null) 'Android: $androidVersion',
                          if (sdkVersion != null) 'SDK: $sdkVersion',
                          if (appVersion != null) 'App: $appVersion',
                          'Total logs: $totalLogs',
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Recovery stats card
                      _buildDetailInfoCard(
                        scheme: scheme,
                        isDark: isDark,
                        title: 'Recovery Statistics',
                        icon: Icons.healing,
                        items: [
                          'Total Errors: $totalErrors',
                          'Recovered: $recoveredCount',
                          'Recovery Rate: ${(recoveryRate * 100).toStringAsFixed(1)}%',
                          'Avg Recovery Time: ${avgRecoveryTime != null ? _formatDuration(avgRecoveryTime) : 'N/A'}',
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Error Timeline Chart
                      if (errorsByHour.isNotEmpty) ...[
                        Text(
                          'Error Timeline',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Shows errors grouped by hour over time',
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          height: 200,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: isDark
                                  ? [
                                      Colors.blueGrey.shade800.withValues(alpha: 0.4),
                                      Colors.blueGrey.shade900.withValues(alpha: 0.3),
                                    ]
                                  : [Colors.white, Colors.grey.shade50],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: scheme.outlineVariant.withValues(alpha: 0.3),
                            ),
                          ),
                          child: _buildErrorTimelineChart(errorsByHour, scheme, isDark),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailInfoCard({
    required ColorScheme scheme,
    required bool isDark,
    required String title,
    required IconData icon,
    required List<String> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  Colors.blueGrey.shade800.withValues(alpha: 0.4),
                  Colors.blueGrey.shade900.withValues(alpha: 0.3),
                ]
              : [Colors.white, Colors.grey.shade50],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: scheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  item,
                  style: TextStyle(
                    fontSize: 13,
                    color: scheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              )),
        ],
      ),
    );
  }

  /// Compute error counts grouped by hour for timeline chart
  Map<String, int> _computeErrorTimeline() {
    final Map<String, int> errorsByHour = {};
    final dateFormat = DateFormat('MM/dd HH:00');

    // Helper to check if Error field is NOT null (has error)
    bool hasError(String message) {
      final match = RegExp(r'Error:\s*(\S+)', caseSensitive: false)
          .firstMatch(message);
      if (match == null) return false;
      final errorValue = match.group(1);
      return errorValue != null &&
          errorValue.toLowerCase() != 'null' &&
          errorValue.isNotEmpty;
    }

    // Find HealthCheck logs with errors
    for (final log in _filteredLogs) {
      if (!log.message.contains('[HealthCheck]') &&
          !log.message.contains('Progress:')) {
        continue;
      }
      if (!hasError(log.message)) continue;
      if (log.genTime == null) continue;

      final hourKey = dateFormat.format(log.genTime!);
      errorsByHour[hourKey] = (errorsByHour[hourKey] ?? 0) + 1;
    }

    return errorsByHour;
  }

  Widget _buildErrorTimelineChart(
      Map<String, int> errorsByHour, ColorScheme scheme, bool isDark) {
    if (errorsByHour.isEmpty) {
      return Center(
        child: Text(
          'No error data',
          style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.5)),
        ),
      );
    }

    // Sort by time
    final sortedKeys = errorsByHour.keys.toList()..sort();
    final maxValue = errorsByHour.values.reduce((a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxValue.toDouble() * 1.2,
        barGroups: sortedKeys.asMap().entries.map((entry) {
          final idx = entry.key;
          final key = entry.value;
          final value = errorsByHour[key]!;

          return BarChartGroupData(
            x: idx,
            barRods: [
              BarChartRodData(
                toY: value.toDouble(),
                width: 16,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.red.shade400,
                    Colors.red.shade600,
                  ],
                ),
              ),
            ],
          );
        }).toList(),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= sortedKeys.length) {
                  return const SizedBox.shrink();
                }
                // Show every nth label to avoid overlap
                final step = (sortedKeys.length / 5).ceil().clamp(1, 10);
                if (idx % step != 0) return const SizedBox.shrink();

                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    sortedKeys[idx].split(' ').last, // Show only hour
                    style: TextStyle(
                      fontSize: 10,
                      color: scheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox.shrink();
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    fontSize: 10,
                    color: scheme.onSurface.withValues(alpha: 0.6),
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxValue > 4 ? (maxValue / 4).ceilToDouble() : 1,
          getDrawingHorizontalLine: (value) => FlLine(
            color: scheme.outlineVariant.withValues(alpha: 0.3),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            tooltipPadding: const EdgeInsets.all(8),
            tooltipMargin: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final key = sortedKeys[group.x];
              return BarTooltipItem(
                '$key\n${rod.toY.toInt()} errors',
                TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMiniLegend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  /// Compute user recovery summaries from filtered logs
  /// 
  /// HealthCheck log format:
  /// - Progress: SCANNING | CONNECTING | CONNECTED | SYNCING | IDLE | DISCONNECTED
  /// - Error: null (no error) or error text (has error)
  /// 
  /// Recovery = Error log followed by Progress=CONNECTED/SYNCING/IDLE with Error=null
  List<Map<String, dynamic>> _computeUserRecoverySummaries() {
    if (_filteredLogs.isEmpty) return [];

    // Helper to parse Progress from HealthCheck message
    String? parseProgress(String message) {
      final match = RegExp(r'Progress:\s*([A-Z_]+)', caseSensitive: false)
          .firstMatch(message);
      return match?.group(1)?.toUpperCase();
    }

    // Helper to check if Error field is NOT null (has error)
    bool hasError(String message) {
      final match = RegExp(r'Error:\s*(\S+)', caseSensitive: false)
          .firstMatch(message);
      if (match == null) return false;
      final errorValue = match.group(1);
      return errorValue != null &&
          errorValue.toLowerCase() != 'null' &&
          errorValue.isNotEmpty;
    }

    // Helper to check if Progress indicates success state
    bool isSuccessProgress(String? progress) {
      if (progress == null) return false;
      return progress == 'CONNECTED' ||
          progress == 'SYNCING' ||
          progress == 'IDLE';
    }

    // Sort all logs by genTime ascending
    final allLogs = _filteredLogs.toList();
    allLogs.sort((a, b) {
      if (a.genTime == null || b.genTime == null) return 0;
      return a.genTime!.compareTo(b.genTime!);
    });

    // Find HealthCheck logs only
    final healthCheckLogs = allLogs.where((l) =>
        l.message.contains('[HealthCheck]') ||
        l.message.contains('Progress:')).toList();

    if (healthCheckLogs.isEmpty) return [];

    // Find error logs (Error field is not null)
    final errorLogs = healthCheckLogs.where((l) => hasError(l.message)).toList();

    if (errorLogs.isEmpty) return [];

    // Try to find device info from logs
    String? deviceModel;
    String? appVersion;
    String? androidVersion;
    String? sdkVersion;

    for (final log in allLogs) {
      final msg = log.message;
      if (msg.contains('Android') && androidVersion == null) {
        final androidMatch = RegExp(r'Android\s*(\d+)').firstMatch(msg);
        if (androidMatch != null) androidVersion = androidMatch.group(1);
      }
      if (msg.contains('SDK') && sdkVersion == null) {
        final sdkMatch = RegExp(r'SDK[:\s]*(\d+)').firstMatch(msg);
        if (sdkMatch != null) sdkVersion = sdkMatch.group(1);
      }
      if ((msg.contains('Model:') || msg.contains('model=')) && deviceModel == null) {
        final modelMatch = RegExp(r'(?:Model:|model=)\s*([^\s,\]]+)')
            .firstMatch(msg);
        if (modelMatch != null) deviceModel = modelMatch.group(1);
      }
      if ((msg.contains('app_version') || msg.contains('version=')) && appVersion == null) {
        final versionMatch = RegExp(r'(?:app_version|version)[=:]\s*([^\s,\]]+)')
            .firstMatch(msg);
        if (versionMatch != null) appVersion = versionMatch.group(1);
      }
    }

    // Count recovered errors
    int recoveredCount = 0;
    Duration totalRecoveryTime = Duration.zero;

    for (final errorLog in errorLogs) {
      if (errorLog.genTime == null) continue;

      // Look for recovery within next 30 mins
      final deadline = errorLog.genTime!.add(const Duration(minutes: 30));

      // Find the next logs AFTER this error
      for (final nextLog in healthCheckLogs) {
        if (nextLog.genTime == null) continue;
        // Must be AFTER the error
        if (!nextLog.genTime!.isAfter(errorLog.genTime!)) continue;
        // Must be within 30 min window
        if (nextLog.genTime!.isAfter(deadline)) continue;

        final progress = parseProgress(nextLog.message);
        final nextHasError = hasError(nextLog.message);

        // Recovery: Success progress AND no error
        if (isSuccessProgress(progress) && !nextHasError) {
          recoveredCount++;
          totalRecoveryTime += nextLog.genTime!.difference(errorLog.genTime!);
          break; // Found recovery for this error
        }
      }
    }

    final recoveryRate = recoveredCount / errorLogs.length;
    final avgRecoveryTime = recoveredCount > 0
        ? Duration(milliseconds: totalRecoveryTime.inMilliseconds ~/ recoveredCount)
        : null;

    // Return single summary (for single-user file)
    return [{
      'userId': _stats.uniqueUsers.isNotEmpty 
          ? _stats.uniqueUsers.first 
          : 'All Users',
      'totalErrors': errorLogs.length,
      'recoveredCount': recoveredCount,
      'recoveryRate': recoveryRate,
      'avgRecoveryTime': avgRecoveryTime,
      'deviceModel': deviceModel,
      'appVersion': appVersion,
      'androidVersion': androidVersion,
      'sdkVersion': sdkVersion,
      'totalLogs': allLogs.length,
    }];
  }

  Widget _buildUserRecoverySection(ColorScheme scheme) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final summaries = _computeUserRecoverySummaries();

    // Always show section header, with info if empty
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.people, size: 20, color: scheme.primary),
            const SizedBox(width: 8),
            Text(
              summaries.isNotEmpty 
                  ? 'User Sync Recovery Stats (Top ${summaries.length})'
                  : 'User Sync Recovery Stats',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (summaries.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.blueGrey.shade800.withValues(alpha: 0.3) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: scheme.primary.withValues(alpha: 0.6)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Không tìm thấy logs HealthCheck có lỗi BLE/Sync. '
                    'Logs cần chứa "[HealthCheck]" và field "Error:" khác null.',
                    style: TextStyle(
                      fontSize: 13,
                      color: scheme.onSurface.withValues(alpha: 0.7),
                ))),
              ],
            ),
          )
        else
          SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: summaries.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final s = summaries[index];
                return _buildUserRecoveryCard(
                  scheme: scheme,
                  isDark: isDark,
                  userId: s['userId'] as String,
                  deviceModel: s['deviceModel'] as String?,
                  appVersion: s['appVersion'] as String?,
                  androidVersion: s['androidVersion'] as String?,
                  sdkVersion: s['sdkVersion'] as String?,
                  recoveryRate: s['recoveryRate'] as double,
                  avgRecoveryTime: s['avgRecoveryTime'] as Duration?,
                  totalErrors: s['totalErrors'] as int,
                  recoveredCount: s['recoveredCount'] as int,
                  onTap: () => _showUserDetailBottomSheet(s),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildUserRecoveryCard({
    required ColorScheme scheme,
    required bool isDark,
    required String userId,
    String? deviceModel,
    String? appVersion,
    String? androidVersion,
    String? sdkVersion,
    required double recoveryRate,
    Duration? avgRecoveryTime,
    required int totalErrors,
    required int recoveredCount,
    VoidCallback? onTap,
  }) {
    final recoveryPercent = (recoveryRate * 100).toStringAsFixed(0);
    final MaterialColor recoveryColor = recoveryRate >= 0.7
        ? Colors.green
        : recoveryRate >= 0.4
            ? Colors.orange
            : Colors.red;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 280,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
          colors: isDark
              ? [
                  Colors.blueGrey.shade800.withValues(alpha: 0.6),
                  Colors.blueGrey.shade900.withValues(alpha: 0.4),
                ]
              : [Colors.white, Colors.grey.shade50],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // User ID header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.person,
                  size: 16,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  userId,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Device info line
          if (deviceModel != null || androidVersion != null)
            Text(
              [
                if (androidVersion != null) 'Android $androidVersion',
                if (sdkVersion != null) '(SDK $sdkVersion)',
                if (deviceModel != null) '| $deviceModel',
                if (appVersion != null) '| $appVersion',
              ].join(' '),
              style: TextStyle(
                fontSize: 11,
                color: scheme.onSurface.withValues(alpha: 0.6),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          const Spacer(),
          // Stats row
          Row(
            children: [
              // Recovery rate
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: recoveryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Tỉ lệ khôi phục: $recoveryPercent%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: recoveryColor.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Recovery time and error count
          Text(
            [
              'T/g khôi phục TB: ${avgRecoveryTime != null ? _formatDuration(avgRecoveryTime) : 'N/A'}',
              'Số lần: $totalErrors',
            ].join(' | '),
            style: TextStyle(
              fontSize: 11,
              color: scheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    if (d.inMinutes < 1) {
      return '${d.inSeconds}s';
    } else if (d.inHours < 1) {
      return '${d.inMinutes}m';
    } else {
      return '${d.inHours}h ${d.inMinutes % 60}m';
    }
  }

  Widget _buildFilters(ColorScheme scheme) {
    final dateTimeLabel = DateFormat('dd/MM/yyyy HH:mm');

    return Column(
      children: [
        TextField(
          controller: _searchController,
          enabled: !_isFileLoading,
          decoration: InputDecoration(
            labelText: 'Tìm kiếm theo message hoặc account ID',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: scheme.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide(color: scheme.outlineVariant),
            ),
            suffixIcon: _searchText.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => _searchController.clear(),
                  )
                : null,
          ),
        ),
        const SizedBox(height: 8),
        // Quick filter chips row with enhanced styling
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildEnhancedFilterChip(
                label: 'Chỉ Errors',
                icon: Icons.error_outline,
                isSelected: _showErrorsOnly,
                selectedColor: Colors.red,
                onSelected: (val) {
                  setState(() {
                    _showErrorsOnly = val;
                    if (val) _showSyncErrorsOnly = false;
                    _isTableLoading = true;
                  });
                  _rebuildFilteredLogs();
                },
              ),
              const SizedBox(width: 10),
              _buildEnhancedFilterChip(
                label: 'Sync/BLE Errors',
                icon: Icons.bluetooth_disabled,
                isSelected: _showSyncErrorsOnly,
                selectedColor: Colors.orange,
                onSelected: (val) {
                  setState(() {
                    _showSyncErrorsOnly = val;
                    if (val) _showErrorsOnly = false;
                    _isTableLoading = true;
                  });
                  _rebuildFilteredLogs();
                },
              ),
              const SizedBox(width: 16),
              // Level filter
              DropdownButton<LogLevel?>(
                value: _filterLevel,
                hint: const Text('Log Level'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Tất cả')),
                  ...LogLevel.values.map(
                    (l) => DropdownMenuItem(value: l, child: Text(l.displayName)),
                  ),
                ],
                onChanged: (val) {
                  setState(() {
                    _filterLevel = val;
                    _isTableLoading = true;
                  });
                  _rebuildFilteredLogs();
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // Date range
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isFileLoading ? null : _pickFromGenDateTime,
                icon: const Icon(Icons.calendar_today, size: 18),
                label: Text(
                  _fromGenDateTime == null
                      ? 'Từ ngày'
                      : 'Từ: ${dateTimeLabel.format(_fromGenDateTime!)}',
                  overflow: TextOverflow.ellipsis,
                ),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isFileLoading ? null : _pickToGenDateTime,
                icon: const Icon(Icons.calendar_today_outlined, size: 18),
                label: Text(
                  _toGenDateTime == null
                      ? 'Đến ngày'
                      : 'Đến: ${dateTimeLabel.format(_toGenDateTime!)}',
                  overflow: TextOverflow.ellipsis,
                ),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(Icons.clear_all),
              label: const Text('Xoá lọc'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEnhancedFilterChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color selectedColor,
    required ValueChanged<bool> onSelected,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        gradient: isSelected
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  selectedColor,
                  selectedColor.withValues(alpha: 0.8),
                ],
              )
            : null,
        color: isSelected ? null : (isDark ? Colors.grey.shade800 : Colors.grey.shade100),
        borderRadius: BorderRadius.circular(12),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: selectedColor.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onSelected(!isSelected),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected 
                      ? Colors.white 
                      : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected 
                        ? Colors.white 
                        : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme scheme) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Container(
        padding: const EdgeInsets.all(40),
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    Colors.blueGrey.shade800.withValues(alpha: 0.3),
                    Colors.blueGrey.shade900.withValues(alpha: 0.1),
                  ]
                : [
                    scheme.primaryContainer.withValues(alpha: 0.3),
                    scheme.primaryContainer.withValues(alpha: 0.1),
                  ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.cloud_upload_rounded,
                size: 56,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Import Log Report',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Chọn file CSV để xem báo cáo log chi tiết với biểu đồ và thống kê',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: scheme.onSurface.withValues(alpha: 0.7),
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: scheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Hỗ trợ định dạng Kibana (@timestamp, request_body)',
                    style: TextStyle(
                      color: scheme.onSurface.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogTable({
    required ThemeData theme,
    required List<ReportLogEntry> pageLogs,
    required int total,
    required int pageCount,
    required int currentPage,
    required int startIndex,
    required int endIndex,
  }) {
    final scheme = theme.colorScheme;
    final dateFormat = DateFormat('dd/MM HH:mm:ss');

    return Column(
      children: [
        // Table header with sort
        Row(
          children: [
            Text(
              'Hiển thị ${startIndex + 1} - $endIndex / $total logs (Trang ${currentPage + 1}/$pageCount)',
              style: theme.textTheme.bodySmall,
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _sortAscending = !_sortAscending;
                  _isTableLoading = true;
                });
                _rebuildFilteredLogs();
              },
              icon: Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward, size: 18),
              label: Text(_sortAscending ? 'Cũ nhất' : 'Mới nhất'),
            ),
            const SizedBox(width: 8),
            DropdownButton<int>(
              value: _rowsPerPage,
              items: _pageSizeOptions.map((s) => DropdownMenuItem(value: s, child: Text('$s/trang'))).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _rowsPerPage = val;
                    _currentPage = 0;
                  });
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Table
        Expanded(
          child: _isTableLoading
              ? const Center(child: CircularProgressIndicator())
              : Scrollbar(
                  controller: _tableScrollController,
                  thumbVisibility: true,
                  child: ListView.builder(
                    controller: _tableScrollController,
                    itemCount: pageLogs.length,
                    itemBuilder: (context, index) {
                      final log = pageLogs[index];

                      Color levelColor;
                      IconData levelIcon;
                      switch (log.level) {
                        case LogLevel.error:
                          levelColor = Colors.red;
                          levelIcon = Icons.error;
                          break;
                        case LogLevel.warning:
                          levelColor = Colors.orange;
                          levelIcon = Icons.warning;
                          break;
                        case LogLevel.info:
                          levelColor = Colors.blue;
                          levelIcon = Icons.info;
                          break;
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 4),
                        child: ExpansionTile(
                          leading: Icon(levelIcon, color: levelColor, size: 20),
                          title: Text(
                            log.genTime != null ? dateFormat.format(log.genTime!) : '-',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(
                            log.message.length > 100
                                ? '${log.message.substring(0, 100)}...'
                                : log.message,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                          ),
                          trailing: log.accountId != null
                              ? Chip(
                                  label: Text(
                                    log.accountId!.length > 8
                                        ? '${log.accountId!.substring(0, 8)}...'
                                        : log.accountId!,
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                  padding: EdgeInsets.zero,
                                  visualDensity: VisualDensity.compact,
                                )
                              : null,
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              color: scheme.surfaceContainerHighest.withOpacity(0.5),
                              child: SelectableText(
                                log.message,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                  color: scheme.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
        ),

        // Pagination
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: currentPage > 0
                  ? () => setState(() => _currentPage = 0)
                  : null,
              icon: const Icon(Icons.first_page),
            ),
            IconButton(
              onPressed: currentPage > 0
                  ? () => setState(() => _currentPage--)
                  : null,
              icon: const Icon(Icons.chevron_left),
            ),
            const SizedBox(width: 16),
            Text('Trang ${currentPage + 1} / $pageCount'),
            const SizedBox(width: 16),
            IconButton(
              onPressed: currentPage < pageCount - 1
                  ? () => setState(() => _currentPage++)
                  : null,
              icon: const Icon(Icons.chevron_right),
            ),
            IconButton(
              onPressed: currentPage < pageCount - 1
                  ? () => setState(() => _currentPage = pageCount - 1)
                  : null,
              icon: const Icon(Icons.last_page),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool wide;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.wide = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(minWidth: wide ? 200 : 140),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: isDark ? 0.25 : 0.15),
            color.withValues(alpha: isDark ? 0.1 : 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _EnhancedLegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final int count;

  const _EnhancedLegendItem({
    required this.color,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SyncStatusItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final int count;

  const _SyncStatusItem({
    required this.icon,
    required this.color,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
