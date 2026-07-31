import 'package:flutter/material.dart';

class ApiAction {
  final String label;
  final Future<Object?> Function() run;

  const ApiAction(this.label, this.run);
}

class ApiSection {
  final String title;
  final IconData icon;
  final List<ApiAction> actions;

  const ApiSection({
    required this.title,
    required this.icon,
    required this.actions,
  });
}

class ApiSectionCard extends StatelessWidget {
  final ApiSection section;
  final ValueChanged<ApiAction> onRun;
  final bool initiallyExpanded;

  const ApiSectionCard({
    super.key,
    required this.section,
    required this.onRun,
    this.initiallyExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        leading: Icon(section.icon, color: theme.colorScheme.primary),
        title: Text(section.title, style: theme.textTheme.titleSmall),
        subtitle: Text(
          '${section.actions.length} ${section.actions.length == 1 ? 'call' : 'calls'}',
          style: theme.textTheme.bodySmall,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final action in section.actions)
                FilledButton.tonal(
                  onPressed: () => onRun(action),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  child: Text(action.label),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
