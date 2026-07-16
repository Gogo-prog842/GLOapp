class Season {
  const Season({
    required this.id,
    required this.name,
    required this.leagueId,
    required this.isActive,
    this.startDate,
    this.endDate,
  });

  final int id;
  final String name;
  final int leagueId;
  final bool isActive;
  final DateTime? startDate;
  final DateTime? endDate;

  factory Season.fromMap(Map<String, dynamic> map) {
    return Season(
      id: (map['id'] as num).toInt(),
      name: (map['name'] as String?) ?? 'Sezon',
      leagueId: (map['league_id'] as num).toInt(),
      isActive: map['is_active'] == true,
      startDate: DateTime.tryParse((map['start_date'] as String?) ?? ''),
      endDate: DateTime.tryParse((map['end_date'] as String?) ?? ''),
    );
  }
}
