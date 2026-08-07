import 'package:flutter/material.dart';
import 'package:mecha_connect/features/ai/models/models.dart';
import 'package:mecha_connect/features/ai/screens/chat_screen.dart';
import 'package:mecha_connect/features/ai/screens/conversation_detail_screen.dart';
import 'package:mecha_connect/features/ai/screens/conversation_history_screen.dart';
import 'package:mecha_connect/features/ai/screens/diagnosis_screen.dart';
import 'package:mecha_connect/features/fuel_delivery/screens/fuel_home_screen.dart';
import 'package:mecha_connect/features/marketplace/screens/marketplace_home_screen.dart';
import 'package:mecha_connect/features/mechanic/screens/mechanic_home_screen.dart';

/// Route names used by the AI feature.
const String aiHomeRoute = '/ai';
const String aiChatRoute = '/ai/chat';
const String aiDiagnosisRoute = '/ai/diagnosis';
const String aiHistoryRoute = '/ai/history';
const String aiConversationRoute = '/ai/conversation';

/// Fade-through page transition used across AI screens (matches Marketplace).
Route<void> aiFadeRoute(Widget screen) {
  return PageRouteBuilder<void>(
    transitionDuration: const Duration(milliseconds: 220),
    reverseTransitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (_, animation, secondaryAnimation) =>
        FadeTransition(opacity: animation, child: screen),
  );
}

/// Opens the chat surface. Pass [prompt] to auto-send a suggested question /
/// quick-action prompt the moment the screen is ready.
void openAiChat(BuildContext context, {String? conversationId, String? prompt}) {
  Navigator.of(context).push(
    aiFadeRoute(ChatScreen(conversationId: conversationId, initialPrompt: prompt)),
  );
}

void openAiDiagnosis(BuildContext context) {
  Navigator.of(context).push(aiFadeRoute(const DiagnosisScreen()));
}

void openAiHistory(BuildContext context) {
  Navigator.of(context).push(aiFadeRoute(const ConversationHistoryScreen()));
}

void openAiConversationDetail(BuildContext context, String conversationId) {
  Navigator.of(context).push(
    aiFadeRoute(ConversationDetailScreen(conversationId: conversationId)),
  );
}

/// Maps a structured reply [AiActionButton] to a real destination.
void openAiAction(BuildContext context, AiActionButton button) {
  switch (button.action) {
    case AiAction.openDiagnosis:
      openAiDiagnosis(context);
    case AiAction.openChat:
      openAiChat(context, prompt: button.prompt);
    case AiAction.bookMechanic:
      Navigator.of(context)
          .push(aiFadeRoute(const MechanicHomeScreen()));
    case AiAction.searchParts:
      Navigator.of(context).push(aiFadeRoute(const MarketplaceHomeScreen()));
    case AiAction.fuelRecommendation:
      Navigator.of(context).push(aiFadeRoute(const FuelHomeScreen()));
  }
}
