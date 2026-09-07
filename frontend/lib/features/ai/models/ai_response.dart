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

  factory AiBlock.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type']?.toString() ?? 'text';
    final blockType = AiBlockType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => AiBlockType.text,
    );
    final rawItems = json['items'];
    List<String> parsedItems = const [];
    if (rawItems is List) {
      parsedItems = rawItems.map((e) => e.toString()).toList();
    }
    return AiBlock(
      type: blockType,
      title: json['title'] as String?,
      text: json['text'] as String?,
      items: parsedItems,
      note: json['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      if (title != null) 'title': title,
      if (text != null) 'text': text,
      if (items.isNotEmpty) 'items': items,
      if (note != null) 'note': note,
    };
  }
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

  factory AiActionButton.fromJson(Map<String, dynamic> json) {
    final actionStr = json['action']?.toString() ?? '';
    final act = AiAction.values.firstWhere(
      (e) => e.name == actionStr,
      orElse: () => AiAction.openChat,
    );
    return AiActionButton(
      label: json['label']?.toString() ?? '',
      action: act,
      prompt: json['prompt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'action': action.name,
      if (prompt != null) 'prompt': prompt,
    };
  }
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

  factory AiResponse.fromJson(Map<String, dynamic> json) {
    final rawBlocks = json['blocks'];
    List<AiBlock> parsedBlocks = const [];
    if (rawBlocks is List) {
      parsedBlocks = rawBlocks
          .whereType<Map<String, dynamic>>()
          .map((b) => AiBlock.fromJson(b))
          .toList();
    }

    final rawActions = json['actions'];
    List<AiActionButton> parsedActions = const [];
    if (rawActions is List) {
      parsedActions = rawActions
          .whereType<Map<String, dynamic>>()
          .map((a) => AiActionButton.fromJson(a))
          .toList();
    }

    return AiResponse(
      blocks: parsedBlocks,
      actions: parsedActions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (blocks.isNotEmpty) 'blocks': blocks.map((b) => b.toJson()).toList(),
      if (actions.isNotEmpty)
        'actions': actions.map((a) => a.toJson()).toList(),
    };
  }
}
