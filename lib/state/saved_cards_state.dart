import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/saved_card.dart';

/// The customer's linked cards. Starts empty — cards only exist once the
/// customer links one via the Profile screen or Checkout's card picker.
class SavedCardsNotifier extends Notifier<List<SavedCard>> {
  @override
  List<SavedCard> build() => [];

  void add(SavedCard card) => state = [...state, card];

  void remove(String id) => state = state.where((c) => c.id != id).toList();
}

final savedCardsProvider = NotifierProvider<SavedCardsNotifier, List<SavedCard>>(SavedCardsNotifier.new);
