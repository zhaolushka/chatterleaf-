class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.ts,
    required this.text,
    required this.fromPlant,
  });

  final String id;
  final DateTime ts;
  final String text;
  final bool fromPlant;

  Map<String, dynamic> toMap() => {
        'ts': ts.toIso8601String(),
        'text': text,
        'fromPlant': fromPlant,
      };

  factory ChatMessage.fromMap(String id, Map<String, dynamic> data) {
    return ChatMessage(
      id: id,
      ts: DateTime.tryParse(data['ts'] as String? ?? '') ?? DateTime.now(),
      text: data['text'] as String? ?? '',
      fromPlant: data['fromPlant'] as bool? ?? true,
    );
  }
}
