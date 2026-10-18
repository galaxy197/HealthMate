import 'dart:async';

/// Delivers every error while subscribed, but owns errors from asynchronous
/// cancellation. An async* Firestore adapter can fail its cancel Future when
/// auth is revoked while its await-for loop is shutting down. The old consumer
/// is already gone; that failure must not escape into the next account's zone.
Stream<T> subscriptionStream<T>(Stream<T> source) {
  late StreamController<T> output;
  StreamSubscription<T>? subscription;
  var cancelled = false;
  output = StreamController<T>(
    onListen: () {
      subscription = source.listen(
        (value) {
          if (!cancelled) output.add(value);
        },
        onError: (Object error, StackTrace stack) {
          if (!cancelled) output.addError(error, stack);
        },
        onDone: () {
          if (!cancelled) output.close();
        },
      );
    },
    onPause: () => subscription?.pause(),
    onResume: () => subscription?.resume(),
    onCancel: () async {
      cancelled = true;
      try {
        await subscription?.cancel();
      } catch (_) {
        // Only cleanup of a cancelled subscription. Active read/write errors
        // still propagate normally; never replace them with empty data.
      }
    },
  );
  return output.stream;
}
