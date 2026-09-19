import 'package:flutter/material.dart';

import '../models/skill.dart';

class SkillItem extends StatelessWidget {
  const SkillItem({
    super.key,
    required this.skill,
  });

  final StudentSkill skill;

  static const double maximumSkillLevel = 21.0;

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF16E883);

    final progress =
        (skill.level / maximumSkillLevel).clamp(0.0, 1.0);

    final percentage = (progress * 100).floor();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(skill.name),
              ),
              Text(
                '${skill.level.toStringAsFixed(2)} ($percentage%)',
                style: const TextStyle(
                  color: green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            minHeight: 7,
            backgroundColor: Colors.white12,
            color: green,
          ),
        ],
      ),
    );
  }
}