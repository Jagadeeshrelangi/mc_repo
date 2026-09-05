import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mecha_connect/features/home/models/home_models.dart';
import 'package:mecha_connect/features/profile/models/vehicle.dart';
import 'package:mecha_connect/services/api_client.dart';

/// Data repository for the Home dashboard connecting with live backend endpoints.
class HomeRepository {
  final ApiClient _apiClient;

  HomeRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<HomeData> fetchHomeData() async {
    // 1. Fetch user profile if logged in
    UserProfile user = const UserProfile();
    try {
      final token = await _apiClient.getAccessToken();
      if (token != null && token.isNotEmpty) {
        final res = await _apiClient.get('/api/v1/users/me', requiresAuth: true);
        if (res is Map<String, dynamic>) {
          user = UserProfile(
            name: (res['name'] ?? '').toString(),
            greeting: '',
            avatarUrl: (res['avatar_url'] ?? '').toString(),
          );
        }
      }
    } catch (e) {
      debugPrint('HomeRepository.fetchHomeData (user): $e');
    }

    // 2. Fetch mechanics for nearby services
    List<NearbyService> nearbyServices = [];
    try {
      final res = await _apiClient.get('/api/v1/mechanic/mechanics', requiresAuth: false);
      if (res is List) {
        nearbyServices = res.map((m) {
          final item = m as Map<String, dynamic>;
          final name = (item['name'] ?? 'Garage').toString();
          final rating = (item['rating'] as num?)?.toDouble() ?? 4.5;
          final address = (item['address'] ?? 'Nearby').toString();
          final category = (item['specialty'] ?? item['category'] ?? 'Mechanic').toString();
          return NearbyService(
            name: name,
            distance: address,
            rating: rating,
            category: category,
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('HomeRepository.fetchHomeData (mechanics): $e');
    }

    // 3. Fetch marketplace products for preview
    List<MarketplaceItem> marketplaceItems = [];
    try {
      final res = await _apiClient.get('/api/v1/marketplace/products', requiresAuth: false);
      if (res is List) {
        marketplaceItems = res.take(6).map((p) {
          final item = p as Map<String, dynamic>;
          final name = (item['name'] ?? 'Part').toString();
          final price = (item['price'] as num?)?.toDouble() ?? 0.0;
          return MarketplaceItem(
            name: name,
            price: '₹${price.toStringAsFixed(0)}',
            icon: Icons.build_circle_outlined,
            imageUrl: (item['image_url'] ?? '').toString(),
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('HomeRepository.fetchHomeData (marketplace): $e');
    }

    // 4. Fetch marketplace active offers
    List<OfferInfo> offers = [];
    try {
      final res = await _apiClient.get('/api/v1/marketplace/offers', requiresAuth: false);
      if (res is List) {
        offers = res.map((o) {
          final item = o as Map<String, dynamic>;
          final title = (item['title'] ?? 'Special Offer').toString();
          final discount = (item['discount_percent'] != null
                  ? '${item['discount_percent']}% OFF'
                  : item['discount'] ?? 'OFFER')
              .toString();
          final description = (item['description'] ?? '').toString();
          final code = (item['code'] ?? '').toString();
          return OfferInfo(
            title: title,
            discount: discount,
            description: description,
            code: code,
            gradientStart: const Color(0xFFF15A22),
            gradientEnd: const Color(0xFFD44A15),
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('HomeRepository.fetchHomeData (offers): $e');
    }

    // 5. Fetch user recent activity from all 3 domains (Fuel, Mechanics, Marketplace)
    List<ActivityItem> activities = [];
    try {
      final token = await _apiClient.getAccessToken();
      if (token != null && token.isNotEmpty) {
        final results = await Future.wait([
          _apiClient.get('/api/v1/fuel/orders', requiresAuth: true).catchError((e) {
            debugPrint('Home: fetch fuel orders error: $e');
            return <dynamic>[];
          }),
          _apiClient.get('/api/v1/mechanic/bookings', requiresAuth: true).catchError((e) {
            debugPrint('Home: fetch mechanic bookings error: $e');
            return <dynamic>[];
          }),
          _apiClient.get('/api/v1/marketplace/orders', requiresAuth: true).catchError((e) {
            debugPrint('Home: fetch marketplace orders error: $e');
            return <dynamic>[];
          }),
        ]);

        final fuelOrders = results[0];
        final mechanicBookings = results[1];
        final marketplaceOrders = results[2];

        // 5a. Fuel orders mapping
        if (fuelOrders is List) {
          for (final o in fuelOrders) {
            if (o is! Map<String, dynamic>) continue;
            final fuelType = (o['fuel_type'] ?? 'Fuel').toString().toUpperCase();
            final quantity = o['quantity'] != null ? '${o['quantity']}L ' : '';
            final status = (o['status'] ?? 'pending').toString();
            final isCompleted = status.toLowerCase() == 'completed' || status.toLowerCase() == 'delivered';
            final isCancelled = status.toLowerCase() == 'cancelled';
            final timestamp = o['created_at'] != null ? DateTime.tryParse(o['created_at'].toString()) : null;

            activities.add(ActivityItem(
              title: '$quantity$fuelType Delivery',
              status: _capitalize(status),
              icon: Icons.local_gas_station_rounded,
              statusColor: isCompleted
                  ? const Color(0xFF10B981)
                  : isCancelled
                      ? const Color(0xFFEF4444)
                      : const Color(0xFFF59E0B),
              isCompleted: isCompleted,
              timestamp: timestamp,
              type: 'fuel',
            ));
          }
        }

        // 5b. Mechanic bookings mapping
        if (mechanicBookings is List) {
          for (final b in mechanicBookings) {
            if (b is! Map<String, dynamic>) continue;
            final status = (b['status'] ?? 'requested').toString();
            final isCompleted = status.toLowerCase() == 'completed';
            final isCancelled = status.toLowerCase() == 'cancelled';
            final timestamp = b['created_at'] != null ? DateTime.tryParse(b['created_at'].toString()) : null;

            activities.add(ActivityItem(
              title: 'Mechanic Service',
              status: _capitalize(status),
              icon: Icons.build_circle_rounded,
              statusColor: isCompleted
                  ? const Color(0xFF10B981)
                  : isCancelled
                      ? const Color(0xFFEF4444)
                      : const Color(0xFFF59E0B),
              isCompleted: isCompleted,
              timestamp: timestamp,
              type: 'mechanic',
            ));
          }
        }

        // 5c. Marketplace orders mapping
        if (marketplaceOrders is List) {
          for (final m in marketplaceOrders) {
            if (m is! Map<String, dynamic>) continue;
            final status = (m['status'] ?? 'placed').toString();
            final isCompleted = status.toLowerCase() == 'delivered' || status.toLowerCase() == 'completed';
            final isCancelled = status.toLowerCase() == 'cancelled';
            final timestamp = m['created_at'] != null ? DateTime.tryParse(m['created_at'].toString()) : null;
            final items = m['items'] as List<dynamic>?;
            String title = 'Marketplace Order';
            if (items != null && items.isNotEmpty && items[0] is Map<String, dynamic>) {
              final firstItemName = (items[0]['product_name'] ?? 'Item').toString();
              title = items.length > 1
                  ? '$firstItemName + ${items.length - 1} more'
                  : firstItemName;
            }

            activities.add(ActivityItem(
              title: title,
              status: _capitalize(status),
              icon: Icons.shopping_bag_rounded,
              statusColor: isCompleted
                  ? const Color(0xFF10B981)
                  : isCancelled
                      ? const Color(0xFFEF4444)
                      : const Color(0xFFF59E0B),
              isCompleted: isCompleted,
              timestamp: timestamp,
              type: 'marketplace',
            ));
          }
        }

        // Sort unified activities newest first
        activities.sort((a, b) {
          if (a.timestamp == null && b.timestamp == null) return 0;
          if (a.timestamp == null) return 1;
          if (b.timestamp == null) return -1;
          return b.timestamp!.compareTo(a.timestamp!);
        });

        // Limit to 5 most recent activities on dashboard
        if (activities.length > 5) {
          activities = activities.sublist(0, 5);
        }
      }
    } catch (e) {
      debugPrint('HomeRepository.fetchHomeData (activities): $e');
    }

    // 6. Fetch default vehicle if logged in
    VehicleInfo vehicle = const VehicleInfo(name: '');
    try {
      final token = await _apiClient.getAccessToken();
      if (token != null && token.isNotEmpty) {
        final res = await _apiClient.get('/api/v1/vehicles', requiresAuth: true);
        if (res is List && res.isNotEmpty) {
          final vehicles = res
              .whereType<Map<String, dynamic>>()
              .map((j) => ProfileVehicle.fromJson(j))
              .toList();
          if (vehicles.isNotEmpty) {
            final defaultVeh = vehicles.firstWhere(
              (v) => v.isDefault,
              orElse: () => vehicles.first,
            );
            final now = DateTime.now();
            String insuranceStatus = 'N/A';
            if (defaultVeh.insuranceExpiry != null) {
              insuranceStatus =
                  defaultVeh.insuranceExpiry!.isAfter(now) ? 'Valid' : 'Expired';
            }
            String serviceInfo = 'Up to date';
            if (defaultVeh.serviceDueKm != null) {
              serviceInfo = 'Due at ${defaultVeh.serviceDueKm} km';
            } else if (defaultVeh.serviceDueDate != null) {
              serviceInfo =
                  'Due ${defaultVeh.serviceDueDate!.toIso8601String().split('T').first}';
            }

            vehicle = VehicleInfo(
              name: defaultVeh.name,
              healthPercent: defaultVeh.healthScore,
              fuelPercent: 100,
              battery: 'Good',
              insurance: insuranceStatus,
              lastService: serviceInfo,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('HomeRepository.fetchHomeData (vehicles): $e');
    }

    return HomeData(
      user: user,
      location: const LocationInfo(),
      vehicle: vehicle,
      quickServices: mockQuickServices,
      nearbyServices: nearbyServices,
      marketplaceItems: marketplaceItems,
      activities: activities,
      offers: offers,
    );
  }

  static String _capitalize(String value) {
    if (value.isEmpty) return value;
    final cleaned = value.replaceAll('_', ' ');
    return cleaned.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}
