class TradeSession {
  const TradeSession({
    required this.tradeId,
    required this.date,
    required this.time,
    required this.method,
    this.id = '',
    this.locationOrLink = '',
    this.notes = '',
    this.isCompleted = false,
  });

  final String id;
  final String tradeId;
  final String date;
  final String time;
  final String method;
  final String locationOrLink;
  final String notes;
  final bool isCompleted;

  TradeSession copyWith({
    String? id, String? tradeId, String? date, String? time, String? method,
    String? locationOrLink, String? notes, bool? isCompleted,
  }) => TradeSession(
    id: id ?? this.id, tradeId: tradeId ?? this.tradeId,
    date: date ?? this.date, time: time ?? this.time,
    method: method ?? this.method, locationOrLink: locationOrLink ?? this.locationOrLink,
    notes: notes ?? this.notes, isCompleted: isCompleted ?? this.isCompleted,
  );
}
