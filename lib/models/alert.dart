class AlertItem {
  const AlertItem({
    required this.id,
    required this.ts,
    required this.parameter,
    required this.value,
    required this.message,
    required this.read,
  });

  final String id;
  final DateTime ts;
  final String parameter; // airTemp | airHumidity | soilMoisture | light
  final double value;
  final String message;
  final bool read;

  AlertItem copyWith({bool? read}) {
    return AlertItem(
      id: id,
      ts: ts,
      parameter: parameter,
      value: value,
      message: message,
      read: read ?? this.read,
    );
  }

  Map<String, dynamic> toMap() => {
        'ts': ts.toIso8601String(),
        'parameter': parameter,
        'value': value,
        'message': message,
        'read': read,
      };

  factory AlertItem.fromMap(String id, Map<String, dynamic> data) {
    return AlertItem(
      id: id,
      ts: DateTime.tryParse(data['ts'] as String? ?? '') ?? DateTime.now(),
      parameter: data['parameter'] as String? ?? '',
      value: (data['value'] as num?)?.toDouble() ?? 0,
      message: data['message'] as String? ?? '',
      read: data['read'] as bool? ?? false,
    );
  }
}
