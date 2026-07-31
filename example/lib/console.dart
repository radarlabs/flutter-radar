import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum ConsoleStatus { success, error }

class ConsoleEntry {
  final String label;
  final ConsoleStatus status;
  final String body;
  final DateTime timestamp;

  ConsoleEntry({
    required this.label,
    required this.status,
    required this.body,
  }) : timestamp = DateTime.now();

  String get formattedTime {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    final s = timestamp.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}

/// Shared by the UI and the static, top-level callbacks that Radar invokes,
/// which cannot reach widget state.
final ConsoleController console = ConsoleController();

class ConsoleController extends ChangeNotifier {
  static const int _maxEntries = 200;

  final List<ConsoleEntry> _entries = [];

  List<ConsoleEntry> get entries => List.unmodifiable(_entries);

  bool get isEmpty => _entries.isEmpty;

  void log(String label, Object? result, {ConsoleStatus? status}) {
    _add(ConsoleEntry(
      label: label,
      status: status ?? (looksLikeError(result) ? ConsoleStatus.error : ConsoleStatus.success),
      body: prettyValue(result),
    ));
  }

  /// Listener events fire continuously once tracking starts, so they go to the
  /// terminal rather than the in-app console, which is reserved for the
  /// response of whichever button was pressed.
  void logEvent(String label, Object? payload) {
    debugPrint('[$label] ${prettyValue(payload)}');
  }

  void logError(String label, Object error) {
    _add(ConsoleEntry(
      label: label,
      status: ConsoleStatus.error,
      body: error.toString(),
    ));
  }

  void clear() {
    _entries.clear();
    notifyListeners();
  }

  String asText() => _entries
      .map((e) => '[${e.formattedTime}] ${e.label}\n${e.body}')
      .join('\n\n');

  void _add(ConsoleEntry entry) {
    _entries.insert(0, entry);
    if (_entries.length > _maxEntries) {
      _entries.removeLast();
    }
    notifyListeners();
  }
}

/// The plugin reports failures as a `status` string or an `error` key rather
/// than by throwing, so success can't be inferred from the call completing.
bool looksLikeError(Object? result) {
  if (result is! Map) return false;
  if (result['error'] != null) return true;
  final status = result['status'];
  return status is String && status != 'SUCCESS';
}

String prettyValue(Object? value) {
  if (value == null) return 'null';
  if (value is String) return value.isEmpty ? '""' : value;
  try {
    return const JsonEncoder.withIndent('  ').convert(_normalize(value));
  } catch (_) {
    return value.toString();
  }
}

/// Platform channels hand back `Map<Object?, Object?>`, which `jsonEncode`
/// rejects; keys have to be coerced to strings first.
Object? _normalize(Object? value) {
  if (value == null || value is num || value is bool || value is String) {
    return value;
  }
  if (value is Map) {
    return value.map((k, v) => MapEntry('$k', _normalize(v)));
  }
  if (value is Iterable) {
    return value.map(_normalize).toList();
  }
  return value.toString();
}

class ConsolePanel extends StatefulWidget {
  const ConsolePanel({super.key});

  @override
  State<ConsolePanel> createState() => _ConsolePanelState();
}

class _ConsolePanelState extends State<ConsolePanel> {
  bool _expanded = true;

  @override
  void initState() {
    super.initState();
    console.addListener(_onConsoleChanged);
  }

  @override
  void dispose() {
    console.removeListener(_onConsoleChanged);
    super.dispose();
  }

  void _onConsoleChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = console.entries;
    final maxHeight = MediaQuery.of(context).size.height * 0.42;

    return Material(
      elevation: 12,
      color: theme.colorScheme.surfaceContainerHighest,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _header(theme, entries.length),
            AnimatedSize(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              child: SizedBox(
                height: _expanded ? maxHeight : 0,
                width: double.infinity,
                child: entries.isEmpty
                    ? _emptyState(theme)
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                        itemCount: entries.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 6),
                        itemBuilder: (context, i) => _EntryTile(entry: entries[i]),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(ThemeData theme, int count) {
    return InkWell(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
        child: Row(
          children: [
            Icon(
              _expanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text('Console', style: theme.textTheme.titleSmall),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const Spacer(),
            IconButton(
              tooltip: 'Copy all',
              icon: const Icon(Icons.copy_all, size: 20),
              onPressed: count == 0
                  ? null
                  : () {
                      Clipboard.setData(ClipboardData(text: console.asText()));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Console copied'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
            ),
            IconButton(
              tooltip: 'Clear',
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: count == 0 ? null : console.clear,
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(ThemeData theme) {
    return Center(
      child: Text(
        'Run an API call to see results here',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _EntryTile extends StatefulWidget {
  final ConsoleEntry entry;

  const _EntryTile({required this.entry});

  @override
  State<_EntryTile> createState() => _EntryTileState();
}

class _EntryTileState extends State<_EntryTile> {
  bool _expanded = false;

  static const int _collapsedLineLimit = 3;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entry = widget.entry;
    final lines = entry.body.split('\n');
    final isTruncatable = lines.length > _collapsedLineLimit;
    final body = _expanded || !isTruncatable
        ? entry.body
        : '${lines.take(_collapsedLineLimit).join('\n')}\n…';

    return Card(
      margin: EdgeInsets.zero,
      color: theme.colorScheme.surface,
      child: InkWell(
        onTap: isTruncatable ? () => setState(() => _expanded = !_expanded) : null,
        onLongPress: () {
          Clipboard.setData(ClipboardData(text: '${entry.label}\n${entry.body}'));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Entry copied'),
              duration: Duration(seconds: 1),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _statusDot(entry.status),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.label,
                      style: theme.textTheme.labelLarge,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    entry.formattedTime,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              SelectableText(
                body,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusDot(ConsoleStatus status) {
    final color = switch (status) {
      ConsoleStatus.success => Colors.green,
      ConsoleStatus.error => Colors.red,
    };
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
