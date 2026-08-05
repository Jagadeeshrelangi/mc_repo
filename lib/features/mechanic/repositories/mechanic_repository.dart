import 'dart:async';
import '../models/models.dart';

/// Mock API layer for the mechanic module.
///
/// Sprint 1.6: simulates network latency with in-memory state so every screen
/// can be wired through an async repository. Swap this implementation with a
/// real HTTP client in Sprint 2 without touching screens/providers.
class MechanicRepository {
  final List<Booking> _bookings = [];

  MechanicRepository() {
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
    await _delay();
    return List<MechanicInfo>.from(mockMechanics);
  }

  Future<List<MechanicInfo>> fetchFeaturedMechanics() async {
    await _delay();
    return List<MechanicInfo>.from(featuredMechanics);
  }

  Future<MechanicInfo> fetchMechanicById(String id) async {
    await _delay();
    try {
      return mockMechanics.firstWhere((m) => m.id == id);
    } catch (_) {
      throw Exception('Mechanic not found');
    }
  }

  Future<List<MechanicReview>> fetchReviews(String mechanicId) async {
    await _delay();
    return List<MechanicReview>.from(mechanicReviews[mechanicId] ?? const []);
  }

  Future<List<MechanicCategory>> fetchCategories() async {
    await _delay();
    return List<MechanicCategory>.from(mechanicCategories);
  }

  /// Creates a booking and stores it in-memory as the "active" booking.
  Future<Booking> createBooking({
    required MechanicInfo mechanic,
    required MechanicService service,
    required String vehicle,
    required String address,
    required double estimatedCost,
  }) async {
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
    await _delay();
    try {
      return _bookings.firstWhere((b) => b.bookingId == bookingId);
    } catch (_) {
      throw Exception('Booking not found');
    }
  }

  Future<Booking> cancelBooking(String bookingId) async {
    await _delay();
    final index = _bookings.indexWhere((b) => b.bookingId == bookingId);
    if (index == -1) throw Exception('Booking not found');
    final updated = _bookings[index].copyWith(status: BookingStatus.cancelled);
    _bookings[index] = updated;
    return updated;
  }

  Future<Booking> completeBooking(String bookingId) async {
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
