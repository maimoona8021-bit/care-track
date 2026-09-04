import 'package:flutter/material.dart';

import 'package:sehatfile/core/routes/app_routes.dart';
import 'package:sehatfile/core/theme/app_colors.dart';
import 'package:sehatfile/core/theme/app_text_styles.dart';

class DashboardBackAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String title;

  const DashboardBackAppBar({
    super.key,
    required this.title,
  });

  void _goToDashboard(BuildContext context) {
    Navigator.of(
      context,
      rootNavigator: true,
    ).pushNamedAndRemoveUntil(
      AppRoutes.home,
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      centerTitle: false,
      automaticallyImplyLeading: false,

      leading: IconButton(
        tooltip: 'Back to Dashboard',
        onPressed: () {
          _goToDashboard(context);
        },
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: AppColors.textPrimary,
        ),
      ),

      title: Text(
        title,
        style: AppTextStyles.bodyMedium.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}