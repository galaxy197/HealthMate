import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/errors/operation_diagnostics.dart';

import '../../../core/utils/local_date_key.dart';
import '../../daily_quest/models/daily_quest.dart';
import '../models/goal_failure.dart';
import '../models/tracking_goal.dart';
import 'goals_repository.dart';

class FirebaseGoalsRepository implements GoalsRepository {
  FirebaseGoalsRepository(this.firestore);
  final FirebaseFirestore firestore;
  CollectionReference<Map<String, dynamic>> _goals(String uid) =>
      firestore.collection('users').doc(uid).collection('goals');
  DocumentReference<Map<String, dynamic>> _quest(String uid, String key) =>
      firestore
          .collection('users')
          .doc(uid)
          .collection('daily_quests')
          .doc(key);

  @override
  Stream<List<TrackingGoal>> watchGoals(String uid) async* {
    try {
      await for (final snapshot in _goals(uid).snapshots()) {
        final goals = snapshot.docs.map((doc) {
          final d = doc.data();
          return TrackingGoal(
            id: doc.id,
            draft: GoalDraft(
              type: GoalType.values.byName(d['goalType'] as String),
              targetValue: (d['targetValue'] as num).toDouble(),
              startDate: _dateKey(d['startDateKey'] as String),
              endDate: _dateKey(d['endDateKey'] as String),
              status: GoalStatus.values.byName(d['status'] as String),
              baselineWeightKg: (d['baselineWeightKg'] as num?)?.toDouble(),
            ),
          );
        }).toList()..sort((a, b) => a.id.compareTo(b.id));
        yield goals;
      }
    } catch (error) {
      throw GoalFailure.at(error, 'goals-read');
    }
  }

  @override
  String newGoalId() => firestore.collection('users').doc().id;

  @override
  Future<void> saveGoal(
    String uid,
    GoalDraft draft, {
    String? id,
    bool create = false,
  }) => _guard('goal-save', () async {
    final error = draft.validate();
    if (error != null) throw GoalFailure(error);
    final data = <String, Object?>{
      'goalType': draft.type.name,
      'targetValue': draft.targetValue,
      'unit': draft.type.unit,
      'startDateKey': localDateKey(draft.startDate),
      'endDateKey': localDateKey(draft.endDate),
      'status': draft.status.name,
      'baselineWeightKg': draft.baselineWeightKg,
      'updatedAt': FieldValue.serverTimestamp(),
      'schemaVersion': 1,
    };
    if (create) {
      if (id == null) {
        throw const GoalFailure('Thiếu mã thao tác tạo mục tiêu.');
      }
      final reference = _goals(uid).doc(id);
      await firestore.runTransaction((transaction) async {
        final previous = await transaction.get(reference);
        if (previous.exists) {
          final matches = data.entries
              .where((e) => e.key != 'updatedAt')
              .every((e) => previous.data()?[e.key] == e.value);
          if (!matches) {
            throw const GoalFailure(
              'Thao tác trước đã lưu nội dung khác. Hãy đóng form, tải lại mục tiêu và chọn sửa.',
            );
          }
          return;
        }
        transaction.set(reference, {
          ...data,
          'createdAt': FieldValue.serverTimestamp(),
        });
      });
    } else if (id == null) {
      await _goals(
        uid,
      ).doc().set({...data, 'createdAt': FieldValue.serverTimestamp()});
    } else {
      await _goals(uid).doc(id).update(data);
    }
  });

  @override
  Future<void> deleteGoal(String uid, String id) =>
      _guard('goal-delete', () => _goals(uid).doc(id).delete());

  @override
  Stream<DailyQuest?> watchQuest(String uid, String dateKey) async* {
    try {
      await for (final snapshot in _quest(uid, dateKey).snapshots()) {
        final d = snapshot.data();
        yield d == null
            ? null
            : DailyQuest(
                dateKey: dateKey,
                type: QuestType.values.byName(d['questType'] as String),
                title: d['title'] as String,
                description: d['description'] as String,
                reason: d['reason'] as String,
                targetValue: (d['targetValue'] as num).toDouble(),
                unit: d['unit'] as String,
                status: QuestStatus.values.byName(d['status'] as String),
                ruleVersion: d['ruleVersion'] as int,
              );
      }
    } catch (error) {
      throw GoalFailure.at(error, 'quest-read');
    }
  }

  @override
  Future<void> ensureQuest(String uid, DailyQuest candidate) =>
      _guard('quest-create', () async {
        final doc = _quest(uid, candidate.dateKey);
        await firestore.runTransaction((transaction) async {
          final existing = await transaction.get(doc);
          if (existing.exists) return;
          transaction.set(doc, {
            'dateKey': candidate.dateKey,
            'questType': candidate.type.name,
            'title': candidate.title,
            'description': candidate.description,
            'reason': candidate.reason,
            'targetValue': candidate.targetValue,
            'unit': candidate.unit,
            'status': 'available',
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            'completedAt': null,
            'ruleVersion': candidate.ruleVersion,
          });
        });
      });

  @override
  Future<void> finishQuest(String uid, String dateKey, QuestStatus status) =>
      _guard('quest-finish', () async {
        if (status == QuestStatus.available) {
          throw const GoalFailure('Chọn hoàn thành hoặc bỏ qua.');
        }
        final doc = _quest(uid, dateKey);
        await firestore.runTransaction((transaction) async {
          final snapshot = await transaction.get(doc);
          if (!snapshot.exists) {
            throw const GoalFailure('Nhiệm vụ chưa được tạo.');
          }
          if (snapshot.data()!['status'] != 'available') return;
          transaction.update(doc, {
            'status': status.name,
            'updatedAt': FieldValue.serverTimestamp(),
            'completedAt': status == QuestStatus.completed
                ? FieldValue.serverTimestamp()
                : null,
          });
        });
      });

  Future<void> _guard(String stage, Future<void> Function() action) async {
    final clock = Stopwatch()..start();
    operationDiagnostic('goals', stage, 'start', clock);
    try {
      // A write Future stays pending until SDK acknowledgement. A UI timeout
      // would not cancel the write and previously allowed duplicate goals.
      await action();
      operationDiagnostic('goals', stage, 'success', clock);
    } catch (error) {
      final failure = GoalFailure.at(error, stage);
      operationDiagnostic('goals', stage, 'error', clock, code: failure.code);
      if (error is GoalFailure) rethrow;
      throw failure;
    }
  }

  DateTime _dateKey(String key) {
    if (!isValidDateKey(key)) {
      throw const GoalFailure('Ngày mục tiêu không hợp lệ.');
    }
    final parts = key.split('-').map(int.parse).toList();
    return DateTime(parts[0], parts[1], parts[2]);
  }
}
