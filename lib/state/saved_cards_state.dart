import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/saved_card.dart';
import '../services/api_service.dart';

class SavedCardsNotifier extends Notifier<List<SavedCard>> {
  @override
  List<SavedCard> build() => [];

  Future<void> loadCards() async {
    try {
      final data = await api.getCards();
      state = data.map((j) => SavedCard(
        id: j['id'] as String? ?? '',
        holderName: j['holder_name'] as String? ?? '',
        last4: j['last4'] as String? ?? '',
        expiry: j['expiry'] as String? ?? '',
        brand: _parseBrand(j['brand'] as String?),
      )).toList();
    } on ApiException {
      // Keep existing state
    }
  }

  Future<bool> addCard({
    required String number,
    required String holderName,
    required String expiry,
    required String cvc,
  }) async {
    try {
      await api.addCard({
        'number': number,
        'holder_name': holderName,
        'expiry': expiry,
        'cvc': cvc,
      });
      await loadCards();
      return true;
    } on ApiException {
      return false;
    }
  }

  Future<bool> removeCard(String id) async {
    try {
      await api.deleteCard(id);
      state = state.where((c) => c.id != id).toList();
      return true;
    } on ApiException {
      return false;
    }
  }

  void addLocal(SavedCard card) => state = [...state, card];

  void removeLocal(String id) => state = state.where((c) => c.id != id).toList();

  CardBrand _parseBrand(String? brand) {
    return switch (brand) {
      'visa' => CardBrand.visa,
      'mastercard' => CardBrand.mastercard,
      _ => CardBrand.bank,
    };
  }
}

final savedCardsProvider = NotifierProvider<SavedCardsNotifier, List<SavedCard>>(SavedCardsNotifier.new);
