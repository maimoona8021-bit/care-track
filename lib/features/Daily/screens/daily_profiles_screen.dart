import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:sehatfile/core/routes/app_routes.dart';
import 'package:sehatfile/core/theme/app_colors.dart';
import 'package:sehatfile/core/theme/app_text_styles.dart';
import 'package:sehatfile/core/widgets/dashboard_back_app_bar.dart';
import 'package:sehatfile/features/daily/screens/daily_screen.dart';
import 'package:sehatfile/services/firestore_service.dart';

class DailyProfilesScreen extends StatelessWidget {
  DailyProfilesScreen({
    super.key,
  });

  final FirestoreService _firestoreService = FirestoreService();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // =====================================================
  // INITIALS
  // =====================================================

  String _initials(
      String name,
      ) {
    final List<String> parts = name
        .trim()
        .split(' ')
        .where(
          (part) => part.isNotEmpty,
    )
        .toList();

    if (parts.isEmpty) {
      return 'CT';
    }

    if (parts.length == 1) {
      return parts.first[0].toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  // =====================================================
  // GO TO DASHBOARD
  // =====================================================

  void _goToDashboard(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.home,
          (route) => false,
    );
  }

  // =====================================================
  // OPEN DAILY
  // =====================================================

  void _openDaily({
    required BuildContext context,
    required String profileName,
    required String? profileId,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DailyScreen(
          profileName: profileName,
          profileId: profileId,
        ),
      ),
    );
  }

  // =====================================================
  // PROFILE CARD
  // =====================================================

  Widget _profileCard({
    required BuildContext context,
    required String name,
    required String subtitle,
    required String? profileId,
    required bool isMainProfile,
  }) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(
          18,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(
            18,
          ),
          onTap: () {
            _openDaily(
              context: context,
              profileName: name,
              profileId: profileId,
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(
              14,
            ),
            child: Row(
              children: [
                // =====================================
                // AVATAR
                // =====================================

                Container(
                  width: 54,
                  height: 54,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isMainProfile
                        ? Colors.teal.shade50
                        : Colors.deepPurple.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    _initials(
                      name,
                    ),
                    style: TextStyle(
                      color: isMainProfile
                          ? AppColors.primary
                          : Colors.deepPurple,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),

                const SizedBox(
                  width: 13,
                ),

                // =====================================
                // PROFILE INFORMATION
                // =====================================

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),

                          if (isMainProfile) ...[
                            const SizedBox(
                              width: 7,
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.teal.shade50,
                                borderRadius: BorderRadius.circular(
                                  8,
                                ),
                              ),
                              child: Text(
                                'Me',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(
                        height: 5,
                      ),

                      Text(
                        subtitle,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  width: 8,
                ),

                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(
                      11,
                    ),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: AppColors.primary,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =====================================================
  // EMPTY FAMILY PROFILES
  // =====================================================

  Widget _emptyFamilyProfiles() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        18,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          17,
        ),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.group_outlined,
              color: AppColors.primary,
              size: 27,
            ),
          ),

          const SizedBox(
            height: 11,
          ),

          const Text(
            'No family profiles yet',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(
            height: 5,
          ),

          Text(
            'Created family profiles will appear here.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // SCREEN
  // =====================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    final User? user = _auth.currentUser;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (
          bool didPop,
          Object? result,
          ) {
        if (didPop) {
          return;
        }

        _goToDashboard(context);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,

        // =================================================
        // TOP BACK BUTTON
        // =================================================

        appBar: const DashboardBackAppBar(
          title: 'Daily Health',
        ),

        body: SafeArea(
          child: StreamBuilder<
              DocumentSnapshot<Map<String, dynamic>>>(
            stream: _firestoreService.userProfileStream(),

            builder: (
                context,
                userSnapshot,
                ) {
              if (userSnapshot.connectionState ==
                  ConnectionState.waiting &&
                  !userSnapshot.hasData) {
                return Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                );
              }

              if (userSnapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(
                      24,
                    ),
                    child: Text(
                      'Unable to load your profile.\n'
                          '${userSnapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              final Map<String, dynamic> userData =
                  userSnapshot.data?.data() ?? {};

              String mainUserName =
                  userData['fullName']?.toString().trim() ?? '';

              if (mainUserName.isEmpty) {
                mainUserName = user?.displayName?.trim() ?? '';
              }

              if (mainUserName.isEmpty) {
                mainUserName = 'My Profile';
              }

              // =========================================
              // FAMILY PROFILES
              // =========================================

              return StreamBuilder<
                  QuerySnapshot<Map<String, dynamic>>>(
                stream: _firestoreService.profilesStream(),

                builder: (
                    context,
                    profilesSnapshot,
                    ) {
                  if (profilesSnapshot.connectionState ==
                      ConnectionState.waiting &&
                      !profilesSnapshot.hasData) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    );
                  }

                  if (profilesSnapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(
                          24,
                        ),
                        child: Text(
                          'Unable to load profiles.\n'
                              '${profilesSnapshot.error}',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  final profiles =
                      profilesSnapshot.data?.docs ?? [];

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(
                      18,
                      18,
                      18,
                      28,
                    ),
                    children: [
                      // =================================
                      // INTRODUCTION
                      // =================================

                      Text(
                        'Choose whose daily medicines and health readings you want to manage.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.45,
                        ),
                      ),

                      const SizedBox(
                        height: 24,
                      ),

                      // =================================
                      // MAIN PROFILE
                      // =================================

                      Text(
                        'My Profile',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      const SizedBox(
                        height: 10,
                      ),

                      _profileCard(
                        context: context,
                        name: mainUserName,
                        subtitle:
                        'My medicines, health checks & history',
                        profileId: null,
                        isMainProfile: true,
                      ),

                      const SizedBox(
                        height: 18,
                      ),

                      // =================================
                      // FAMILY PROFILES
                      // =================================

                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Family Profiles',
                              style:
                              AppTextStyles.bodyMedium.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),

                          Text(
                            '${profiles.length}',
                            style:
                            AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 10,
                      ),

                      if (profiles.isEmpty)
                        _emptyFamilyProfiles()
                      else
                        ...profiles.map(
                              (document) {
                            final Map<String, dynamic> data =
                            document.data();

                            final String name =
                                data['fullName']
                                    ?.toString()
                                    .trim() ??
                                    'Family Member';

                            final String relationship =
                                data['relationship']
                                    ?.toString()
                                    .trim() ??
                                    'Family Profile';

                            return _profileCard(
                              context: context,
                              name: name,
                              subtitle: relationship,
                              profileId: document.id,
                              isMainProfile: false,
                            );
                          },
                        ),
                    ],
                  );
                },
              );
            },
          ),
        ),

        // No bottom navigation on this screen.
      ),
    );
  }
}