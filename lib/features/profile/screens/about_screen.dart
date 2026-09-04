import 'package:flutter/material.dart';

import 'package:sehatfile/core/theme/app_colors.dart';
import 'package:sehatfile/core/theme/app_text_styles.dart';
import 'package:sehatfile/features/profile/widgets/profile_page_scaffold.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Widget _feature({
    required IconData icon,
    required String title,
  }) {
    return Padding(
      padding:
      const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius:
              BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 20,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              title,
              style:
              AppTextStyles.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ProfilePageScaffold(
      title: 'About Care Track',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            // ==========================================
            // APP HEADER
            // ==========================================
            Center(
              child: Column(
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color:
                      Colors.teal.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons
                          .health_and_safety_rounded,
                      size: 48,
                      color:
                      AppColors.primary,
                    ),
                  ),

                  const SizedBox(height: 14),

                  Text(
                    'Care Track',
                    style: AppTextStyles
                        .titleLarge
                        .copyWith(
                      fontSize: 24,
                      fontWeight:
                      FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    'Your health, all in one place',
                    style: AppTextStyles
                        .bodySmall
                        .copyWith(
                      color: AppColors
                          .textSecondary,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Container(
                    padding:
                    const EdgeInsets
                        .symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration:
                    BoxDecoration(
                      color:
                      Colors.teal.shade50,
                      borderRadius:
                      BorderRadius.circular(
                        20,
                      ),
                    ),
                    child: Text(
                      'Version 1.0.0',
                      style: AppTextStyles
                          .bodySmall
                          .copyWith(
                        color:
                        AppColors.primary,
                        fontWeight:
                        FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // ==========================================
            // ABOUT
            // ==========================================
            Text(
              'About Care Track',
              style: AppTextStyles
                  .titleLarge
                  .copyWith(
                fontWeight:
                FontWeight.w700,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              'Care Track is a personal health record management application designed to help individuals and families organize important health information in one convenient place.',
              style:
              AppTextStyles.bodyMedium.copyWith(
                color:
                AppColors.textSecondary,
                height: 1.6,
              ),
            ),

            const SizedBox(height: 26),

            // ==========================================
            // PURPOSE
            // ==========================================
            Text(
              'Our Purpose',
              style: AppTextStyles
                  .titleLarge
                  .copyWith(
                fontWeight:
                FontWeight.w700,
              ),
            ),

            const SizedBox(height: 10),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius:
                BorderRadius.circular(16),
              ),
              child: Text(
                'To make personal and family health information easier to organize, manage and access when needed.',
                style:
                AppTextStyles.bodyMedium.copyWith(
                  height: 1.5,
                ),
              ),
            ),

            const SizedBox(height: 26),

            // ==========================================
            // FEATURES
            // ==========================================
            Text(
              'Main Features',
              style: AppTextStyles
                  .titleLarge
                  .copyWith(
                fontWeight:
                FontWeight.w700,
              ),
            ),

            const SizedBox(height: 16),

            _feature(
              icon:
              Icons.people_outline,
              title:
              'Multiple health profiles',
            ),

            _feature(
              icon:
              Icons.folder_outlined,
              title:
              'Medical record management',
            ),

            _feature(
              icon:
              Icons.description_outlined,
              title:
              'Prescription and report storage',
            ),

            _feature(
              icon:
              Icons.medication_outlined,
              title:
              'Medicine management',
            ),

            _feature(
              icon:
              Icons.monitor_heart_outlined,
              title:
              'Health information tracking',
            ),

            _feature(
              icon:
              Icons.qr_code_rounded,
              title:
              'QR health sharing',
            ),

            const SizedBox(height: 24),

            const Divider(),

            const SizedBox(height: 18),

            Center(
              child: Column(
                children: [
                  Text(
                    'Care Track',
                    style: AppTextStyles
                        .bodyMedium
                        .copyWith(
                      fontWeight:
                      FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    'Built with Flutter & Firebase',
                    style: AppTextStyles
                        .bodySmall
                        .copyWith(
                      color: AppColors
                          .textSecondary,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    '© 2026 Care Track',
                    style: AppTextStyles
                        .bodySmall
                        .copyWith(
                      color: AppColors
                          .textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}