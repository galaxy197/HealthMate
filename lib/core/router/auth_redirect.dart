import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/models/auth_user.dart';
import 'app_routes.dart';

// Only app-owned destinations are accepted, never URLs supplied by a caller.
String _destination(Uri uri) {
  const allowed = {
    AppRoutes.dashboard,
    AppRoutes.journal,
    AppRoutes.quest,
    AppRoutes.chat,
    AppRoutes.profile,
  };
  final candidate = uri.queryParameters['from'] ?? uri.path;
  return allowed.contains(candidate) ? candidate : AppRoutes.dashboard;
}

String? authRedirect(AsyncValue<AuthUser?> session, Uri uri) {
  final isAuth = uri.path == AppRoutes.auth;
  final isSession = uri.path == AppRoutes.session;
  final destination = _destination(uri);
  if (session.isLoading || session.hasError) {
    return isSession
        ? null
        : Uri(
            path: AppRoutes.session,
            queryParameters: {'from': destination},
          ).toString();
  }
  if (session.value == null) {
    return isAuth
        ? null
        : Uri(
            path: AppRoutes.auth,
            queryParameters: {'from': destination},
          ).toString();
  }
  return isAuth || isSession ? destination : null;
}
