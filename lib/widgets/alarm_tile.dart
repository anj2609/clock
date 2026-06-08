import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/alarm.dart';
import '../providers/alarm_provider.dart';
import '../utils/constants.dart';

class AlarmTile extends ConsumerWidget {
  final Alarm alarm;

  const AlarmTile({super.key, required this.alarm});

  String _formatTime(String time24) {
    final parts = time24.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final dateTime = DateTime(2000, 1, 1, hour, minute);
    return DateFormat('hh:mm a').format(dateTime);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dismissible(
      key: Key(alarm.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: colorScheme.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.delete_outline, color: colorScheme.onError, size: 28),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text(AppConstants.deleteConfirmTitle),
            content: const Text(AppConstants.deleteConfirmMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(AppConstants.cancelButton),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  AppConstants.deleteButton,
                  style: TextStyle(color: colorScheme.error),
                ),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) {
        ref.read(alarmNotifierProvider.notifier).deleteAlarm(alarm.id);
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () =>
              context.go('${AppConstants.routeEditAlarm}/${alarm.id}'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatTime(alarm.time),
                        style:
                            Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: alarm.isEnabled
                                      ? colorScheme.onSurface
                                      : colorScheme.onSurface.withValues(alpha: 0.4),
                                ),
                      ),
                      if (alarm.label.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            alarm.label,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: alarm.isEnabled
                                      ? colorScheme.onSurfaceVariant
                                      : colorScheme.onSurface.withValues(alpha: 0.3),
                                ),
                          ),
                        ),
                      if (alarm.repeatDays.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Wrap(
                            spacing: 4,
                            children: List.generate(7, (index) {
                              final isActive =
                                  alarm.repeatDays.contains(index);
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? colorScheme.primaryContainer
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isActive
                                        ? colorScheme.primary
                                        : colorScheme.outline.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Text(
                                  AppConstants.dayLabels[index],
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isActive
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isActive
                                        ? colorScheme.primary
                                        : colorScheme.onSurface.withValues(alpha: 0.4),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                    ],
                  ),
                ),
                Switch(
                  value: alarm.isEnabled,
                  onChanged: (value) {
                    ref.read(alarmNotifierProvider.notifier).updateAlarm(
                          alarm.copyWith(isEnabled: value),
                        );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
