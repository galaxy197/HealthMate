import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Shared by day-based screens. A minute tick handles midnight; resume handles
// time/timezone changes while the app was backgrounded. No Firestore reads.
final currentLocalTimeProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

final localClockProvider = Provider.autoDispose<DateTime>((ref) {
  final now = ref.watch(currentLocalTimeProvider)();
  final timer = Timer(
    Duration(
      microseconds:
          60000000 -
          now.second * 1000000 -
          now.millisecond * 1000 -
          now.microsecond,
    ),
    ref.invalidateSelf,
  );
  final observer = _ClockResumeObserver(ref.invalidateSelf);
  WidgetsBinding.instance.addObserver(observer);
  ref.onDispose(() {
    timer.cancel();
    WidgetsBinding.instance.removeObserver(observer);
  });
  return now;
});

class _ClockResumeObserver extends WidgetsBindingObserver {
  _ClockResumeObserver(this.refresh);
  final VoidCallback refresh;
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) refresh();
  }
}
