import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';

class StudentNavBar extends StatelessWidget {
  const StudentNavBar({super.key, required this.currentIndex});

  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      onTap: (index) {
        if (index == currentIndex) return;
        switch (index) {
          case 0:
            context.go(RouteNames.studentHome);
          case 1:
            context.go(RouteNames.studentAttendance);
          case 2:
            context.go(RouteNames.studentGrades);
          case 3:
            context.go(RouteNames.studentProfile);
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.fitness_center_outlined),
          activeIcon: Icon(Icons.fitness_center),
          label: 'Attendance',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.military_tech_outlined),
          activeIcon: Icon(Icons.military_tech),
          label: 'Grades',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'My Profile',
        ),
      ],
    );
  }
}
