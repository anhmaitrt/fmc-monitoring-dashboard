import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/user_journey_parser.dart';
import '../../../model/log_report/log_report_model.dart';
import '../../../model/log_report/user_journey_event.dart';

/// A premium timeline widget that visualizes the user's journey through the app
class UserJourneyTimeline extends StatefulWidget {
  const UserJourneyTimeline({required this.allLogs, super.key});

  final List<ReportLogEntry> allLogs;

  @override
  State<UserJourneyTimeline> createState() => _UserJourneyTimelineState();
}

class _UserJourneyTimelineState extends State<UserJourneyTimeline> {
  List<UserJourneyEvent> _allEvents = [];
  List<UserJourneySession> _sessions = [];
  Set<String> _accounts = {};
  String? _selectedAccount;

  Set<JourneyEventType> _enabledTypes = JourneyEventType.values.toSet();
  int? _expandedSessionIndex;
  bool _isLoading = true;

  final _timeFormat = DateFormat('HH:mm:ss');
  final _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm:ss');

  @override
  void initState() {
    super.initState();
    _parseData();
  }

  @override
  void didUpdateWidget(covariant UserJourneyTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.allLogs != oldWidget.allLogs) {
      _parseData();
    }
  }

  void _parseData() {
    setState(() => _isLoading = true);

    Future.microtask(() {
      final events = UserJourneyParser.parseJourneyEvents(widget.allLogs);
      final accounts = UserJourneyParser.getUniqueAccounts(events);

      final filteredEvents = _selectedAccount != null
          ? events.where((e) => e.accountId == _selectedAccount).toList()
          : events;

      final sessions = UserJourneyParser.groupIntoSessions(filteredEvents);

      if (mounted) {
        setState(() {
          _allEvents = events;
          _accounts = accounts;
          _sessions = sessions;
          _isLoading = false;
          _expandedSessionIndex = sessions.isNotEmpty ? 0 : null;
        });
      }
    });
  }

  void _filterByAccount(String? accountId) {
    setState(() {
      _selectedAccount = accountId;
      _isLoading = true;
    });

    Future.microtask(() {
      final filteredEvents = accountId != null
          ? _allEvents.where((e) => e.accountId == accountId).toList()
          : _allEvents;
      final sessions = UserJourneyParser.groupIntoSessions(filteredEvents);

      if (mounted) {
        setState(() {
          _sessions = sessions;
          _isLoading = false;
          _expandedSessionIndex = sessions.isNotEmpty ? 0 : null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_allEvents.isEmpty) {
      return Center(
        child: Text(
          'No journey events found in loaded logs.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: scheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Controls Row ──
        _buildControls(scheme, isDark),
        const SizedBox(height: 12),

        // ── Summary Cards ──
        _buildSummaryCards(scheme, isDark),
        const SizedBox(height: 16),

        // ── Sessions Timeline ──
        Expanded(
          child: ListView.builder(
            itemCount: _sessions.length,
            padding: const EdgeInsets.only(bottom: 24),
            itemBuilder: (context, index) {
              return _buildSessionCard(index, scheme, isDark);
            },
          ),
        ),
      ],
    );
  }

  // ─── Controls ──────────────────────────────────────────────────────

  Widget _buildControls(ColorScheme scheme, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  Colors.blueGrey.shade800.withValues(alpha: 0.5),
                  Colors.blueGrey.shade900.withValues(alpha: 0.3),
                ]
              : [
                  scheme.primaryContainer.withValues(alpha: 0.3),
                  scheme.primaryContainer.withValues(alpha: 0.1),
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(Icons.route_rounded, color: scheme.primary, size: 22),
          const SizedBox(width: 10),
          Text(
            'User Journey',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(width: 20),

          // Account selector
          if (_accounts.isNotEmpty) ...[
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: _selectedAccount,
                    isExpanded: true,
                    hint: Text(
                      'All accounts (${_accounts.length})',
                      style: TextStyle(
                        fontSize: 13,
                        color: scheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text(
                          'All accounts (${_accounts.length})',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      ..._accounts.map(
                        (a) => DropdownMenuItem(
                          value: a,
                          child: Text(
                            a.length > 20
                                ? '${a.substring(0, 8)}...${a.substring(a.length - 8)}'
                                : a,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                    onChanged: _filterByAccount,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],

          // Event type filter chips
          _buildTypeFilterChip(JourneyEventType.appLifecycle, scheme),
          _buildTypeFilterChip(JourneyEventType.feature, scheme),
          _buildTypeFilterChip(JourneyEventType.error, scheme),
          _buildTypeFilterChip(JourneyEventType.network, scheme),
          _buildTypeFilterChip(JourneyEventType.notification, scheme),
        ],
      ),
    );
  }

  Widget _buildTypeFilterChip(JourneyEventType type, ColorScheme scheme) {
    final enabled = _enabledTypes.contains(type);
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: FilterChip(
        label: Text(type.emoji, style: const TextStyle(fontSize: 14)),
        tooltip: type.displayName,
        selected: enabled,
        onSelected: (val) {
          setState(() {
            if (val) {
              _enabledTypes.add(type);
            } else {
              _enabledTypes.remove(type);
            }
          });
        },
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        labelPadding: const EdgeInsets.symmetric(horizontal: 2),
        backgroundColor: scheme.surfaceContainerHighest,
        selectedColor: _getTypeColor(type).withValues(alpha: 0.2),
        checkmarkColor: _getTypeColor(type),
        side: BorderSide(
          color: enabled
              ? _getTypeColor(type).withValues(alpha: 0.5)
              : Colors.transparent,
        ),
      ),
    );
  }

  // ─── Summary Cards ─────────────────────────────────────────────────

  Widget _buildSummaryCards(ColorScheme scheme, bool isDark) {
    final totalEvents = _sessions.fold<int>(
      0,
      (sum, s) => sum + s.events.length,
    );
    final totalErrors = _sessions.fold<int>(0, (sum, s) => sum + s.errorCount);
    final totalWarnings = _sessions.fold<int>(
      0,
      (sum, s) => sum + s.warningCount,
    );

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _MiniStatCard(
          icon: Icons.timeline,
          label: 'Sessions',
          value: _sessions.length.toString(),
          color: scheme.primary,
          isDark: isDark,
        ),
        _MiniStatCard(
          icon: Icons.event_note,
          label: 'Events',
          value: totalEvents.toString(),
          color: scheme.tertiary,
          isDark: isDark,
        ),
        _MiniStatCard(
          icon: Icons.error_outline,
          label: 'Errors',
          value: totalErrors.toString(),
          color: scheme.error,
          isDark: isDark,
        ),
        _MiniStatCard(
          icon: Icons.warning_amber_rounded,
          label: 'Warnings',
          value: totalWarnings.toString(),
          color: Colors.orange,
          isDark: isDark,
        ),
      ],
    );
  }

  // ─── Session Card ─────────────────────────────────────────────────

  Widget _buildSessionCard(int index, ColorScheme scheme, bool isDark) {
    final session = _sessions[index];
    final isExpanded = _expandedSessionIndex == index;

    // Filter events by enabled types
    final visibleEvents = session.events
        .where((e) => _enabledTypes.contains(e.type))
        .toList();

    final durationStr = _formatDuration(session.duration);
    final hasErrors = session.errorCount > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasErrors
              ? scheme.error.withValues(alpha: 0.3)
              : scheme.outlineVariant.withValues(alpha: 0.2),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  Colors.blueGrey.shade800.withValues(alpha: 0.4),
                  Colors.blueGrey.shade900.withValues(alpha: 0.2),
                ]
              : [Colors.white, Colors.grey.shade50],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Session header
          InkWell(
            onTap: () {
              setState(() {
                _expandedSessionIndex = isExpanded ? null : index;
              });
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  // Session number badge
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: hasErrors
                            ? [
                                scheme.error,
                                scheme.error.withValues(alpha: 0.7),
                              ]
                            : [
                                scheme.primary,
                                scheme.primary.withValues(alpha: 0.7),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: scheme.onPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Session time range
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_dateTimeFormat.format(session.startTime)} → ${_timeFormat.format(session.endTime)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: scheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            _TagBadge(
                              label: durationStr,
                              color: scheme.primary,
                            ),
                            const SizedBox(width: 6),
                            _TagBadge(
                              label: '${visibleEvents.length} events',
                              color: scheme.tertiary,
                            ),
                            if (session.errorCount > 0) ...[
                              const SizedBox(width: 6),
                              _TagBadge(
                                label: '${session.errorCount} errors',
                                color: scheme.error,
                              ),
                            ],
                            if (session.warningCount > 0) ...[
                              const SizedBox(width: 6),
                              _TagBadge(
                                label: '${session.warningCount} warnings',
                                color: Colors.orange,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Expand icon
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: scheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expanded events timeline
          if (isExpanded)
            Container(
              constraints: BoxConstraints(
                maxHeight: math.min(visibleEvents.length * 72.0 + 24, 500),
              ),
              child: visibleEvents.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'No events matching current filters.',
                        style: TextStyle(
                          color: scheme.onSurface.withValues(alpha: 0.4),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        bottom: 16,
                      ),
                      itemCount: visibleEvents.length,
                      itemBuilder: (context, i) {
                        return _buildEventRow(
                          visibleEvents[i],
                          i,
                          visibleEvents.length,
                          scheme,
                          isDark,
                        );
                      },
                    ),
            ),
        ],
      ),
    );
  }

  // ─── Single Event Row ──────────────────────────────────────────────

  Widget _buildEventRow(
    UserJourneyEvent event,
    int index,
    int total,
    ColorScheme scheme,
    bool isDark,
  ) {
    final color = _getTypeColor(event.type);
    final isError = event.logLevel == LogLevel.error;
    final isWarning = event.logLevel == LogLevel.warning;
    final isLast = index == total - 1;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline line and dot
          SizedBox(
            width: 40,
            child: Column(
              children: [
                // Dot
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: isError
                        ? scheme.error
                        : isWarning
                        ? Colors.orange
                        : color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (isError ? scheme.error : color).withValues(
                          alpha: 0.4,
                        ),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: isError
                      ? const Icon(Icons.close, size: 10, color: Colors.white)
                      : null,
                ),
                // Line
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: scheme.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
              ],
            ),
          ),

          // Event card
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isError
                    ? scheme.errorContainer.withValues(alpha: 0.3)
                    : isWarning
                    ? Colors.orange.withValues(alpha: 0.08)
                    : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isError
                      ? scheme.error.withValues(alpha: 0.3)
                      : isWarning
                      ? Colors.orange.withValues(alpha: 0.2)
                      : scheme.outlineVariant.withValues(alpha: 0.15),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row: time, type badge, app state badge
                  Row(
                    children: [
                      Text(
                        _timeFormat.format(event.timestamp),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'monospace',
                          color: scheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _TagBadge(
                        label: event.type.emoji,
                        color: color,
                        small: true,
                      ),
                      const SizedBox(width: 4),
                      _TagBadge(
                        label: event.component.isNotEmpty
                            ? event.component
                            : event.type.displayName,
                        color: color,
                        small: true,
                      ),
                      if (event.appState != AppState.unknown) ...[
                        const SizedBox(width: 4),
                        _TagBadge(
                          label: event.appState == AppState.foreground
                              ? 'FG'
                              : 'BG',
                          color: event.appState == AppState.foreground
                              ? Colors.green
                              : Colors.blueGrey,
                          small: true,
                        ),
                      ],
                      const Spacer(),
                      if (isError)
                        Icon(Icons.error, size: 16, color: scheme.error),
                      if (isWarning)
                        const Icon(
                          Icons.warning_amber,
                          size: 16,
                          color: Colors.orange,
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Action / summary
                  Text(
                    event.action,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                  ),

                  // Details (truncated, expandable on tap)
                  if (event.details.isNotEmpty && event.details != event.action)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        event.details.length > 200
                            ? '${event.details.substring(0, 197)}...'
                            : event.details,
                        style: TextStyle(
                          fontSize: 11,
                          color: scheme.onSurface.withValues(alpha: 0.5),
                          fontFamily: 'monospace',
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────────

  Color _getTypeColor(JourneyEventType type) {
    switch (type) {
      case JourneyEventType.appLifecycle:
        return Colors.blue;
      case JourneyEventType.screen:
        return Colors.purple;
      case JourneyEventType.feature:
        return Colors.teal;
      case JourneyEventType.error:
        return Colors.red;
      case JourneyEventType.network:
        return Colors.cyan;
      case JourneyEventType.notification:
        return Colors.amber.shade700;
      case JourneyEventType.unknown:
        return Colors.grey;
    }
  }

  String _formatDuration(Duration d) {
    if (d.inHours > 0) {
      return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    } else if (d.inMinutes > 0) {
      return '${d.inMinutes}m ${d.inSeconds.remainder(60)}s';
    } else {
      return '${d.inSeconds}s';
    }
  }
}

// ─── Reusable small widgets ──────────────────────────────────────────

class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [color.withValues(alpha: 0.15), color.withValues(alpha: 0.05)]
              : [color.withValues(alpha: 0.08), color.withValues(alpha: 0.02)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: color.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TagBadge extends StatelessWidget {
  const _TagBadge({
    required this.label,
    required this.color,
    this.small = false,
  });

  final String label;
  final Color color;
  final bool small;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 6 : 8,
        vertical: small ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: small ? 10 : 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
