import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mecha_connect/features/mechanic/models/models.dart';
import 'package:mecha_connect/features/mechanic/providers/mechanic_provider.dart';
import 'package:mecha_connect/features/mechanic/repositories/mechanic_repository.dart';
import 'package:mecha_connect/features/mechanic/screens/rating_review_screen.dart';
import 'package:mecha_connect/features/orders/orders.dart';
import 'package:mecha_connect/bottom_bar/order_screen.dart';
import 'package:mecha_connect/services/api_client.dart';

class FakeMechanicRepository extends MechanicRepository {
  final Map<String, BookingRating> _store = {};
  bool shouldFailFetch = false;
  bool shouldFailSubmit = false;
  String failMessage = 'Simulated error';
  int submitCallCount = 0;
  int fetchCallCount = 0;

  @override
  Future<BookingRating?> fetchRating(String bookingId) async {
    fetchCallCount++;
    if (shouldFailFetch) {
      throw ApiException(statusCode: 500, message: failMessage);
    }
    return _store[bookingId];
  }

  @override
  Future<BookingRating> submitRating(
    String bookingId, {
    required double rating,
    String? review,
  }) async {
    submitCallCount++;
    if (shouldFailSubmit) {
      throw ApiException(statusCode: 400, message: failMessage);
    }
    final r = BookingRating(
      bookingId: bookingId,
      rating: rating,
      review: review,
    );
    _store[bookingId] = r;
    return r;
  }
}

Widget _buildTestApp({
  required Widget child,
  required MechanicProvider provider,
}) {
  return MaterialApp(
    home: ChangeNotifierProvider<MechanicProvider>.value(
      value: provider,
      child: child,
    ),
  );
}

void _setTestWindow(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

void main() {
  group('BookingRating Model', () {
    test('serializes and deserializes properly', () {
      final json = {
        'booking_id': 'b-123',
        'rating': 4.5,
        'review': 'Great work by mechanic',
      };
      final rating = BookingRating.fromJson(json);
      expect(rating.bookingId, 'b-123');
      expect(rating.rating, 4.5);
      expect(rating.review, 'Great work by mechanic');

      final output = rating.toJson();
      expect(output['booking_id'], 'b-123');
      expect(output['rating'], 4.5);
      expect(output['review'], 'Great work by mechanic');
    });

    test('handles null review and fallback booking ID', () {
      final json = {'rating': 5};
      final rating = BookingRating.fromJson(json);
      expect(rating.bookingId, '');
      expect(rating.rating, 5.0);
      expect(rating.review, isNull);
    });
  });

  group('MechanicProvider Rating Management', () {
    test('submits and caches rating', () async {
      final repo = FakeMechanicRepository();
      final provider = MechanicProvider(repository: repo);

      expect(provider.isSubmittingRating, isFalse);
      expect(provider.ratingError, isNull);

      final rating = await provider.submitRating(
        'b-1',
        rating: 5.0,
        review: 'Excellent service',
      );

      expect(rating.bookingId, 'b-1');
      expect(rating.rating, 5.0);
      expect(provider.getRating('b-1'), isNotNull);
      expect(provider.getRating('b-1')!.rating, 5.0);
      expect(provider.isSubmittingRating, isFalse);
      expect(provider.ratingError, isNull);
    });

    test('handles submission error gracefully', () async {
      final repo = FakeMechanicRepository()..shouldFailSubmit = true..failMessage = 'Only completed bookings can be rated.';
      final provider = MechanicProvider(repository: repo);

      await expectLater(
        provider.submitRating('b-2', rating: 4.0),
        throwsA(isA<ApiException>()),
      );
      expect(provider.ratingError, 'Only completed bookings can be rated.');
      expect(provider.isSubmittingRating, isFalse);

      provider.clearRatingError();
      expect(provider.ratingError, isNull);
    });

    test('fetches rating and caches in provider', () async {
      final repo = FakeMechanicRepository();
      final provider = MechanicProvider(repository: repo);

      await repo.submitRating('b-3', rating: 4.0, review: 'Fast turnaround');

      final fetched = await provider.fetchRating('b-3');
      expect(fetched, isNotNull);
      expect(fetched!.rating, 4.0);
      expect(provider.getRating('b-3')!.review, 'Fast turnaround');
    });
  });

  group('RatingReviewScreen Widget Tests', () {
    testWidgets('shows loading state initially while checking rating', (tester) async {
      _setTestWindow(tester);
      final repo = FakeMechanicRepository();
      final provider = MechanicProvider(repository: repo);

      await tester.pumpWidget(
        _buildTestApp(
          provider: provider,
          child: const RatingReviewScreen(
            bookingId: 'b-loading',
            serviceName: 'Brake Repair',
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Checking service details...'), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.text('How was your service?'), findsOneWidget);
    });

    testWidgets('validates 1-5 star selection before submission', (tester) async {
      _setTestWindow(tester);
      final repo = FakeMechanicRepository();
      final provider = MechanicProvider(repository: repo);

      await tester.pumpWidget(
        _buildTestApp(
          provider: provider,
          child: const RatingReviewScreen(
            bookingId: 'b-val',
            serviceName: 'Oil Change',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Attempt submit without stars
      await tester.tap(find.text('Submit Review'));
      await tester.pump();

      expect(find.text('Please select a rating between 1 and 5 stars.'), findsOneWidget);
      expect(repo.submitCallCount, 0);
    });

    testWidgets('selects 5 stars and submits review successfully', (tester) async {
      _setTestWindow(tester);
      final repo = FakeMechanicRepository();
      final provider = MechanicProvider(repository: repo);

      await tester.pumpWidget(
        _buildTestApp(
          provider: provider,
          child: const RatingReviewScreen(
            bookingId: 'b-sub',
            serviceName: 'Tire Replacement',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Select 5th star
      final starFinder = find.bySemanticsLabel('5 stars');
      expect(starFinder, findsOneWidget);
      await tester.tap(starFinder);
      await tester.pump();

      // Enter review comment
      await tester.enterText(
        find.byType(TextField),
        'Quick and polite mechanic!',
      );
      await tester.pump();

      // Submit
      await tester.tap(find.text('Submit Review'));
      await tester.pump(); // Start submission

      await tester.pumpAndSettle(); // Complete submission animation

      expect(find.text('Thank You!'), findsOneWidget);
      expect(find.text('Your feedback helps us improve'), findsOneWidget);
      expect(find.text('Quick and polite mechanic!'), findsOneWidget);
      expect(repo.submitCallCount, 1);
    });

    testWidgets('displays already-reviewed state when booking was previously rated', (tester) async {
      _setTestWindow(tester);
      final repo = FakeMechanicRepository();
      await repo.submitRating(
        'b-already',
        rating: 4.0,
        review: 'Service was completed on time',
      );
      final provider = MechanicProvider(repository: repo);

      await tester.pumpWidget(
        _buildTestApp(
          provider: provider,
          child: const RatingReviewScreen(
            bookingId: 'b-already',
            serviceName: 'Engine Tuning',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Review Submitted'), findsOneWidget);
      expect(find.text('4.0 out of 5'), findsOneWidget);
      expect(find.text('Service was completed on time'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);
      expect(find.text('Submit Review'), findsNothing);
    });

    testWidgets('displays initial error and allows retry when fetch fails', (tester) async {
      _setTestWindow(tester);
      final repo = FakeMechanicRepository()
        ..shouldFailFetch = true
        ..failMessage = 'Network connection timed out';
      final provider = MechanicProvider(repository: repo);

      await tester.pumpWidget(
        _buildTestApp(
          provider: provider,
          child: const RatingReviewScreen(
            bookingId: 'b-err',
            serviceName: 'General Service',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Unable to Load Review'), findsOneWidget);
      expect(find.text('Network connection timed out'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      // Fix network and tap Retry
      repo.shouldFailFetch = false;
      await tester.tap(find.text('Retry'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('How was your service?'), findsOneWidget);
    });

    testWidgets('displays API submission error and allows retry', (tester) async {
      _setTestWindow(tester);
      final repo = FakeMechanicRepository()
        ..shouldFailSubmit = true
        ..failMessage = 'This booking has already been rated.';
      final provider = MechanicProvider(repository: repo);

      await tester.pumpWidget(
        _buildTestApp(
          provider: provider,
          child: const RatingReviewScreen(
            bookingId: 'b-sub-err',
            serviceName: 'General Service',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap 4 stars
      await tester.tap(find.bySemanticsLabel('4 stars'));
      await tester.pump();

      // Tap submit
      await tester.tap(find.text('Submit Review'));
      await tester.pumpAndSettle();

      expect(find.text('This booking has already been rated.'), findsOneWidget);

      // Allow retry
      repo.shouldFailSubmit = false;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('Thank You!'), findsOneWidget);
    });

    testWidgets('completed mechanic order in Orders tab shows Rate / Review Service button', (tester) async {
      _setTestWindow(tester);
      final ordersRepo = OrdersRepository(
        mockOrders: [
          const UnifiedOrder(
            id: 'ORD-MEC-COMPLETED',
            name: 'Periodic Maintenance',
            brand: 'Yamaha',
            quantity: 1,
            price: 1200.0,
            type: 'mechanic',
            status: 'Completed',
            date: 'Today',
          ),
        ],
      );
      final ordersProvider = OrdersProvider(repository: ordersRepo);
      final mechanicRepo = FakeMechanicRepository();
      final mechanicProvider = MechanicProvider(repository: mechanicRepo);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<OrdersProvider>.value(value: ordersProvider),
            ChangeNotifierProvider<MechanicProvider>.value(value: mechanicProvider),
          ],
          child: const MaterialApp(home: Orderscreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Periodic Maintenance'), findsOneWidget);

      // Tap the order to open bottom sheet details
      await tester.tap(find.text('Periodic Maintenance'));
      await tester.pumpAndSettle();

      expect(find.text('Rate / Review Service'), findsOneWidget);

      // Tap 'Rate / Review Service'
      await tester.tap(find.text('Rate / Review Service'));
      await tester.pumpAndSettle();

      expect(find.text('How was your service?'), findsOneWidget);
    });
  });
}
