import 'package:flutter/material.dart';

import '../../model/interruption_range.dart';

/// A reusable dialog for selecting export options.
/// 
/// Usage:
/// ```dart
/// final result = await ExportOptionsDialog.show(
///   context: context,
///   title: 'Export Options',
///   options: [
///     ExportOption(
///       id: 'interruption_range',
///       label: 'Interruption Range',
///       type: ExportOptionType.multiSelect,
///       choices: InterruptionRange.values.map((e) => 
///         ExportChoice(id: e.name, label: e.label, value: e)
///       ).toList(),
///     ),
///   ],
/// );
/// 
/// if (result != null) {
///   final selectedRanges = result['interruption_range'] as Set<InterruptionRange>?;
///   // Use selectedRanges...
/// }
/// ```
class ExportOptionsDialog extends StatefulWidget {
  final String title;
  final String? subtitle;
  final List<ExportOption> options;
  final String confirmText;
  final String cancelText;

  const ExportOptionsDialog({
    super.key,
    required this.title,
    this.subtitle,
    required this.options,
    this.confirmText = 'Xuất',
    this.cancelText = 'Hủy',
  });

  /// Shows the dialog and returns a map of option IDs to their selected values.
  /// Returns null if the dialog was cancelled.
  static Future<Map<String, dynamic>?> show({
    required BuildContext context,
    required String title,
    String? subtitle,
    required List<ExportOption> options,
    String confirmText = 'Xuất',
    String cancelText = 'Hủy',
  }) {
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => ExportOptionsDialog(
        title: title,
        subtitle: subtitle,
        options: options,
        confirmText: confirmText,
        cancelText: cancelText,
      ),
    );
  }

  @override
  State<ExportOptionsDialog> createState() => _ExportOptionsDialogState();
}

class _ExportOptionsDialogState extends State<ExportOptionsDialog> {
  late Map<String, dynamic> _selectedValues;

  @override
  void initState() {
    super.initState();
    _selectedValues = {};
    
    // Initialize default values
    for (final option in widget.options) {
      switch (option.type) {
        case ExportOptionType.singleSelect:
          _selectedValues[option.id] = option.defaultValue;
          break;
        case ExportOptionType.multiSelect:
          _selectedValues[option.id] = option.defaultValues?.toSet() ?? <dynamic>{};
          break;
        case ExportOptionType.toggle:
          _selectedValues[option.id] = option.defaultValue ?? false;
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.title),
          if (widget.subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                widget.subtitle!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: widget.options.map(_buildOption).toList(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text(widget.cancelText),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_selectedValues),
          child: Text(widget.confirmText),
        ),
      ],
    );
  }

  Widget _buildOption(ExportOption option) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            option.label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          if (option.description != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 8),
              child: Text(
                option.description!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ),
          const SizedBox(height: 8),
          _buildOptionInput(option),
        ],
      ),
    );
  }

  Widget _buildOptionInput(ExportOption option) {
    switch (option.type) {
      case ExportOptionType.singleSelect:
        return _buildSingleSelect(option);
      case ExportOptionType.multiSelect:
        return _buildMultiSelect(option);
      case ExportOptionType.toggle:
        return _buildToggle(option);
    }
  }

  Widget _buildSingleSelect(ExportOption option) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: option.choices.map((choice) {
        final isSelected = _selectedValues[option.id] == choice.value;
        return ChoiceChip(
          label: Text(choice.label),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _selectedValues[option.id] = selected ? choice.value : null;
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildMultiSelect(ExportOption option) {
    final selectedSet = _selectedValues[option.id] as Set<dynamic>? ?? {};
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Select all / Deselect all buttons
        Row(
          children: [
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _selectedValues[option.id] = option.choices.map((c) => c.value).toSet();
                });
              },
              icon: const Icon(Icons.select_all, size: 18),
              label: const Text('Chọn tất cả', style: TextStyle(fontSize: 12)),
            ),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _selectedValues[option.id] = <dynamic>{};
                });
              },
              icon: const Icon(Icons.deselect, size: 18),
              label: const Text('Bỏ chọn', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: option.choices.map((choice) {
            final isSelected = selectedSet.contains(choice.value);
            return FilterChip(
              label: Text(choice.label),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  final newSet = Set<dynamic>.from(selectedSet);
                  if (selected) {
                    newSet.add(choice.value);
                  } else {
                    newSet.remove(choice.value);
                  }
                  _selectedValues[option.id] = newSet;
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildToggle(ExportOption option) {
    final isEnabled = _selectedValues[option.id] as bool? ?? false;
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(option.choices.firstOrNull?.label ?? ''),
      value: isEnabled,
      onChanged: (value) {
        setState(() {
          _selectedValues[option.id] = value;
        });
      },
    );
  }
}

/// Represents a single export option configuration.
class ExportOption {
  final String id;
  final String label;
  final String? description;
  final ExportOptionType type;
  final List<ExportChoice> choices;
  final dynamic defaultValue;
  final List<dynamic>? defaultValues;

  const ExportOption({
    required this.id,
    required this.label,
    this.description,
    required this.type,
    this.choices = const [],
    this.defaultValue,
    this.defaultValues,
  });
}

/// Represents a choice within an export option.
class ExportChoice<T> {
  final String id;
  final String label;
  final T value;

  const ExportChoice({
    required this.id,
    required this.label,
    required this.value,
  });
}

/// The type of export option input.
enum ExportOptionType {
  singleSelect,
  multiSelect,
  toggle,
}

// ============================================================================
// Convenience factory for InterruptionRange export
// ============================================================================

/// Helper class to quickly create export dialogs for common use cases.
class ExportDialogPresets {
  ExportDialogPresets._();

  /// Shows an export dialog with InterruptionRange selection.
  /// Returns the selected ranges, or null if cancelled.
  static Future<Set<InterruptionRange>?> showInterruptionRangeDialog({
    required BuildContext context,
    String title = 'Tùy chọn xuất dữ liệu',
    String? subtitle,
    Set<InterruptionRange>? initialSelection,
  }) async {
    final result = await ExportOptionsDialog.show(
      context: context,
      title: title,
      subtitle: subtitle,
      options: [
        ExportOption(
          id: 'interruption_range',
          label: 'Mức độ chậm đồng bộ',
          description: 'Chọn các mức độ chậm đồng bộ bạn muốn xuất',
          type: ExportOptionType.multiSelect,
          choices: InterruptionRange.values
              .map((e) => ExportChoice(
                    id: e.name,
                    label: e.label,
                    value: e,
                  ))
              .toList(),
          defaultValues: initialSelection?.toList() ?? InterruptionRange.values,
        ),
      ],
    );

    if (result == null) return null;

    final selectedSet = result['interruption_range'] as Set<dynamic>?;
    if (selectedSet == null || selectedSet.isEmpty) return {};

    return selectedSet.cast<InterruptionRange>();
  }

  /// Shows a more complete export dialog with multiple options.
  static Future<ExportSettings?> showFullExportDialog({
    required BuildContext context,
    String title = 'Tùy chọn xuất dữ liệu',
    Set<InterruptionRange>? initialRanges,
    bool initialIncludeVipOnly = false,
  }) async {
    final result = await ExportOptionsDialog.show(
      context: context,
      title: title,
      options: [
        ExportOption(
          id: 'interruption_range',
          label: 'Mức độ chậm đồng bộ',
          description: 'Chọn các mức độ chậm đồng bộ bạn muốn xuất',
          type: ExportOptionType.multiSelect,
          choices: InterruptionRange.values
              .map((e) => ExportChoice(
                    id: e.name,
                    label: e.label,
                    value: e,
                  ))
              .toList(),
          defaultValues: initialRanges?.toList() ?? InterruptionRange.values,
        ),
        ExportOption(
          id: 'vip_only',
          label: 'Lọc khách hàng',
          type: ExportOptionType.toggle,
          choices: [
            const ExportChoice(
              id: 'vip_only',
              label: 'Chỉ xuất khách VIP',
              value: true,
            ),
          ],
          defaultValue: initialIncludeVipOnly,
        ),
      ],
    );

    if (result == null) return null;

    final selectedRanges = result['interruption_range'] as Set<dynamic>?;
    final vipOnly = result['vip_only'] as bool? ?? false;

    return ExportSettings(
      ranges: selectedRanges?.cast<InterruptionRange>() ?? {},
      vipOnly: vipOnly,
    );
  }
}

/// Settings returned from the full export dialog.
class ExportSettings {
  final Set<InterruptionRange> ranges;
  final bool vipOnly;

  const ExportSettings({
    required this.ranges,
    required this.vipOnly,
  });
}
