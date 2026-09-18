import 'package:flutter/material.dart';
import '../models/project.dart';

class ProjectItem extends StatelessWidget {
  const ProjectItem({super.key, required this.project});
  final StudentProject project;

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          title: Text(project.name),
          subtitle: Text(project.status),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(project.finalMark?.toString() ?? '—',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              if (project.validated != null)
                Icon(project.validated! ? Icons.check_circle : Icons.cancel,
                    size: 16,
                    color: project.validated! ? const Color(0xFF16E883) : Colors.redAccent),
            ],
          ),
        ),
      );
}
