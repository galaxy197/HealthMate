import 'package:cloud_firestore/cloud_firestore.dart';

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
    } catch (_) {
      throw const GoalFailure();
    }
  }

  @override
  Future<void> saveGoal(String uid, GoalDraft draft, {String? id}) =>
      _guard(() async {
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
        if (id == null) {
          await _goals(
            uid,
          ).doc().set({...data, 'createdAt': FieldValue.serverTimestamp()});
        } else {
          await _goals(uid).doc(id).update(data);
        }
      });

  @override
  Future<void> deleteGoal(String uid, String id) =>
      _guard(() => _goals(uid).doc(id).delete());

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
    } catch (_) {
      throw const GoalFailure();
    }
  }

  @override
  Future<void> ensureQuest(String uid, DailyQuest candidate) =>
      _guard(() async {
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
      _guard(() async {
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

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action().timeout(const Duration(seconds: 15));
    } on GoalFailure {
      rethrow;
    } catch (_) {
      throw const GoalFailure();
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
