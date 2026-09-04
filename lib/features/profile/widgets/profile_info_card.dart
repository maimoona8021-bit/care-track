import 'package:flutter/material.dart';

import 'package:sehatfile/core/theme/app_colors.dart';
import 'package:sehatfile/core/theme/app_text_styles.dart';

class ProfileInfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final Color iconBackgroundColor;

  const ProfileInfoCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    required this.iconBackgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.border,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconBackgroundColor,
              borderRadius:
              BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 23,
            ),
          ),

          const Spacer(),

          Text(
            label,
            style:
            AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style:
            AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}