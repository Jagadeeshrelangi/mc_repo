import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../repositories/fuel_repository.dart';

enum OrderState { initial, creating, created, assigning, assigned, cancelling, cancelled, error }

class OrderProvider extends ChangeNotifier {
  final FuelRepository _repository = FuelRepository();

  OrderState _state = OrderState.initial;
  OrderState get state => _state;

  FuelOrder? _currentOrder;
  FuelOrder? get currentOrder => _currentOrder;

  List<FuelOrder> _orderHistory = [];
  List<FuelOrder> get orderHistory => _orderHistory;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void loadHistory() {
    _orderHistory = _repository.getOrderHistory();
    notifyListeners();
  }

  Future<void> createOrder({
    required FuelType fuelType,
    required double quantity,
    required String vehicleName,
    required String vehicleNumber,
    required DeliveryLocation location,
  }) async {
    _state = OrderState.creating;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentOrder = await _repository.createOrder(
        fuelType: fuelType,
        quantity: quantity,
        vehicleName: vehicleName,
        vehicleNumber: vehicleNumber,
        location: location,
      );
      _state = OrderState.created;
    } catch (e) {
      _state = OrderState.error;
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> assignPartner() async {
    if (_currentOrder == null) return;

    _state = OrderState.assigning;
    _isLoading = true;
    notifyListeners();

    try {
      _currentOrder = await _repository.assignPartner(_currentOrder!.id);
      _state = OrderState.assigned;
    } catch (e) {
      _state = OrderState.error;
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> cancelOrder() async {
    if (_currentOrder == null) return;

    _state = OrderState.cancelling;
    _isLoading = true;
    notifyListeners();

    try {
      _currentOrder = await _repository.cancelOrder(_currentOrder!.id);
      _state = OrderState.cancelled;
    } catch (e) {
      _state = OrderState.error;
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  void reset() {
    _state = OrderState.initial;
    _currentOrder = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
}
