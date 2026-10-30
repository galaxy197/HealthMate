import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/local_clock_provider.dart';
import '../../../core/config/ai_access_policy.dart';
import '../../../core/config/app_feature_flags.dart';
import '../../../core/errors/operation_diagnostics.dart';
import '../../activity/providers/activity_providers.dart';
import '../../auth/providers/auth_providers.dart';
import '../../wellness/providers/energy_providers.dart';
import '../../nutrition/providers/nutrition_providers.dart';
import '../../nutrition_targets/providers/nutrition_target_providers.dart';
import '../../profile/providers/profile_providers.dart';
import '../../water/providers/water_providers.dart';
import '../data/chat_repository.dart';
import '../data/firebase_chat_repository.dart';
import '../data/firebase_knowledge_service.dart';
import '../data/knowledge_service.dart';
import '../domain/journal_chat_context.dart';
import '../domain/chat_request.dart';
import '../domain/personal_chat_context.dart';
import '../models/chat_models.dart';
import '../models/assistant_request.dart';
import 'assistant_providers.dart';
import 'chat_resume_provider.dart';
import '../../premium/providers/premium_providers.dart';
import '../../premium/models/premium_models.dart';

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

final personalChatContextProvider = Provider<PersonalChatContext>(
  (ref) => PersonalChatContext(
    nutrition: ref.watch(nutritionRepositoryProvider),
    water: ref.watch(waterRepositoryProvider),
    activity: ref.watch(activityRepositoryProvider),
    targets: ref.watch(nutritionTargetRepositoryProvider),
    profile: ref.watch(healthProfileRepositoryProvider),
    energyLoader: (uid, start, end) {
      if (!ref.mounted) throw const ChatFailure('Lượt hỏi đã hủy.');
      return ref
          .read(energyRepositoryProvider)
          .loadAdjustments(uid, start, end);
    },
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
  ChatRequest? _plannedRequest;
  ChatRequest? _contextRequest;
  bool _useAssistant = false;

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
    _contextRequest = null;
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
    _plannedRequest = null;
    _useAssistant = false;
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
        if (state.sessionId == null && state.messages.isEmpty) {
          final resume = ref.read(chatResumeProvider);
          final id = resume.selected
              ? resume.sessionId
              : sessions.firstOrNull?.id;
          if (id != null) await openSession(id);
        }
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
    _contextRequest = null;
    final uid = _uid;
    final generation = ++_generation;
    state = ChatState(
      sessions: state.sessions,
      sessionId: id,
      phase: ChatPhase.loading,
    );
    try {
      final messages = await _repository.loadMessages(uid, id);
      if (_valid(generation)) {
        state = state.change(messages: messages, phase: ChatPhase.idle);
        ref.read(chatResumeProvider.notifier).select(uid, id);
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
    _contextRequest = null;
    ref.read(chatResumeProvider.notifier).select(_uid, null);
    state = ChatState(sessions: state.sessions);
  }

  void resetQuestionContext() {
    if (!state.busy) _contextRequest = null;
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
    bool allowKnowledge = false,
    bool allowAssistant = false,
    bool localOnly = false,
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
    if (!localOnly && ref.read(flexibleChatAvailableProvider)) {
      if (!allowAssistant) {
        state = state.change(
          error:
              'Hãy đồng ý gửi nội dung và dữ liệu liên quan tới Cloudflare trước khi dùng chat AI.',
        );
        return false;
      }
      final access = ref.read(aiAccessProvider);
      if (!access.allowed) {
        state = state.change(error: access.message);
        return false;
      }
      _useAssistant = true;
      return _send(text, selectedDate, null);
    }
    var request = topic == null
        ? planChatRequest(text, selectedDate, now, previous: _contextRequest)
        : ChatRequest(
            intent: ChatIntent.knowledge,
            start: selectedDate,
            end: DateTime(
              selectedDate.year,
              selectedDate.month,
              selectedDate.day + 1,
            ),
            topic: topic,
          );
    if (localOnly && request.topic != null) {
      request = ChatRequest(
        intent: ChatIntent.help,
        start: request.start,
        end: request.end,
        message:
            'Chế độ tra cứu nhật ký không gửi câu hỏi đến AI. Hãy hỏi về dữ liệu đã ghi hoặc tắt chế độ này để trò chuyện với AI.',
      );
    } else if (topic == null && request.topic != null && !allowKnowledge) {
      request = ChatRequest(
        intent: ChatIntent.help,
        start: request.start,
        end: request.end,
        message:
            'Câu hỏi này thuộc chủ đề “${request.topic!.label}”. Hãy chọn chủ đề trong mục Kiến thức chung từ AI để đọc thông tin xử lý dữ liệu trước khi gửi.',
      );
    }
    _plannedRequest = request;
    return _send(text, request.start, request.topic);
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
    final resume = ref.read(chatResumeProvider.notifier);
    final resumeRevision = ref.read(chatResumeProvider).revision;
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
        ]).timeout(Duration(seconds: _useAssistant ? 90 : 45));
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
          source: _useAssistant || topic != null
              ? ChatSource.ai
              : _plannedRequest?.isPersonal == true
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
      // A late save must not overwrite a newer selection or another auth session.
      resume.select(uid, sessionId, expectedRevision: resumeRevision);
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
      _contextRequest = _plannedRequest?.isPersonal == true
          ? _plannedRequest
          : null;
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
    if (!_useAssistant && topic == null) {
      final request = _plannedRequest!;
      if (!request.isPersonal) return request.message!;
      return ref.read(personalChatContextProvider).answer(uid, request);
    }
    final access = ref.read(aiAccessProvider);
    if (!access.allowed) throw ChatFailure(access.message);
    try {
      await ref.read(premiumQuotaProvider)(PremiumAiFeature.chat);
    } on PremiumFailure catch (error) {
      throw ChatFailure(error.message);
    }
    if (!_valid(generation)) throw const _Cancelled();
    final result = Completer<String>();
    final buffer = StringBuffer();
    final Stream<String> answerStream;
    if (_useAssistant) {
      bool current() =>
          _valid(generation) && ref.read(authSessionProvider).value?.uid == uid;
      final today = ref.read(currentLocalTimeProvider)();
      answerStream = ref
          .read(chatAssistantProvider)
          .reply(
            AssistantConversation(
              question: question,
              history: List.of(state.messages),
              today: today,
              selectedDate: date,
            ),
            uid: uid,
            isCurrent: current,
            readData: (requests) => ref
                .read(chatDataReaderProvider)
                .read(uid, requests, today, current),
          );
    } else {
      answerStream = ref.read(knowledgeServiceProvider).explain(topic!);
    }
    _stream = answerStream.listen(
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
