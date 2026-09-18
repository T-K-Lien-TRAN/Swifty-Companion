class StudentSkill {
  const StudentSkill({required this.name, required this.level});
  final String name;
  final double level;

  factory StudentSkill.fromJson(Map<String, dynamic> json) => StudentSkill(
        name: json['name']?.toString() ?? 'Unknown skill',
        level: (json['level'] as num?)?.toDouble() ?? 0,
      );
}
