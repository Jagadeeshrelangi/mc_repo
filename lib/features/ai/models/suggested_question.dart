/// A tappable suggested-question chip shown on the AI home and the empty chat
/// state. Tapping one sends the question to the assistant immediately.
class SuggestedQuestion {
  final String id;
  final String text;

  const SuggestedQuestion({
    required this.id,
    required this.text,
  });
}
