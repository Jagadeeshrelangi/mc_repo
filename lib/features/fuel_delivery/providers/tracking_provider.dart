import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../repositories/fuel_repository.dart';

class TrackingProvider extends ChangeNotifier {
  final FuelRepository _repository = FuelRepository();

  TrackingInfo? _trackingInfo;
  TrackingInfo? get trackingInfo => _trackingInfo;

  bool _isTracking = false;
  bool get isTracking => _isTracking;

  Timer? _pollTimer;

  void startTracking(String orderId) {
    _isTracking = true;
    _poll();

    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _poll();
    });
  }

  void _poll() {
    try {
      _repository.trackOrder('').then((info) {
        _trackingInfo = info;
        notifyListeners();
      }).catchError((_) {});
    } catch (_) {}
  }

  void stopTracking() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _isTracking = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}
