import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/local_date_key.dart';
import '../../../core/config/app_feature_flags.dart';
import '../../../shared/providers/local_clock_provider.dart';
import '../../auth/providers/auth_providers.dart';
import '../models/chat_models.dart';
import '../providers/chat_providers.dart';

class ChatScreen extends ConsumerWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(appFeatureFlagsProvider).chatbotEnabled) {
      return const SizedBox.shrink();
    }
    if (!TickerMode.valuesOf(context).enabled) return const SizedBox.shrink();
    final uid = ref.watch(
      authSessionProvider.select((session) => session.value?.uid),
    );
    if (uid == null) return const SizedBox.shrink();
    return _ChatBody(key: ValueKey(uid));
  }
}

class _ChatBody extends ConsumerStatefulWidget {
  const _ChatBody({super.key});

  @override
  ConsumerState<_ChatBody> createState() => _ChatBodyState();
}

class _ChatBodyState extends ConsumerState<_ChatBody> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  late DateTime _date;
  bool _aiDisclosureAccepted = false;
  bool _scrollScheduled = false;

  void _showLatest() {
    if (_scrollScheduled) return;
    _scrollScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollScheduled = false;
      if (mounted && _scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _date = localDateOnly(ref.read(currentLocalTimeProvider)());
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send({String? text, KnowledgeTopic? topic}) async {
    if (topic != null && !_aiDisclosureAccepted) {
      final accepted = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Kiến thức chung từ AI'),
          content: const SingleChildScrollView(
            child: Text(
              'Chỉ chủ đề định sẵn được gửi đến dịch vụ AI của Google. '
              'Không gửi nội dung tự nhập, hồ sơ, nhật ký hay lịch sử hội thoại. '
              'Dịch vụ miễn phí có thể dùng câu hỏi và câu trả lời để cải thiện '
              'sản phẩm, có thể có người đánh giá nội dung.\n\n'
              'Câu trả lời AI có thể sai, chỉ cung cấp kiến thức chung và không '
              'thay thế tư vấn y tế. Hội thoại được lưu trong tài khoản HealthMate.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Để sau'),
            ),
            FilledButton(
              key: const ValueKey('chat-accept-ai'),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Tiếp tục'),
            ),
          ],
        ),
      );
      if (!mounted || accepted != true) return;
      _aiDisclosureAccepted = true;
    }
    final original = _input.text;
    final saved = await ref
        .read(chatControllerProvider.notifier)
        .send(text ?? original, _date, topic: topic);
    if (!mounted) return;
    if (saved && topic == null && text == null && _input.text == original) {
      _input.clear();
    }
    _showLatest();
  }

  Future<void> _chooseDate() async {
    final now = ref.read(currentLocalTimeProvider)();
    final date = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(1900),
      lastDate: localDateOnly(now),
    );
    if (date != null && mounted) setState(() => _date = date);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(chatControllerProvider, (previous, next) {
      final nearBottom =
          !_scroll.hasClients || _scroll.position.extentAfter < 100;
      if (previous?.pendingQuestion != next.pendingQuestion ||
          previous?.messages.length != next.messages.length ||
          (nearBottom && previous?.preview != next.preview)) {
        _showLatest();
      }
    });
    final chat = ref.watch(chatControllerProvider);
    final controller = ref.read(chatControllerProvider.notifier);
    final enabled = !chat.busy && !chat.full && !chat.pendingSave;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Trò chuyện',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                key: const ValueKey('chat-new'),
                tooltip: 'Cuộc trò chuyện mới',
                onPressed: chat.busy ? null : controller.newSession,
                icon: const Icon(Icons.add_comment_outlined),
              ),
              PopupMenuButton<String>(
                key: const ValueKey('chat-history'),
                tooltip: '20 cuộc trò chuyện gần nhất',
                enabled: !chat.busy,
                onSelected: (id) {
                  if (id == 'refresh') {
                    controller.loadSessions();
                  } else {
                    controller.openSession(id);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'refresh',
                    child: Text('Tải lại lịch sử'),
                  ),
                  for (final session in chat.sessions)
                    PopupMenuItem(
                      value: session.id,
                      child: Text(
                        '${DateFormat('dd/MM HH:mm').format(session.updatedAt.toLocal())} · ${session.messageCount ~/ 2} lượt',
                      ),
                    ),
                ],
                icon: const Icon(Icons.history_rounded),
              ),
            ],
          ),
          Expanded(
            child: ListView(
              key: const ValueKey('chat-messages'),
              controller: _scroll,
              children: [
                Text(
                  'Thêm một người đồng hành',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tra cứu số liệu trong ứng dụng; AI giải thích kiến thức chung. Không chẩn đoán hoặc thay thế tư vấn y tế.',
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    OutlinedButton.icon(
                      key: const ValueKey('chat-date'),
                      onPressed: chat.busy ? null : _chooseDate,
                      icon: const Icon(Icons.calendar_month_outlined),
                      label: Text(DateFormat('dd/MM/yyyy').format(_date)),
                    ),
                    for (final question in const [
                      'Tóm tắt ngày đã chọn',
                      'Kcal đã ghi',
                      'Nước đã ghi',
                      'Vận động đã ghi',
                    ])
                      ActionChip(
                        label: Text(question),
                        onPressed: enabled ? () => _send(text: question) : null,
                      ),
                  ],
                ),
                if (chat.phase == ChatPhase.loading)
                  const LinearProgressIndicator(),
                if (chat.messages.isEmpty &&
                    !chat.busy &&
                    chat.pendingQuestion.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'Bắt đầu bằng một câu hỏi về nhật ký hoặc chọn chủ đề bên dưới. '
                      'Bạn có thể hỏi “Hôm nay tôi ăn bao nhiêu kcal?” hoặc “Hôm qua uống bao nhiêu nước?”. '
                      'Ngày không có bản ghi sẽ được ghi rõ, không suy đoán lượng thực tế.',
                    ),
                  ),
                const Divider(height: 24),
                Text(
                  'Kiến thức chung từ AI',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Text(
                  'Chỉ gửi chủ đề định sẵn; không gửi nhật ký hoặc nội dung tự nhập. Mỗi chủ đề là một yêu cầu độc lập.',
                ),
                for (final topic in KnowledgeTopic.values)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      key: ValueKey('chat-topic-${topic.name}'),
                      onPressed: enabled ? () => _send(topic: topic) : null,
                      icon: const Icon(Icons.auto_awesome_outlined),
                      label: Text(topic.label),
                    ),
                  ),
                const SizedBox(height: 12),
                for (final message in chat.messages)
                  _Bubble(
                    text: message.text,
                    isUser: message.isUser,
                    source: message.source,
                  ),
                if (chat.pendingQuestion.isNotEmpty) ...[
                  _Bubble(
                    text: chat.pendingQuestion,
                    isUser: true,
                    source: ChatSource.help,
                  ),
                  if (chat.preview.isNotEmpty)
                    _Bubble(
                      text: chat.preview,
                      isUser: false,
                      source: ChatSource.help,
                      pending: true,
                    ),
                ],
                if (chat.phase == ChatPhase.answering)
                  const Text('Đang chuẩn bị câu trả lời…'),
                if (chat.phase == ChatPhase.saving)
                  const Text('Đang lưu hội thoại…'),
                if (chat.error != null)
                  Semantics(
                    liveRegion: true,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            chat.error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                          if (chat.canRetry)
                            TextButton(
                              key: const ValueKey('chat-retry'),
                              onPressed: chat.busy ? null : controller.retry,
                              child: const Text('Thử lại'),
                            ),
                        ],
                      ),
                    ),
                  ),
                if (chat.full)
                  const Text(
                    'Đã đủ 20 lượt. Nhấn nút cuộc trò chuyện mới để tiếp tục.',
                  ),
                const SizedBox(height: 12),
              ],
            ),
          ),
          if (chat.phase == ChatPhase.answering)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const ValueKey('chat-cancel'),
                onPressed: controller.cancel,
                icon: const Icon(Icons.stop_circle_outlined),
                label: const Text('Dừng nhận'),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    key: const ValueKey('chat-input'),
                    controller: _input,
                    enabled: enabled,
                    minLines: 1,
                    maxLines: 3,
                    maxLength: ChatLimits.inputCharacters,
                    textInputAction: TextInputAction.send,
                    onSubmitted: enabled ? (_) => _send() : null,
                    decoration: const InputDecoration(
                      labelText: 'Hỏi nhật ký',
                      hintText: 'Hôm nay tôi ăn bao nhiêu kcal?',
                      counterText: '',
                    ),
                  ),
                ),
                IconButton(
                  key: const ValueKey('chat-send'),
                  tooltip: 'Gửi câu hỏi nhật ký',
                  onPressed: enabled ? () => _send() : null,
                  icon: const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.text,
    required this.isUser,
    required this.source,
    this.pending = false,
  });
  final String text;
  final bool isUser;
  final ChatSource source;
  final bool pending;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUser ? colors.primaryContainer : colors.surfaceContainer,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isUser
                  ? 'Bạn'
                  : pending
                  ? 'Bản tạm · chưa lưu'
                  : switch (source) {
                      ChatSource.journal => 'Từ nhật ký · tính tại ứng dụng',
                      ChatSource.ai => 'AI · kiến thức chung',
                      ChatSource.help => 'HealthMate',
                    },
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 4),
            SelectableText(
              text,
              style: TextStyle(
                color: isUser ? colors.onPrimaryContainer : colors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
