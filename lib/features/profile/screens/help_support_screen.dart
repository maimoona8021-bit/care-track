import 'package:flutter/material.dart';

import 'package:sehatfile/core/theme/app_colors.dart';
import 'package:sehatfile/core/theme/app_text_styles.dart';
import 'package:sehatfile/features/profile/widgets/profile_page_scaffold.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  Widget _helpCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius:
              BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles
                      .bodyMedium
                      .copyWith(
                    fontWeight:
                    FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  description,
                  style: AppTextStyles
                      .bodySmall
                      .copyWith(
                    color:
                    AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ProfilePageScaffold(
      title: 'Help & Support',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            // ==========================================
            // INTRODUCTION
            // ==========================================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius:
                BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons
                        .support_agent_rounded,
                    color:
                    AppColors.primary,
                    size: 34,
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          'How can we help?',
                          style: AppTextStyles
                              .titleLarge
                              .copyWith(
                            fontWeight:
                            FontWeight.w700,
                          ),
                        ),

                        const SizedBox(
                          height: 4,
                        ),

                        Text(
                          'Find quick answers about using Care Track.',
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
                ],
              ),
            ),

            const SizedBox(height: 24),

            Text(
              'Frequently Asked Questions',
              style: AppTextStyles
                  .titleLarge
                  .copyWith(
                fontWeight:
                FontWeight.w700,
              ),
            ),

            const SizedBox(height: 14),

            _helpCard(
              icon:
              Icons.person_add_alt_1_outlined,
              title:
              'How do I create a profile?',
              description:
              'Open Profiles from the dashboard and select Create New Profile. Add the person’s basic information and save.',
            ),

            _helpCard(
              icon:
              Icons.folder_outlined,
              title:
              'How do I add medical records?',
              description:
              'Open the Records section and choose the profile whose medical information you want to manage.',
            ),

            _helpCard(
              icon:
              Icons.medication_outlined,
              title:
              'How do I manage medicines?',
              description:
              'Open Medicines from the dashboard to add and manage medicine information for your health profiles.',
            ),

            _helpCard(
              icon:
              Icons.qr_code_rounded,
              title:
              'What is QR sharing?',
              description:
              'QR sharing allows important health information to be shared quickly when needed.',
            ),

            _helpCard(
              icon:
              Icons.edit_outlined,
              title:
              'How do I update a profile?',
              description:
              'Open the Health Profile and select Edit Profile to change personal or health information.',
            ),

            const SizedBox(height: 14),

            // ==========================================
            // CONTACT SUPPORT
            // ==========================================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.border,
                ),
              ),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.email_outlined,
                        color:
                        AppColors.primary,
                      ),

                      const SizedBox(
                        width: 10,
                      ),

                      Text(
                        'Contact Support',
                        style: AppTextStyles
                            .bodyMedium
                            .copyWith(
                          fontWeight:
                          FontWeight.w700,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  Text(
                    'If you need additional help, contact the Care Track support team.',
                    style: AppTextStyles
                        .bodySmall
                        .copyWith(
                      color: AppColors
                          .textSecondary,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    'support@caretrack.app',
                    style: AppTextStyles
                        .bodyMedium
                        .copyWith(
                      color:
                      AppColors.primary,
                      fontWeight:
                      FontWeight.w600,
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