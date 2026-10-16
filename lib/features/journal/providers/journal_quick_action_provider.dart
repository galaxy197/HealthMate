import 'package:flutter_riverpod/flutter_riverpod.dart';

enum JournalQuickAction { addMeal, scanFood, addWater, addActivity }

final journalQuickActionProvider =
    NotifierProvider<JournalQuickActionController, JournalQuickAction?>(
      JournalQuickActionController.new,
    );

class JournalQuickActionController extends Notifier<JournalQuickAction?> {
  @override
  JournalQuickAction? build() => null;

  void request(JournalQuickAction action) => state = action;

  JournalQuickAction? take() {
    final action = state;
    state = null;
    return action;
  }
}
