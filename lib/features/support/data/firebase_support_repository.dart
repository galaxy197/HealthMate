import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/support_models.dart';
import 'support_repository.dart';

class FirebaseSupportRepository implements SupportRepository {
  FirebaseSupportRepository(this.db);
  final FirebaseFirestore db;
  CollectionReference<Map<String, dynamic>> get _tickets =>
      db.collection('support_tickets');
  @override
  String newId() => _tickets.doc().id;

  SupportTicket _ticket(String id, Map<String, dynamic> d) => SupportTicket(
    id: id,
    uid: d['uid'] as String,
    type: SupportType.values.byName(d['type'] as String),
    title: d['title'] as String,
    description: d['description'] as String,
    status: SupportStatus.values.firstWhere((s) => s.code == d['status']),
    createdAt: (d['createdAt'] as Timestamp).toDate(),
    updatedAt: (d['updatedAt'] as Timestamp).toDate(),
    messageCount: d['messageCount'] as int,
  );

  @override
  Stream<List<SupportTicket>> watchTickets(String uid) => _tickets
      .where('uid', isEqualTo: uid)
      .orderBy('updatedAt', descending: true)
      .limit(50)
      .snapshots(includeMetadataChanges: true)
      .where((s) => !s.metadata.isFromCache && !s.metadata.hasPendingWrites)
      .map(
        (s) => s.docs
            .where((d) => d.data()['deleting'] != true)
            .map((d) => _ticket(d.id, d.data()))
            .toList(),
      );

  @override
  Stream<SupportTicket?> watchTicket(String uid, String ticketId) => _tickets
      .doc(ticketId)
      .snapshots(includeMetadataChanges: true)
      .where((s) => !s.metadata.isFromCache && !s.metadata.hasPendingWrites)
      .map((s) {
        if (!s.exists || s.data()?['deleting'] == true) return null;
        final value = _ticket(s.id, s.data()!);
        if (value.uid != uid) {
          throw const SupportFailure('Yêu cầu không thuộc tài khoản này.');
        }
        return value;
      });

  @override
  Stream<List<SupportMessage>> watchMessages(String uid, String ticketId) =>
      _tickets
          .doc(ticketId)
          .collection('messages')
          .orderBy('sequence')
          .limit(100)
          .snapshots(includeMetadataChanges: true)
          .where((s) => !s.metadata.isFromCache && !s.metadata.hasPendingWrites)
          .map(
            (s) => s.docs.map((doc) {
              final d = doc.data();
              return SupportMessage(
                id: doc.id,
                text: d['text'] as String,
                isAdmin: d['role'] == 'admin',
                createdAt: (d['createdAt'] as Timestamp).toDate(),
                sequence: d['sequence'] as int,
              );
            }).toList(),
          );

  @override
  Future<void> create(
    String uid,
    String id,
    SupportType type,
    String title,
    String description,
  ) async {
    final cleanTitle = supportText(title, 120, 'Tiêu đề');
    final cleanBody = supportText(description, 2000, 'Nội dung');
    final ticket = _tickets.doc(id);
    try {
      await db.runTransaction((t) async {
        final old = await t.get(ticket);
        if (old.exists) {
          if (old.data()?['uid'] != uid ||
              old.data()?['title'] != cleanTitle ||
              old.data()?['description'] != cleanBody ||
              old.data()?['type'] != type.name) {
            throw const SupportFailure(
              'Mã yêu cầu đã được dùng. Đóng form rồi gửi yêu cầu mới.',
            );
          }
          return;
        }
        t.set(ticket, {
          'uid': uid,
          'type': type.name,
          'title': cleanTitle,
          'description': cleanBody,
          'status': 'open',
          'messageCount': 0,
          'lastMessageId': '',
          'updatedBy': uid,
          'deleting': false,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
      await ticket.get(const GetOptions(source: Source.server));
    } on FirebaseException {
      throw const SupportFailure(
        'Chưa xác nhận gửi yêu cầu. Kiểm tra mạng rồi thử lại; nội dung vẫn được giữ.',
      );
    }
  }

  @override
  Future<void> reply(
    String uid,
    String ticketId,
    String messageId,
    String text,
  ) async {
    final clean = supportText(text, 2000, 'Tin nhắn');
    final ticket = _tickets.doc(ticketId),
        message = _tickets.doc(ticketId).collection('messages').doc(messageId);
    try {
      await db.runTransaction((t) async {
        final old = await t.get(message);
        final parent = await t.get(ticket);
        if (!parent.exists || parent.data()?['uid'] != uid) {
          throw const SupportFailure('Yêu cầu không còn khả dụng.');
        }
        if (old.exists) {
          if (old.data()?['authorUid'] != uid || old.data()?['text'] != clean) {
            throw const SupportFailure(
              'Tin nhắn đã gửi. Tải lại cuộc trao đổi.',
            );
          }
          return;
        }
        final count = parent.data()!['messageCount'] as int;
        if (count >= 100) {
          throw const SupportFailure(
            'Cuộc trao đổi đã đủ 100 tin nhắn. Hãy tạo yêu cầu mới.',
          );
        }
        t.set(message, {
          'authorUid': uid,
          'role': 'customer',
          'text': clean,
          'sequence': count + 1,
          'createdAt': FieldValue.serverTimestamp(),
        });
        t.update(ticket, {
          'messageCount': count + 1,
          'lastMessageId': messageId,
          'updatedBy': uid,
          'status': 'open',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
      await message.get(const GetOptions(source: Source.server));
    } on FirebaseException {
      throw const SupportFailure(
        'Chưa xác nhận gửi tin nhắn. Kiểm tra mạng rồi thử lại.',
      );
    }
  }
}
