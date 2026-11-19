export 'persona.dart';
import 'persona.dart';

class Greenhouse {
  const Greenhouse({
    required this.id,
    required this.ownerUid,
    required this.name,
    required this.mode,
    required this.persona,
  });

  final String id;
  final String ownerUid;
  final String name;
  final String mode; // "auto" | "manual"
  final Persona persona;

  bool get isAuto => mode == 'auto';

  Greenhouse copyWith({
    String? name,
    String? mode,
    Persona? persona,
  }) {
    return Greenhouse(
      id: id,
      ownerUid: ownerUid,
      name: name ?? this.name,
      mode: mode ?? this.mode,
      persona: persona ?? this.persona,
    );
  }

  Map<String, dynamic> toMap() => {
        'ownerUid': ownerUid,
        'name': name,
        'mode': mode,
        'persona': persona.id,
      };

  factory Greenhouse.fromMap(String id, Map<String, dynamic> data) {
    return Greenhouse(
      id: id,
      ownerUid: data['ownerUid'] as String? ?? '',
      name: data['name'] as String? ?? 'My Greenhouse',
      mode: data['mode'] as String? ?? 'manual',
      persona: Persona.fromId(data['persona'] as String?),
    );
  }
}
