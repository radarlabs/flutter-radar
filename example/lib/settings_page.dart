import 'dart:io' show exit;

import 'package:flutter/material.dart';

import 'environment.dart';

/// The example app's settings, opened from the gear button on the home
/// screen. Like the native example apps' Settings sheet: Done just closes it.
class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.settings,
    required this.keyCheck,
  });

  final EnvironmentSettings settings;
  final KeyCheck keyCheck;

  /// Opens the page as a full-screen dialog over [context].
  static Future<void> open(
    BuildContext context, {
    required EnvironmentSettings settings,
    required KeyCheck keyCheck,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => SettingsPage(settings: settings, keyCheck: keyCheck),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [EnvironmentSection(settings: settings, keyCheck: keyCheck)],
      ),
    );
  }
}

/// Picks the Radar environment, its publishable key and, for Local, the
/// server URLs. Changes apply on the next launch: Apply saves them and quits
/// the app.
class EnvironmentSection extends StatefulWidget {
  const EnvironmentSection({
    super.key,
    required this.settings,
    required this.keyCheck,
  });

  final EnvironmentSettings settings;
  final KeyCheck keyCheck;

  @override
  State<EnvironmentSection> createState() => _EnvironmentSectionState();
}

class _EnvironmentSectionState extends State<EnvironmentSection> {
  late RadarEnvironment _selected = widget.settings.environment;
  late final _key = TextEditingController(
    text: _editableKey(widget.settings.environment),
  );
  late final _localUrl = TextEditingController(text: widget.settings.localUrl);
  late final _localVerifiedUrl = TextEditingController(
    text: widget.settings.localVerifiedUrl,
  );

  @override
  void dispose() {
    _key.dispose();
    _localUrl.dispose();
    _localVerifiedUrl.dispose();
    super.dispose();
  }

  /// The saved key for [env], or empty when only the placeholder is set.
  String _editableKey(RadarEnvironment env) {
    final key = widget.settings.publishableKey(env);
    return key == defaultPublishableKey ? '' : key;
  }

  /// The hosts the selected environment would use, from the fields as typed.
  String get _host => _selected.fixedHost ?? _localUrl.text.trim();

  String get _verifiedHost =>
      _selected.fixedVerifiedHost ??
      (_localVerifiedUrl.text.trim().isEmpty
          ? _localUrl.text.trim()
          : _localVerifiedUrl.text.trim());

  bool get _canApply =>
      _key.text.trim().isNotEmpty &&
      (_selected != RadarEnvironment.local || _localUrl.text.trim().isNotEmpty);

  Future<void> _apply() async {
    await widget.settings.save(
      environment: _selected,
      publishableKey: _key.text,
      localUrl: _localUrl.text,
      localVerifiedUrl: _localVerifiedUrl.text,
    );
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Text('Environment saved'),
            content: Text(
              'The app will quit. Reopen it to use ${_selected.label}.',
            ),
            actions: [
              // Quit rather than reinitialize, so the SDK never mixes one
              // environment's host with another's key or cached state.
              FilledButton(onPressed: () => exit(0), child: const Text('Quit')),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = widget.settings;
    final running = settings.environment;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Environment', style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          'Running: ${running.label} · '
          '${keyPrefix(settings.resolvedPublishableKey)} · '
          'key ${widget.keyCheck.summary}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        SegmentedButton<RadarEnvironment>(
          segments: [
            for (final env in RadarEnvironment.values)
              ButtonSegment(value: env, label: Text(env.label)),
          ],
          selected: {_selected},
          onSelectionChanged:
              (selection) => setState(() {
                _selected = selection.single;
                _key.text = _editableKey(_selected);
              }),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _key,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            labelText: 'Publishable key',
            hintText: 'prj_test_pk_…',
            border: OutlineInputBorder(),
          ),
        ),
        if (_selected == RadarEnvironment.local) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _localUrl,
            onChanged: (_) => setState(() {}),
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'Local URL',
              hintText: 'http://localhost:8081',
              helperText:
                  'Android emulator: http://10.0.2.2:8081. Device: your '
                  "machine's LAN IP.",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _localVerifiedUrl,
            onChanged: (_) => setState(() {}),
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'Local verified URL (optional)',
              helperText: 'Defaults to the Local URL.',
              border: OutlineInputBorder(),
            ),
          ),
        ],
        const SizedBox(height: 12),
        Text(
          'API: ${_host.ifEmpty('(set a Local URL)')}\n'
          'Verified: ${_verifiedHost.ifEmpty('(set a Local URL)')}',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _canApply ? _apply : null,
          child: const Text('Apply & quit'),
        ),
        const SizedBox(height: 4),
        Text(
          'Changes apply on the next launch, so the app quits after saving.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// A red strip shown only when the environment is misconfigured: no key is
/// set, or the key check says it isn't valid on the running environment.
class EnvironmentBadge extends StatelessWidget {
  const EnvironmentBadge({
    super.key,
    required this.settings,
    required this.keyCheck,
  });

  final EnvironmentSettings settings;
  final KeyCheck keyCheck;

  @override
  Widget build(BuildContext context) {
    final env = settings.environment;
    final String problem;
    if (!settings.hasKey) {
      problem = 'no key set';
    } else if (keyCheck.mismatches(env)) {
      problem =
          '${keyPrefix(settings.resolvedPublishableKey)} · ${keyCheck.summary}';
    } else {
      return const SizedBox.shrink();
    }
    return Container(
      width: double.infinity,
      color: Colors.red.shade700,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Text(
        '⚠ ${env.label} · $problem',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// A key's type and first characters, e.g. `prj_test_pk_1a2b…`, so the full
/// key never shows on screen.
String keyPrefix(String key) {
  if (key.isEmpty) return 'no key';
  final match = RegExp(r'^(prj_(?:test|live)_pk_)(.{0,4})').firstMatch(key);
  if (match != null) return '${match[1]}${match[2]}…';
  return key.length <= 4 ? key : '${key.substring(0, 4)}…';
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
