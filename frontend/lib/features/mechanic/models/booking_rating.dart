/// Represents a rating and review submitted for a completed mechanic booking.
class BookingRating {
  final String bookingId;
  final double rating;
  final String? review;

  const BookingRating({
    required this.bookingId,
    required this.rating,
    this.review,
  });

  factory BookingRating.fromJson(Map<String, dynamic> json) {
    return BookingRating(
      bookingId: (json['booking_id'] ?? json['bookingId'] ?? '').toString(),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      review: json['review'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'booking_id': bookingId,
    'rating': rating,
    if (review != null) 'review': review,
  };

  BookingRating copyWith({
    String? bookingId,
    double? rating,
    String? review,
  }) {
    return BookingRating(
      bookingId: bookingId ?? this.bookingId,
      rating: rating ?? this.rating,
      review: review ?? this.review,
    );
  }
}
