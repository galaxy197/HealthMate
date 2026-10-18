import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/local_clock_provider.dart';
import '../../../core/config/ai_access_policy.dart';
import '../../../core/config/app_feature_flags.dart';
import '../../../core/errors/operation_diagnostics.dart';
import '../../activity/providers/activity_providers.dart';
import '../../auth/providers/auth_providers.dart';
import '../../nutrition/providers/nutrition_providers.dart';
import '../../water/providers/water_providers.dart';
import '../data/chat_repository.dart';
import '../data/firebase_chat_repository.dart';
import '../data/firebase_knowledge_service.dart';
import '../data/knowledge_service.dart';
import '../domain/journal_chat_context.dart';
import '../models/chat_models.dart';

final chatRepositoryProvider = Provider<ChatRepository>(
  (ref) => FirebaseChatRepository(FirebaseFirestore.instance),
);
final knowledgeServiceProvider = Provider<KnowledgeService>((ref) {
  if (!ref.watch(appFeatureFlagsProvider).chatbotEnabled) {
    return const _DisabledKnowledgeService();
  }
  return FirebaseKnowledgeService();
});

class _DisabledKnowledgeService implements KnowledgeService {
  const _DisabledKnowledgeService();

  @override
  Stream<String> explain(KnowledgeTopic topic) => Stream.error(
    const ChatFailure('Trò chuyện đang tạm tắt trong bản core.'),
  );
}

final journalChatContextProvider = Provider<JournalChatContext>(
  (ref) => JournalChatContext(
    nutrition: ref.watch(nutritionRepositoryProvider),
    water: ref.watch(waterRepositoryProvider),
    activity: ref.watch(activityRepositoryProvider),
  ),
);

enum ChatPhase { idle, loading, answering, saving }

class ChatState {
  const ChatState({
    this.sessions = const [],
    this.messages = const [],
    this.sessionId,
    this.phase = ChatPhase.idle,
    this.pendingQuestion = '',
    this.preview = '',
    this.error,
    this.canRetry = false,
  });
  final List<ChatSession> sessions;
  final List<ChatMessage> messages;
  final String? sessionId;
  final ChatPhase phase;
  final String pendingQuestion;
  final String preview;
  final String? error;
  final bool canRetry;
  bool get busy => phase != ChatPhase.idle;
  bool get full => messages.length >= ChatLimits.messagesPerSession;
  bool get pendingSave => canRetry && preview.isNotEmpty;

  ChatState change({
    List<ChatSession>? sessions,
    List<ChatMessage>? messages,
    ChatPhase? phase,
    String? pendingQuestion,
    String? preview,
    String? error,
    bool canRetry = false,
  }) => ChatState(
    sessions: sessions ?? this.sessions,
    messages: messages ?? this.messages,
    sessionId: sessionId,
    phase: phase ?? this.phase,
    pendingQuestion: pendingQuestion ?? this.pendingQuestion,
    preview: preview ?? this.preview,
    error: error,
    canRetry: canRetry,
  );
}

final chatControllerProvider =
    NotifierProvider.autoDispose<ChatController, ChatState>(ChatController.new);

class ChatController extends Notifier<ChatState> {
  int _generation = 0;
  StreamSubscription<String>? _stream;
  Completer<void>? _cancelled;
  ChatTurn? _readyToSave;
  String? _turnId;
  String? _lastQuestion;
  DateTime? _lastDate;
  KnowledgeTopic? _lastTopic;

  @override
  ChatState build() {
    final enabled = ref.watch(appFeatureFlagsProvider).chatbotEnabled;
    ref.watch(authSessionProvider.select((session) => session.value?.uid));
    final generation = ++_generation;
    ref.onDispose(_abort);
    Future.microtask(() {
      if (enabled && _valid(generation)) loadSessions();
    });
    _resetRequest();
    return const ChatState();
  }

  bool _valid(int generation) => ref.mounted && generation == _generation;
  String get _uid =>
      ref.read(authSessionProvider).value?.uid ??
      (throw const ChatFailure('Hãy đăng nhập để trò chuyện.'));
  ChatRepository get _repository => ref.read(chatRepositoryProvider);

  void _abort() {
    _generation++;
    _stream?.cancel().ignore();
    _stream = null;
    if (_cancelled case final cancelled? when !cancelled.isCompleted) {
      cancelled.complete();
    }
  }

  void _resetRequest() {
    _readyToSave = null;
    _turnId = null;
    _lastQuestion = null;
    _lastDate = null;
    _lastTopic = null;
  }

  Future<void> loadSessions() async {
    if (!ref.read(appFeatureFlagsProvider).chatbotEnabled) return;
    if (state.busy) return;
    final generation = _generation;
    state = state.change(phase: ChatPhase.loading);
    try {
      final sessions = await _repository.loadSessions(_uid);
      if (_valid(generation)) {
        state = state.change(sessions: sessions, phase: ChatPhase.idle);
      }
    } catch (error) {
      if (_valid(generation)) {
        state = state.change(phase: ChatPhase.idle, error: _message(error));
      }
    }
  }

  Future<void> openSession(String id) async {
    if (!ref.read(appFeatureFlagsProvider).chatbotEnabled) return;
    if (state.busy) return;
    _resetRequest();
    final generation = ++_generation;
    state = ChatState(
      sessions: state.sessions,
      sessionId: id,
      phase: ChatPhase.loading,
    );
    try {
      final messages = await _repository.loadMessages(_uid, id);
      if (_valid(generation)) {
        state = state.change(messages: messages, phase: ChatPhase.idle);
      }
    } catch (error) {
      // Do not allow sending into an incompletely loaded conversation.
      if (_valid(generation)) {
        state = ChatState(sessions: state.sessions, error: _message(error));
      }
    }
  }

  void newSession() {
    if (state.busy) return;
    _generation++;
    _resetRequest();
    state = ChatState(sessions: state.sessions);
  }

  void cancel() {
    if (state.phase != ChatPhase.answering) return;
    _abort();
    _resetRequest();
    state = state.change(
      phase: ChatPhase.idle,
      pendingQuestion: '',
      preview: '',
      error:
          'Đã dừng nhận câu trả lời. Yêu cầu AI đã gửi có thể vẫn tính hạn mức.',
    );
  }

  Future<void> retry() async {
    if (!state.canRetry || state.busy) return;
    await _send(_lastQuestion!, _lastDate!, _lastTopic);
  }

  Future<bool> send(
    String question,
    DateTime selectedDate, {
    KnowledgeTopic? topic,
  }) async {
    if (!ref.read(appFeatureFlagsProvider).chatbotEnabled) return false;
    if (state.busy || state.full || state.pendingSave) return false;
    final text = topic?.label ?? question.trim();
    if (text.isEmpty || text.length > ChatLimits.inputCharacters) {
      state = state.change(error: 'Nhập câu hỏi từ 1 đến 1000 ký tự.');
      return false;
    }
    _resetRequest();
    final now = ref.read(currentLocalTimeProvider)();
    return _send(text, journalQuestionDate(text, selectedDate, now), topic);
  }

  Future<bool> _send(
    String question,
    DateTime date,
    KnowledgeTopic? topic,
  ) async {
    final diagnosticClock = Stopwatch()..start();
    final generation = ++_generation;
    _lastQuestion = question;
    _lastDate = date;
    _lastTopic = topic;
    _turnId ??= _repository.newId();
    final uid = _uid;
    final sessionId = state.sessionId ?? _repository.newId();
    state = ChatState(
      sessions: state.sessions,
      messages: state.messages,
      sessionId: sessionId,
      phase: ChatPhase.answering,
      pendingQuestion: question,
    );
    _cancelled = Completer<void>();
    try {
      if (_readyToSave == null) {
        final answer = await Future.any<String>([
          _answer(uid, question, date, topic, generation),
          _cancelled!.future.then<String>((_) => throw const _Cancelled()),
        ]).timeout(const Duration(seconds: 45));
        if (!_valid(generation)) return false;
        if (answer.trim().isEmpty ||
            answer.length > ChatLimits.outputCharacters) {
          throw const ChatFailure(
            'Câu trả lời trống hoặc vượt giới hạn. Hãy thử lại.',
          );
        }
        _readyToSave = ChatTurn(
          id: _turnId!,
          question: question,
          answer: answer,
          source: topic != null
              ? ChatSource.ai
              : journalQuestion(question) != null
              ? ChatSource.journal
              : ChatSource.help,
        );
      }
      if (!_valid(generation)) return false;
      state = state.change(
        phase: ChatPhase.saving,
        preview: _readyToSave!.answer,
      );
      final turn = _readyToSave!;
      operationDiagnostic('chat', 'save', 'start', diagnosticClock);
      await _repository.saveTurn(uid, sessionId, turn);
      operationDiagnostic('chat', 'save', 'success', diagnosticClock);
      if (!_valid(generation)) return false;
      final count = state.messages.length;
      final messages = [
        ...state.messages,
        ChatMessage(
          id: '${turn.id}_u',
          isUser: true,
          text: question,
          sequence: count,
          source: turn.source,
        ),
        ChatMessage(
          id: '${turn.id}_a',
          isUser: false,
          text: turn.answer,
          sequence: count + 1,
          source: turn.source,
        ),
      ];
      final sessions = [
        ChatSession(
          id: sessionId,
          title: 'Trò chuyện HealthMate',
          updatedAt: ref.read(currentLocalTimeProvider)(),
          messageCount: messages.length,
        ),
        ...state.sessions.where((session) => session.id != sessionId),
      ].take(ChatLimits.recentSessions).toList();
      _resetRequest();
      state = ChatState(
        sessions: sessions,
        messages: messages,
        sessionId: sessionId,
      );
      return true;
    } on _Cancelled {
      operationDiagnostic('chat', 'answer', 'cancelled', diagnosticClock);
      return false;
    } catch (error) {
      operationDiagnostic(
        'chat',
        _readyToSave == null ? 'answer' : 'save',
        'error',
        diagnosticClock,
        code: diagnosticErrorCode(error),
      );
      if (_valid(generation)) {
        state = state.change(
          phase: ChatPhase.idle,
          preview: _readyToSave?.answer ?? '',
          error: _readyToSave != null
              ? '${_message(error)} Đáp án chưa được xác nhận lưu. Thử lại sẽ lưu cùng ID, không gọi AI lại; hoặc tạo cuộc trò chuyện mới.'
              : _message(error),
          canRetry: true,
        );
      }
      return false;
    } finally {
      if (_valid(generation)) {
        // Cancellation starts immediately; SDK cleanup must not hold up the UI.
        _stream?.cancel().ignore();
        _stream = null;
        _cancelled = null;
      }
    }
  }

  Future<String> _answer(
    String uid,
    String question,
    DateTime date,
    KnowledgeTopic? topic,
    int generation,
  ) async {
    if (topic == null) {
      final kind = journalQuestion(question);
      if (kind == null) {
        return 'Tôi có thể tra cứu bữa ăn/kcal, nước, vận động hoặc tóm tắt ngày đã chọn. Hãy chọn ngày bằng nút lịch. Câu hỏi về hôm nay/hôm qua dùng đúng ngày đó. Với kiến thức chung, hãy chọn chủ đề AI bên dưới. Nội dung tự nhập không gửi đến AI; tôi không chẩn đoán hoặc tư vấn điều trị.';
      }
      return ref.read(journalChatContextProvider).answer(uid, kind, date);
    }
    final access = ref.read(aiAccessProvider);
    if (!access.allowed) throw ChatFailure(access.message);
    final result = Completer<String>();
    final buffer = StringBuffer();
    _stream = ref
        .read(knowledgeServiceProvider)
        .explain(topic)
        .listen(
          (chunk) {
            if (!_valid(generation) || result.isCompleted) return;
            buffer.write(chunk);
            if (buffer.length > ChatLimits.outputCharacters) {
              result.completeError(
                const ChatFailure('Câu trả lời AI vượt giới hạn. Hãy thử lại.'),
              );
            } else {
              state = state.change(preview: buffer.toString());
            }
          },
          onError: (Object error, StackTrace stack) {
            if (!result.isCompleted) result.completeError(error, stack);
          },
          onDone: () {
            if (!result.isCompleted) result.complete(buffer.toString());
          },
        );
    return result.future;
  }

  String _message(Object error) => error is ChatFailure
      ? error.message
      : error is TimeoutException
      ? 'Yêu cầu quá thời gian chờ. Chưa nhận được đáp án hoàn chỉnh; hãy thử lại hoặc dùng tra cứu nhật ký. Nguyên nhân dịch vụ cần được kiểm tra riêng.'
      : 'Chưa thể hoàn tất yêu cầu. Kiểm tra mạng rồi thử lại.';
}

class _Cancelled implements Exception {
  const _Cancelled();
}
