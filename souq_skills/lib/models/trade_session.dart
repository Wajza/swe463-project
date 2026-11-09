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
}
