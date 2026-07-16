class League {
  const League({required this.id, required this.name});

  final int id;
  final String name;

  factory League.fromMap(Map<String, dynamic> map) {
    return League(
      id: (map['id'] as num).toInt(),
      name: (map['name'] as String?)?.trim().isNotEmpty == true
          ? (map['name'] as String).trim()
          : 'Liga ${(map['id'] as num).toInt()}',
    );
  }
}
