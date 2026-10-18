import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_feature_flags.dart';

enum JournalQuickAction { addMeal, scanFood, addWater, addActivity }

final journalQuickActionProvider =
    NotifierProvider<JournalQuickActionController, JournalQuickAction?>(
      JournalQuickActionController.new,
    );

class JournalQuickActionController extends Notifier<JournalQuickAction?> {
  @override
  JournalQuickAction? build() => null;

  void request(JournalQuickAction action) {
    if (action == JournalQuickAction.scanFood &&
        !ref.read(appFeatureFlagsProvider).foodScannerEnabled) {
      return;
    }
    state = action;
  }

  JournalQuickAction? take() {
    final action = state;
    state = null;
    return action;
  }
}
