import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';

String diagnosticErrorCode(Object error) {
  if (error is TimeoutException) return 'timeout';
  if (error is FirebaseException) return error.code;
  final text = error.toString().toLowerCase();
  if (text.contains('429') || text.contains('quota')) return 'quota';
  if (text.contains('403') || text.contains('app check')) {
    return 'app-check-or-permission';
  }
  if (text.contains('404') || text.contains('model not found')) {
    return 'model-not-found';
  }
  if (text.contains('socket') || text.contains('network')) return 'network';
  return 'unknown';
}

/// Developer-owned stage labels and error codes only. No UID, prompt, token,
/// request/response payload, health data or raw exception text is accepted.
void operationDiagnostic(
  String area,
  String stage,
  String outcome,
  Stopwatch clock, {
  String code = 'none',
}) {
  if (!kDebugMode) return;
  final safeCode = RegExp(r'^[a-z0-9_-]{1,40}$').hasMatch(code)
      ? code
      : 'unknown';
  debugPrint(
    'HM_DIAG area=$area stage=$stage outcome=$outcome code=$safeCode elapsedMs=${clock.elapsedMilliseconds}',
  );
}
