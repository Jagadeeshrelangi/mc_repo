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
    _seedHistory();
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
    if (_apiClient != null) {
      try {
        final res = await _apiClient.get('/api/v1/mechanic/mechanics', requiresAuth: false);
        if (res is List && res.isNotEmpty) {
          return res.map((item) => MechanicInfo.fromJson(item as Map<String, dynamic>)).toList();
        }
      } catch (e) {
        debugPrint('Backend mechanic list fetch fell back to mock: $e');
      }
    }
    await _delay();
    return List<MechanicInfo>.from(mockMechanics);
  }

  Future<List<MechanicInfo>> fetchFeaturedMechanics() async {
    if (_apiClient != null) {
      try {
        final res = await _apiClient.get('/api/v1/mechanic/mechanics/featured', requiresAuth: false);
        if (res is List && res.isNotEmpty) {
          return res.map((item) => MechanicInfo.fromJson(item as Map<String, dynamic>)).toList();
        }
      } catch (e) {
        debugPrint('Backend featured mechanics fetch fell back to mock: $e');
      }
    }
    await _delay();
    return List<MechanicInfo>.from(featuredMechanics);
  }

  Future<MechanicInfo> fetchMechanicById(String id) async {
    if (_apiClient != null) {
      try {
        final res = await _apiClient.get('/api/v1/mechanic/mechanics/$id', requiresAuth: false);
        if (res is Map<String, dynamic>) {
          return MechanicInfo.fromJson(res);
        }
      } catch (e) {
        debugPrint('Backend mechanic detail fetch fell back to mock: $e');
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
    if (_apiClient != null) {
      try {
        final res = await _apiClient.get('/api/v1/mechanic/mechanics/$mechanicId/reviews', requiresAuth: false);
        if (res is List && res.isNotEmpty) {
          return res.map((item) => MechanicReview.fromJson(item as Map<String, dynamic>)).toList();
        }
      } catch (e) {
        debugPrint('Backend reviews fetch fell back to mock: $e');
      }
    }
    await _delay();
    return List<MechanicReview>.from(mechanicReviews[mechanicId] ?? const []);
  }

  Future<List<MechanicCategory>> fetchCategories() async {
    if (_apiClient != null) {
      try {
        final res = await _apiClient.get('/api/v1/mechanic/categories', requiresAuth: false);
        if (res is List && res.isNotEmpty) {
          return res.map((item) => MechanicCategory.fromJson(item as Map<String, dynamic>)).toList();
        }
      } catch (e) {
        debugPrint('Backend categories fetch fell back to mock: $e');
      }
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
        final payload = {
          'mechanic_id': mechanic.id,
          if (service.id.isNotEmpty) 'service_id': service.id,
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

  Future<Booking> cancelBooking(String bookingId) async {
    if (_apiClient != null) {
      try {
        final res = await _apiClient.post(
          '/api/v1/mechanic/bookings/$bookingId/cancel',
          requiresAuth: true,
        );
        if (res is Map<String, dynamic>) {
          final updated = Booking.fromJson(res);
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
          final updated = Booking.fromJson(res);
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

  List<Booking> getBookingHistory() => List.unmodifiable(_bookings);

  Future<void> _delay([Duration duration = const Duration(milliseconds: 700)]) {
    return Future.delayed(duration);
  }
}
