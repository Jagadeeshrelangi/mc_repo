import 'package:flutter/material.dart';

/// Where a [QuickAction] card leads.
enum QuickActionDestination {
  diagnosis,
  chat,
  mechanic,
  fuel,
  marketplace,
  emergency,
}

/// A home-screen quick action. Every card is backed by an action that really
/// navigates (or, for chat prompts, opens the chat with the prompt queued) —
/// there are no dead buttons on the AI home.
class QuickAction {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final String prompt;
  final QuickActionDestination destination;

  const QuickAction({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.prompt,
    required this.destination,
  });
}
