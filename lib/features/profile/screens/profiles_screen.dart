import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:sehatfile/core/routes/app_routes.dart';
import 'package:sehatfile/core/theme/app_colors.dart';
import 'package:sehatfile/core/theme/app_text_styles.dart';


import 'package:sehatfile/features/profile/screens/profile_screen.dart';
import 'package:sehatfile/services/firestore_service.dart';

class ProfilesScreen extends StatelessWidget {
  const ProfilesScreen({super.key});

  String _initials(String name) {
    final parts = name
        .trim()
        .split(' ')
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return 'CT';
    }

    if (parts.length == 1) {
      return parts.first[0].toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService =
    FirestoreService();

    return Scaffold(
      backgroundColor: AppColors.background,

      body: SafeArea(
        child: Column(
          children: [
            // ==========================================
            // HEADER
            // ==========================================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(
                18,
                16,
                18,
                26,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryDark,
                    AppColors.primary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius:
                          BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                          ),
                        ),
                      ),

                      Expanded(
                        child: Text(
                          'Health Profiles',
                          textAlign: TextAlign.center,
                          style:
                          AppTextStyles.titleLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),

                      const SizedBox(width: 48),
                    ],
                  ),

                  const SizedBox(height: 22),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(17),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius:
                      BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                            BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.health_and_safety_outlined,
                            color: AppColors.primary,
                            size: 27,
                          ),
                        ),

                        const SizedBox(width: 13),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Your family, one place',
                                style: AppTextStyles
                                    .bodyMedium
                                    .copyWith(
                                  color: Colors.white,
                                  fontWeight:
                                  FontWeight.w700,
                                ),
                              ),

                              const SizedBox(height: 4),

                              Text(
                                'Keep each person’s health information organized separately.',
                                style: AppTextStyles
                                    .bodySmall
                                    .copyWith(
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ==========================================
            // TITLE
            // ==========================================
            Padding(
              padding: const EdgeInsets.fromLTRB(
                18,
                22,
                18,
                12,
              ),
              child: Row(
                children: [
                  Text(
                    'YOUR PROFILES',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),

            // ==========================================
            // MAIN USER + CREATED PROFILES
            // ==========================================
            Expanded(
              child: StreamBuilder<
                  DocumentSnapshot<
                      Map<String, dynamic>>>(
                stream: firestoreService
                    .userProfileStream(),
                builder: (
                    context,
                    userSnapshot,
                    ) {
                  if (!userSnapshot.hasData) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    );
                  }

                  final userData =
                      userSnapshot.data?.data() ?? {};

                  final String mainName =
                      userData['fullName']
                          ?.toString() ??
                          'My Profile';

                  return StreamBuilder<
                      QuerySnapshot<
                          Map<String, dynamic>>>(
                    stream: firestoreService
                        .profilesStream(),
                    builder: (
                        context,
                        profilesSnapshot,
                        ) {
                      if (profilesSnapshot
                          .connectionState ==
                          ConnectionState.waiting) {
                        return Center(
                          child:
                          CircularProgressIndicator(
                            color:
                            AppColors.primary,
                          ),
                        );
                      }

                      final profiles =
                          profilesSnapshot
                              .data?.docs ??
                              [];

                      return ListView(
                        padding:
                        const EdgeInsets.symmetric(
                          horizontal: 18,
                        ),
                        children: [
                          // ==============================
                          // MAIN / SELF PROFILE
                          // ==============================
                          _ProfileCard(
                            initials:
                            _initials(mainName),
                            name: mainName,
                            relationship: 'My Profile',
                            iconBackground:
                            Colors.orange.shade100,
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.profile,
                              );
                            },
                          ),

                          if (profiles.isNotEmpty)
                            const SizedBox(height: 12),

                          // ==============================
                          // CREATED PROFILES
                          // ==============================
                          ...profiles.map(
                                (profile) {
                              final data =
                              profile.data();

                              final String name =
                                  data['fullName']
                                      ?.toString() ??
                                      'Profile';

                              final String relation =
                                  data['relationship']
                                      ?.toString() ??
                                      'Family';

                              return Padding(
                                padding:
                                const EdgeInsets.only(
                                  bottom: 12,
                                ),
                                child: _ProfileCard(
                                  initials:
                                  _initials(name),
                                  name: name,
                                  relationship:
                                  relation,
                                  iconBackground:
                                  Colors
                                      .teal.shade50,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) =>
                                            ProfileScreen(
                                              profileId:
                                              profile.id,
                                            ),
                                      ),
                                    );
                                  },
                                ),
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

            // ==========================================
            // CREATE PROFILE BUTTON AT END
            // ==========================================
            Padding(
              padding: const EdgeInsets.fromLTRB(
                18,
                10,
                18,
                16,
              ),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor:
                    AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.createProfile,
                    );
                  },
                  icon: const Icon(
                    Icons.person_add_alt_1_rounded,
                  ),
                  label: const Text(
                    'Create New Profile',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      // ==========================================
      // SAME NAV BAR
      // ==========================================
    );
  }
}

// =============================================================
// PROFILE CARD
// =============================================================

class _ProfileCard extends StatelessWidget {
  final String initials;
  final String name;
  final String relationship;
  final Color iconBackground;
  final VoidCallback onTap;

  const _ProfileCard({
    required this.initials,
    required this.name,
    required this.relationship,
    required this.iconBackground,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius:
            BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: iconBackground,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  initials,
                  style:
                  AppTextStyles.titleMedium.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: AppTextStyles
                          .bodyMedium
                          .copyWith(
                        fontWeight:
                        FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Container(
                      padding:
                      const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        borderRadius:
                        BorderRadius.circular(15),
                      ),
                      child: Text(
                        relationship,
                        style: AppTextStyles
                            .bodySmall
                            .copyWith(
                          color:
                          AppColors.primaryDark,
                          fontWeight:
                          FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}