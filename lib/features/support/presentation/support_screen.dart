import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../auth/providers/auth_providers.dart';
import '../models/support_models.dart';
import '../providers/support_providers.dart';

String _time(DateTime date) =>
    '${DateFormat('dd/MM/yyyy HH:mm').format(date.toUtc().add(const Duration(hours: 7)))} · VN';
String _failure(Object error) => error is SupportFailure
    ? error.message
    : 'Chưa tải được yêu cầu. Kiểm tra mạng rồi tải lại.';

class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key});
  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> {
  final _cursors = <SupportTicketCursor?>[null];
  String? _uid;
  @override
  Widget build(BuildContext context) {
    if (!TickerMode.valuesOf(context).enabled) return const SizedBox.shrink();
    final uid = ref.watch(authSessionProvider).value?.uid;
    if (_uid != uid) {
      _uid = uid;
      _cursors
        ..clear()
        ..add(null);
    }
    final tickets = ref.watch(supportTicketPageProvider(_cursors.last));
    return Scaffold(
      appBar: AppBar(title: const Text('Báo lỗi & Góp ý')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Gửi yêu cầu và trao đổi trực tiếp với đội ngũ HealthMate.',
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              key: const ValueKey('new-support-ticket'),
              onPressed: uid == null
                  ? null
                  : () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => _NewTicket(uid: uid),
                      ),
                    ),
              icon: const Icon(Icons.add),
              label: const Text('Gửi yêu cầu mới'),
            ),
            const SizedBox(height: 24),
            Text(
              'Yêu cầu của bạn',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            ...tickets.when(
              loading: () => [
                const LinearProgressIndicator(),
                const Text('Đang kết nối máy chủ…'),
              ],
              error: (error, _) => [
                Text(_failure(error)),
                TextButton(
                  onPressed: () =>
                      ref.invalidate(supportTicketPageProvider(_cursors.last)),
                  child: const Text('Tải lại'),
                ),
              ],
              data: (page) => [
                if (page.tickets.isEmpty)
                  const Text(
                    'Chưa có yêu cầu. Bạn có thể gửi báo lỗi hoặc đề xuất cải thiện tại đây.',
                  ),
                for (final ticket in page.tickets)
                  Card(
                    child: ListTile(
                      key: ValueKey('support-${ticket.id}'),
                      leading: Icon(
                        ticket.type == SupportType.bug
                            ? Icons.bug_report_outlined
                            : Icons.lightbulb_outline,
                      ),
                      title: Text(
                        ticket.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          '${ticket.status.label}\n${_time(ticket.updatedAt)}',
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              SupportThreadScreen(ticketId: ticket.id),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    TextButton(
                      key: const ValueKey('support-newer'),
                      onPressed: _cursors.length == 1
                          ? null
                          : () => setState(() => _cursors.removeLast()),
                      child: const Text('Mới hơn'),
                    ),
                    Text('Trang ${_cursors.length}'),
                    TextButton(
                      key: const ValueKey('support-older'),
                      onPressed: page.nextCursor == null
                          ? null
                          : () => setState(() => _cursors.add(page.nextCursor)),
                      child: const Text('Cũ hơn'),
                    ),
                    TextButton(
                      onPressed: () => setState(() {
                        _cursors
                          ..clear()
                          ..add(null);
                        ref.invalidate(supportTicketPageProvider(null));
                      }),
                      child: const Text('Về mới nhất'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NewTicket extends ConsumerStatefulWidget {
  const _NewTicket({required this.uid});
  final String uid;
  @override
  ConsumerState<_NewTicket> createState() => _NewTicketState();
}

class _NewTicketState extends ConsumerState<_NewTicket> {
  final _title = TextEditingController(), _body = TextEditingController();
  SupportType _type = SupportType.bug;
  bool _busy = false;
  String? _id, _error;
  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_busy || ref.read(authSessionProvider).value?.uid != widget.uid) return;
    try {
      supportText(_title.text, 120, 'Tiêu đề');
      supportText(_body.text, 2000, 'Nội dung');
    } on SupportFailure catch (error) {
      setState(() => _error = error.message);
      return;
    }
    final repository = ref.read(supportRepositoryProvider);
    _id ??= repository.newId();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await repository.create(widget.uid, _id!, _type, _title.text, _body.text);
      if (!mounted || ref.read(authSessionProvider).value?.uid != widget.uid) {
        return;
      }
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Đã gửi yêu cầu. Bạn có thể xem phản hồi tại Báo lỗi & Góp ý.',
          ),
        ),
      );
    } catch (error) {
      if (mounted) setState(() => _error = _failure(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) =>
      ref.watch(authSessionProvider).value?.uid != widget.uid
      ? const Scaffold(
          body: Center(child: Text('Phiên đăng nhập đã thay đổi.')),
        )
      : Scaffold(
          appBar: AppBar(title: const Text('Yêu cầu mới')),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                DropdownButtonFormField<SupportType>(
                  initialValue: _type,
                  decoration: const InputDecoration(labelText: 'Loại yêu cầu'),
                  items: [
                    for (final type in SupportType.values)
                      DropdownMenuItem(value: type, child: Text(type.label)),
                  ],
                  onChanged: _id != null
                      ? null
                      : (value) => setState(() => _type = value!),
                ),
                const SizedBox(height: 16),
                TextField(
                  key: const ValueKey('support-title'),
                  controller: _title,
                  maxLength: 120,
                  readOnly: _id != null,
                  decoration: const InputDecoration(
                    labelText: 'Tiêu đề',
                    hintText: 'Ví dụ: Không lưu được bữa sáng',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const ValueKey('support-description'),
                  controller: _body,
                  minLines: 5,
                  maxLines: 10,
                  maxLength: 2000,
                  readOnly: _id != null,
                  decoration: const InputDecoration(
                    labelText: 'Nội dung',
                    hintText: 'Mô tả vấn đề hoặc điều bạn muốn cải thiện',
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Nội dung bạn gửi sẽ được admin xem để hỗ trợ. Không gửi mật khẩu, thông tin ngân hàng hoặc hồ sơ sức khỏe nhạy cảm.',
                ),
                const SizedBox(height: 8),
                Text(
                  'Tối đa ${SupportPolicy.dailyTicketLimit} yêu cầu mới/ngày, cách nhau ${SupportPolicy.createInterval.inSeconds} giây. Bạn vẫn có thể trả lời yêu cầu đã có.',
                ),
                const SizedBox(height: 16),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                FilledButton(
                  key: const ValueKey('send-support-ticket'),
                  onPressed: _busy ? null : _send,
                  child: Text(
                    _busy
                        ? 'Đang gửi…'
                        : _id != null
                        ? 'Thử gửi lại'
                        : 'Gửi yêu cầu',
                  ),
                ),
              ],
            ),
          ),
        );
}

class SupportThreadScreen extends ConsumerWidget {
  const SupportThreadScreen({required this.ticketId, super.key});
  final String ticketId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!TickerMode.valuesOf(context).enabled) return const SizedBox.shrink();
    final uid = ref.watch(authSessionProvider).value?.uid;
    return uid == null
        ? const Scaffold(
            body: Center(child: Text('Hãy đăng nhập để xem yêu cầu.')),
          )
        : _SupportThread(
            key: ValueKey('$uid/$ticketId'),
            uid: uid,
            ticketId: ticketId,
          );
  }
}

class _SupportThread extends ConsumerStatefulWidget {
  const _SupportThread({required this.uid, required this.ticketId, super.key});
  final String uid, ticketId;
  @override
  ConsumerState<_SupportThread> createState() => _SupportThreadState();
}

class _SupportThreadState extends ConsumerState<_SupportThread> {
  final _reply = TextEditingController();
  bool _busy = false;
  String? _messageId, _error;
  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_busy || ref.read(authSessionProvider).value?.uid != widget.uid) return;
    try {
      supportText(_reply.text, 2000, 'Tin nhắn');
    } on SupportFailure catch (error) {
      setState(() => _error = error.message);
      return;
    }
    final repository = ref.read(supportRepositoryProvider);
    _messageId ??= repository.newId();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await repository.reply(
        widget.uid,
        widget.ticketId,
        _messageId!,
        _reply.text,
      );
      if (!mounted || ref.read(authSessionProvider).value?.uid != widget.uid) {
        return;
      }
      _reply.clear();
      _messageId = null;
    } catch (error) {
      if (mounted) setState(() => _error = _failure(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticket = ref.watch(supportTicketProvider(widget.ticketId));
    final messages = ref.watch(supportMessagesProvider(widget.ticketId));
    return Scaffold(
      appBar: AppBar(title: const Text('Trao đổi hỗ trợ')),
      body: SafeArea(
        child: ticket.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_failure(error)),
                TextButton(
                  onPressed: () =>
                      ref.invalidate(supportTicketProvider(widget.ticketId)),
                  child: const Text('Tải lại'),
                ),
              ],
            ),
          ),
          data: (value) => value == null
              ? const Center(child: Text('Yêu cầu không còn khả dụng.'))
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(
                      value.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text('${value.type.label} · ${value.status.label}'),
                    const SizedBox(height: 16),
                    _MessageCard(
                      label: 'Bạn · ${_time(value.createdAt)}',
                      text: value.description,
                    ),
                    ...messages.when(
                      loading: () => [const LinearProgressIndicator()],
                      error: (error, _) => [
                        Text(_failure(error)),
                        TextButton(
                          onPressed: () => ref.invalidate(
                            supportMessagesProvider(widget.ticketId),
                          ),
                          child: const Text('Tải lại tin nhắn'),
                        ),
                      ],
                      data: (items) => [
                        for (final item in items)
                          _MessageCard(
                            label:
                                '${item.isAdmin ? 'HealthMate hỗ trợ' : 'Bạn'} · ${_time(item.createdAt)}',
                            text: item.text,
                            admin: item.isAdmin,
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (value.messageCount >= 100)
                      const Text(
                        'Cuộc trao đổi đã đủ 100 tin nhắn. Hãy tạo yêu cầu mới nếu cần.',
                      )
                    else ...[
                      TextField(
                        key: const ValueKey('support-reply'),
                        controller: _reply,
                        minLines: 2,
                        maxLines: 6,
                        maxLength: 2000,
                        readOnly: _messageId != null,
                        decoration: const InputDecoration(
                          labelText: 'Bổ sung thông tin',
                        ),
                      ),
                      if (value.status == SupportStatus.resolved)
                        const Text('Gửi tin nhắn mới sẽ mở lại yêu cầu.'),
                      if (_error != null)
                        Text(
                          _error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      FilledButton(
                        key: const ValueKey('send-support-reply'),
                        onPressed:
                            _busy || messages.hasError || messages.isLoading
                            ? null
                            : _send,
                        child: Text(
                          _busy
                              ? 'Đang gửi…'
                              : _messageId != null
                              ? 'Thử gửi lại'
                              : 'Gửi tin nhắn',
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.label,
    required this.text,
    this.admin = false,
  });
  final String label, text;
  final bool admin;
  @override
  Widget build(BuildContext context) => Card(
    color: admin ? Theme.of(context).colorScheme.secondaryContainer : null,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 8),
          SelectableText(text),
        ],
      ),
    ),
  );
}
