import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/premium_models.dart';
import 'premium_repository.dart';

class FirebasePremiumRepository implements PremiumRepository {
  FirebasePremiumRepository(this.db, {DateTime Function()? now})
    : now = now ?? DateTime.now;
  final FirebaseFirestore db;
  final DateTime Function() now;
  DocumentReference<Map<String, dynamic>> _account(String uid) =>
      db.collection('demo_premium_accounts').doc(uid);
  DocumentReference<Map<String, dynamic>> _usage(String uid, DateTime day) => db
      .collection('ai_gateway_usage')
      .doc(uid)
      .collection('days')
      .doc(PremiumDemoPlan.gatewayDayId(day));

  PremiumMembership? _membership(Map<String, dynamic>? data) {
    if (data == null) return null;
    final start = data['startedAt'], expiry = data['expiresAt'];
    if (data['mode'] != 'demo' ||
        data['planId'] != PremiumDemoPlan.id ||
        start is! Timestamp ||
        expiry is! Timestamp ||
        expiry.toDate().difference(start.toDate()) !=
            PremiumDemoPlan.duration) {
      throw const PremiumFailure('Thông tin gói chưa hợp lệ. Hãy tải lại.');
    }
    return PremiumMembership(
      startedAt: start.toDate(),
      expiresAt: expiry.toDate(),
    );
  }

  PremiumDailyUsage _counts(Map<String, dynamic>? data) {
    if (data == null) return const PremiumDailyUsage();
    final scans = data['scans'] ?? 0, chats = data['chats'];
    if (scans is! int ||
        chats is! int ||
        scans < 0 ||
        scans > 20 ||
        chats < 0 ||
        chats > 50) {
      throw const PremiumFailure('Chưa xác nhận được số lượt AI hôm nay.');
    }
    return PremiumDailyUsage(scans: scans, chats: chats);
  }

  @override
  Stream<PremiumMembership?> watchMembership(String uid) => _account(uid)
      .snapshots(includeMetadataChanges: true)
      .where((s) => !s.metadata.isFromCache && !s.metadata.hasPendingWrites)
      .map((s) => _membership(s.data()));

  @override
  Stream<PremiumDailyUsage> watchUsage(String uid, DateTime day) =>
      _usage(uid, day)
          .snapshots(includeMetadataChanges: true)
          .where((s) => !s.metadata.isFromCache && !s.metadata.hasPendingWrites)
          .map((s) => _counts(s.data()));

  @override
  String newTransactionId() =>
      db.collection('demo_premium_transactions').doc().id;

  @override
  Future<void> purchaseDemo(String uid, String transactionId) async {
    final order = db.collection('demo_premium_transactions').doc(transactionId);
    final account = _account(uid);
    try {
      await db.runTransaction((t) async {
        final existing = await t.get(order);
        if (existing.exists) {
          if (existing.data()?['uid'] != uid) {
            throw const PremiumFailure('Giao dịch không thuộc tài khoản này.');
          }
          return; // Retry after uncertain ACK must not create a second sale.
        }
        final current = await t.get(account);
        final start = now().toUtc();
        if (_membership(current.data())?.activeAt(start) == true) {
          throw const PremiumFailure(
            'Gói Premium vẫn còn hạn. Bạn chưa cần mua lại.',
          );
        }
        final shared = {
          'mode': 'demo',
          'planId': PremiumDemoPlan.id,
          'startedAt': Timestamp.fromDate(start),
          'expiresAt': Timestamp.fromDate(start.add(PremiumDemoPlan.duration)),
        };
        t.set(order, {
          ...shared,
          'uid': uid,
          'amountVnd': PremiumDemoPlan.priceVnd,
          'currency': 'VND',
          'status': 'simulated_paid',
          'source': 'demo_checkout',
          'occurredAt': FieldValue.serverTimestamp(),
        });
        t.set(account, {
          ...shared,
          'transactionId': transactionId,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
      final confirmed = await order.get(
        const GetOptions(source: Source.server),
      );
      if (!confirmed.exists || confirmed.data()?['uid'] != uid) {
        throw const PremiumFailure(
          'Chưa xác nhận được giao dịch mô phỏng. Hãy thử lại.',
        );
      }
    } on FirebaseException {
      throw const PremiumFailure(
        'Chưa mua được gói demo. Kiểm tra mạng, giờ thiết bị và cấu hình Premium trong Firestore Rules.',
      );
    }
  }

  @override
  Future<void> consume(String uid, PremiumAiFeature feature) async {
    throw const PremiumFailure(
      'Lượt AI chỉ được cấp bởi dịch vụ khi gửi yêu cầu. Ứng dụng không tự ghi hạn mức.',
    );
  }
}
