import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mecha_connect/features/mechanic/models/models.dart';
import 'package:mecha_connect/features/mechanic/providers/mechanic_provider.dart';
import 'package:mecha_connect/features/mechanic/repositories/mechanic_repository.dart';
import 'package:mecha_connect/features/mechanic/screens/mechanic_home_screen.dart';
import 'package:mecha_connect/features/mechanic/services/mechanic_form_validator.dart';
import 'package:provider/provider.dart';

Widget _wrap(Widget child) {
  return ChangeNotifierProvider(
    create: (_) => MechanicProvider(),
    child: MaterialApp(home: child),
  );
}

void main() {
  group('MechanicFormValidator', () {
    test('rejects an empty form', () {
      final error = MechanicFormValidator.validateVehicleForm();
      expect(error, 'Please select a vehicle type');
    });

    test('rejects a short problem description', () {
      final error = MechanicFormValidator.validateVehicleForm(
        vehicleType: 'Bike',
        brand: 'Honda',
        model: 'Activa 6G',
        fuelType: 'Petrol',
        registration: 'KA 01 AB 1234',
        problem: 'Noise',
        address: '123 Main Road, Surampalem',
        pincode: '533437',
      );
      expect(error, 'Please describe the problem in more detail');
    });

    test('rejects an invalid registration number', () {
      final error = MechanicFormValidator.validateRegistration('12345');
      expect(error, contains('valid registration'));
    });

    test('accepts a fully valid form', () {
      final error = MechanicFormValidator.validateVehicleForm(
        vehicleType: 'Bike',
        brand: 'Honda',
        model: 'Activa 6G',
        fuelType: 'Petrol',
        registration: 'KA 01 AB 1234',
        problem: 'Engine overheating while riding',
        address: '123 Main Road, Surampalem',
        pincode: '533437',
      );
      expect(error, isNull);
    });
  });

  group('MechanicRepository', () {
    test('seeds booking history on construction', () async {
      final repository = MechanicRepository();
      final history = repository.getBookingHistory();
      expect(history.length, 3);
      expect(history.where((b) => b.status == BookingStatus.completed).length, 2);
      expect(history.where((b) => b.status == BookingStatus.cancelled).length, 1);
    });

    test('creates and cancels a booking', () async {
      final repository = MechanicRepository();
      final booking = await repository.createBooking(
        mechanic: mockMechanics[0],
        service: generalServices[0],
        vehicle: 'Honda Activa 6G',
        address: '123, Main Road',
        estimatedCost: 499,
      );

      expect(booking.status, BookingStatus.requested);
      expect(booking.bookingId, startsWith('MEC'));

      final cancelled = await repository.cancelBooking(booking.bookingId);
      expect(cancelled.status, BookingStatus.cancelled);
    });

    test('fetches mechanics and reviews', () async {
      final repository = MechanicRepository();
      final mechanics = await repository.fetchMechanics();
      expect(mechanics.length, greaterThan(0));
      expect(mechanics.every((m) => m.name.isNotEmpty), isTrue);

      final reviews = await repository.fetchReviews('m1');
      expect(reviews.length, greaterThan(0));
    });
  });

  group('MechanicProvider', () {
    test('loads home data and moves to ready state', () async {
      final provider = MechanicProvider();
      await provider.loadHome();

      expect(provider.state, MechanicScreenState.ready);
      expect(provider.mechanics.length, greaterThan(0));
      expect(provider.featuredMechanics.length, greaterThan(0));
      expect(provider.categories.length, greaterThan(0));
    });

    test('createBooking sets active booking and request status', () async {
      final provider = MechanicProvider();
      provider.setBookingRequest(
        const BookingRequest(
          vehicleType: 'Bike',
          brand: 'Honda',
          model: 'Activa 6G',
          fuelType: 'Petrol',
          registration: 'KA 01 AB 1234',
          problemDescription: 'Brake noise on application',
          address: '123 Main Road',
        ),
      );

      final booking = await provider.createBooking(
        mechanic: mockMechanics[1],
        service: generalServices[2],
      );

      expect(provider.activeBooking?.bookingId, booking.bookingId);
      expect(provider.requestStatus, BookingStatus.requested);
      expect(provider.selectedVehicle, 'Honda Activa 6G');
      expect(provider.bookingHistory.length, greaterThan(0));
    });
  });

  group('MechanicHomeScreen', () {
    testWidgets('renders core sections after loading', (tester) async {
      await tester.pumpWidget(_wrap(const MechanicHomeScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Mechanic'), findsOneWidget);
      expect(find.text('Categories'), findsOneWidget);
      expect(find.text('Featured Mechanics'), findsOneWidget);
      expect(find.text('Nearby Mechanics'), findsOneWidget);
      expect(find.text('Emergency Mechanic'), findsOneWidget);
    });
  });
}
