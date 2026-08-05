import 'package:flutter/foundation.dart';
import 'package:mecha_connect/features/home/models/home_models.dart';
import 'package:mecha_connect/features/home/repositories/home_repository.dart';

class HomeProvider extends ChangeNotifier {
  final HomeRepository _repository;

  bool _isLoading = false;
  bool _isRefreshing = false;
  String? _error;
  HomeData? _data;

  HomeProvider(this._repository);

  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  String? get error => _error;
  HomeData? get data => _data;

  UserProfile get user => _data?.user ?? const UserProfile();
  LocationInfo get location => _data?.location ?? const LocationInfo();
  VehicleInfo get vehicle => _data?.vehicle ?? const VehicleInfo();
  List<QuickService> get quickServices => _data?.quickServices ?? const [];
  List<NearbyService> get nearbyServices => _data?.nearbyServices ?? const [];
  List<MarketplaceItem> get marketplaceItems => _data?.marketplaceItems ?? const [];
  List<ActivityItem> get activities => _data?.activities ?? const [];
  List<OfferInfo> get offers => _data?.offers ?? const [];

  String greetingForHour(int hour) {
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Future<void> load() async {
    if (_isLoading || _data != null) return;
    await _fetch();
  }

  Future<void> refresh() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    notifyListeners();
    await _fetch();
    _isRefreshing = false;
    notifyListeners();
  }

  Future<void> _fetch() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _data = await _repository.fetchHomeData();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
