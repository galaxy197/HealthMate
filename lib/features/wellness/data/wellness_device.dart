import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/wellness_models.dart';

class WellnessDevice {
  static const channel = MethodChannel('healthmate/wellness');
  bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  Future<void> setAccount(String? uid) =>
      channel.invokeMethod<void>('setAccount', {'uid': uid});
  Future<List<MealReminder>> readSettings(String uid) async {
    final raw = await channel.invokeMethod<String>('readSettings', {
      'uid': uid,
    });
    final data = jsonDecode(raw ?? '{}') as Map;
    if (data.isEmpty) return defaultMealReminders;
    final values = (data['reminders'] as List)
        .map((r) => MealReminder.fromData(r as Map))
        .toList();
    if (values.length != 4 || values.map((r) => r.meal).toSet().length != 4) {
      throw const FormatException('Lịch nhắc trên máy chưa hợp lệ.');
    }
    return values;
  }

  Future<void> saveSettings(String uid, List<MealReminder> reminders) =>
      channel.invokeMethod<void>('saveSettings', {
        'uid': uid,
        'json': jsonEncode({
          'reminders': reminders.map((r) => r.toData()).toList(),
        }),
      });
  Future<bool> notificationsAllowed() async =>
      await channel.invokeMethod<bool>('notificationsAllowed') ?? false;
  Future<List<int>> activeNotificationIds(String uid) async =>
      (await channel.invokeListMethod<int>('activeNotifications', {
        'uid': uid,
      })) ??
      [];
  Future<bool> requestNotifications() async =>
      await channel.invokeMethod<bool>('requestNotifications') ?? false;
  Future<bool> requestMotion() async =>
      await channel.invokeMethod<bool>('requestMotion') ?? false;
  Future<void> recordMeals(String uid, String day, List<String> meals) =>
      channel.invokeMethod<void>('recordMeals', {
        'uid': uid,
        'json': jsonEncode({'day': day, 'meals': meals}),
      });
  Future<void> testReminder(String uid) =>
      channel.invokeMethod<void>('testReminder', {'uid': uid});
  Future<Map<String, dynamic>> steps(String uid) async =>
      Map<String, dynamic>.from(
        jsonDecode(
              await channel.invokeMethod<String>('getSteps', {'uid': uid}) ??
                  '{}',
            )
            as Map,
      );
  Future<void> startSteps(String uid) =>
      channel.invokeMethod<void>('startSteps', {'uid': uid});
  Future<void> stopSteps(String uid) =>
      channel.invokeMethod<void>('stopSteps', {'uid': uid});
  Future<void> clearAccount(String uid) =>
      channel.invokeMethod<void>('clearAccount', {'uid': uid});
  Future<bool> takeReminderTap(String uid) async =>
      await channel.invokeMethod<bool>('takeReminderTap', {'uid': uid}) ??
      false;
  Future<SleepReminder> readSleepReminder(String uid) async =>
      SleepReminder.fromData(
        jsonDecode(
              await channel.invokeMethod<String>('readSleepReminder', {
                    'uid': uid,
                  }) ??
                  '{}',
            )
            as Map,
      );
  Future<void> saveSleepReminder(String uid, SleepReminder value) =>
      channel.invokeMethod<void>('saveSleepReminder', {
        'uid': uid,
        'json': jsonEncode(value.toData()),
      });
  Future<void> testSleepReminder(String uid) =>
      channel.invokeMethod<void>('testSleepReminder', {'uid': uid});
  Future<bool> takeSleepReminderTap(String uid) async =>
      await channel.invokeMethod<bool>('takeSleepReminderTap', {'uid': uid}) ??
      false;
}
