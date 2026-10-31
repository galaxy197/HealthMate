import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/features/nutrition/models/nutrition_models.dart';
import 'package:healthmate/features/nutrition/presentation/meal_form_controller.dart';

const item = MealItemSnapshot(
  foodId: 'fixture',
  name: 'Fixture',
  grams: 100,
  nutrition: NutritionTotals(kcal: 100, proteinG: 2, carbsG: 20, fatG: 1),
  sourceLabel: 'Fixture',
  isEstimated: true,
);

void main() {
  final at = DateTime.utc(2026, 10, 30, 18);
  MealFormController controller({
    List<MealItemSnapshot> items = const [item],
    Future<void> Function(MealDraft)? persist,
    void Function()? changed,
    bool Function()? current,
  }) => MealFormController(
    type: MealType.dinner,
    consumedAt: at,
    items: items,
    source: MealSource.manual,
    minimumSchemaVersion: 5,
    timezoneOffsetOverride: 420,
    onDraftChanged: persist,
    onChanged: changed,
    isCurrent: current,
  );

  test('snapshot retains stored timezone, schema, source and item values', () {
    final form = controller();
    final snapshot = form.draft;
    form.items.clear();
    expect(snapshot.items, [item]);
    expect(() => snapshot.items.add(item), throwsUnsupportedError);
    expect(snapshot.dateKey, '2026-10-31');
    expect(snapshot.timezoneOffsetMinutes, 420);
    expect(snapshot.minimumSchemaVersion, 5);
    expect(snapshot.source, MealSource.manual);
    form.scannerAiUsed = true;
    expect(form.draft.source, MealSource.aiAssisted);
  });

  test(
    'out-of-order draft ACK cannot replace newest failed revision status',
    () async {
      final gates = <Completer<void>>[];
      final snapshots = <MealDraft>[];
      final form = controller(
        persist: (draft) {
          snapshots.add(draft);
          final gate = Completer<void>();
          gates.add(gate);
          return gate.future;
        },
      );
      final first = form.persistLocal();
      form.type = MealType.breakfast;
      final second = form.persistLocal();
      gates[1].completeError(StateError('Local storage unavailable'));
      await second;
      final failed = form.localStatus;
      gates[0].complete();
      await first;
      expect(form.localStatus, failed);
      expect(failed, contains('Chưa giữ được nháp'));
      expect(snapshots.first.type, MealType.dinner);
      expect(snapshots.last.type, MealType.breakfast);
      form.dispose();
    },
  );

  test('UID change and disposal suppress late draft publication', () async {
    var current = true;
    var changes = 0;
    final gate = Completer<void>();
    final form = controller(
      persist: (_) => gate.future,
      changed: () => changes++,
      current: () => current,
    );
    final pending = form.persistLocal();
    expect(changes, 1);
    current = false;
    gate.complete();
    await pending;
    expect(changes, 1);
    await form.persistLocal();
    expect(changes, 1);
    form.dispose();
  });

  test(
    'submit waits for one ACK and never sends a duplicate pending write',
    () async {
      final form = controller();
      var calls = 0;
      final gate = Completer<bool>();
      Future<bool> persist(MealDraft value) {
        calls++;
        expect(value.items, [item]);
        return gate.future;
      }

      final pending = form.submit(form.draft, persist);
      expect(await form.submit(form.draft, persist), false);
      expect(calls, 1);
      gate.complete(true);
      expect(await pending, true);
      form.dispose();
    },
  );

  test(
    'failed ACK retains draft for explicit retry and propagates persistence errors',
    () async {
      final form = controller();
      expect(await form.submit(form.draft, (_) async => false), false);
      expect(form.items, [item]);
      await expectLater(
        form.submit(form.draft, (_) async => throw StateError('Denied')),
        throwsStateError,
      );
      expect(await form.submit(form.draft, (_) async => true), true);
      form.dispose();
    },
  );

  test(
    'dispose while awaiting ACK suppresses success and any later write',
    () async {
      final form = controller();
      final gate = Completer<bool>();
      var calls = 0;
      Future<bool> persist(MealDraft draft) {
        calls++;
        return gate.future;
      }

      final pending = form.submit(form.draft, persist);
      form.dispose();
      gate.complete(true);
      expect(await pending, false);
      expect(await form.submit(form.draft, persist), false);
      expect(calls, 1);
    },
  );

  test(
    'a successful old-account ACK cannot report saved after UID change',
    () async {
      var current = true;
      final gate = Completer<bool>();
      final form = controller(current: () => current);
      final pending = form.submit(form.draft, (_) => gate.future);
      current = false;
      gate.complete(true);
      expect(await pending, false);
      var calls = 0;
      expect(
        await form.submit(form.draft, (_) async {
          calls++;
          return true;
        }),
        false,
      );
      expect(calls, 0);
      form.dispose();
    },
  );

  test(
    'validation checks date, count and existing snapshot without repairing data',
    () {
      expect(controller(items: []).entryError(at), contains('ít nhất'));
      expect(
        controller(items: List.filled(6, item)).entryError(at),
        contains('tối đa 5'),
      );
      expect(
        controller().entryError(at.subtract(const Duration(minutes: 1))),
        contains('tương lai'),
      );
      final form = controller();
      expect(form.entryError(at), isNull);
      expect(form.snapshotError(), isNull);
      expect(form.draft.totals.kcal, 100);
      form.dispose();
    },
  );
}
