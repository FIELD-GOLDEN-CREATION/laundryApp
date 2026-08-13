enum CardBrand { visa, mastercard, bank }

String brandLabel(CardBrand brand) => switch (brand) {
  CardBrand.visa => 'Visa',
  CardBrand.mastercard => 'Mastercard',
  CardBrand.bank => 'Bank card',
};

/// Classifies a card by its leading digits (standard Visa/Mastercard IIN
/// ranges), falling back to a generic bank card for everything else.
CardBrand detectCardBrand(String digitsOnly) {
  if (digitsOnly.startsWith('4')) return CardBrand.visa;
  if (RegExp(r'^(5[1-5]|2(2[2-9]|[3-6]\d|7[01]|720))').hasMatch(digitsOnly)) {
    return CardBrand.mastercard;
  }
  return CardBrand.bank;
}

class SavedCard {
  const SavedCard({
    required this.id,
    required this.holderName,
    required this.last4,
    required this.expiry,
    required this.brand,
  });

  final String id;
  final String holderName;
  final String last4;
  final String expiry;
  final CardBrand brand;

  String get label => '${brandLabel(brand)} •••• $last4';
}
