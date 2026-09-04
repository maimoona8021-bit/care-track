import 'package:flutter/material.dart';

import 'package:sehatfile/core/theme/app_colors.dart';

class CareTrackBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CareTrackBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      backgroundColor: Colors.white,
      indicatorColor: AppColors.primary.withOpacity(0.12),

      destinations: const [
        NavigationDestination(
          icon: Icon(
            Icons.home_outlined,
          ),
          selectedIcon: Icon(
            Icons.home_rounded,
          ),
          label: 'Dashboard',
        ),

        NavigationDestination(
          icon: Icon(
            Icons.calendar_today_outlined,
          ),
          selectedIcon: Icon(
            Icons.calendar_today_rounded,
          ),
          label: 'Daily',
        ),

        NavigationDestination(
          icon: Icon(
            Icons.health_and_safety_outlined,
          ),
          selectedIcon: Icon(
            Icons.health_and_safety_rounded,
          ),
          label: 'Care Guide',
        ),
      ],
    );
  }
}