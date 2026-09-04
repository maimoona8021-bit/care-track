import 'package:flutter/material.dart';

import 'package:sehatfile/core/theme/app_colors.dart';
import 'package:sehatfile/core/theme/app_text_styles.dart';

import 'package:sehatfile/features/profile/screens/change_password_screen.dart';
import 'package:sehatfile/features/profile/widgets/profile_menu_tile.dart';
import 'package:sehatfile/features/profile/widgets/profile_page_scaffold.dart';

class PrivacySecurityScreen extends StatelessWidget {
  const PrivacySecurityScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ProfilePageScaffold(
      title: 'Privacy & Security',

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            // ==========================================
            // SECURITY INFO CARD
            // ==========================================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),

              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(18),
              ),

              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,

                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),

                    child: Icon(
                      Icons.security_rounded,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        Text(
                          'Account Security',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          'Manage your password and account security.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 26),

            // ==========================================
            // SECURITY SETTINGS TITLE
            // ==========================================
            Text(
              'SECURITY SETTINGS',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),

            const SizedBox(height: 12),

            // ==========================================
            // CHANGE PASSWORD
            // ==========================================
            ProfileMenuTile(
              icon: Icons.password_rounded,
              title: 'Change Password',
              subtitle: 'Update your account password',

              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                    const ChangePasswordScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            // ==========================================
            // APP LOCK - FUTURE FEATURE
            // ==========================================
            ProfileMenuTile(
              icon: Icons.lock_outline_rounded,
              title: 'App Lock',
              subtitle: 'Protect Care Track with an app lock',

              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'App lock will be connected later.',
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            // ==========================================
            // BIOMETRIC LOCK - FUTURE FEATURE
            // ==========================================
            ProfileMenuTile(
              icon: Icons.fingerprint_rounded,
              title: 'Biometric Lock',
              subtitle: 'Use fingerprint to protect your data',

              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Biometric lock will be connected later.',
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 28),

            // ==========================================
            // ACCOUNT MANAGEMENT
            // ==========================================
            Text(
              'ACCOUNT MANAGEMENT',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),

            const SizedBox(height: 12),

            // ==========================================
            // DELETE ACCOUNT
            // ==========================================
            ProfileMenuTile(
              icon: Icons.delete_outline_rounded,
              title: 'Delete Account',
              subtitle: 'Permanently remove your account',
              iconColor: Colors.red,
              titleColor: Colors.red,

              onTap: () {
                showDialog(
                  context: context,

                  builder: (dialogContext) {
                    return AlertDialog(
                      title: const Text(
                        'Delete Account?',
                      ),

                      content: const Text(
                        'Account deletion will be connected after '
                            'your medical records and files are fully '
                            'integrated so all data can be removed safely.',
                      ),

                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(dialogContext);
                          },

                          child: const Text('Cancel'),
                        ),

                        TextButton(
                          onPressed: () {
                            Navigator.pop(dialogContext);
                          },

                          child: const Text(
                            'OK',
                            style: TextStyle(
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}