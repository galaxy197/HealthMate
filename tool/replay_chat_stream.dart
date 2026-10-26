import 'dart:io';
import 'package:healthmate/features/chatbot/data/cloudflare_chat_assistant.dart';

// Replays a synthetic provider capture without contacting Firebase or AI.
Future<void> main(List<String> args) async {
  final file = File(args.single);
  final answer = await decodeChatEvents(file.openRead()).join();
  if (answer.trim().isEmpty || answer.length > 3800) {
    throw StateError('Captured answer is empty or exceeds the text budget.');
  }
  stdout.writeln(
    'Replay completed: ${await file.length()} wire bytes, '
    '${answer.length} answer characters.',
  );
}
