import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/assistant_request.dart';
import '../models/chat_models.dart';
import 'chat_assistant.dart';

class ChatApiCredentials {
  const ChatApiCredentials(this.idToken, this.appCheckToken);
  final String idToken, appCheckToken;
}

/// Tokens authenticate only the proxy; neither token nor UID enters model input.
class CloudflareChatAssistant implements ChatAssistant {
  CloudflareChatAssistant({
    required this.endpoint,
    required this.credentials,
    http.Client Function()? clientFactory,
  }) : clientFactory = clientFactory ?? http.Client.new;
  final Uri endpoint;
  final Future<ChatApiCredentials> Function(String uid) credentials;
  final http.Client Function() clientFactory;

  @override
  Stream<String> reply(
    AssistantConversation conversation, {
    required String uid,
    required bool Function() isCurrent,
    required Future<List<ChatDataResult>> Function(List<ChatDataRequest>)
    readData,
  }) {
    final controller = StreamController<String>();
    final client = clientFactory();
    var cancelled = false;
    controller.onCancel = () {
      cancelled = true;
      client.close();
    };
    bool current() => !cancelled && isCurrent();
    void check() {
      if (!current()) throw const ChatFailure('Phiên yêu cầu đã kết thúc.');
    }

    Future<http.StreamedResponse> post(Map<String, Object?> body) async {
      check();
      if (endpoint.scheme != 'https' ||
          endpoint.host.isEmpty ||
          endpoint.hasQuery ||
          endpoint.hasFragment ||
          endpoint.userInfo.isNotEmpty ||
          endpoint.path != '/v1/chat') {
        throw const ChatFailure(
          'Địa chỉ API chatbot chưa được cấu hình hợp lệ.',
        );
      }
      final tokens = await credentials(uid);
      check();
      if (tokens.idToken.isEmpty || tokens.appCheckToken.isEmpty) {
        throw const ChatFailure(
          'Chưa xác thực được ứng dụng. Hãy đăng nhập lại.',
        );
      }
      final request = http.Request('POST', endpoint)
        ..followRedirects = false
        ..headers.addAll({
          'content-type': 'application/json',
          'authorization': 'Bearer ${tokens.idToken}',
          'x-firebase-appcheck': tokens.appCheckToken,
        })
        ..body = jsonEncode(body);
      final response = await client
          .send(request)
          .timeout(const Duration(seconds: 35));
      check();
      if (response.statusCode != 200) {
        await response.stream.listen(null).cancel();
        throw ChatFailure(switch (response.statusCode) {
          401 || 403 =>
            'Chưa xác thực được tài khoản hoặc App Check. Hãy đăng nhập lại.',
          429 =>
            'AI đã chạm hạn mức miễn phí hoặc giới hạn yêu cầu. Hãy thử lại sau; bạn vẫn có thể tra cứu nhật ký.',
          400 ||
          413 => 'Câu hỏi hoặc ngữ cảnh quá dài/chưa hợp lệ. Hãy hỏi ngắn hơn.',
          _ =>
            'Dịch vụ chatbot chưa sẵn sàng. Hãy thử lại sau hoặc tra cứu nhật ký.',
        });
      }
      return response;
    }

    Future<void> run() async {
      try {
        final planResponse = await post(conversation.body('plan'));
        final planText = await boundedBody(planResponse.stream, 8000);
        check();
        final raw = jsonDecode(planText);
        if (raw is! Map<String, dynamic> ||
            raw.keys.any((k) => k != 'requests') ||
            raw['requests'] is! List ||
            (raw['requests'] as List).length > 3) {
          throw const ChatFailure('AI trả kế hoạch chưa hợp lệ. Hãy thử lại.');
        }
        final requests = (raw['requests'] as List)
            .map((r) => ChatDataRequest.parse(r, conversation.today))
            .toList();
        final results = await readData(requests);
        check();
        final answer = await post({
          ...conversation.body('answer'),
          'results': results.map((r) => r.toJson()).toList(),
        });
        var length = 0;
        await for (final chunk in decodeChatEvents(answer.stream)) {
          check();
          length += chunk.length;
          if (length > 3800) {
            throw const ChatFailure(
              'Câu trả lời AI quá dài. Hãy thu hẹp câu hỏi.',
            );
          }
          controller.add(chunk);
        }
        check();
        if (length == 0) {
          throw const ChatFailure('AI chưa trả câu trả lời. Hãy thử lại.');
        }
        // Keep authoritative app calculations visible alongside AI prose.
        if (results.isNotEmpty) {
          final facts = results.map((r) => r.text).join('\n\n');
          if (facts.length <= 2100) {
            controller.add('\n\nSố liệu tra cứu từ HealthMate:\n$facts');
          } else {
            controller.add(
              '\n\nĐáp án dựa trên dữ liệu HealthMate đã tra cứu; hãy đối chiếu nhật ký trước khi quyết định.',
            );
          }
        }
      } catch (error, stack) {
        if (current()) {
          controller.addError(
            error is ChatFailure
                ? error
                : const ChatFailure(
                    'Chưa thể nhận đáp án hoàn chỉnh. Kiểm tra mạng rồi thử lại.',
                  ),
            stack,
          );
        }
      } finally {
        client.close();
        await controller.close();
      }
    }

    unawaited(run());
    return controller.stream;
  }
}

Future<String> boundedBody(Stream<List<int>> stream, int limit) async {
  final bytes = <int>[];
  await for (final chunk in stream.timeout(const Duration(seconds: 30))) {
    if (bytes.length + chunk.length > limit) {
      throw const ChatFailure('Phản hồi API quá lớn.');
    }
    bytes.addAll(chunk);
  }
  return utf8.decode(bytes);
}

/// Supports Cloudflare response SSE and its OpenAI-compatible choices/deltas.
/// An incomplete stream is never accepted/saved as a complete answer.
Stream<String> decodeChatEvents(Stream<List<int>> bytes) async* {
  var completed = false, event = '', raw = '', shown = '';
  // SSE includes an envelope for every token. Bound wire bytes separately from
  // the 3800-character answer limit; valid Llama streams exceed 32 KB easily.
  Stream<List<int>> boundedWire() async* {
    var wireBytes = 0;
    await for (final chunk in bytes) {
      wireBytes += chunk.length;
      if (wireBytes > 2 * 1024 * 1024) {
        throw const ChatFailure('Phản hồi AI vượt giới hạn truyền dữ liệu.');
      }
      yield chunk;
    }
  }

  await for (final line
      in boundedWire()
          .timeout(const Duration(seconds: 30))
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
    if (line.startsWith('data:')) {
      event += '${line.substring(5).trimLeft()}\n';
      if (event.length > 16000) {
        throw const ChatFailure('Đoạn phản hồi AI vượt giới hạn.');
      }
      continue;
    }
    if (line.isNotEmpty || event.isEmpty) continue;
    final data = event.trim();
    event = '';
    if (data == '[DONE]') {
      completed = true;
      break;
    }
    final payload = jsonDecode(data);
    if (payload is! Map<String, dynamic> || payload['error'] != null) {
      throw const ChatFailure('Dịch vụ AI bị ngắt. Chưa lưu đáp án.');
    }
    final choices = payload['choices'];
    String? chunk;
    if (choices is List && choices.isNotEmpty) {
      final choice = choices.first as Map<String, dynamic>;
      final finish = choice['finish_reason'];
      if (finish != null) {
        if (finish != 'stop') {
          throw const ChatFailure('Đáp án AI chưa hoàn chỉnh. Hãy thử lại.');
        }
        completed = true;
      }
      final delta = choice['delta'];
      if (delta is Map && delta['content'] is String) {
        chunk = delta['content'] as String;
      }
    } else if (payload['response'] is String) {
      chunk = payload['response'] as String;
    }
    if (chunk == null) continue;
    raw += chunk;
    if (raw.length > 16000) {
      throw const ChatFailure('Nội dung phản hồi AI vượt giới hạn.');
    }
    final visible = visibleChatText(raw);
    if (!visible.startsWith(shown)) {
      throw const ChatFailure('Định dạng phản hồi AI chưa hợp lệ.');
    }
    if (visible.length > shown.length) yield visible.substring(shown.length);
    shown = visible;
  }
  if (!completed || event.isNotEmpty) {
    throw const ChatFailure(
      'Kết nối bị ngắt trước khi nhận đủ đáp án. Hãy thử lại.',
    );
  }
}

String visibleChatText(String raw) {
  var visible = raw
      .replaceAll(RegExp(r'<think>[\s\S]*?</think>'), '')
      .replaceAll(RegExp(r'<think>[\s\S]*$'), '');
  for (var i = 1; i < '<think>'.length; i++) {
    if (visible.endsWith('<think>'.substring(0, i))) {
      return visible.substring(0, visible.length - i);
    }
  }
  return visible;
}
