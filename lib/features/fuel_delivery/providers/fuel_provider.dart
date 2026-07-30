import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../repositories/fuel_repository.dart';
import '../services/fuel_service.dart';

enum FuelScreenState { initial, loading, ready, error, noLocation, noInternet, empty }

class FuelProvider extends ChangeNotifier {
  final FuelRepository _repository = FuelRepository();
  final FuelService _fuelService = FuelService();

  FuelScreenState _state = FuelScreenState.initial;
  FuelScreenState get state => _state;

  List<FuelType> _fuelTypes = [];
  List<FuelType> get fuelTypes => _fuelTypes;

  FuelType? _selectedFuelType;
  FuelType? get selectedFuelType => _selectedFuelType;

  double _quantity = 5;
  double get quantity => _quantity;

  PriceEstimate? _priceEstimate;
  PriceEstimate? get priceEstimate => _priceEstimate;

  List<FuelPartner> _partners = [];
  List<FuelPartner> get partners => _partners;

  bool _isSearching = false;
  bool get isSearching => _isSearching;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void loadFuelTypes() {
    _state = FuelScreenState.ready;
    _fuelTypes = _repository.getFuelTypes();
    notifyListeners();
  }

  void selectFuelType(FuelType type) {
    _selectedFuelType = type;
    _calculatePrice();
    notifyListeners();
  }

  void setQuantity(double value) {
    _quantity = value.clamp(1, 20);
    _calculatePrice();
    notifyListeners();
  }

  void _calculatePrice() {
    if (_selectedFuelType == null) return;
    _priceEstimate = _fuelService.calculatePrice(_selectedFuelType!, _quantity);
  }

  void runSearch() {
    if (_selectedFuelType == null) return;
    _isSearching = true;
    _state = FuelScreenState.loading;
    _errorMessage = null;
    notifyListeners();

    _partners = _repository.getNearbyPartners(latitude: 12.97, longitude: 77.59);

    Timer(const Duration(seconds: 2), () {
      if (_partners.any((p) => p.isAvailable)) {
        _isSearching = false;
        _state = FuelScreenState.ready;
      } else {
        _isSearching = false;
        _state = FuelScreenState.empty;
        _errorMessage = 'No delivery partners available nearby';
      }
      notifyListeners();
    });
  }

  void setError(FuelScreenState errorState, String message) {
    _state = errorState;
    _errorMessage = message;
    notifyListeners();
  }

  void reset() {
    _state = FuelScreenState.initial;
    _selectedFuelType = null;
    _quantity = 5;
    _priceEstimate = null;
    _partners = [];
    _isSearching = false;
    _errorMessage = null;
    notifyListeners();
  }
}
