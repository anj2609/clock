import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/alarm.dart';
import '../providers/alarm_provider.dart';
import '../utils/constants.dart';

class AddEditAlarmScreen extends ConsumerStatefulWidget {
  final String? alarmId;

  const AddEditAlarmScreen({super.key, this.alarmId});

  @override
  ConsumerState<AddEditAlarmScreen> createState() => _AddEditAlarmScreenState();
}

class _AddEditAlarmScreenState extends ConsumerState<AddEditAlarmScreen> {
  late Alarm _alarm;
  late TextEditingController _labelController;
  bool _isEditMode = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController();
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  void _initializeAlarm() {
    if (_initialized) return;
    _initialized = true;

    if (widget.alarmId != null) {
      _isEditMode = true;
      final hiveBox = ref.read(hiveAlarmBoxProvider);
      final existingAlarm = hiveBox.get(widget.alarmId);
      if (existingAlarm != null) {
        _alarm = existingAlarm;
      } else {
        _alarm = Alarm.empty();
      }
    } else {
      _alarm = Alarm.empty();
    }
    _labelController.text = _alarm.label;
  }

  String _formatTime(String time24) {
    final parts = time24.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final dateTime = DateTime(2000, 1, 1, hour, minute);
    return DateFormat('hh:mm a').format(dateTime);
  }

  Future<void> _pickTime() async {
    final parts = _alarm.time.split(':');
    final initialTime = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked != null) {
      final newTime =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() {
        _alarm = _alarm.copyWith(time: newTime);
      });
    }
  }

  void _toggleDay(int day) {
    final days = List<int>.from(_alarm.repeatDays);
    if (days.contains(day)) {
      days.remove(day);
    } else {
      days.add(day);
    }
    setState(() {
      _alarm = _alarm.copyWith(repeatDays: days);
    });
  }

  Future<void> _handleSave() async {
    final label = _labelController.text.trim();
    if (label.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(AppConstants.errorEmptyLabel),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    final alarmToSave = _alarm.copyWith(label: label);

    if (_isEditMode) {
      await ref.read(alarmNotifierProvider.notifier).updateAlarm(alarmToSave);
    } else {
      await ref.read(alarmNotifierProvider.notifier).addAlarm(alarmToSave);
    }

    final state = ref.read(alarmNotifierProvider);
    if (state is! AsyncError && mounted) {
      context.go(AppConstants.routeHome);
    }
  }

  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
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
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(alarmNotifierProvider.notifier).deleteAlarm(_alarm.id);
      if (mounted) {
        context.go(AppConstants.routeHome);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _initializeAlarm();

    final alarmState = ref.watch(alarmNotifierProvider);
    final isLoading = alarmState is AsyncLoading;
    final colorScheme = Theme.of(context).colorScheme;

    ref.listen<AsyncValue<void>>(alarmNotifierProvider, (_, next) {
      if (next is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error.toString().replaceAll('Exception: ', '')),
            backgroundColor: colorScheme.error,
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditMode ? AppConstants.editAlarmTitle : AppConstants.addAlarmTitle,
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppConstants.routeHome),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTap: _pickTime,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 32),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    _formatTime(_alarm.time),
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _labelController,
              decoration: InputDecoration(
                labelText: AppConstants.labelHint,
                prefixIcon: const Icon(Icons.label_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppConstants.repeatLabel,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: List.generate(7, (index) {
                final isActive = _alarm.repeatDays.contains(index);
                return FilterChip(
                  label: Text(AppConstants.dayLabels[index]),
                  selected: isActive,
                  onSelected: (_) => _toggleDay(index),
                  selectedColor: colorScheme.primaryContainer,
                  checkmarkColor: colorScheme.primary,
                );
              }),
            ),
            const SizedBox(height: 24),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppConstants.snoozeLabel,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Row(
                      children: [
                        if (_alarm.snoozeEnabled)
                          DropdownButton<int>(
                            value: _alarm.snoozeMinutes,
                            underline: const SizedBox.shrink(),
                            items: AppConstants.snoozeOptions.map((minutes) {
                              return DropdownMenuItem<int>(
                                value: minutes,
                                child: Text('$minutes min'),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _alarm =
                                      _alarm.copyWith(snoozeMinutes: value);
                                });
                              }
                            },
                          ),
                        Switch(
                          value: _alarm.snoozeEnabled,
                          onChanged: (value) {
                            setState(() {
                              _alarm = _alarm.copyWith(snoozeEnabled: value);
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: isLoading ? null : _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        AppConstants.saveButton,
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
            if (_isEditMode) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: isLoading ? null : _handleDelete,
                child: Text(
                  AppConstants.deleteButton,
                  style: TextStyle(
                    color: colorScheme.error,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
