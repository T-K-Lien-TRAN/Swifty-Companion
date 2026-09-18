class StudentProject {
  const StudentProject({
    required this.name,
    required this.status,
    required this.validated,
    required this.finalMark,
  });
  final String name;
  final String status;
  final bool? validated;
  final int? finalMark;

  factory StudentProject.fromJson(Map<String, dynamic> json) {
    final project = json['project'];
    return StudentProject(
      name: project is Map ? project['name']?.toString() ?? 'Unknown project' : 'Unknown project',
      status: json['status']?.toString() ?? 'Unknown',
      validated: json['validated?'] as bool?,
      finalMark: (json['final_mark'] as num?)?.toInt(),
    );
  }
}
