import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mecha_connect/features/ai/models/models.dart';
import 'package:mecha_connect/features/ai/providers/ai_provider.dart';
import 'package:mecha_connect/features/ai/repositories/ai_repository.dart';
import 'package:mecha_connect/features/ai/screens/ai_home_screen.dart';
import 'package:mecha_connect/features/ai/screens/chat_screen.dart';
import 'package:mecha_connect/features/ai/screens/conversation_history_screen.dart';
import 'package:mecha_connect/features/ai/screens/diagnosis_screen.dart';
import 'package:mecha_connect/features/ai/services/ai_service.dart';
import 'package:mecha_connect/features/ai/services/diagnosis_service.dart';
import 'package:provider/provider.dart';

/// Zero-latency repository so unit tests never wait on the mock 900ms delay.
AiRepository _fastRepo({int failForFirstCalls = 0}) {
  return AiRepository(latency: Duration.zero, failForFirstCalls: failForFirstCalls);
}

/// Pumps [child] under a single [AiProvider] (mirrors the root wiring that
/// `app_wiring.dart` provides to the real app).
Widget _wrap(Widget child, {AiRepository? repository}) {
  return ChangeNotifierProvider(
    create: (_) => AiProvider(repository: repository ?? _fastRepo()),
    child: MaterialApp(home: child),
  );
}

void main() {
  group('AiRepository', () {
    test('seeds five conversations with pinned-first ordering', () async {
      final repository = _fastRepo();
      final conversations = await repository.fetchConversations();

      expect(conversations.length, 5);
      expect(conversations.first.isPinned, isTrue);
      // The two pinned threads float above the three unpinned ones.
      expect(
        conversations.takeWhile((c) => c.isPinned).map((c) => c.title),
        ['Battery not holding charge', 'Engine overheating'],
      );
    });

    test('fails for the first N calls then succeeds', () async {
      final repository = _fastRepo(failForFirstCalls: 1);

      await expectLater(
        repository.fetchConversations(),
        throwsA(isA<AiNetworkException>()),
      );
      final conversations = await repository.fetchConversations();
      expect(conversations.length, 5);
    });

    test('sendMessage returns a keyword-matched raw reply', () async {
      final repository = _fastRepo();
      final reply = await repository.sendMessage('ai-0001', 'Battery problem');

      expect(reply, contains('Battery'));
      expect(reply, isNotEmpty);
    });

    test('diagnoseVehicle returns a structured payload with causes', () async {
      final repository = _fastRepo();
      final raw = await repository.diagnoseVehicle(
        vehicleType: 'Scooter',
        problem: 'Brake noise',
        symptoms: const ['Clicking sound'],
      );

      expect(raw['possible_causes'], isA<List<dynamic>>());
      expect((raw['possible_causes'] as List).length, greaterThan(0));
      expect(raw['severity'], 'medium');
    });
  });

  group('AiService', () {
    test('composes structured blocks for brake questions', () async {
      final service = AiService(repository: _fastRepo());
      final reply = await service.generateResponse('Brake noise');

      expect(reply.text, isNotEmpty);
      expect(
        reply.response.blocks.any((b) => b.type == AiBlockType.costEstimate),
        isTrue,
      );
      expect(
        reply.response.actions.any((a) => a.action == AiAction.searchParts),
        isTrue,
      );
      expect(
        reply.response.actions.any((a) => a.action == AiAction.bookMechanic),
        isTrue,
      );
    });

    test('offers guided diagnosis for start / diagnosis questions', () async {
      final service = AiService(repository: _fastRepo());
      final reply = await service.generateResponse('My bike won\'t start');

      expect(
        reply.response.actions.any((a) => a.action == AiAction.openDiagnosis),
        isTrue,
      );
    });
  });

  group('DiagnosisService', () {
    test('diagnoses and maps severity for brake noise', () async {
      final service = DiagnosisService(repository: _fastRepo());
      final diagnosis = await service.diagnose(
        vehicleName: 'Honda Activa 6G',
        vehicleType: 'Scooter',
        problem: 'Brake noise',
        symptoms: const ['Clicking sound'],
      );

      expect(diagnosis.possibleCauses, isNotEmpty);
      expect(diagnosis.severity, SeverityLevel.medium);
      expect(diagnosis.estimatedCost, greaterThan(0));
      expect(diagnosis.shouldDrive, isTrue);
    });

    test('throws FormatException when causes are missing', () {
      final service = DiagnosisService(repository: _fastRepo());
      expect(
        () => service.parseDiagnosis({'problem': 'x'}, vehicleName: 'Test'),
        throwsFormatException,
      );
    });
  });

  group('AiProvider', () {
    test('loadHome seeds conversations and moves to ready', () async {
      final provider = AiProvider(repository: _fastRepo());
      await provider.loadHome();

      expect(provider.state, AiScreenState.ready);
      expect(provider.conversations.length, 5);
      expect(provider.conversations.first.isPinned, isTrue);
    });

    test('loadHome surfaces an error state with a retry path', () async {
      final provider = AiProvider(repository: _fastRepo(failForFirstCalls: 1));

      await provider.loadHome();
      expect(provider.state, AiScreenState.error);
      expect(provider.errorMessage, isNotNull);

      await provider.loadHome();
      expect(provider.state, AiScreenState.ready);
    });

    test('sendMessage starts a conversation and appends the reply', () async {
      final provider = AiProvider(repository: _fastRepo());
      await provider.sendMessage('Brake noise');

      expect(provider.hasActiveChat, isTrue);
      expect(provider.currentConversation, isNotNull);
      expect(provider.messages.length, 2);
      expect(provider.messages.last.isUser, isFalse);
      expect(provider.messages.last.response, isNotNull);
      expect(provider.conversations.first.title, 'Brake noise');
    });

    test('sendMessage continues the active conversation', () async {
      final provider = AiProvider(repository: _fastRepo());
      await provider.sendMessage('Battery problem');
      final conversationId = provider.currentConversationId!;
      await provider.sendMessage('Oil leak');

      expect(provider.currentConversationId, conversationId);
      expect(provider.messages.length, 4);
    });

    test('retryLast re-sends after a simulated failure', () async {
      final provider = AiProvider(repository: _fastRepo(failForFirstCalls: 1));

      await provider.sendMessage('Brake noise');
      expect(provider.lastFailedUserText, 'Brake noise');
      expect(provider.messages.length, 1);

      await provider.retryLast();
      expect(provider.lastFailedUserText, isNull);
      expect(provider.messages.length, 2);
    });

    test('regenerateLast replaces the previous assistant reply', () async {
      final provider = AiProvider(repository: _fastRepo());
      await provider.sendMessage('Battery problem');
      final firstReply = provider.messages.last.content;

      await provider.regenerateLast();
      expect(provider.messages.length, 2);
      expect(provider.messages.last.isUser, isFalse);
      expect(provider.messages.last.content, isNotEmpty);
      expect(provider.messages.last.content, firstReply);
    });

    test('togglePin floats a conversation to the top', () async {
      final provider = AiProvider(repository: _fastRepo());
      await provider.loadHome();

      final target = provider.conversations.firstWhere((c) => !c.isPinned);
      provider.togglePin(target.id);

      final updated = provider.conversations.firstWhere((c) => c.id == target.id);
      expect(updated.isPinned, isTrue);
      // Pinned threads always float above the unpinned block.
      final firstUnpinned = provider.conversations.indexWhere((c) => !c.isPinned);
      expect(provider.conversations.indexOf(updated), lessThan(firstUnpinned));
    });

    test('rename, delete and clear all manage the store', () async {
      final provider = AiProvider(repository: _fastRepo());
      await provider.loadHome();

      await provider.renameConversation(
        provider.conversations.first.id,
        'Overheating',
      );
      expect(provider.conversations.first.title, 'Overheating');

      final id = provider.conversations.first.id;
      await provider.deleteConversation(id);
      expect(provider.conversations.length, 4);
      expect(provider.currentConversationId, isNot(id));

      await provider.clearAllConversations();
      expect(provider.conversations, isEmpty);
    });

    test('searchConversations filters by title and preview', () async {
      final provider = AiProvider(repository: _fastRepo());
      await provider.loadHome();

      final results = provider.searchConversations('brake');
      expect(results.length, 1);
      expect(results.single.title, 'Brake noise');

      expect(provider.searchConversations('zzz-not-found'), isEmpty);
    });

    test('startDiagnosis stores the last four diagnoses', () async {
      final provider = AiProvider(repository: _fastRepo());

      for (final problem in const [
        'Brake noise',
        'Battery not holding charge',
        'Oil leak',
        'Poor fuel efficiency',
        'Flat tyre',
      ]) {
        final diagnosis = await provider.startDiagnosis(
          vehicleName: 'Honda Activa 6G',
          vehicleType: 'Scooter',
          problem: problem,
          symptoms: const ['Clicking sound'],
        );
        expect(diagnosis, isNotNull);
      }

      expect(provider.recentDiagnoses.length, 4);
      expect(provider.recentDiagnoses.first.problem, 'Flat tyre');
    });

    test('rejects diagnosis without symptoms', () async {
      final provider = AiProvider(repository: _fastRepo());
      final diagnosis = await provider.startDiagnosis(
        vehicleName: 'Honda Activa 6G',
        vehicleType: 'Scooter',
        problem: 'Brake noise',
        symptoms: const [],
      );

      expect(diagnosis, isNull);
      expect(provider.diagnosisError, contains('symptom'));
    });

    test('exposes non-empty suggestions, tips, actions and health', () {
      expect(AiProvider.suggestions.length, 8);
      expect(AiProvider.tips.length, 3);
      expect(AiProvider.vehicleHealth.score, 92);

      final provider = AiProvider(repository: _fastRepo());
      final destinations =
          provider.quickActions.map((a) => a.destination).toSet();
      expect(provider.quickActions.length, 9);
      expect(destinations, containsAll(QuickActionDestination.values));
    });
  });

  group('AiHomeScreen', () {
    testWidgets('renders all sections after loading', (tester) async {
      await tester.pumpWidget(_wrap(const AiHomeScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Mecha AI'), findsOneWidget);
      expect(find.text('Quick actions'), findsOneWidget);
      expect(find.text('Recent conversations'), findsOneWidget);
      expect(find.text('Recent diagnoses'), findsOneWidget);
      expect(find.text('No diagnoses yet'), findsOneWidget);
      expect(find.text('Daily tips'), findsOneWidget);
    });

    testWidgets('quick action opens the guided diagnosis', (tester) async {
      await tester.pumpWidget(_wrap(const AiHomeScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Vehicle Diagnosis'));
      await tester.pumpAndSettle();

      expect(find.byType(DiagnosisScreen), findsOneWidget);
      expect(find.text('Which vehicle?'), findsOneWidget);
    });
  });

  group('ChatScreen', () {
    testWidgets('auto-sends the queued prompt and renders the reply',
        (tester) async {
      await tester.pumpWidget(
        _wrap(const ChatScreen(initialPrompt: 'My bike won\'t start')),
      );

      // Post-frame hook opens a fresh conversation and queues the message.
      await tester.pump();
      // Let the zero-latency repository future complete.
      await tester.pump(const Duration(milliseconds: 20));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Mecha AI'), findsWidgets);
      expect(find.textContaining('guided diagnosis', findRichText: true),
          findsWidgets);
      expect(find.text('Start Guided Diagnosis'), findsOneWidget);
    });

    testWidgets('send button appends a message to the thread', (tester) async {
      await tester.pumpWidget(_wrap(const ChatScreen()));
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'Brake noise');
      await tester.tap(find.bySemanticsLabel('Send message'));
      await tester.pump(const Duration(milliseconds: 20));
      await tester.pumpAndSettle();

      expect(find.textContaining('Brake noise', findRichText: true),
          findsOneWidget);
      expect(find.text('Search Parts'), findsOneWidget);
    });
  });

  group('ConversationHistoryScreen', () {
    testWidgets('renders seeded conversations and filters by search',
        (tester) async {
      await tester.pumpWidget(_wrap(const ConversationHistoryScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Conversations'), findsOneWidget);
      expect(find.text('Brake noise'), findsOneWidget);
      expect(find.text('Battery not holding charge'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'oil');
      await tester.pumpAndSettle();

      expect(find.text('Oil change interval'), findsOneWidget);
      expect(find.text('Brake noise'), findsNothing);
    });
  });
}
