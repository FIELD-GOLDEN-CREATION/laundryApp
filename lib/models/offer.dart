class Offer {
  const Offer({
    required this.slotId,
    required this.slotHint,
    required this.tag,
    required this.title,
    required this.sub,
    this.imageUrl = '',
  });

  final String slotId;
  final String slotHint;
  final String tag;
  final String title;
  final String sub;

  /// Offer photo URL; empty means "no photo yet".
  final String imageUrl;
}
