class CurrentBreak {
  const CurrentBreak({
    required this.isOnBreak,
    this.breakId,
    this.startedAt,
  });

  final bool isOnBreak;
  final String? breakId;
  final DateTime? startedAt;

  factory CurrentBreak.fromJson(Map<String, dynamic> json) => CurrentBreak(
        isOnBreak: json['isOnBreak'] as bool? ?? false,
        breakId: json['breakId']?.toString(),
        startedAt: DateTime.tryParse(json['startedAt']?.toString() ?? ''),
      );
}

class BreakHistoryItem {
  const BreakHistoryItem({
    required this.id,
    required this.startedAt,
    this.endedAt,
    this.durationMinutes,
    required this.autoClosed,
  });

  final String id;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int? durationMinutes;
  final bool autoClosed;

  factory BreakHistoryItem.fromJson(Map<String, dynamic> json) =>
      BreakHistoryItem(
        id: json['id']?.toString() ?? '',
        startedAt: DateTime.parse(json['startedAt'].toString()),
        endedAt: DateTime.tryParse(json['endedAt']?.toString() ?? ''),
        durationMinutes: (json['durationMinutes'] as num?)?.toInt(),
        autoClosed: json['autoClosed'] as bool? ?? false,
      );
}

class ActiveColleagueBreak {
  const ActiveColleagueBreak({
    required this.userId,
    required this.fullName,
    this.department,
    required this.startedAt,
  });

  final String userId;
  final String fullName;
  final String? department;
  final DateTime startedAt;

  factory ActiveColleagueBreak.fromJson(Map<String, dynamic> json) =>
      ActiveColleagueBreak(
        userId: json['userId']?.toString() ?? '',
        fullName: json['fullName']?.toString() ?? 'Çalışan',
        department: json['department']?.toString(),
        startedAt: DateTime.parse(json['startedAt'].toString()),
      );
}
