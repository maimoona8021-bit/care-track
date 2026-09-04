import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:sehatfile/core/routes/app_routes.dart';
import 'package:sehatfile/core/theme/app_colors.dart';
import 'package:sehatfile/core/theme/app_text_styles.dart';


import 'package:sehatfile/features/profile/screens/edit_profile_screen.dart';
import 'package:sehatfile/features/profile/widgets/profile_info_card.dart';
import 'package:sehatfile/features/profile/widgets/profile_menu_tile.dart';

import 'package:sehatfile/services/auth_service.dart';
import 'package:sehatfile/services/firestore_service.dart';

class ProfileScreen extends StatelessWidget {
  final String? profileId;

  const ProfileScreen({
    super.key,
    this.profileId,
  });

  // =====================================================
  // INITIALS
  // =====================================================
  String _initials(String name) {
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

    return '${parts.first[0]}${parts.last[0]}'
        .toUpperCase();
  }

  // =====================================================
  // SAFE FIRESTORE VALUE
  // =====================================================
  String _getValue(
      Map<String, dynamic> data,
      String key,
      String fallback,
      ) {
    final dynamic value = data[key];

    if (value == null ||
        value.toString().trim().isEmpty) {
      return fallback;
    }

    return value.toString();
  }

  // =====================================================
  // LOGOUT
  // =====================================================
  Future<void> _logout(
      BuildContext context,
      ) async {
    final bool? shouldLogout =
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(20),
          ),

          title: const Text(
            'Logout?',
          ),

          content: const Text(
            'Are you sure you want to logout of your Care Track account?',
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'Cancel',
              ),
            ),

            FilledButton(
              style:
              FilledButton.styleFrom(
                backgroundColor:
                Colors.red,
              ),
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text(
                'Logout',
              ),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) {
      return;
    }

    await AuthService().signOut();

    if (!context.mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
          (route) => false,
    );
  }

  // =====================================================
  // DELETE CREATED PROFILE
  // =====================================================
  Future<void> _deleteProfile(
      BuildContext context,
      ) async {
    // Main logged-in account
    // cannot be deleted from here.
    if (profileId == null) {
      return;
    }

    final bool? shouldDelete =
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(20),
          ),

          title: const Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.red,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Delete Profile?',
                ),
              ),
            ],
          ),

          content: const Text(
            'Are you sure you want to permanently delete this health profile? This action cannot be undone.',
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'Cancel',
              ),
            ),

            FilledButton(
              style:
              FilledButton.styleFrom(
                backgroundColor:
                Colors.red,
              ),
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text(
                'Delete',
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    try {
      await FirestoreService()
          .deleteProfile(
        profileId: profileId!,
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Profile deleted successfully.',
          ),
        ),
      );

      // Return to profiles list
      Navigator.pop(context);
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Unable to delete profile: $e',
          ),
        ),
      );
    }
  }

  // =====================================================
  // SCREEN
  // =====================================================
  @override
  Widget build(
      BuildContext context,
      ) {
    final FirestoreService firestoreService =
    FirestoreService();

    final User? user =
        FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor:
      AppColors.background,

      body: SafeArea(
        child: StreamBuilder<
            DocumentSnapshot<
                Map<String, dynamic>>>(
          stream:
          firestoreService.profileStream(
            profileId: profileId,
          ),

          builder: (
              context,
              snapshot,
              ) {
            // ==========================================
            // LOADING
            // ==========================================
            if (snapshot.connectionState ==
                ConnectionState.waiting &&
                !snapshot.hasData) {
              return Center(
                child:
                CircularProgressIndicator(
                  color:
                  AppColors.primary,
                ),
              );
            }

            // ==========================================
            // ERROR
            // ==========================================
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding:
                  const EdgeInsets.all(
                    24,
                  ),
                  child: Text(
                    'Unable to load profile.',
                    style: AppTextStyles
                        .bodyMedium,
                  ),
                ),
              );
            }

            final Map<String, dynamic>
            data =
                snapshot.data?.data() ?? {};

            final String name =
            _getValue(
              data,
              'fullName',
              user?.displayName ??
                  'Care Track User',
            );

            final String patientId =
            _getValue(
              data,
              'patientId',
              profileId == null
                  ? user == null
                  ? 'CT-USER'
                  : 'CT-${user.uid.substring(0, 6).toUpperCase()}'
                  : 'CT-PROFILE',
            );

            return SingleChildScrollView(
              padding:
              const EdgeInsets.only(
                bottom: 24,
              ),

              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,

                children: [
                  // ====================================
                  // HEADER
                  // ====================================
                  Container(
                    width: double.infinity,

                    padding:
                    const EdgeInsets.fromLTRB(
                      16,
                      16,
                      16,
                      28,
                    ),

                    decoration: BoxDecoration(
                      gradient:
                      LinearGradient(
                        colors: [
                          AppColors.primaryDark,
                          AppColors.primary,
                        ],

                        begin:
                        Alignment.topLeft,

                        end:
                        Alignment.bottomRight,
                      ),

                      borderRadius:
                      const BorderRadius.only(
                        bottomLeft:
                        Radius.circular(30),

                        bottomRight:
                        Radius.circular(30),
                      ),
                    ),

                    child: Column(
                      children: [
                        // ===============================
                        // TOP BAR
                        // ===============================
                        Row(
                          children: [
                            Container(
                              decoration:
                              BoxDecoration(
                                color:
                                Colors.white24,

                                borderRadius:
                                BorderRadius.circular(
                                  12,
                                ),
                              ),

                              child:
                              IconButton(
                                onPressed: () {
                                  Navigator.pop(
                                    context,
                                  );
                                },

                                icon:
                                const Icon(
                                  Icons
                                      .arrow_back_rounded,

                                  color:
                                  Colors.white,
                                ),
                              ),
                            ),

                            Expanded(
                              child: Text(
                                'Health Profile',

                                textAlign:
                                TextAlign.center,

                                style:
                                AppTextStyles
                                    .titleLarge
                                    .copyWith(
                                  color:
                                  Colors.white,

                                  fontWeight:
                                  FontWeight
                                      .w700,
                                ),
                              ),
                            ),

                            Container(
                              decoration:
                              BoxDecoration(
                                color:
                                Colors.white24,

                                borderRadius:
                                BorderRadius.circular(
                                  12,
                                ),
                              ),

                              child:
                              IconButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,

                                    MaterialPageRoute(
                                      builder:
                                          (context) =>
                                          EditProfileScreen(
                                            profileId:
                                            profileId,
                                          ),
                                    ),
                                  );
                                },

                                icon:
                                const Icon(
                                  Icons
                                      .edit_rounded,

                                  color:
                                  Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(
                          height: 24,
                        ),

                        // ===============================
                        // INITIALS CIRCLE
                        // ===============================
                        Container(
                          width: 96,
                          height: 96,

                          alignment:
                          Alignment.center,

                          decoration:
                          BoxDecoration(
                            color: Colors
                                .orange.shade100,

                            shape:
                            BoxShape.circle,

                            border: Border.all(
                              color:
                              Colors.white,

                              width: 4,
                            ),
                          ),

                          child: Text(
                            _initials(name),

                            style:
                            AppTextStyles
                                .titleLarge
                                .copyWith(
                              color: AppColors
                                  .primaryDark,

                              fontSize: 28,

                              fontWeight:
                              FontWeight
                                  .w700,
                            ),
                          ),
                        ),

                        const SizedBox(
                          height: 14,
                        ),

                        // ===============================
                        // NAME
                        // ===============================
                        Text(
                          name,

                          style:
                          AppTextStyles
                              .titleLarge
                              .copyWith(
                            color:
                            Colors.white,

                            fontWeight:
                            FontWeight.w700,
                          ),
                        ),

                        const SizedBox(
                          height: 5,
                        ),

                        // ===============================
                        // PATIENT ID
                        // ===============================
                        Text(
                          'Patient ID • $patientId',

                          style:
                          AppTextStyles
                              .bodySmall
                              .copyWith(
                            color:
                            Colors.white70,
                          ),
                        ),

                        const SizedBox(
                          height: 12,
                        ),

                        // ===============================
                        // BADGE
                        // ===============================
                        Container(
                          padding:
                          const EdgeInsets
                              .symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),

                          decoration:
                          BoxDecoration(
                            color:
                            Colors.white24,

                            borderRadius:
                            BorderRadius.circular(
                              20,
                            ),
                          ),

                          child: Row(
                            mainAxisSize:
                            MainAxisSize.min,

                            children: [
                              const Icon(
                                Icons
                                    .health_and_safety_outlined,

                                color:
                                Colors.white,

                                size: 17,
                              ),

                              const SizedBox(
                                width: 6,
                              ),

                              Text(
                                profileId == null
                                    ? 'Main Profile'
                                    : 'Health Profile',

                                style:
                                const TextStyle(
                                  color:
                                  Colors.white,

                                  fontWeight:
                                  FontWeight
                                      .w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ====================================
                  // BASIC INFORMATION TITLE
                  // ====================================
                  Padding(
                    padding:
                    const EdgeInsets.fromLTRB(
                      18,
                      22,
                      18,
                      12,
                    ),

                    child: Text(
                      'BASIC INFORMATION',

                      style:
                      AppTextStyles
                          .bodySmall
                          .copyWith(
                        color: AppColors
                            .primaryDark,

                        fontWeight:
                        FontWeight.w700,

                        letterSpacing: 1,
                      ),
                    ),
                  ),

                  // ====================================
                  // INFORMATION CARDS
                  // ====================================
                  // ====================================
// INFORMATION CARDS
// ====================================
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                    ),
                    child: GridView.count(
                      shrinkWrap: true,
                      physics:
                      const NeverScrollableScrollPhysics(),

                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.1,

                      children: [
                        // ==================================
                        // DATE OF BIRTH
                        // ==================================
                        ProfileInfoCard(
                          icon: Icons.cake_outlined,
                          label: 'Date of birth',
                          value: _getValue(
                            data,
                            'dateOfBirth',
                            'Not added',
                          ),
                          iconColor: Colors.orange,
                          iconBackgroundColor:
                          Colors.orange.shade50,
                        ),

                        // ==================================
                        // GENDER
                        // ==================================
                        ProfileInfoCard(
                          icon: Icons.people_outline,
                          label: 'Gender',
                          value: _getValue(
                            data,
                            'gender',
                            'Not added',
                          ),
                          iconColor: Colors.indigo,
                          iconBackgroundColor:
                          Colors.indigo.shade50,
                        ),

                        // ==================================
                        // BLOOD GROUP
                        // ==================================
                        ProfileInfoCard(
                          icon: Icons.bloodtype_outlined,
                          label: 'Blood group',
                          value: _getValue(
                            data,
                            'bloodGroup',
                            'Not added',
                          ),
                          iconColor: Colors.red,
                          iconBackgroundColor:
                          Colors.red.shade50,
                        ),

                        // ==================================
                        // HEIGHT
                        // ==================================
                        ProfileInfoCard(
                          icon: Icons.straighten_outlined,
                          label: 'Height',
                          value: _getValue(
                            data,
                            'height',
                            'Not added',
                          ),
                          iconColor: Colors.deepPurple,
                          iconBackgroundColor:
                          Colors.deepPurple.shade50,
                        ),

                        // ==================================
                        // WEIGHT
                        // ==================================
                        ProfileInfoCard(
                          icon:
                          Icons.monitor_weight_outlined,
                          label: 'Weight',
                          value: _getValue(
                            data,
                            'weight',
                            'Not added',
                          ),
                          iconColor: Colors.orange,
                          iconBackgroundColor:
                          Colors.orange.shade50,
                        ),

                        // ==================================
                        // RELATIONSHIP
                        // ==================================
                        ProfileInfoCard(
                          icon:
                          Icons.family_restroom_rounded,
                          label: 'Relationship',
                          value: profileId == null
                              ? 'Self'
                              : _getValue(
                            data,
                            'relationship',
                            'Not added',
                          ),
                          iconColor: Colors.teal,
                          iconBackgroundColor:
                          Colors.teal.shade50,
                        ),
                      ],
                    ),
                  ),
                  // ====================================
                  // SETTINGS TITLE
                  // ====================================
                  Padding(
                    padding:
                    const EdgeInsets.fromLTRB(
                      18,
                      28,
                      18,
                      12,
                    ),

                    child: Text(
                      'ACCOUNT & SETTINGS',

                      style:
                      AppTextStyles
                          .bodySmall
                          .copyWith(
                        color: AppColors
                            .primaryDark,

                        fontWeight:
                        FontWeight.w700,

                        letterSpacing: 1,
                      ),
                    ),
                  ),

                  // ====================================
                  // SETTINGS OPTIONS
                  // ====================================
                  Padding(
                    padding:
                    const EdgeInsets.symmetric(
                      horizontal: 18,
                    ),

                    child: Column(
                      children: [
                        // EDIT PROFILE
                        ProfileMenuTile(
                          icon:
                          Icons.edit_outlined,

                          title:
                          'Edit Profile',

                          subtitle:
                          'Personal and health information',

                          onTap: () {
                            Navigator.push(
                              context,

                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                    EditProfileScreen(
                                      profileId:
                                      profileId,
                                    ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(
                          height: 10,
                        ),

                        // HELP
                        ProfileMenuTile(
                          icon: Icons
                              .help_outline_rounded,

                          title:
                          'Help & Support',

                          subtitle:
                          'FAQs and support',

                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes
                                  .helpSupport,
                            );
                          },
                        ),

                        const SizedBox(
                          height: 10,
                        ),

                        // ABOUT
                        ProfileMenuTile(
                          icon: Icons
                              .info_outline_rounded,

                          title:
                          'About Care Track',

                          subtitle:
                          'App information',

                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.about,
                            );
                          },
                        ),

                        // =================================
                        // DELETE PROFILE
                        // ONLY FOR CREATED PROFILES
                        // =================================
                        if (profileId !=
                            null) ...[
                          const SizedBox(
                            height: 10,
                          ),

                          ProfileMenuTile(
                            icon: Icons
                                .delete_outline_rounded,

                            title:
                            'Delete Profile',

                            subtitle:
                            'Permanently remove this health profile',

                            iconColor:
                            Colors.red,

                            titleColor:
                            Colors.red,

                            onTap: () {
                              _deleteProfile(
                                context,
                              );
                            },
                          ),
                        ],

                        const SizedBox(
                          height: 10,
                        ),

                        // LOGOUT
                        ProfileMenuTile(
                          icon:
                          Icons.logout_rounded,

                          title: 'Logout',

                          iconColor:
                          Colors.red,

                          titleColor:
                          Colors.red,

                          onTap: () {
                            _logout(
                              context,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),

      // ========================================
      // SAME BOTTOM NAVIGATION
      // ========================================

    );
  }
}