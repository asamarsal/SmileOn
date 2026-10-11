/// Model Kuota Event untuk melacak pemakaian foto pada fitur Event Mode
class EventQuotaModel {
  final String eventId;
  final String eventName;
  final int totalCredits; // Total alokasi kuota foto (misal: 100)
  final int usedCredits; // Kuota foto yang sudah diambil (misal: 37)
  final int userCreditsPerGuest; // Limit kuota per tamu
  final DateTime lastUpdated;

  const EventQuotaModel({
    required this.eventId,
    required this.eventName,
    required this.totalCredits,
    this.usedCredits = 0,
    this.userCreditsPerGuest = 1,
    required this.lastUpdated,
  });

  /// Sisa kuota foto yang masih dapat digunakan
  int get remainingCredits =>
      (totalCredits - usedCredits).clamp(0, totalCredits);

  /// Rasio penggunaan kuota (0.0 s/d 1.0)
  double get usagePercentage =>
      totalCredits > 0 ? (usedCredits / totalCredits).clamp(0.0, 1.0) : 1.0;

  /// String representasi kuota untuk footer kamera (misal: "37/100")
  String get quotaDisplayString => '$usedCredits/$totalCredits';

  bool get isExhausted => remainingCredits <= 0;
  bool get isLowQuota =>
      remainingCredits <= (totalCredits * 0.15).round() && !isExhausted;

  EventQuotaModel copyWith({
    String? eventId,
    String? eventName,
    int? totalCredits,
    int? usedCredits,
    int? userCreditsPerGuest,
    DateTime? lastUpdated,
  }) {
    return EventQuotaModel(
      eventId: eventId ?? this.eventId,
      eventName: eventName ?? this.eventName,
      totalCredits: totalCredits ?? this.totalCredits,
      usedCredits: usedCredits ?? this.usedCredits,
      userCreditsPerGuest: userCreditsPerGuest ?? this.userCreditsPerGuest,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  Map<String, dynamic> toJson() => {
        'eventId': eventId,
        'eventName': eventName,
        'totalCredits': totalCredits,
        'usedCredits': usedCredits,
        'userCreditsPerGuest': userCreditsPerGuest,
        'lastUpdated': lastUpdated.toIso8601String(),
      };

  factory EventQuotaModel.fromJson(Map<String, dynamic> json) =>
      EventQuotaModel(
        eventId: json['eventId'] as String? ?? 'default_event',
        eventName: json['eventName'] as String? ?? 'SmileOn Event',
        totalCredits: (json['totalCredits'] as num?)?.toInt() ?? 100,
        usedCredits: (json['usedCredits'] as num?)?.toInt() ?? 0,
        userCreditsPerGuest:
            (json['userCreditsPerGuest'] as num?)?.toInt() ?? 1,
        lastUpdated: json['lastUpdated'] != null
            ? DateTime.parse(json['lastUpdated'] as String)
            : DateTime.now(),
      );

  static EventQuotaModel get defaultMock => EventQuotaModel(
        eventId: 'event-asa-aulia',
        eventName: 'Asa & Aulia',
        totalCredits: 100,
        usedCredits: 37,
        lastUpdated: DateTime.now(),
      );
}
