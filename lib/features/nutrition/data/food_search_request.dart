import 'dart:async';

enum FoodSearchFailureKind {
  cancelled,
  timeout,
  quota,
  network,
  provider,
  invalidData,
}

class FoodSearchFailure implements Exception {
  const FoodSearchFailure(this.kind);
  final FoodSearchFailureKind kind;
  String get message => switch (kind) {
    FoodSearchFailureKind.cancelled => 'Đã dừng tìm kiếm.',
    FoodSearchFailureKind.timeout =>
      'Tra cứu món quá thời gian chờ. Hãy thử lại.',
    FoodSearchFailureKind.quota =>
      'USDA đã chạm hạn mức tra cứu. Hãy thử lại sau.',
    FoodSearchFailureKind.network =>
      'Chưa kết nối được USDA. Kiểm tra mạng rồi thử lại.',
    FoodSearchFailureKind.provider => 'USDA đang lỗi. Hãy thử lại sau.',
    FoodSearchFailureKind.invalidData =>
      'Dữ liệu USDA chưa hợp lệ. Hãy thử lại hoặc chọn món khác.',
  };
}

/// One deadline covers cache + HTTP + parsing, not one timeout per request.
/// Timer-based so tests can advance the clock without real network/sleeps.
class FoodSearchRequest {
  FoodSearchRequest({Duration timeout = defaultTimeout}) {
    _timer = Timer(timeout, () => _stop(FoodSearchFailureKind.timeout));
  }
  static const defaultTimeout = Duration(seconds: 8);
  final _stopped = Completer<void>();
  late final Timer _timer;
  FoodSearchFailureKind? _reason;
  Future<void> get abortTrigger => _stopped.future;
  bool get isActive => _reason == null;
  void check() {
    if (_reason case final reason?) throw FoodSearchFailure(reason);
  }

  void _stop(FoodSearchFailureKind reason) {
    if (_reason != null) return;
    _reason = reason;
    _timer.cancel();
    _stopped.complete();
  }

  void cancel() => _stop(FoodSearchFailureKind.cancelled);
  void finish() => _timer.cancel();

  Future<T> run<T>(Future<T> Function() work) async {
    check();
    final value = await Future.any<T>([
      Future.sync(work),
      _stopped.future.then<T>((_) => throw FoodSearchFailure(_reason!)),
    ]);
    check();
    return value;
  }
}
