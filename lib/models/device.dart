class Device {
  const Device({
    required this.id,
    required this.name,
    required this.type,
    required this.isOn,
    required this.updatedAt,
    required this.changedBy,
  });

  final String id;
  final String name;
  final String type; // irrigation | ventilation | lighting | heating
  final bool isOn;
  final DateTime updatedAt;
  final String changedBy; // "user" | "auto"

  Device copyWith({
    bool? isOn,
    DateTime? updatedAt,
    String? changedBy,
  }) {
    return Device(
      id: id,
      name: name,
      type: type,
      isOn: isOn ?? this.isOn,
      updatedAt: updatedAt ?? this.updatedAt,
      changedBy: changedBy ?? this.changedBy,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'type': type,
        'isOn': isOn,
        'updatedAt': updatedAt.toIso8601String(),
        'changedBy': changedBy,
      };

  factory Device.fromMap(String id, Map<String, dynamic> data) {
    return Device(
      id: id,
      name: data['name'] as String? ?? id,
      type: data['type'] as String? ?? id,
      isOn: data['isOn'] as bool? ?? false,
      updatedAt: DateTime.tryParse(data['updatedAt'] as String? ?? '') ??
          DateTime.now(),
      changedBy: data['changedBy'] as String? ?? 'user',
    );
  }

  static List<Device> defaults() {
    final now = DateTime.now();
    return [
      Device(
        id: 'irrigation',
        name: 'Irrigation',
        type: 'irrigation',
        isOn: false,
        updatedAt: now,
        changedBy: 'user',
      ),
      Device(
        id: 'ventilation',
        name: 'Ventilation',
        type: 'ventilation',
        isOn: false,
        updatedAt: now,
        changedBy: 'user',
      ),
      Device(
        id: 'lighting',
        name: 'Lighting',
        type: 'lighting',
        isOn: false,
        updatedAt: now,
        changedBy: 'user',
      ),
      Device(
        id: 'heating',
        name: 'Heating',
        type: 'heating',
        isOn: false,
        updatedAt: now,
        changedBy: 'user',
      ),
    ];
  }
}
