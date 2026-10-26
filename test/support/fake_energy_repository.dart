import 'dart:async';
import 'package:healthmate/features/wellness/data/energy_repository.dart';
import 'package:healthmate/features/wellness/models/energy_budget.dart';
import 'package:healthmate/core/utils/local_date_key.dart';

class FakeEnergyRepository implements EnergyRepository {
  final preferences = <String, WellnessPreferences>{};
  final adjustments = <String, EnergyAdjustment>{};
  final changes = StreamController<void>.broadcast(sync: true);
  @override
  Stream<WellnessPreferences> watchPreferences(String uid) async* {
    yield preferences[uid] ?? const WellnessPreferences();
    yield* changes.stream.map(
      (_) => preferences[uid] ?? const WellnessPreferences(),
    );
  }

  @override
  Stream<EnergyAdjustment?> watchAdjustment(String uid, String day) async* {
    yield adjustments['$uid/$day'];
    yield* changes.stream.map((_) => adjustments['$uid/$day']);
  }

  @override
  Future<void> savePreferences(String uid, WellnessPreferences p) async {
    preferences[uid] = p;
    changes.add(null);
  }

  @override
  Future<void> saveAdjustment(String uid, EnergyAdjustment a) async {
    adjustments['$uid/${a.dateKey}'] = a;
    changes.add(null);
  }

  @override
  Future<void> clearAdjustment(String uid, String day) async {
    adjustments.remove('$uid/$day');
    changes.add(null);
  }

  @override
  Future<List<EnergyAdjustment>> loadAdjustments(
    String uid,
    DateTime start,
    DateTime end,
  ) async => adjustments.entries
      .where(
        (e) =>
            e.key.startsWith('$uid/') &&
            e.value.dateKey.compareTo(localDateKey(start)) >= 0 &&
            e.value.dateKey.compareTo(localDateKey(end)) < 0,
      )
      .map((e) => e.value)
      .toList();
}
