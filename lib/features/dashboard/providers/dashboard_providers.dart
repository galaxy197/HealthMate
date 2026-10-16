import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/local_date_key.dart';
import '../../../shared/providers/local_clock_provider.dart';

final dashboardClockProvider = Provider.autoDispose<DateTime>(
  (ref) => ref.watch(localClockProvider),
);

final dashboardTodayProvider = Provider.autoDispose<DateTime>(
  (ref) => localDateOnly(ref.watch(dashboardClockProvider)),
);
