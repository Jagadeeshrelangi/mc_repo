import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../repositories/mechanic_repository.dart';

enum MechanicScreenState { initial, loading, ready, error, empty }

class MechanicProvider extends ChangeNotifier {
  final MechanicRepository _repository;

  MechanicProvider({MechanicRepository? repository})
    : _repository = repository ?? MechanicRepository();

  MechanicScreenState _state = MechanicScreenState.initial;
  MechanicScreenState get state => _state;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<MechanicInfo> _mechanics = [];
  List<MechanicInfo> get mechanics => List.unmodifiable(_mechanics);

  List<MechanicInfo> _featuredMechanics = [];
  List<MechanicInfo> get featuredMechanics =>
      List.unmodifiable(_featuredMechanics);

  List<MechanicCategory> _categories = [];
  List<MechanicCategory> get categories => List.unmodifiable(_categories);

  List<MechanicReview> _reviews = [];
  List<MechanicReview> get reviews => List.unmodifiable(_reviews);

  MechanicInfo? _selectedMechanic;
  MechanicInfo? get selectedMechanic => _selectedMechanic;

  MechanicService? _selectedService;
  MechanicService? get selectedService => _selectedService;

  BookingRequest? _bookingRequest;
  BookingRequest? get bookingRequest => _bookingRequest;

  String? _selectedVehicle;
  String? get selectedVehicle => _selectedVehicle;

  Booking? _activeBooking;
  Booking? get activeBooking => _activeBooking;

  BookingStatus? _requestStatus;
  BookingStatus? get requestStatus => _requestStatus;

  List<Booking> _bookingHistory = [];
  List<Booking> get bookingHistory => List.unmodifiable(_bookingHistory);

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  bool _isRefreshing = false;
  bool get isRefreshing => _isRefreshing;

  Future<void> loadHome() async {
    _state = MechanicScreenState.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      _featuredMechanics = await _repository.fetchFeaturedMechanics();
      _mechanics = await _repository.fetchMechanics();
      _categories = await _repository.fetchCategories();
      _state = MechanicScreenState.ready;
    } catch (e) {
      _state = MechanicScreenState.error;
      _errorMessage = 'Could not load mechanics. Pull to retry.';
    }
    notifyListeners();
  }

  Future<void> refresh() async {
    _isRefreshing = true;
    notifyListeners();
    await loadHome();
    _isRefreshing = false;
    notifyListeners();
  }

  Future<void> loadMechanics() async {
    _state = MechanicScreenState.loading;
    notifyListeners();
    try {
      _mechanics = await _repository.fetchMechanics();
      _state =
          _mechanics.isEmpty
              ? MechanicScreenState.empty
              : MechanicScreenState.ready;
    } catch (_) {
      _state = MechanicScreenState.error;
      _errorMessage = 'Could not load mechanics. Pull to retry.';
    }
    notifyListeners();
  }

  void selectMechanic(MechanicInfo mechanic) {
    _selectedMechanic = mechanic;
    notifyListeners();
  }

  void selectService(MechanicService service) {
    _selectedService = service;
    notifyListeners();
  }

  void setBookingRequest(BookingRequest request) {
    _bookingRequest = request;
    _selectedVehicle = request.vehicleSummary;
    notifyListeners();
  }

  Future<void> loadReviews(String mechanicId) async {
    _reviews = await _repository.fetchReviews(mechanicId);
    notifyListeners();
  }

  /// Creates a booking via the repository and records it as active.
  Future<Booking> createBooking({
    required MechanicInfo mechanic,
    required MechanicService service,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final request =
          _bookingRequest ??
          const BookingRequest(
            vehicleType: 'Bike',
            brand: 'Honda',
            model: 'Activa 6G',
            fuelType: 'Petrol',
            registration: 'KA 01 AB 1234',
            problemDescription: 'General service',
            address: '123, Main Road, Surampalem',
          );

      final booking = await _repository.createBooking(
        mechanic: mechanic,
        service: service,
        vehicle: request.vehicleSummary,
        address: request.address,
        estimatedCost: service.price + (mechanic.isAvailable ? 0 : 100),
      );

      _activeBooking = booking;
      _requestStatus = booking.status;
      _bookingHistory = _repository.getBookingHistory();
      return booking;
    } catch (e) {
      _errorMessage = 'Could not create booking. Please try again.';
      rethrow;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<Booking> loadActiveBooking(String bookingId) async {
    _state = MechanicScreenState.loading;
    notifyListeners();
    try {
      _activeBooking = await _repository.getBookingById(bookingId);
      _requestStatus = _activeBooking!.status;
      _state = MechanicScreenState.ready;
      return _activeBooking!;
    } catch (_) {
      _state = MechanicScreenState.error;
      _errorMessage = 'Could not load booking.';
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  Future<void> cancelActiveBooking() async {
    final booking = _activeBooking;
    if (booking == null) return;
    _activeBooking = await _repository.cancelBooking(booking.bookingId);
    _requestStatus = BookingStatus.cancelled;
    _bookingHistory = _repository.getBookingHistory();
    notifyListeners();
  }

  Future<void> completeActiveBooking() async {
    final booking = _activeBooking;
    if (booking == null) return;
    _activeBooking = await _repository.completeBooking(booking.bookingId);
    _requestStatus = BookingStatus.completed;
    _bookingHistory = _repository.getBookingHistory();
    notifyListeners();
  }

  Future<void> loadBookingHistory() async {
    _bookingHistory = _repository.getBookingHistory();
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void reset() {
    _state = MechanicScreenState.initial;
    _errorMessage = null;
    _mechanics = [];
    _featuredMechanics = [];
    _categories = [];
    _reviews = [];
    _selectedMechanic = null;
    _selectedService = null;
    _bookingRequest = null;
    _selectedVehicle = null;
    _activeBooking = null;
    _requestStatus = null;
    _isSubmitting = false;
    _isRefreshing = false;
    notifyListeners();
  }
}
