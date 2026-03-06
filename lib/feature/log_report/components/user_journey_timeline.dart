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
  List<JourneyNode> _nodes = [];
  Set<String> _accounts = {};
  String? _selectedAccount;
  final Set<int> _expandedNodes = {};

  Set<JourneyEventType> _enabledTypes = JourneyEventType.values.toSet();
  bool _isLoading = true;
  String _searchQuery = '';

  final _timeFormat = DateFormat('HH:mm:ss');
  final _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm:ss');
  final _searchController = TextEditingController();

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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _parseData() {
    setState(() => _isLoading = true);

    Future.microtask(() {
      final events = UserJourneyParser().parseJourneyEvents(widget.allLogs);
      final accounts = UserJourneyParser().getUniqueAccounts(events);

      final filteredEvents = _selectedAccount != null
          ? events.where((e) => e.accountId == _selectedAccount).toList()
          : events;

      final nodes = UserJourneyParser().buildJourneyNodes(filteredEvents);

      if (mounted) {
        setState(() {
          _allEvents = events;
          _accounts = accounts;
          _nodes = nodes;
          _isLoading = false;
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
      final nodes = UserJourneyParser().buildJourneyNodes(filteredEvents);

      if (mounted) {
        setState(() {
          _nodes = nodes;
          _isLoading = false;
        });
      }
    });
  }

  void _expandAll() {
    setState(() {
      _expandedNodes.addAll(List.generate(_nodes.length, (i) => i));
    });
  }

  void _collapseAll() {
    setState(() => _expandedNodes.clear());
  }

  bool _matchesSearch(UserJourneyEvent event) {
    if (_searchQuery.isEmpty) return true;
    final q = _searchQuery.toLowerCase();
    return event.component.toLowerCase().contains(q) ||
        event.action.toLowerCase().contains(q) ||
        event.details.toLowerCase().contains(q) ||
        (event.tag?.toLowerCase().contains(q) ?? false) ||
        (event.layer?.toLowerCase().contains(q) ?? false);
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
        const SizedBox(height: 8),

        // ── Search + Expand/Collapse ──
        _buildSearchAndActions(scheme, isDark),
        const SizedBox(height: 8),

        // ── Summary Cards ──
        _buildSummaryCards(scheme, isDark),
        const SizedBox(height: 12),

        // ── Continuous Timeline ──
        Expanded(
          child: SelectionArea(
            child: ListView.builder(
              itemCount: _nodes.length,
              padding: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
              itemBuilder: (context, index) {
                return _buildJourneyNode(_nodes[index], index, scheme, isDark);
              },
            ),
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

  Widget _buildSearchAndActions(ColorScheme scheme, bool isDark) {
    return Row(
      children: [
        // Search field
        Expanded(
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.2),
              ),
            ),
            child: TextField(
              controller: _searchController,
              style: TextStyle(fontSize: 13, color: scheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Search events (component, action, details, tag)...',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: scheme.onSurface.withValues(alpha: 0.4),
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  size: 18,
                  color: scheme.onSurface.withValues(alpha: 0.4),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: scheme.onSurface.withValues(alpha: 0.5),
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                isDense: true,
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Expand all
        Tooltip(
          message: 'Expand all',
          child: Material(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: _expandAll,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.unfold_more_rounded,
                  size: 22,
                  color: scheme.primary,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),

        // Collapse all
        Tooltip(
          message: 'Collapse all',
          child: Material(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: _collapseAll,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.unfold_less_rounded,
                  size: 22,
                  color: scheme.primary,
                ),
              ),
            ),
          ),
        ),
      ],
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
        selectedColor: type.color.withValues(alpha: 0.2),
        checkmarkColor: type.color,
        side: BorderSide(
          color: enabled
              ? type.color.withValues(alpha: 0.5)
              : Colors.transparent,
        ),
      ),
    );
  }

  // ─── Summary Cards ─────────────────────────────────────────────────

  Widget _buildSummaryCards(ColorScheme scheme, bool isDark) {
    final totalNodes = _nodes.length;
    final totalEvents = _nodes.fold<int>(
      0,
      (sum, n) => sum + n.events.length + 1, // +1 for the main state event
    );
    final totalErrors = _nodes.fold<int>(0, (sum, n) => sum + n.errorCount);
    final totalWarnings = _nodes.fold<int>(0, (sum, n) => sum + n.warningCount);

    // Count native vs flutter events
    int nativeCount = 0;
    int flutterCount = 0;
    for (final node in _nodes) {
      if (node.mainStateEvent.layer == 'Native') nativeCount++;
      if (node.mainStateEvent.layer == 'Flutter') flutterCount++;
      for (final e in node.events) {
        if (e.layer == 'Native') nativeCount++;
        if (e.layer == 'Flutter') flutterCount++;
      }
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _MiniStatCard(
          icon: Icons.timeline,
          label: 'Lifecycle States',
          value: totalNodes.toString(),
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
        _MiniStatCard(
          icon: Icons.phone_android_rounded,
          label: 'Native',
          value: nativeCount.toString(),
          color: Colors.green.shade600,
          isDark: isDark,
        ),
        _MiniStatCard(
          icon: Icons.flutter_dash,
          label: 'Flutter',
          value: flutterCount.toString(),
          color: Colors.blue.shade600,
          isDark: isDark,
        ),
      ],
    );
  }

  // ─── Continuous Timeline Node (Main Bone) ──────────────────────────

  Widget _buildJourneyNode(
    JourneyNode node,
    int index,
    ColorScheme scheme,
    bool isDark,
  ) {
    final isLastNode = index == _nodes.length - 1;
    final hasErrors = node.errorCount > 0;
    final isExpanded = _expandedNodes.contains(index);

    // Filter secondary events by type and search
    final visibleEvents = node.events
        .where((e) => _enabledTypes.contains(e.type))
        .where(_matchesSearch)
        .toList();

    // If searching and neither the main event nor children match, hide the node
    if (_searchQuery.isNotEmpty &&
        !_matchesSearch(node.mainStateEvent) &&
        visibleEvents.isEmpty) {
      return const SizedBox.shrink();
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── The Main Bone (Vertical Line & Major Node Dot) ──
          SizedBox(
            width: 50,
            child: Column(
              children: [
                // Major Node Dot
                Container(
                  width: 32,
                  height: 32,
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: hasErrors
                          ? [scheme.error, scheme.error.withValues(alpha: 0.7)]
                          : [
                              scheme.primary,
                              scheme.primary.withValues(alpha: 0.7),
                            ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (hasErrors ? scheme.error : scheme.primary)
                            .withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    node.mainStateEvent.lifecycleIcon,
                    color: scheme.onPrimary,
                    size: 16,
                  ),
                ),

                // The continuous line segment connecting to the next node
                if (!isLastNode || (isExpanded && visibleEvents.isNotEmpty))
                  Expanded(
                    child: Container(
                      width: 4,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // ── The Content (Major Node Header + Secondary Events) ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),

                // Major Node Header (Lifecycle State)
                InkWell(
                  onTap: () {
                    setState(() {
                      if (isExpanded) {
                        _expandedNodes.remove(index);
                      } else {
                        _expandedNodes.add(index);
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: hasErrors
                          ? scheme.errorContainer.withValues(alpha: 0.2)
                          : scheme.primaryContainer.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: hasErrors
                            ? scheme.error.withValues(alpha: 0.3)
                            : scheme.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Action title + App state badge
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      node.mainStateEvent.action,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: scheme.onSurface,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _AppStateBadge(
                                    appState: node.mainStateEvent.appState,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              // Timestamp + layer badge
                              Row(
                                children: [
                                  Text(
                                    _dateTimeFormat.format(node.startTime),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'monospace',
                                      color: scheme.onSurface.withValues(
                                        alpha: 0.6,
                                      ),
                                    ),
                                  ),
                                  if (node.mainStateEvent.layer != null) ...[
                                    const SizedBox(width: 8),
                                    _LayerBadge(
                                      layer: node.mainStateEvent.layer!,
                                    ),
                                  ],
                                ],
                              ),
                              if (node.mainStateEvent.details.isNotEmpty &&
                                  node.mainStateEvent.details !=
                                      node.mainStateEvent.action) ...[
                                const SizedBox(height: 4),
                                Text(
                                  node.mainStateEvent.details,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: scheme.onSurface.withValues(
                                      alpha: 0.5,
                                    ),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (node.duration != null &&
                            node.duration!.inSeconds > 0)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _TagBadge(
                              label: _formatDuration(node.duration!),
                              color: scheme.primary,
                            ),
                          ),
                        if (visibleEvents.isNotEmpty) ...[
                          Text(
                            '${visibleEvents.length} events',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: scheme.primary.withValues(alpha: 0.8),
                            ),
                          ),
                          Icon(
                            isExpanded ? Icons.expand_less : Icons.expand_more,
                            color: scheme.primary,
                          ),
                        ],
                      ],
                    ),
                  ),
                ), // InkWell

                const SizedBox(height: 16),

                // Secondary Events attached to this node
                if (isExpanded && visibleEvents.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      children: List.generate(
                        visibleEvents.length,
                        (i) => _buildSecondaryEventRow(
                          visibleEvents[i],
                          i,
                          visibleEvents.length,
                          isLastNode,
                          scheme,
                          isDark,
                        ),
                      ),
                    ),
                  ),

                if (visibleEvents.isEmpty && !isLastNode)
                  const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Single Secondary Event Row ──────────────────────────────────────────────

  Widget _buildSecondaryEventRow(
    UserJourneyEvent event,
    int index,
    int total,
    bool isLastNode,
    ColorScheme scheme,
    bool isDark,
  ) {
    final color = event.type.color;
    final isError = event.logLevel == LogLevel.error;
    final isWarning = event.logLevel == LogLevel.warning;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline connector to main bone
          SizedBox(
            width: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Horizontal connector branch
                Container(
                  height: 2,
                  width: 16,
                  margin: const EdgeInsets.only(top: 14),
                  color: scheme.outlineVariant.withValues(alpha: 0.4),
                ),
              ],
            ),
          ),

          // Event card
          Expanded(
            child: Container(
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
                  // Header row: time, type badge, layer badge, component, app state
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
                      const SizedBox(width: 6),
                      _TagBadge(
                        label: event.type.emoji,
                        color: color,
                        small: true,
                      ),
                      const SizedBox(width: 4),
                      if (event.layer != null) ...[
                        _LayerBadge(layer: event.layer!, small: true),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: _TagBadge(
                          label: event.component.isNotEmpty
                              ? event.component
                              : event.type.displayName,
                          color: color,
                          small: true,
                        ),
                      ),
                      if (event.tag != null &&
                          event.tag!.isNotEmpty &&
                          event.tag != event.component) ...[
                        const SizedBox(width: 4),
                        _TagBadge(
                          label: event.tag!,
                          color: scheme.outline,
                          small: true,
                        ),
                      ],
                      const SizedBox(width: 4),
                      if (event.appState != AppState.unknown)
                        _AppStateBadge(appState: event.appState, small: true),
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
                  const SizedBox(height: 6),

                  // Action / summary
                  Text(
                    event.action,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                  ),

                  // Details (truncated)
                  if (event.details.isNotEmpty && event.details != event.action)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        event.details.length > 200
                            ? '${event.details.substring(0, 197)}...'
                            : event.details,
                        style: TextStyle(
                          fontSize: 11,
                          color: scheme.onSurface.withValues(alpha: 0.6),
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
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// Badge showing "Native" or "Flutter" layer origin
class _LayerBadge extends StatelessWidget {
  const _LayerBadge({required this.layer, this.small = false});

  final String layer;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final isNative = layer == 'Native';
    final color = isNative ? Colors.green.shade600 : Colors.blue.shade600;
    final icon = isNative ? Icons.phone_android : Icons.flutter_dash;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 5 : 7,
        vertical: small ? 1 : 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: small ? 10 : 12, color: color),
          const SizedBox(width: 3),
          Text(
            layer,
            style: TextStyle(
              fontSize: small ? 9 : 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Badge showing Foreground/Background app state
class _AppStateBadge extends StatelessWidget {
  const _AppStateBadge({required this.appState, this.small = false});

  final AppState appState;
  final bool small;

  @override
  Widget build(BuildContext context) {
    if (appState == AppState.unknown) return const SizedBox.shrink();

    final isForeground = appState == AppState.foreground;
    final color = isForeground ? Colors.green : Colors.orange.shade700;
    final label = isForeground ? 'FG' : 'BG';
    final icon = isForeground ? Icons.visibility : Icons.visibility_off;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 4 : 6,
        vertical: small ? 1 : 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: small ? 10 : 12, color: color),
          const SizedBox(width: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: small ? 9 : 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
