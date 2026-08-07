import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mecha_connect/services/location_provider.dart';
import 'package:mecha_connect/services/location_service.dart';
import '../constants/fuel_constants.dart';
import '../models/models.dart';
import '../repositories/fuel_repository.dart';
import '../services/fuel_service.dart';

enum FuelScreenState { initial, loading, ready, error, empty }

/// Single source of truth for the Fuel Delivery module.
///
/// Manages fuel selection, quantity, vehicle, location, station, the active
/// order, live tracking, order history, loading/refreshing and errors.
///
/// The booking wizard owns NO booking data; every write funnels through this
/// provider, and the UI only mirrors it.
class FuelProvider extends ChangeNotifier {
  final FuelRepository _repository = FuelRepository();
  final FuelService _service = FuelService();
  final LocationProvider _locationProvider;
  final LocationService _locationService = LocationService();

  FuelProvider({required LocationProvider locationProvider})
      : _locationProvider = locationProvider;

  // ── UI state ──────────────────────────────────────────────────────────
  FuelScreenState _state = FuelScreenState.initial;
  FuelScreenState get state => _state;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _isRefreshing = false;
  bool get isRefreshing => _isRefreshing;

  // ── Fuel request ──────────────────────────────────────────────────────
  List<FuelType> _fuelTypes = [];
  List<FuelType> get fuelTypes => List.unmodifiable(_fuelTypes);

  FuelType? _selectedFuelType;
  FuelType? get selectedFuelType => _selectedFuelType;

  double _quantity = FuelConstants.defaultLitres;
  double get quantity => _quantity;

  PriceEstimate? _priceEstimate;
  PriceEstimate? get priceEstimate => _priceEstimate;

  // ── Vehicle ───────────────────────────────────────────────────────────
  List<FuelVehicle> _savedVehicles = [];
  List<FuelVehicle> get savedVehicles => List.unmodifiable(_savedVehicles);

  FuelVehicle? _selectedVehicle;
  FuelVehicle? get selectedVehicle => _selectedVehicle;

  // ── Location ──────────────────────────────────────────────────────────
  DeliveryLocation? _deliveryLocation;
  DeliveryLocation? get deliveryLocation => _deliveryLocation;

  /// Mirrors of the address/pincode text fields. The provider is the single
  /// source of truth; the screen's controllers only mirror these values.
  String _deliveryAddress = '';
  String get deliveryAddress => _deliveryAddress;

  String _deliveryPincode = '';
  String get deliveryPincode => _deliveryPincode;

  LocationBannerState _locationStatus = LocationBannerState.idle;
  LocationBannerState get locationStatus => _locationStatus;

  bool _isDetectingLocation = false;
  bool get isDetectingLocation => _isDetectingLocation;

  // ── Station ───────────────────────────────────────────────────────────
  List<FuelStation> _stations = [];
  List<FuelStation> get stations => List.unmodifiable(_stations);

  FuelStation? _selectedStation;
  FuelStation? get selectedStation => _selectedStation;

  // ── Order ─────────────────────────────────────────────────────────────
  FuelOrder? _activeOrder;
  FuelOrder? get activeOrder => _activeOrder;

  List<FuelOrder> _orderHistory = [];
  List<FuelOrder> get orderHistory => List.unmodifiable(_orderHistory);

  bool _isPlacingOrder = false;
  bool get isPlacingOrder => _isPlacingOrder;

  // ── Tracking ──────────────────────────────────────────────────────────
  TrackingInfo? _trackingInfo;
  TrackingInfo? get trackingInfo => _trackingInfo;

  bool _isTracking = false;
  bool get isTracking => _isTracking;

  Timer? _trackingTimer;

  // ── Boot ──────────────────────────────────────────────────────────────

  Future<void> loadHome() async {
    _state = FuelScreenState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _fuelTypes = _repository.getFuelTypes();

      // Load optional data independently so one failing call never blocks
      // the rest of the page or leaves it loading forever.
      final vehiclesFuture = _loadOptional(_repository.getSavedVehicles);
      final historyFuture = _loadOptional(_repository.refreshHistory);

      final vehicles = await vehiclesFuture;
      final history = await historyFuture;

    if (vehicles != null) _savedVehicles = vehicles;
    if (history != null) _orderHistory = history;

    // A loaded provider always has a fuel type selected — the wizard's first
    // step is never left "unselected", and the price estimate is meaningful
    // before the user interacts. (The provider owns this default, not the UI.)
    if (_selectedFuelType == null && _fuelTypes.isNotEmpty) {
      _selectedFuelType = _fuelTypes.firstWhere(
        (t) => t == FuelType.petrol,
        orElse: () => _fuelTypes.first,
      );
      _recalculatePrice();
    }
  } catch (e) {
    _errorMessage = e.toString();
  }

    _state = _fuelTypes.isEmpty ? FuelScreenState.empty : FuelScreenState.ready;
    notifyListeners();
  }

  Future<T?> _loadOptional<T>(Future<T> Function() loader) async {
    try {
      return await loader().timeout(const Duration(seconds: 10));
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    }
  }

  Future<void> refreshHistory() async {
    _isRefreshing = true;
    notifyListeners();
    try {
      _orderHistory = await _repository.refreshHistory();
    } catch (e) {
      _errorMessage = e.toString();
    }
    _isRefreshing = false;
    notifyListeners();
  }

  // ── Fuel selection ────────────────────────────────────────────────────

  void selectFuelType(FuelType type) {
    if (type.comingSoon) return;
    _selectedFuelType = type;
    _recalculatePrice();
    notifyListeners();
  }

  void setQuantity(double value) {
    _quantity = value.clamp(FuelConstants.minLitres, FuelConstants.maxLitres);
    _recalculatePrice();
    notifyListeners();
  }

  void _recalculatePrice() {
    if (_selectedFuelType == null) return;
    _priceEstimate = _service.calculatePrice(
      _selectedFuelType!,
      _quantity,
      pricePerLitre: _selectedStation?.pricePerLitre,
      etaMinutes: _selectedStation?.etaMinutes,
    );
  }

  // ── Vehicle ───────────────────────────────────────────────────────────

  void selectVehicle(FuelVehicle vehicle) {
    _selectedVehicle = vehicle;
    notifyListeners();
  }

  // ── Location ──────────────────────────────────────────────────────────

  /// The ONLY write point for a location produced by GPS detection.
  ///
  /// Commits the model and mirrors it into the address/pincode fields and the
  /// success status in one atomic update, so the banner, the text fields and
  /// the preview card always agree.
  void setDeliveryLocation(DeliveryLocation location) {
    _deliveryLocation = location;
    _deliveryAddress = location.address;
    _deliveryPincode = location.pincode;
    _locationStatus = LocationBannerState.success;
    notifyListeners();
  }

  /// Manual editing of the address/pincode text fields. The provider remains
  /// the single source of truth; the fields only mirror it.
  void setDeliveryAddress(String value) {
    _deliveryAddress = value;
    _rebuildLocationFromText();
    notifyListeners();
  }

  void setDeliveryPincode(String value) {
    _deliveryPincode = value;
    _rebuildLocationFromText();
    notifyListeners();
  }

  /// Switches the location banner back to the manual-entry hint.
  void enterManualLocation() {
    _locationStatus = LocationBannerState.idle;
    notifyListeners();
  }

  void _rebuildLocationFromText() {
    final lat = _deliveryLocation?.latitude ?? FuelConstants.defaultLatitude;
    final lng = _deliveryLocation?.longitude ?? FuelConstants.defaultLongitude;
    _deliveryLocation = DeliveryLocation(
      latitude: lat,
      longitude: lng,
      address: _deliveryAddress,
      label: 'Current Location',
      pincode: _deliveryPincode,
    );
  }

  /// Runs the full location-detection pipeline (permission → GPS → geocode)
  /// through the shared [LocationService] and commits its result through
  /// [setDeliveryLocation] — the only write point. Idempotent: a concurrent
  /// call is swallowed, so back/forward or a double tap can never start two
  /// detections.
  Future<void> detectDeliveryLocation() async {
    if (_isDetectingLocation) return;
    _isDetectingLocation = true;
    _locationStatus = LocationBannerState.loading;
    notifyListeners();

    try {
      final result = await _locationService.detect(provider: _locationProvider);
      _applyDetectedLocation(result);
    } on LocationDetectException catch (e) {
      _locationStatus = e.state;
    } catch (_) {
      _locationStatus = LocationBannerState.error;
    } finally {
      _isDetectingLocation = false;
      notifyListeners();
    }
  }

  void _applyDetectedLocation(DetectedLocation result) {
    final address = result.address;
    if (address == null || address.isEmpty) {
      // Detection reported success but produced no readable address — never
      // render a "success" banner next to empty fields and a stale preview.
      _locationStatus = LocationBannerState.error;
      return;
    }
    final details = result.details;
    setDeliveryLocation(
      DeliveryLocation(
        latitude: result.latLng?.latitude ??
            _deliveryLocation?.latitude ??
            FuelConstants.defaultLatitude,
        longitude: result.latLng?.longitude ??
            _deliveryLocation?.longitude ??
            FuelConstants.defaultLongitude,
        address: address,
        label: 'Current Location',
        pincode: details != null && details.pincode.isNotEmpty
            ? details.pincode
            : _pincodeFromAddress(address),
      ),
    );
  }

  String _pincodeFromAddress(String address) {
    final match = RegExp(r'\b\d{6}\b').firstMatch(address);
    return match?.group(0) ?? '';
  }

  // ── Stations ──────────────────────────────────────────────────────────

  Future<void> fetchStations() async {
    _state = FuelScreenState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _stations = await _repository.getFuelStations(
        latitude: _deliveryLocation?.latitude ?? FuelConstants.defaultLatitude,
        longitude: _deliveryLocation?.longitude ?? FuelConstants.defaultLongitude,
      );
      _state = _stations.isEmpty ? FuelScreenState.empty : FuelScreenState.ready;
    } catch (e) {
      _state = FuelScreenState.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  void selectStation(FuelStation station) {
    if (!station.isSelectable) return;
    _selectedStation = station;
    _recalculatePrice();
    notifyListeners();
  }

  // ── Order ─────────────────────────────────────────────────────────────

  bool get canPlaceOrder =>
      _selectedFuelType != null &&
      _selectedVehicle != null &&
      _deliveryLocation != null &&
      _selectedStation != null;

  Future<bool> placeOrder({String paymentMethod = 'UPI'}) async {
    if (!canPlaceOrder) return false;

    _isPlacingOrder = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _activeOrder = await _repository.createOrder(
        fuelType: _selectedFuelType!,
        quantity: _quantity,
        vehicle: _selectedVehicle!,
        location: _deliveryLocation!,
        station: _selectedStation!,
      );
      _activeOrder = _activeOrder!.copyWith(paymentMethod: paymentMethod);
      _orderHistory = _repository.getOrderHistory();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isPlacingOrder = false;
      notifyListeners();
    }
  }

  void setPaymentMethod(String method) {
    if (_activeOrder == null) return;
    _activeOrder = _activeOrder!.copyWith(paymentMethod: method);
    notifyListeners();
  }

  Future<bool> acceptOrder() async {
    final id = _activeOrder?.id;
    if (id == null) return false;
    try {
      _activeOrder = await _repository.acceptOrder(id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<FuelOrder?> cancelOrder() async {
    final id = _activeOrder?.id;
    if (id == null) return null;
    stopTracking();
    try {
      _activeOrder = await _repository.cancelOrder(id);
      _orderHistory = _repository.getOrderHistory();
      notifyListeners();
      return _activeOrder;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<FuelOrder?> completeOrder() async {
    final id = _activeOrder?.id;
    if (id == null) return null;
    stopTracking();
    try {
      _activeOrder = await _repository.completeOrder(id);
      _orderHistory = _repository.getOrderHistory();
      notifyListeners();
      return _activeOrder;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  // ── Tracking ──────────────────────────────────────────────────────────

  void startTracking(String orderId) {
    _isTracking = true;
    notifyListeners();
    _pollTracking(orderId);

    _trackingTimer?.cancel();
    _trackingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _pollTracking(orderId);
    });
  }

  Future<void> _pollTracking(String orderId) async {
    try {
      final advanced = await _repository.advanceStatus(orderId);
      final order = _repository.getOrderById(orderId);
      if (order != null) _activeOrder = order;

      if (order?.status == OrderStatus.delivered || advanced?.status == OrderStatus.delivered) {
        await completeOrder();
        notifyListeners();
        return;
      }
      if (order != null && !order.status.isTerminal) {
        _trackingInfo = await _repository.getTracking(orderId);
      }
      notifyListeners();
    } catch (_) {
      notifyListeners();
    }
  }

  void stopTracking() {
    _trackingTimer?.cancel();
    _trackingTimer = null;
    _isTracking = false;
    notifyListeners();
  }

  // ── Receipt ───────────────────────────────────────────────────────────

  Future<Invoice> generateInvoice() async {
    final id = _activeOrder?.id;
    if (id == null) throw StateError('No active order');
    final invoice = await _repository.generateInvoice(id);
    _activeOrder = _activeOrder!.copyWith(invoice: invoice);
    notifyListeners();
    return invoice;
  }

  /// Loads an invoice for an arbitrary (e.g. history) order without
  /// changing the active order.
  Future<Invoice> generateInvoiceForOrder(FuelOrder order) {
    return _repository.generateInvoice(order.id);
  }

  /// Brings a previously created order into the active slot so tracking
  /// and receipts can operate on it.
  void openOrder(FuelOrder order) {
    _activeOrder = order;
    _trackingInfo = null;
    notifyListeners();
  }

  // ── Reset ─────────────────────────────────────────────────────────────

  void resetRequest() {
    _selectedFuelType = null;
    _selectedVehicle = null;
    _deliveryLocation = null;
    _deliveryAddress = '';
    _deliveryPincode = '';
    _locationStatus = LocationBannerState.idle;
    _isDetectingLocation = false;
    _selectedStation = null;
    _quantity = FuelConstants.defaultLitres;
    _priceEstimate = null;
    notifyListeners();
  }

  void reset() {
    stopTracking();
    _state = FuelScreenState.initial;
    _errorMessage = null;
    _activeOrder = null;
    _trackingInfo = null;
    _stations = [];
    resetRequest();
  }

  @override
  void dispose() {
    _trackingTimer?.cancel();
    super.dispose();
  }
}
