class Review {
  const Review({required this.id, required this.rating, this.comment = ''});

  final int id;
  final int rating;
  final String comment;
}

Review? orderReviewFromJson(Map<String, dynamic>? j) {
  if (j == null) return null;
  return Review(
    id: j['id'] as int,
    rating: (j['rating'] as num?)?.toInt() ?? 0,
    comment: j['comment'] as String? ?? '',
  );
}
