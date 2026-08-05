/// The visual kind of a structured answer block.
enum AiBlockType {
  text,
  bulletList,
  warning,
  recommendation,
  checklist,
  costEstimate,
}

/// One structured section of a premium AI reply.
///
/// [text] is used by `text`, `warning` and `recommendation` blocks.
/// [items] is used by `bulletList`, `checklist` and `costEstimate` blocks.
/// [note] is an optional footer (e.g. the total of a cost estimate).
class AiBlock {
  final AiBlockType type;
  final String? title;
  final String? text;
  final List<String> items;
  final String? note;

  const AiBlock({
    required this.type,
    this.title,
    this.text,
    this.items = const [],
    this.note,
  });
}

/// Actions a reply can offer. Screens map each action to a real route or a
/// queued chat prompt — nothing is decorative.
enum AiAction {
  openDiagnosis,
  openChat,
  bookMechanic,
  searchParts,
  fuelRecommendation,
}

class AiActionButton {
  final String label;
  final AiAction action;
  final String? prompt;

  const AiActionButton({
    required this.label,
    required this.action,
    this.prompt,
  });
}

/// The full structured payload of an assistant message: intro [content]
/// (plain text) plus [blocks] and [actions].
class AiResponse {
  final List<AiBlock> blocks;
  final List<AiActionButton> actions;

  const AiResponse({
    this.blocks = const [],
    this.actions = const [],
  });

  bool get isEmpty => blocks.isEmpty && actions.isEmpty;
}
