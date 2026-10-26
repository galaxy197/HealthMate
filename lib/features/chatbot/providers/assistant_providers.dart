import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_providers.dart';
import '../../nutrition/providers/nutrition_providers.dart';
import '../data/chat_assistant.dart';
import '../data/cloudflare_chat_assistant.dart';
import '../domain/chat_data_reader.dart';
import '../models/chat_models.dart';
import 'chat_providers.dart';

// Public URL only, never an AI/provider secret. Empty keeps existing local lookup.
final chatApiEndpointProvider = Provider<String>(
  (ref) => const String.fromEnvironment('HEALTHMATE_CHAT_API_URL'),
);
final flexibleChatAvailableProvider = Provider<bool>(
  (ref) => ref.watch(chatApiEndpointProvider).isNotEmpty,
);
final chatAssistantProvider = Provider<ChatAssistant>(
  (ref) => CloudflareChatAssistant(
    endpoint: Uri.parse(ref.watch(chatApiEndpointProvider)),
    credentials: (expectedUid) async {
      void check() {
        if (!ref.mounted ||
            ref.read(authSessionProvider).value?.uid != expectedUid ||
            FirebaseAuth.instance.currentUser?.uid != expectedUid) {
          throw const ChatFailure('Phiên đăng nhập đã thay đổi.');
        }
      }

      check();
      final user = FirebaseAuth.instance.currentUser!;
      final idToken = await user.getIdToken();
      check();
      final appCheck = await FirebaseAppCheck.instance.getToken();
      check();
      if (idToken == null || appCheck == null) {
        throw const ChatFailure('Chưa lấy được token bảo vệ ứng dụng.');
      }
      return ChatApiCredentials(idToken, appCheck);
    },
  ),
);
final chatDataReaderProvider = Provider<ChatDataReader>(
  (ref) => ChatDataReader(
    personal: ref.watch(personalChatContextProvider),
    loadCatalog: () => ref.read(foodCatalogProvider.future),
  ),
);
