import 'package:flutter/material.dart';
import '../models/skill.dart';

class SkillItem extends StatelessWidget {
  const SkillItem({super.key, required this.skill});
  final StudentSkill skill;

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF16E883);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text(skill.name)),
            Text('Level ${skill.level.toStringAsFixed(2)}',
                style: const TextStyle(color: green)),
          ]),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            // Visual scale only: raw 42 skill levels, capped at level 20.
            value: (skill.level / 20).clamp(0.0, 1.0),
            minHeight: 7,
            backgroundColor: Colors.white12,
            color: green,
          ),
        ],
      ),
    );
  }
}
