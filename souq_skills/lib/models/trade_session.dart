import 'identifiable.dart';

class TradeSession implements Identifiable {
  const TradeSession({
    required this.id,
    required this.tradeId,
    required this.scheduledAt,
    required this.method,
    this.locationOrLink = '',
    this.notes = '',
    this.isCompleted = false,
  });

  @override
  final String id;
  final String tradeId;
  final DateTime scheduledAt;
  final String method;
  final String locationOrLink;
  final String notes;
  final bool isCompleted;

  TradeSession copyWith({
    DateTime? scheduledAt,
    String? method,
    String? locationOrLink,
    String? notes,
    bool? isCompleted,
  }) => TradeSession(
    id: id,
    tradeId: tradeId,
    scheduledAt: scheduledAt ?? this.scheduledAt,
    method: method ?? this.method,
    locationOrLink: locationOrLink ?? this.locationOrLink,
    notes: notes ?? this.notes,
    isCompleted: isCompleted ?? this.isCompleted,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'tradeId': tradeId,
    'scheduledAt': scheduledAt.toIso8601String(),
    'method': method,
    'locationOrLink': locationOrLink,
    'notes': notes,
    'isCompleted': isCompleted,
  };

  factory TradeSession.fromJson(Map<String, dynamic> json) => TradeSession(
    id: json['id'] as String,
    tradeId: json['tradeId'] as String,
    scheduledAt: DateTime.parse(json['scheduledAt'] as String),
    method: json['method'] as String,
    locationOrLink: json['locationOrLink'] as String,
    notes: json['notes'] as String,
    isCompleted: json['isCompleted'] as bool,
  );
}
