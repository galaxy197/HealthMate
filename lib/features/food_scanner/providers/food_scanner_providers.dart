import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/firebase_food_scanner_service.dart';
import '../data/food_scanner_service.dart';

final foodScannerServiceProvider = Provider<FoodScannerService>(
  (ref) => FirebaseFoodScannerService(),
);
