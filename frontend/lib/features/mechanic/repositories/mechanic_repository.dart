import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mecha_connect/services/api_client.dart';
import '../models/models.dart';

/// Mechanics and Bookings API repository connecting Flutter with FastAPI `/api/v1/mechanic/*`.
class MechanicRepository {
  final List<Booking> _bookings = [];
  final ApiClient? _apiClient;

  MechanicRepository({ApiClient? apiClient})
      : _apiClient = apiClient {
    if (_apiClient == null) {
      _seedHistory();
    }
  }

  void _seedHistory() {
    final now = DateTime.now();
    _bookings.addAll([
      Booking(
        bookingId: 'MEC123456',
        mechanic: mockMechanics[0],
        service: generalServices[0],
        vehicle: 'Honda Activa 6G',
        address: '123, Main Road, Surampalem',
        estimatedArrival: now.subtract(const Duration(days: 2)),
        estimatedCost: 499,
        status: BookingStatus.completed,
        bookingTime: now.subtract(const Duration(days: 2, hours: 1)),
      ),
      Booking(
        bookingId: 'MEC234567',
        mechanic: mockMechanics[2],
        service: generalServices[2],
        vehicle: 'TVS Jupiter',
        address: '45, Green Park, Surampalem',
        estimatedArrival: now.subtract(const Duration(days: 5)),
        estimatedCost: 199,
        status: BookingStatus.completed,
        bookingTime: now.subtract(const Duration(days: 5, hours: 2)),
      ),
      Booking(
        bookingId: 'MEC345678',
        mechanic: mockMechanics[3],
        service: generalServices[4],
        vehicle: 'Maruti Alto 800',
        address: '78, Temple Road, Surampalem',
        estimatedArrival: now.subtract(const Duration(days: 1)),
        estimatedCost: 399,
        status: BookingStatus.cancelled,
        bookingTime: now.subtract(const Duration(days: 1, hours: 3)),
      ),
    ]);
  }

  Future<List<MechanicInfo>> fetchMechanics() async {
    final client = _apiClient;
    if (client != null) {
      final res = await client.get('/api/v1/mechanic/mechanics', requiresAuth: false);
      if (res is List) {
        return res
            .whereType<Map<String, dynamic>>()
            .map((item) => MechanicInfo.fromJson(item))
            .toList();
      }
      return [];
    }
    await _delay();
    return List<MechanicInfo>.from(mockMechanics);
  }

  Future<List<MechanicInfo>> fetchFeaturedMechanics() async {
    final client = _apiClient;
    if (client != null) {
      final res = await client.get('/api/v1/mechanic/mechanics/featured', requiresAuth: false);
      if (res is List) {
        return res
            .whereType<Map<String, dynamic>>()
            .map((item) => MechanicInfo.fromJson(item))
            .toList();
      }
      return [];
    }
    await _delay();
    return List<MechanicInfo>.from(featuredMechanics);
  }

  Future<MechanicInfo> fetchMechanicById(String id) async {
    final client = _apiClient;
    if (client != null) {
      final res = await client.get('/api/v1/mechanic/mechanics/$id', requiresAuth: false);
      if (res is Map<String, dynamic>) {
        return MechanicInfo.fromJson(res);
      }
    }
    await _delay();
    try {
      return mockMechanics.firstWhere((m) => m.id == id);
    } catch (_) {
      throw Exception('Mechanic not found');
    }
  }

  Future<List<MechanicReview>> fetchReviews(String mechanicId) async {
    final client = _apiClient;
    if (client != null) {
      final res = await client.get('/api/v1/mechanic/mechanics/$mechanicId/reviews', requiresAuth: false);
      if (res is List) {
        return res
            .whereType<Map<String, dynamic>>()
            .map((item) => MechanicReview.fromJson(item))
            .toList();
      }
      return [];
    }
    await _delay();
    return List<MechanicReview>.from(mechanicReviews[mechanicId] ?? const []);
  }

  Future<List<MechanicCategory>> fetchCategories() async {
    final client = _apiClient;
    if (client != null) {
      final res = await client.get('/api/v1/mechanic/categories', requiresAuth: false);
      if (res is List) {
        return res
            .whereType<Map<String, dynamic>>()
            .map((item) => MechanicCategory.fromJson(item))
            .toList();
      }
      return [];
    }
    await _delay();
    return List<MechanicCategory>.from(mechanicCategories);
  }

  /// Creates a booking via FastAPI `/api/v1/mechanic/bookings`.
  Future<Booking> createBooking({
    required MechanicInfo mechanic,
    required MechanicService service,
    required String vehicle,
    required String address,
    required double estimatedCost,
  }) async {
    if (_apiClient != null) {
      try {
        final isCustomService = service.id.isEmpty || service.id == 'svc_custom';
        final payload = {
          'mechanic_id': mechanic.id,
          if (!isCustomService) 'service_id': service.id,
          'address': address,
          'scheduled_at': DateTime.now().toUtc().toIso8601String(),
        };

        final res = await _apiClient.post(
          '/api/v1/mechanic/bookings',
          body: payload,
          requiresAuth: true,
        );

        if (res is Map<String, dynamic>) {
          final booking = Booking.fromJson(
            res,
            mechanic: mechanic,
            service: service,
          ).copyWith(status: BookingStatus.requested);
          _bookings.insert(0, booking);
          return booking;
        }
      } catch (e) {
        debugPrint('Backend booking creation fell back to local store: $e');
      }
    }

    await _delay();
    final booking = Booking(
      bookingId: 'MEC${DateTime.now().millisecondsSinceEpoch.toString().substring(5, 12)}',
      mechanic: mechanic,
      service: service,
      vehicle: vehicle,
      address: address,
      estimatedArrival: DateTime.now().add(Duration(minutes: mechanic.etaMinutes)),
      estimatedCost: estimatedCost,
      status: BookingStatus.requested,
      bookingTime: DateTime.now(),
    );
    _bookings.insert(0, booking);
    return booking;
  }

  Future<Booking> getBookingById(String bookingId) async {
    if (_apiClient != null) {
      try {
        final res = await _apiClient.get('/api/v1/mechanic/bookings/$bookingId', requiresAuth: true);
        if (res is Map<String, dynamic>) {
          return Booking.fromJson(res);
        }
      } catch (e) {
        debugPrint('Backend get booking fell back to local store: $e');
      }
    }

    await _delay();
    try {
      return _bookings.firstWhere((b) => b.bookingId == bookingId);
    } catch (_) {
      throw Exception('Booking not found');
    }
  }

  /// Updates booking status along the canonical lifecycle.
  Future<Booking> updateBookingStatus(
    String bookingId,
    BookingStatus status, {
    Map<String, dynamic>? payload,
  }) async {
    if (_apiClient != null) {
      try {
        final res = await _apiClient.patch(
          '/api/v1/mechanic/bookings/$bookingId/status',
          body: {
            'status': status.toBackendValue,
            if (payload != null) 'payload': payload,
          },
          requiresAuth: true,
        );
        if (res is Map<String, dynamic>) {
          final existing = _bookings.where((b) => b.bookingId == bookingId).firstOrNull;
          final updated = Booking.fromJson(
            res,
            mechanic: existing?.mechanic,
            service: existing?.service,
          );
          final index = _bookings.indexWhere((b) => b.bookingId == bookingId);
          if (index >= 0) {
            _bookings[index] = updated;
          } else {
            _bookings.insert(0, updated);
          }
          return updated;
        }
      } catch (e) {
        debugPrint('Backend update booking status fell back to local store: $e');
      }
    }

    await _delay();
    final index = _bookings.indexWhere((b) => b.bookingId == bookingId);
    if (index == -1) throw Exception('Booking not found');
    final updated = _bookings[index].copyWith(status: status);
    _bookings[index] = updated;
    return updated;
  }

  /// Fetches audit event logs for a booking.
  Future<List<BookingEventModel>> fetchBookingEvents(String bookingId) async {
    if (_apiClient != null) {
      try {
        final res = await _apiClient.get(
          '/api/v1/mechanic/bookings/$bookingId/events',
          requiresAuth: true,
        );
        if (res is List) {
          return res
              .whereType<Map<String, dynamic>>()
              .map((e) => BookingEventModel.fromJson(e))
              .toList();
        }
      } catch (e) {
        debugPrint('Backend fetch events fell back to empty: $e');
      }
    }
    return const [];
  }

  Future<Booking> cancelBooking(String bookingId) async {
    if (_apiClient != null) {
      try {
        final res = await _apiClient.post(
          '/api/v1/mechanic/bookings/$bookingId/cancel',
          requiresAuth: true,
        );
        if (res is Map<String, dynamic>) {
          final existing = _bookings.where((b) => b.bookingId == bookingId).firstOrNull;
          final updated = Booking.fromJson(
            res,
            mechanic: existing?.mechanic,
            service: existing?.service,
          );
          final index = _bookings.indexWhere((b) => b.bookingId == bookingId);
          if (index >= 0) _bookings[index] = updated;
          return updated;
        }
      } catch (e) {
        debugPrint('Backend cancel booking fell back to local store: $e');
      }
    }

    await _delay();
    final index = _bookings.indexWhere((b) => b.bookingId == bookingId);
    if (index == -1) throw Exception('Booking not found');
    final updated = _bookings[index].copyWith(status: BookingStatus.cancelled);
    _bookings[index] = updated;
    return updated;
  }

  Future<Booking> completeBooking(String bookingId) async {
    if (_apiClient != null) {
      try {
        final res = await _apiClient.post(
          '/api/v1/mechanic/bookings/$bookingId/complete',
          requiresAuth: true,
        );
        if (res is Map<String, dynamic>) {
          final existing = _bookings.where((b) => b.bookingId == bookingId).firstOrNull;
          final updated = Booking.fromJson(
            res,
            mechanic: existing?.mechanic,
            service: existing?.service,
          );
          final index = _bookings.indexWhere((b) => b.bookingId == bookingId);
          if (index >= 0) _bookings[index] = updated;
          return updated;
        }
      } catch (e) {
        debugPrint('Backend complete booking fell back to local store: $e');
      }
    }

    await _delay();
    final index = _bookings.indexWhere((b) => b.bookingId == bookingId);
    if (index == -1) throw Exception('Booking not found');
    final updated = _bookings[index].copyWith(status: BookingStatus.completed);
    _bookings[index] = updated;
    return updated;
  }

  Future<List<Booking>> refreshHistory() async {
    if (_apiClient != null) {
      try {
        final res = await _apiClient.get('/api/v1/mechanic/bookings', requiresAuth: true);
        if (res is List) {
          final fetched = res
              .whereType<Map<String, dynamic>>()
              .map((j) {
                final mechId = j['mechanic_id']?.toString();
                final svcId = j['service_id']?.toString();
                MechanicInfo? foundMech;
                MechanicService? foundSvc;
                try {
                  foundMech = _bookings.where((b) => b.mechanic.id == mechId).map((b) => b.mechanic).firstOrNull ??
                      mockMechanics.where((m) => m.id == mechId).firstOrNull;
                } catch (_) {}
                if (foundMech != null && svcId != null) {
                  try {
                    foundSvc = foundMech.services.where((s) => s.id == svcId).firstOrNull ??
                        generalServices.where((s) => s.id == svcId).firstOrNull;
                  } catch (_) {}
                }
                return Booking.fromJson(j, mechanic: foundMech, service: foundSvc);
              })
              .toList();
          _bookings.clear();
          _bookings.addAll(fetched);
          return List.unmodifiable(_bookings);
        }
      } catch (e) {
        debugPrint('Backend bookings fetch fell back to mock: $e');
      }
    }
    await _delay();
    return List.unmodifiable(_bookings);
  }

  List<Booking> getBookingHistory() => List.unmodifiable(_bookings);

  final Map<String, BookingRating> _ratings = {};

  /// Submits a post-service rating for a completed booking.
  Future<BookingRating> submitRating(
    String bookingId, {
    required double rating,
    String? review,
  }) async {
    if (_apiClient != null) {
      final res = await _apiClient.post(
        '/api/v1/mechanic/bookings/$bookingId/rating',
        body: {
          'rating': rating,
          if (review != null && review.trim().isNotEmpty) 'review': review.trim(),
        },
        requiresAuth: true,
      );
      if (res is Map<String, dynamic>) {
        final bRating = BookingRating.fromJson(res);
        _ratings[bookingId] = bRating;
        return bRating;
      }
      throw Exception('Failed to submit rating: unexpected response format');
    }

    await _delay();
    final bRating = BookingRating(
      bookingId: bookingId,
      rating: rating,
      review: review?.trim().isEmpty == true ? null : review?.trim(),
    );
    _ratings[bookingId] = bRating;
    return bRating;
  }

  /// Fetches an existing rating for a booking (returns null if unrated).
  Future<BookingRating?> fetchRating(String bookingId) async {
    if (_apiClient != null) {
      try {
        final res = await _apiClient.get(
          '/api/v1/mechanic/bookings/$bookingId/rating',
          requiresAuth: true,
        );
        if (res is Map<String, dynamic>) {
          final bRating = BookingRating.fromJson(res);
          _ratings[bookingId] = bRating;
          return bRating;
        }
        return null;
      } on ApiException catch (e) {
        if (e.statusCode == 404) return null;
        rethrow;
      }
    }

    await _delay();
    return _ratings[bookingId];
  }

  Future<void> _delay([Duration duration = const Duration(milliseconds: 700)]) {
    return Future.delayed(duration);
  }
}
