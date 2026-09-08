import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mecha_connect/features/ai/models/models.dart';
import 'package:mecha_connect/features/ai/repositories/ai_repository.dart';
import 'package:mecha_connect/features/ai/services/ai_service.dart';
import 'package:mecha_connect/features/ai/services/diagnosis_service.dart';
import 'package:mecha_connect/features/auth/repositories/auth_repository.dart';
import 'package:mecha_connect/features/mechanic/models/models.dart';
import 'package:mecha_connect/features/mechanic/repositories/mechanic_repository.dart';
import 'package:mecha_connect/features/profile/models/models.dart';
import 'package:mecha_connect/features/profile/repositories/profile_repository.dart';
import 'package:mecha_connect/services/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ApiClient Token Lifecycle & Auth Header', () {
    test('saves, retrieves, and clears JWT tokens', () async {
      final client = ApiClient(baseUrl: 'http://test-server.local');
      await client.saveTokens(
        accessToken: 'mock-access-token',
        refreshToken: 'mock-refresh-token',
      );

      expect(await client.getAccessToken(), 'mock-access-token');
      expect(await client.getRefreshToken(), 'mock-refresh-token');

      await client.clearTokens();
      expect(await client.getAccessToken(), isNull);
      expect(await client.getRefreshToken(), isNull);
    });

    test('AuthRepository.logout sends refresh_token in body and clears tokens', () async {
      late http.BaseRequest capturedRequest;
      String? capturedBody;

      final mockHttp = MockClient((request) async {
        capturedRequest = request;
        capturedBody = request.body;
        return http.Response(jsonEncode({'message': 'Successfully logged out'}), 200);
      });

      final client = ApiClient(baseUrl: 'http://test-server.local', client: mockHttp);
      await client.saveTokens(
        accessToken: 'test-access-token',
        refreshToken: 'valid-refresh-token-xyz',
      );

      final repo = AuthRepository(apiClient: client);
      await repo.logout();

      expect(capturedRequest.url.path, '/api/v1/auth/logout');
      expect(capturedRequest.method, 'POST');
      expect(jsonDecode(capturedBody!), {'refresh_token': 'valid-refresh-token-xyz'});
      expect(await client.getAccessToken(), isNull);
      expect(await client.getRefreshToken(), isNull);
    });

    test('AuthRepository.logout clears local tokens even on server error', () async {
      final mockHttp = MockClient((request) async {
        return http.Response(jsonEncode({'detail': 'Server error'}), 500);
      });

      final client = ApiClient(baseUrl: 'http://test-server.local', client: mockHttp);
      await client.saveTokens(
        accessToken: 'test-access-token',
        refreshToken: 'valid-refresh-token-xyz',
      );

      final repo = AuthRepository(apiClient: client);
      await repo.logout();

      expect(await client.getAccessToken(), isNull);
      expect(await client.getRefreshToken(), isNull);
    });

    test('AuthRepository.logout handles repeated logout without tokens safely', () async {
      final mockHttp = MockClient((request) async {
        return http.Response(jsonEncode({'message': 'ok'}), 200);
      });

      final client = ApiClient(baseUrl: 'http://test-server.local', client: mockHttp);
      final repo = AuthRepository(apiClient: client);

      expect(await client.getRefreshToken(), isNull);
      await repo.logout();
      expect(await client.getAccessToken(), isNull);
      expect(await client.getRefreshToken(), isNull);
    });

    test('injects Bearer token in authenticated requests', () async {
      late http.BaseRequest capturedRequest;

      final mockHttp = MockClient((request) async {
        capturedRequest = request;
        return http.Response(jsonEncode({'status': 'ok'}), 200);
      });

      final client = ApiClient(baseUrl: 'http://test-server.local', client: mockHttp);
      await client.saveTokens(accessToken: 'my-jwt-token', refreshToken: 'my-refresh-token');

      await client.get('/api/v1/users/me', requiresAuth: true);

      expect(capturedRequest.headers['Authorization'], 'Bearer my-jwt-token');
      expect(capturedRequest.url.path, '/api/v1/users/me');
    });

    test('automatically refreshes token on 401 and retries request', () async {
      int attempts = 0;

      final mockHttp = MockClient((request) async {
        if (request.url.path == '/api/v1/diagnosis/diagnose') {
          attempts++;
          if (attempts == 1) {
            return http.Response(jsonEncode({'detail': 'Token expired'}), 401);
          }
          return http.Response(jsonEncode({'predicted_fault': 'Normal', 'confidence': 1.0}), 200);
        } else if (request.url.path == '/api/v1/auth/refresh') {
          return http.Response(
            jsonEncode({'access_token': 'new-valid-token', 'refresh_token': 'new-refresh-token'}),
            200,
          );
        }
        return http.Response('Not found', 404);
      });

      final client = ApiClient(baseUrl: 'http://test-server.local', client: mockHttp);
      await client.saveTokens(accessToken: 'expired-token', refreshToken: 'valid-refresh-token');

      final result = await client.post('/api/v1/diagnosis/diagnose', body: {'mileage': 50000});

      expect(result['predicted_fault'], 'Normal');
      expect(await client.getAccessToken(), 'new-valid-token');
      expect(attempts, 2);
    });
  });

  group('DiagnosisService Backend Contract Parsing', () {
    test('seamlessly parses real FastAPI DiagnosisResponse payload', () {
      final service = DiagnosisService();

      final backendResponse = {
        'predicted_fault': 'Engine Misfire',
        'confidence': 0.95,
        'estimated_cost': 1800,
        'repair_time': '3 hours',
        'safety_advice': 'IMPORTANT: Drive at low speeds and check spark plug immediately.',
        'diagnosis_mode': 'symptom',
        'created_at': '2026-08-19T12:00:00Z',
      };

      final diagnosis = service.parseDiagnosis(
        backendResponse,
        vehicleName: 'Honda Civic',
        inputSymptoms: ['engine vibration', 'black smoke'],
      );

      expect(diagnosis.problem, 'Engine Misfire');
      expect(diagnosis.confidence, 95);
      expect(diagnosis.estimatedCost, 1800.0);
      expect(diagnosis.recommendedAction, contains('Drive at low speeds'));
      expect(diagnosis.recommendedService, '3 hours');
      expect(diagnosis.symptoms, ['engine vibration', 'black smoke']);
      expect(diagnosis.possibleCauses, ['Engine Misfire']);
      expect(diagnosis.shouldDrive, isTrue);
    });

    test('preserves backward-compatible mock payload parsing', () {
      final service = DiagnosisService();

      final mockResponse = {
        'id': 'diag-101',
        'problem': 'Brake noise',
        'symptoms': ['squealing'],
        'possible_causes': ['Worn brake pads', 'Grit on disc'],
        'severity': 'medium',
        'estimated_cost': 1200,
        'recommended_action': 'Inspect pad thickness.',
        'should_drive': true,
        'recommended_service': 'Brake Inspection',
        'confidence': 85,
      };

      final diagnosis = service.parseDiagnosis(mockResponse, vehicleName: 'TVS Jupiter');

      expect(diagnosis.problem, 'Brake noise');
      expect(diagnosis.severity, SeverityLevel.medium);
      expect(diagnosis.confidence, 85);
      expect(diagnosis.possibleCauses.length, 2);
    });
  });

  group('AuthRepository Integration', () {
    test('login dispatches credentials and stores tokens', () async {
      final mockHttp = MockClient((request) async {
        if (request.url.path == '/api/v1/auth/login') {
          return http.Response(
            jsonEncode({
              'access_token': 'test-access-jwt',
              'refresh_token': 'test-refresh-jwt',
              'token_type': 'bearer',
              'expires_in': 900,
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(baseUrl: 'http://test-server.local', client: mockHttp);
      final repo = AuthRepository(apiClient: apiClient);

      final success = await repo.login('driver@example.com', 'SecurePass123!');
      expect(success, isTrue);
      expect(await apiClient.getAccessToken(), 'test-access-jwt');
    });

    test('register dispatches new user data and stores tokens', () async {
      final mockHttp = MockClient((request) async {
        if (request.url.path == '/api/v1/auth/register') {
          return http.Response(
            jsonEncode({
              'access_token': 'reg-access-jwt',
              'refresh_token': 'reg-refresh-jwt',
              'token_type': 'bearer',
              'expires_in': 900,
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(baseUrl: 'http://test-server.local', client: mockHttp);
      final repo = AuthRepository(apiClient: apiClient);

      final success = await repo.register('Ramesh Kumar', 'ramesh@example.com', '+919876543210', 'Pass@1234');
      expect(success, isTrue);
      expect(await apiClient.getAccessToken(), 'reg-access-jwt');
    });
  });

  group('ProfileRepository API Integration', () {
    test('fetchProfile reads from GET /api/v1/users/me', () async {
      final mockHttp = MockClient((request) async {
        if (request.url.path == '/api/v1/users/me') {
          return http.Response(
            jsonEncode({
              'id': 'u1-uuid',
              'name': 'Priya Sharma',
              'email': 'priya@example.com',
              'phone': '+919876543211',
              'role': 'customer',
              'is_active': true,
              'is_verified': true,
              'membership_tier': 'pro',
              'joined_at': '2025-06-01T10:00:00Z',
              'date_of_birth': '1998-05-14',
              'gender': 'Female',
              'emergency_contact_name': 'Anil Sharma',
              'emergency_contact_relation': 'Brother',
              'emergency_contact_phone': '+919876543299',
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(baseUrl: 'http://test-server.local', client: mockHttp);
      await apiClient.saveTokens(accessToken: 'valid-token', refreshToken: 'valid-refresh');
      final repo = ProfileRepository(apiClient: apiClient);

      final profile = await repo.fetchProfile();
      expect(profile.name, 'Priya Sharma');
      expect(profile.email, 'priya@example.com');
      expect(profile.membershipTier, MembershipTier.pro);
      expect(profile.emergencyContact?.name, 'Anil Sharma');
    });

    test('saveProfile patches to PATCH /api/v1/users/me', () async {
      late http.Request captured;
      final mockHttp = MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode({
            'id': 'u1-uuid',
            'name': 'Priya S.',
            'email': 'priya@example.com',
            'phone': '+919876543211',
            'role': 'customer',
            'is_active': true,
            'is_verified': true,
            'membership_tier': 'pro',
            'joined_at': '2025-06-01T10:00:00Z',
          }),
          200,
        );
      });

      final apiClient = ApiClient(baseUrl: 'http://test-server.local', client: mockHttp);
      await apiClient.saveTokens(accessToken: 'valid-token', refreshToken: 'valid-refresh');
      final repo = ProfileRepository(apiClient: apiClient);

      final updated = await repo.saveProfile(
        UserProfile(
          name: 'Priya S.',
          email: 'priya@example.com',
          phone: '+919876543211',
          joinedDate: DateTime(2025, 1, 1),
        ),
      );

      expect(updated.name, 'Priya S.');
      expect(captured.method, 'PATCH');
      expect(jsonDecode(captured.body)['name'], 'Priya S.');
    });
  });

  group('MechanicRepository API Integration', () {
    test('fetchMechanics reads from GET /api/v1/mechanic/mechanics', () async {
      final mockHttp = MockClient((request) async {
        if (request.url.path == '/api/v1/mechanic/mechanics') {
          return http.Response(
            jsonEncode([
              {
                'id': 'm101',
                'name': 'Speedy Garage',
                'rating': 4.9,
                'review_count': 120,
                'experience_years': 8,
                'distance_km': 2.3,
                'eta_minutes': 12,
                'is_available': true,
                'price_starting': 299.0,
                'phone': '+919876500000',
                'is_verified': true,
                'skills': ['Engine Repair', 'Brakes'],
                'languages': ['English', 'Telugu'],
                'working_hours': [
                  {'day': 'Mon-Sat', 'open': '8:00 AM', 'close': '8:00 PM'}
                ],
                'services': [
                  {'id': 'svc_1', 'name': 'General Service', 'price': 499.0, 'estimated_minutes': 45}
                ],
              }
            ]),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(baseUrl: 'http://test-server.local', client: mockHttp);
      final repo = MechanicRepository(apiClient: apiClient);

      final mechanics = await repo.fetchMechanics();
      expect(mechanics.length, 1);
      expect(mechanics.first.id, 'm101');
      expect(mechanics.first.name, 'Speedy Garage');
      expect(mechanics.first.rating, 4.9);
      expect(mechanics.first.services.first.name, 'General Service');
    });

    test('createBooking dispatches POST /api/v1/mechanic/bookings', () async {
      late http.Request captured;
      final mockHttp = MockClient((request) async {
        if (request.url.path == '/api/v1/mechanic/bookings') {
          captured = request;
          return http.Response(
            jsonEncode({
              'id': 'b101-uuid-0000-0000',
              'mechanic_id': 'm101',
              'service_id': 'svc_1',
              'status': 'requested',
              'address': '123 Main Street',
              'scheduled_at': '2026-08-19T14:00:00Z',
              'created_at': '2026-08-19T12:00:00Z',
            }),
            201,
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(baseUrl: 'http://test-server.local', client: mockHttp);
      await apiClient.saveTokens(accessToken: 'user-token', refreshToken: 'refresh-token');
      final repo = MechanicRepository(apiClient: apiClient);

      final booking = await repo.createBooking(
        mechanic: const MechanicInfo(id: 'm101', name: 'Speedy Garage', rating: 4.9),
        service: const MechanicService(
          id: 'svc_1',
          name: 'General Service',
          icon: Icons.build_rounded,
          price: 499.0,
          estimatedMinutes: 45,
        ),
        vehicle: 'Honda Activa',
        address: '123 Main Street',
        estimatedCost: 499.0,
      );

      expect(booking.bookingId, 'b101-uuid-0000-0000');
      expect(booking.status, BookingStatus.requested);
      expect(captured.headers['Authorization'], 'Bearer user-token');
      expect(jsonDecode(captured.body)['mechanic_id'], 'm101');
    });

    test('cancelBooking dispatches POST /api/v1/mechanic/bookings/{id}/cancel', () async {
      final mockHttp = MockClient((request) async {
        if (request.url.path == '/api/v1/mechanic/bookings/b101/cancel') {
          return http.Response(
            jsonEncode({
              'id': 'b101',
              'mechanic_id': 'm101',
              'service_id': 'svc_1',
              'status': 'cancelled',
              'address': '123 Main Street',
              'scheduled_at': '2026-08-19T14:00:00Z',
              'created_at': '2026-08-19T12:00:00Z',
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(baseUrl: 'http://test-server.local', client: mockHttp);
      await apiClient.saveTokens(accessToken: 'user-token', refreshToken: 'refresh-token');
      final repo = MechanicRepository(apiClient: apiClient);

      final cancelled = await repo.cancelBooking('b101');
      expect(cancelled.status, BookingStatus.cancelled);
    });
  });

  group('AiRepository & Chat API Integration', () {
    test('createSession dispatches POST /api/v1/conversation/session', () async {
      final mockHttp = MockClient((request) async {
        if (request.url.path == '/api/v1/conversation/session') {
          return http.Response(
            jsonEncode({'session_id': 'sess-123-uuid'}),
            201,
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(baseUrl: 'http://test-server.local', client: mockHttp);
      await apiClient.saveTokens(accessToken: 'user-jwt-token', refreshToken: 'refresh-token');
      final repo = AiRepository(apiClient: apiClient);

      final sessionId = await repo.createSession();
      expect(sessionId, 'sess-123-uuid');
    });

    test('sendMessage dispatches POST /api/v1/conversation/chat with Bearer token', () async {
      late http.Request captured;
      final mockHttp = MockClient((request) async {
        if (request.url.path == '/api/v1/conversation/chat') {
          captured = request;
          return http.Response(
            jsonEncode({
              'response': 'Brake pads should be inspected every 5,000 km.',
              'intent': 'Vehicle Maintenance',
              'session_id': 'sess-123-uuid',
              'diagnostic_details': null,
              'latency_ms': 45.2,
              'llm_latency_ms': 40.1,
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(baseUrl: 'http://test-server.local', client: mockHttp);
      await apiClient.saveTokens(accessToken: 'user-jwt-token', refreshToken: 'refresh-token');
      final repo = AiRepository(apiClient: apiClient);

      final reply = await repo.sendMessage('sess-123-uuid', 'When should I inspect brakes?');
      expect(reply, 'Brake pads should be inspected every 5,000 km.');
      expect(captured.headers['Authorization'], 'Bearer user-jwt-token');
      expect(jsonDecode(captured.body)['message'], 'When should I inspect brakes?');
      expect(jsonDecode(captured.body)['session_id'], 'sess-123-uuid');
    });

    test('fetchHistory dispatches GET /api/v1/conversation/history', () async {
      final mockHttp = MockClient((request) async {
        if (request.url.path == '/api/v1/conversation/history' &&
            request.url.queryParameters['session_id'] == 'sess-123-uuid') {
          return http.Response(
            jsonEncode({
              'session_id': 'sess-123-uuid',
              'history': [
                {'role': 'user', 'content': 'Hello AI'},
                {'role': 'assistant', 'content': 'Hello, how can I help?'}
              ],
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(baseUrl: 'http://test-server.local', client: mockHttp);
      await apiClient.saveTokens(accessToken: 'user-jwt-token', refreshToken: 'refresh-token');
      final repo = AiRepository(apiClient: apiClient);

      final history = await repo.fetchHistory('sess-123-uuid');
      expect(history.length, 2);
      expect(history[0]['role'], 'user');
      expect(history[0]['content'], 'Hello AI');
      expect(history[1]['role'], 'assistant');
      expect(history[1]['content'], 'Hello, how can I help?');
    });

    test('AiService composes structured blocks over real backend reply', () async {
      final mockHttp = MockClient((request) async {
        if (request.url.path == '/api/v1/conversation/chat') {
          return http.Response(
            jsonEncode({
              'response': 'Squealing noise indicates worn brake pads.',
              'intent': 'Vehicle Diagnosis',
              'session_id': 'sess-123-uuid',
              'diagnostic_details': {
                'predicted_fault': 'Worn Brake Pads',
                'estimated_cost': 1200,
                'repair_time': '45 mins',
                'safety_advice': 'Inspect pad thickness immediately.',
              },
              'latency_ms': 30.5,
              'llm_latency_ms': null,
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(baseUrl: 'http://test-server.local', client: mockHttp);
      await apiClient.saveTokens(accessToken: 'user-jwt-token', refreshToken: 'refresh-token');
      final repo = AiRepository(apiClient: apiClient);
      final service = AiService(repository: repo);

      final reply = await service.generateResponse(
        'Brake noise',
        conversationId: 'sess-123-uuid',
      );

      expect(reply.text, 'Squealing noise indicates worn brake pads.');
      expect(reply.response.blocks.any((b) => b.type == AiBlockType.costEstimate), isTrue);
      expect(reply.response.actions.any((a) => a.action == AiAction.bookMechanic), isTrue);
    });
  });
}
