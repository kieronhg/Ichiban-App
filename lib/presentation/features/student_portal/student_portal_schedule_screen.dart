import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'student_portal_drawer.dart';

class StudentPortalScheduleScreen extends StatelessWidget {
  const StudentPortalScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Schedule')),
      drawer: const StudentPortalDrawer(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 48,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 16),
              Text('Schedule coming soon', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                'Your training schedule and upcoming sessions will appear here.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
