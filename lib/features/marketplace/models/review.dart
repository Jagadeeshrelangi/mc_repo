/// A mock product review. Photos reference asset paths when present so the
/// review UI mirrors a real marketplace (Sprint 2 syncs server data).
class Review {
  final String id;
  final String author;
  final double rating;
  final String comment;
  final String date;
  final bool isVerifiedPurchase;
  final int helpfulCount;
  final List<String> photoUrls;

  const Review({
    required this.id,
    required this.author,
    required this.rating,
    required this.comment,
    required this.date,
    this.isVerifiedPurchase = false,
    this.helpfulCount = 0,
    this.photoUrls = const [],
  });
}
