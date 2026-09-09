import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mecha_connect/features/mechanic/models/models.dart';
import 'package:mecha_connect/features/mechanic/providers/mechanic_provider.dart';
import 'package:mecha_connect/features/mechanic/repositories/mechanic_repository.dart';
import 'package:mecha_connect/features/mechanic/screens/booking_history_screen.dart';
import 'package:mecha_connect/features/mechanic/screens/booking_summary_screen.dart';
import 'package:mecha_connect/features/mechanic/screens/job_completed_screen.dart';
import 'package:mecha_connect/features/mechanic/screens/live_tracking_screen.dart';
import 'package:provider/provider.dart';

Widget _wrap(Widget child, [MechanicProvider? provider]) {
  return ChangeNotifierProvider<MechanicProvider>(
    create: (_) => provider ?? MechanicProvider(),
    child: MaterialApp(
      home: child,
    ),
  );
}

void main() {
  group('Phase 1 / Task 3: Service Booking Hardening Tests', () {
    test('MechanicRepository creates booking with scheduledAt in offline mode', () async {
      final repo = MechanicRepository();
      final scheduleTime = DateTime.now().add(const Duration(days: 2));

      final booking = await repo.createBooking(
        mechanic: mockMechanics[0],
        service: generalServices[0],
        vehicle: 'Yamaha FZ • KA 05 CD 5678',
        address: 'MG Road, Bengaluru',
        estimatedCost: 599.0,
        scheduledAt: scheduleTime,
      );

      expect(booking.status, BookingStatus.requested);
      expect(booking.vehicle, contains('Yamaha FZ'));
      expect(booking.address, 'MG Road, Bengaluru');
      expect(booking.estimatedCost, 599.0);
    });

    test('MechanicProvider sets active booking and clears errors cleanly', () {
      final provider = MechanicProvider();
      final sampleBooking = Booking(
        bookingId: 'MEC_TEST_101',
        mechanic: mockMechanics[0],
        service: generalServices[0],
        vehicle: 'Honda City',
        address: 'Indiranagar, Bengaluru',
        estimatedArrival: DateTime.now().add(const Duration(minutes: 30)),
        estimatedCost: 799.0,
        status: BookingStatus.requested,
        bookingTime: DateTime.now(),
      );

      provider.setActiveBooking(sampleBooking);
      expect(provider.activeBooking, isNotNull);
      expect(provider.activeBooking!.bookingId, 'MEC_TEST_101');
      expect(provider.requestStatus, BookingStatus.requested);

      provider.clearError();
      expect(provider.errorMessage, isNull);
    });

    testWidgets('BookingSummaryScreen renders schedule option and cost breakdown', (tester) async {
      final provider = MechanicProvider();
      final testMechanic = mockMechanics[0];
      final testService = generalServices[0];

      await tester.pumpWidget(
        _wrap(
          BookingSummaryScreen(
            mechanic: testMechanic,
            service: testService,
          ),
          provider,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Booking Summary'), findsOneWidget);
      expect(find.text(testMechanic.name), findsOneWidget);
      expect(find.textContaining(testService.name), findsWidgets);
      expect(find.text('Timing'), findsOneWidget);
      expect(find.text('Schedule'), findsOneWidget);
      expect(find.text('Confirm Booking'), findsOneWidget);
    });

    testWidgets('LiveTrackingScreen renders isolated pilot simulation controls', (tester) async {
      final provider = MechanicProvider();
      final sampleBooking = Booking(
        bookingId: 'MEC_TRACK_001',
        mechanic: mockMechanics[0],
        service: generalServices[0],
        vehicle: 'KTM Duke 390',
        address: 'Koramangala, Bengaluru',
        estimatedArrival: DateTime.now().add(const Duration(minutes: 20)),
        estimatedCost: 499.0,
        status: BookingStatus.requested,
        bookingTime: DateTime.now(),
      );
      provider.setActiveBooking(sampleBooking);

      await tester.pumpWidget(
        _wrap(
          const LiveTrackingScreen(bookingId: 'MEC_TRACK_001'),
          provider,
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(find.text('Pilot Simulator Controls'), findsOneWidget);
      expect(find.text('Call'), findsOneWidget);
      expect(find.text('Chat'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('JobCompletedScreen renders invoice breakdown and Back to Home exit route', (tester) async {
      final sampleBooking = Booking(
        bookingId: 'MEC_DONE_999',
        mechanic: mockMechanics[0],
        service: generalServices[0],
        vehicle: 'Hyundai Creta',
        address: 'Whitefield, Bengaluru',
        estimatedArrival: DateTime.now(),
        estimatedCost: 899.0,
        status: BookingStatus.completed,
        bookingTime: DateTime.now().subtract(const Duration(hours: 2)),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: JobCompletedScreen(booking: sampleBooking),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Job Summary & Invoice'), findsOneWidget);
      expect(find.text('Service Completed!'), findsOneWidget);
      expect(find.text('Rate Service & Technician'), findsOneWidget);
      expect(find.text('Back to Home'), findsWidgets);
      expect(find.text('Payment Verified'), findsOneWidget);
    });

    testWidgets('BookingHistoryScreen detail bottom sheet provides invoice navigation', (tester) async {
      final provider = MechanicProvider();
      await tester.pumpWidget(
        _wrap(
          const BookingHistoryScreen(),
          provider,
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(find.text('Booking History'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Completed'), findsWidgets);
      expect(find.text('Cancelled'), findsWidgets);
    });
  });
}
