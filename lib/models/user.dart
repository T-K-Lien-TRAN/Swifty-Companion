import 'project.dart';
import 'skill.dart';

class StudentUser {
  const StudentUser({
    required this.login,
    required this.name,
    required this.imageUrl,
    required this.email,
    required this.phone,
    required this.wallet,
    required this.evaluationPoints,
    required this.cursusName,
    required this.level,
    required this.skills,
    required this.projects,
  });

  final String login;
  final String name;
  final String? imageUrl;
  final String? email;
  final String? phone;
  final int? wallet;
  final int? evaluationPoints;
  final String? cursusName;
  final double? level;
  final List<StudentSkill> skills;
  final List<StudentProject> projects;

  factory StudentUser.fromJson(Map<String, dynamic> json) {
    final rawCursus = json['cursus_users'] as List? ?? [];
    final cursus = rawCursus.whereType<Map<String, dynamic>>().toList();
    // Show the main 42 curriculum when available, otherwise an available cursus.
    Map<String, dynamic>? selected;
    for (final entry in cursus) {
      final data = entry['cursus'];
      if (data is Map && data['slug']?.toString() == '42cursus') {
        selected = entry;
        break;
      }
    }
    if (selected == null && cursus.isNotEmpty) selected = cursus.first;
    final curriculum = selected?['cursus'];
    final skillData = selected?['skills'] as List? ?? [];
    final projectData = json['projects_users'] as List? ?? [];
    final image = json['image'];

    return StudentUser(
      login: json['login']?.toString() ?? '',
      name: json['displayname']?.toString() ?? json['login']?.toString() ?? 'Student',
      imageUrl: image is Map ? image['link']?.toString() : null,
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      wallet: (json['wallet'] as num?)?.toInt(),
      evaluationPoints: (json['correction_point'] as num?)?.toInt(),
      cursusName: curriculum is Map ? curriculum['name']?.toString() : null,
      level: (selected?['level'] as num?)?.toDouble(),
      skills: skillData.whereType<Map<String, dynamic>>().map(StudentSkill.fromJson).toList()
        ..sort((a, b) => b.level.compareTo(a.level)),
      projects: projectData.whereType<Map<String, dynamic>>().map(StudentProject.fromJson).toList(),
    );
  }
}
