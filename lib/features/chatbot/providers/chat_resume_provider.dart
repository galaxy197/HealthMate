import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_providers.dart';

class ChatResumeState {
  const ChatResumeState({
    required this.uid,
    required this.revision,
    this.selected = false,
    this.sessionId,
  });
  final String? uid, sessionId;
  final int revision;
  final bool selected;
}

// Remembers only a selection, never messages. Auth changes clear the selection.
// A null explicit selection means the user chose a new, empty conversation.
final chatResumeProvider =
    NotifierProvider<ChatResumeController, ChatResumeState>(
      ChatResumeController.new,
    );

class ChatResumeController extends Notifier<ChatResumeState> {
  int _revision = 0;
  @override
  ChatResumeState build() => ChatResumeState(
    uid: ref.watch(authSessionProvider.select((s) => s.value?.uid)),
    revision: ++_revision,
  );

  void select(String uid, String? sessionId, {int? expectedRevision}) {
    if (!ref.mounted ||
        state.uid != uid ||
        (expectedRevision != null && state.revision != expectedRevision)) {
      return;
    }
    state = ChatResumeState(
      uid: uid,
      revision: ++_revision,
      selected: true,
      sessionId: sessionId,
    );
  }
}
