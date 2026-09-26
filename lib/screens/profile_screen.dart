import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/user.dart';
import '../widgets/project_item.dart';
import '../widgets/skill_item.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.student,
  });

  final StudentUser student;

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF16E883);
    final level = student.level;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundImage: student.imageUrl == null
                            ? null
                            : NetworkImage(student.imageUrl!),
                        child: student.imageUrl == null
                            ? const Icon(
                                Icons.person,
                                size: 38,
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              student.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall,
                            ),
                            Text(
                              student.login,
                              style: const TextStyle(color: green),
                            ),
                            if (student.cursusName != null)
                              Text(student.cursusName!),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  if (level != null) ...[
                    Row(
                      children: [
                        Text('LEVEL ${level.floor()}'),
                        const Spacer(),
                        Text( 
                          '${((level - level.floor()) * 100).round()}%',
                          style: const TextStyle(color: green),
                        ),
                          //level.toStringAsFixed(2),
                          //style: const TextStyle(color: green),
                        //),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: level - level.floorToDouble(),
                      color: green,
                      backgroundColor: Colors.white12,
                      minHeight: 8,
                    ),
                    const SizedBox(height: 20),
                  ],

                  Wrap(
                    spacing: 12,
                    runSpacing: 10,
                    children: [
                      if (student.wallet != null)
                        _Fact(
                          'Wallet',
                          '${student.wallet} ₳',
                        ),

                      if (student.evaluationPoints != null)
                        _Fact(
                          'Evaluation',
                          '${student.evaluationPoints} pts',
                        ),

                      if (student.email != null &&
                          student.email!.isNotEmpty)
                        _Fact(
                          'Email',
                          student.email!,
                        ),

                      if (student.phone != null &&
                          student.phone!.isNotEmpty)
                        _Fact(
                          'Phone',
                          student.phone!.toLowerCase() == 'hidden'
                              ? 'Private'
                              : student.phone!,
                        ),

                      if (student.campusName != null &&
                          student.campusName!.isNotEmpty)
                        _Fact(
                          'Campus',
                          student.campusName!,
                        ),
                    ],
                  ),
                ],
              ),
            ),

            TabBar(
              labelColor: green,
              indicatorColor: green,
              tabs: [
                Tab(
                  text: 'Skills (${student.skills.length})',
                ),
                Tab(
                  text: 'Projects (${student.projects.length})',
                ),
              ],
            ),

            Expanded(
              child: TabBarView(
                children: [
                  student.skills.isEmpty
                      ? const Center(
                          child: Text(
                            'No skills available for this cursus.',
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          itemCount: student.skills.length,
                          itemBuilder: (_, index) {
                            return SkillItem(
                              skill: student.skills[index],
                            );
                          },
                        ),

                  student.projects.isEmpty
                      ? const Center(
                          child: Text(
                            'No projects available.',
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: student.projects.length,
                          itemBuilder: (_, index) {
                            return ProjectItem(
                              project: student.projects[index],
                            );
                          },
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: math.max(
          140,
          MediaQuery.sizeOf(context).width - 40,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
            ),
          ),
          SelectableText(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}