import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'alarm.g.dart';

@HiveType(typeId: 0)
class Alarm extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String label;

  @HiveField(2)
  final String time;

  @HiveField(3)
  final bool isEnabled;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  final List<int> repeatDays;

  @HiveField(6)
  final bool snoozeEnabled;

  @HiveField(7)
  final int snoozeMinutes;

  Alarm({
    required this.id,
    required this.label,
    required this.time,
    required this.isEnabled,
    required this.createdAt,
    required this.repeatDays,
    required this.snoozeEnabled,
    required this.snoozeMinutes,
  });

  factory Alarm.fromFirestore(Map<String, dynamic> data, String id) {
    return Alarm(
      id: id,
      label: data['label'] as String? ?? '',
      time: data['time'] as String? ?? '08:00',
      isEnabled: data['isEnabled'] as bool? ?? true,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      repeatDays: data['repeatDays'] != null
          ? List<int>.from(data['repeatDays'] as List)
          : <int>[],
      snoozeEnabled: data['snoozeEnabled'] as bool? ?? false,
      snoozeMinutes: data['snoozeMinutes'] as int? ?? 5,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'label': label,
      'time': time,
      'isEnabled': isEnabled,
      'createdAt': Timestamp.fromDate(createdAt),
      'repeatDays': repeatDays,
      'snoozeEnabled': snoozeEnabled,
      'snoozeMinutes': snoozeMinutes,
    };
  }

  factory Alarm.empty() {
    final now = DateTime.now();
    final remainder = 5 - (now.minute % 5);
    final rounded = now.add(Duration(minutes: remainder));
    final hour = rounded.hour.toString().padLeft(2, '0');
    final minute = rounded.minute.toString().padLeft(2, '0');

    return Alarm(
      id: const Uuid().v4(),
      label: '',
      time: '$hour:$minute',
      isEnabled: true,
      createdAt: DateTime.now(),
      repeatDays: <int>[],
      snoozeEnabled: false,
      snoozeMinutes: 5,
    );
  }

  Alarm copyWith({
    String? id,
    String? label,
    String? time,
    bool? isEnabled,
    DateTime? createdAt,
    List<int>? repeatDays,
    bool? snoozeEnabled,
    int? snoozeMinutes,
  }) {
    return Alarm(
      id: id ?? this.id,
      label: label ?? this.label,
      time: time ?? this.time,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt ?? this.createdAt,
      repeatDays: repeatDays ?? this.repeatDays,
      snoozeEnabled: snoozeEnabled ?? this.snoozeEnabled,
      snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
    );
  }
}
