import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mecha_connect/features/ai/models/models.dart';
import 'package:mecha_connect/features/ai/providers/ai_provider.dart';
import 'package:mecha_connect/features/ai/repositories/ai_repository.dart';
import 'package:mecha_connect/features/ai/screens/conversation_history_screen.dart';
import 'package:mecha_connect/services/api_client.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Model Serialization Tests', () {
    test('Conversation.fromJson parses summary payload', () {
      final json = {
        'id': 'session_123456789abc',
        'title': 'Brake Pad Replacement Guide',
        'is_pinned': true,
        'message_count': 4,
        'preview': 'Check your brake pads before riding.',
        'created_at': '2026-09-06T12:00:00Z',
        'updated_at': '2026-09-06T12:30:00Z',
      };

      final conv = Conversation.fromJson(json);

      expect(conv.id, 'session_123456789abc');
      expect(conv.title, 'Brake Pad Replacement Guide');
      expect(conv.isPinned, isTrue);
      expect(conv.messageCount, 4);
      expect(conv.preview, 'Check your brake pads before riding.');
      expect(conv.createdAt, DateTime.parse('2026-09-06T12:00:00Z'));
      expect(conv.updatedAt, DateTime.parse('2026-09-06T12:30:00Z'));
      expect(conv.messages, isEmpty);
    });

    test('Conversation.fromJson parses detail payload with message turns', () {
      final json = {
        'id': 'session_detail_999',
        'title': 'Engine Diagnostic',
        'is_pinned': false,
        'created_at': '2026-09-06T14:00:00Z',
        'updated_at': '2026-09-06T14:05:00Z',
        'messages': [
          {
            'id': 'msg_01',
            'role': 'user',
            'content': 'Engine is making noise',
            'timestamp': '2026-09-06T14:00:05Z',
          },
          {
            'id': 'msg_02',
            'role': 'assistant',
            'content': 'Could be a loose timing chain.',
            'timestamp': '2026-09-06T14:00:10Z',
          }
        ],
      };

      final conv = Conversation.fromJson(json);

      expect(conv.id, 'session_detail_999');
      expect(conv.title, 'Engine Diagnostic');
      expect(conv.isPinned, isFalse);
      expect(conv.messageCount, 2);
      expect(conv.messages.length, 2);
      expect(conv.messages[0].isUser, isTrue);
      expect(conv.messages[0].content, 'Engine is making noise');
      expect(conv.messages[1].isUser, isFalse);
      expect(conv.messages[1].content, 'Could be a loose timing chain.');
      expect(conv.preview, 'Could be a loose timing chain.');
    });

    test('ChatMessage fromJson and toJson roundtrip', () {
      final message = ChatMessage(
        id: 'msg_test',
        role: MessageRole.assistant,
        content: 'Check your tyres.',
        timestamp: DateTime.parse('2026-09-06T15:00:00Z'),
      );

      final json = message.toJson();
      expect(json['id'], 'msg_test');
      expect(json['role'], 'assistant');
      expect(json['content'], 'Check your tyres.');

      final parsed = ChatMessage.fromJson(json);
      expect(parsed.id, message.id);
      expect(parsed.role, message.role);
      expect(parsed.content, message.content);
    });
  });

  group('AiRepository Contract Integration with Real ApiClient', () {
    test('fetchConversations parses sessions list from backend', () async {
      final mockHttp = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/v1/conversation/sessions');
        return http.Response(
          jsonEncode([
            {
              'id': 'session_01',
              'title': 'Thread 1',
              'is_pinned': true,
              'message_count': 2,
              'preview': 'Preview 1',
              'created_at': '2026-09-06T10:00:00Z',
              'updated_at': '2026-09-06T10:10:00Z',
            },
            {
              'id': 'session_02',
              'title': 'Thread 2',
              'is_pinned': false,
              'message_count': 1,
              'preview': 'Preview 2',
              'created_at': '2026-09-06T11:00:00Z',
              'updated_at': '2026-09-06T11:05:00Z',
            },
          ]),
          200,
        );
      });

      final apiClient = ApiClient(baseUrl: 'http://test-server.local', client: mockHttp);
      final repo = AiRepository(apiClient: apiClient);

      final list = await repo.fetchConversations();
      expect(list.length, 2);
      expect(list[0].id, 'session_01');
      expect(list[0].isPinned, isTrue);
      expect(list[1].id, 'session_02');
    });

    test('fetchConversations returns empty list when backend returns empty []', () async {
      final mockHttp = MockClient((request) async {
        return http.Response(jsonEncode([]), 200);
      });

      final apiClient = ApiClient(baseUrl: 'http://test-server.local', client: mockHttp);
      final repo = AiRepository(apiClient: apiClient);

      final list = await repo.fetchConversations();
      expect(list, isEmpty);
    });

    test('createSession posts to /api/v1/conversation/session and returns session_id', () async {
      final mockHttp = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/v1/conversation/session');
        return http.Response(
          jsonEncode({'session_id': 'session_created_123'}),
          201,
        );
      });

      final apiClient = ApiClient(baseUrl: 'http://test-server.local', client: mockHttp);
      final repo = AiRepository(apiClient: apiClient);

      final sessionId = await repo.createSession();
      expect(sessionId, 'session_created_123');
    });

    test('fetchConversationDetail retrieves selected thread and turns', () async {
      final mockHttp = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/v1/conversation/sessions/session_detail_abc');
        return http.Response(
          jsonEncode({
            'id': 'session_detail_abc',
            'title': 'Test Thread',
            'is_pinned': false,
            'created_at': '2026-09-06T10:00:00Z',
            'updated_at': '2026-09-06T10:05:00Z',
            'messages': [
              {
                'id': 'm1',
                'role': 'user',
                'content': 'Hello AI',
                'timestamp': '2026-09-06T10:00:01Z',
              }
            ],
          }),
          200,
        );
      });

      final apiClient = ApiClient(baseUrl: 'http://test-server.local', client: mockHttp);
      final repo = AiRepository(apiClient: apiClient);

      final detail = await repo.fetchConversationDetail('session_detail_abc');
      expect(detail.id, 'session_detail_abc');
      expect(detail.title, 'Test Thread');
      expect(detail.messages.length, 1);
      expect(detail.messages.first.content, 'Hello AI');
    });

    test('updateConversation patches title and is_pinned', () async {
      late Map<String, dynamic> capturedBody;
      final mockHttp = MockClient((request) async {
        expect(request.method, 'PATCH');
        expect(request.url.path, '/api/v1/conversation/sessions/session_update_xyz');
        capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({
            'id': 'session_update_xyz',
            'title': capturedBody['title'],
            'is_pinned': capturedBody['is_pinned'],
            'created_at': '2026-09-06T10:00:00Z',
            'updated_at': '2026-09-06T10:15:00Z',
          }),
          200,
        );
      });

      final apiClient = ApiClient(baseUrl: 'http://test-server.local', client: mockHttp);
      final repo = AiRepository(apiClient: apiClient);

      final updated = await repo.updateConversation(
        'session_update_xyz',
        title: 'Renamed Title',
        isPinned: true,
      );

      expect(capturedBody['title'], 'Renamed Title');
      expect(capturedBody['is_pinned'], isTrue);
      expect(updated?.title, 'Renamed Title');
      expect(updated?.isPinned, isTrue);
    });

    test('deleteConversation issues DELETE request', () async {
      bool deleteCalled = false;
      final mockHttp = MockClient((request) async {
        expect(request.method, 'DELETE');
        expect(request.url.path, '/api/v1/conversation/sessions/session_del_123');
        deleteCalled = true;
        return http.Response('', 204);
      });

      final apiClient = ApiClient(baseUrl: 'http://test-server.local', client: mockHttp);
      final repo = AiRepository(apiClient: apiClient);

      await repo.deleteConversation('session_del_123');
      expect(deleteCalled, isTrue);
    });

    test('network error propagates properly', () async {
      final mockHttp = MockClient((request) async {
        return http.Response('Server Error', 500);
      });

      final apiClient = ApiClient(baseUrl: 'http://test-server.local', client: mockHttp);
      final repo = AiRepository(apiClient: apiClient);

      expect(() => repo.fetchConversations(), throwsA(isA<ApiException>()));
    });
  });

  group('AiProvider State Management Tests', () {
    test('loadHome with empty backend list transitions to ready and empty state', () async {
      final mockHttp = MockClient((request) async {
        return http.Response(jsonEncode([]), 200);
      });

      final apiClient = ApiClient(baseUrl: 'http://test-server.local', client: mockHttp);
      final provider = AiProvider(apiClient: apiClient);

      await provider.loadHome();

      expect(provider.state, AiScreenState.ready);
      expect(provider.conversations, isEmpty);
      expect(provider.errorMessage, isNull);
    });

    test('loadHome with error transitions to error state', () async {
      final mockHttp = MockClient((request) async {
        return http.Response('Internal Error', 500);
      });

      final apiClient = ApiClient(baseUrl: 'http://test-server.local', client: mockHttp);
      final provider = AiProvider(apiClient: apiClient);

      await provider.loadHome();

      expect(provider.state, AiScreenState.error);
      expect(provider.errorMessage, isNotNull);
    });

    test('openConversation loads detail and preserves active session ID', () async {
      final mockHttp = MockClient((request) async {
        if (request.url.path.contains('/sessions/session_test_42')) {
          return http.Response(
            jsonEncode({
              'id': 'session_test_42',
              'title': 'Active Thread',
              'is_pinned': false,
              'created_at': '2026-09-06T10:00:00Z',
              'updated_at': '2026-09-06T10:00:00Z',
              'messages': [
                {
                  'id': 'm1',
                  'role': 'user',
                  'content': 'Previous question',
                  'timestamp': '2026-09-06T10:00:00Z',
                },
                {
                  'id': 'm2',
                  'role': 'assistant',
                  'content': 'Previous answer',
                  'timestamp': '2026-09-06T10:00:05Z',
                }
              ],
            }),
            200,
          );
        }
        return http.Response(jsonEncode([]), 200);
      });

      final apiClient = ApiClient(baseUrl: 'http://test-server.local', client: mockHttp);
      final provider = AiProvider(apiClient: apiClient);

      await provider.openConversation('session_test_42');

      expect(provider.currentConversationId, 'session_test_42');
      expect(provider.messages.length, 2);
      expect(provider.messages[0].content, 'Previous question');
      expect(provider.messages[1].content, 'Previous answer');
    });

    test('newConversation resets current conversation ID', () async {
      final provider = AiProvider();
      provider.openConversation('some_id');
      expect(provider.currentConversationId, 'some_id');

      provider.newConversation();
      expect(provider.currentConversationId, isNull);
    });

    test('sendMessage creates session when currentConversationId is null', () async {
      final mockHttp = MockClient((request) async {
        if (request.url.path == '/api/v1/conversation/session') {
          return http.Response(jsonEncode({'session_id': 'session_auto_created'}), 201);
        }
        if (request.url.path == '/api/v1/conversation/chat') {
          return http.Response(jsonEncode({'response': 'Here is the diagnosis reply.'}), 200);
        }
        return http.Response(jsonEncode([]), 200);
      });

      final apiClient = ApiClient(baseUrl: 'http://test-server.local', client: mockHttp);
      final provider = AiProvider(apiClient: apiClient);

      await provider.sendMessage('My bike battery is weak');

      expect(provider.currentConversationId, 'session_auto_created');
      expect(provider.messages.length, 2);
      expect(provider.messages[0].content, 'My bike battery is weak');
      expect(provider.messages[1].content, contains('diagnosis reply'));
    });

    test('rename, pin, and delete update provider state and call backend', () async {
      final mockHttp = MockClient((request) async {
        if (request.method == 'GET' && request.url.path.contains('/sessions/session_crud')) {
          return http.Response(
            jsonEncode({
              'id': 'session_crud',
              'title': 'Original Title',
              'is_pinned': false,
              'created_at': '2026-09-06T10:00:00Z',
              'updated_at': '2026-09-06T10:00:00Z',
              'messages': [],
            }),
            200,
          );
        }
        if (request.method == 'PATCH') {
          return http.Response(
            jsonEncode({
              'id': 'session_crud',
              'title': 'New Title',
              'is_pinned': true,
              'created_at': '2026-09-06T10:00:00Z',
              'updated_at': '2026-09-06T10:20:00Z',
            }),
            200,
          );
        }
        if (request.method == 'DELETE') {
          return http.Response('', 204);
        }
        return http.Response(jsonEncode([]), 200);
      });

      final apiClient = ApiClient(baseUrl: 'http://test-server.local', client: mockHttp);
      final provider = AiProvider(apiClient: apiClient);

      await provider.openConversation('session_crud');
      await provider.renameConversation('session_crud', 'New Title');
      await provider.togglePin('session_crud');

      expect(provider.currentConversation?.title, 'New Title');
      expect(provider.currentConversation?.isPinned, isTrue);

      await provider.deleteConversation('session_crud');
      expect(provider.currentConversationId, isNull);
      expect(provider.conversations.any((c) => c.id == 'session_crud'), isFalse);
    });
  });

  group('ConversationHistoryScreen Widget Tests', () {
    testWidgets('renders empty state when there are no conversations', (tester) async {
      final mockHttp = MockClient((request) async {
        return http.Response(jsonEncode([]), 200);
      });

      final apiClient = ApiClient(baseUrl: 'http://test-server.local', client: mockHttp);
      final provider = AiProvider(apiClient: apiClient);
      await provider.loadHome();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MaterialApp(home: ConversationHistoryScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No conversations yet'), findsOneWidget);
      expect(find.text('Start chatting'), findsOneWidget);
    });

    testWidgets('renders pinned and recent sections when conversations exist', (tester) async {
      final mockHttp = MockClient((request) async {
        return http.Response(
          jsonEncode([
            {
              'id': 's1',
              'title': 'Pinned Brake Thread',
              'is_pinned': true,
              'message_count': 3,
              'preview': 'Check brake disc',
              'created_at': '2026-09-06T10:00:00Z',
              'updated_at': '2026-09-06T10:10:00Z',
            },
            {
              'id': 's2',
              'title': 'Recent Fuel Thread',
              'is_pinned': false,
              'message_count': 1,
              'preview': 'Fuel dropped',
              'created_at': '2026-09-06T09:00:00Z',
              'updated_at': '2026-09-06T09:05:00Z',
            },
          ]),
          200,
        );
      });

      final apiClient = ApiClient(baseUrl: 'http://test-server.local', client: mockHttp);
      final provider = AiProvider(apiClient: apiClient);
      await provider.loadHome();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MaterialApp(home: ConversationHistoryScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('PINNED'), findsOneWidget);
      expect(find.text('Pinned Brake Thread'), findsOneWidget);
      expect(find.text('Recent Fuel Thread'), findsOneWidget);
    });
  });
}
