import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:sehatfile/core/routes/app_routes.dart';
import 'package:sehatfile/core/theme/app_colors.dart';
import 'package:sehatfile/core/theme/app_text_styles.dart';
import 'package:sehatfile/core/widgets/care_track_bottom_nav.dart';
import 'package:sehatfile/services/firestore_service.dart';
import 'package:sehatfile/features/chat/chat_screen.dart';
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
  });

  @override
  State<HomeScreen> createState() =>
      _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _firestoreService =
  FirestoreService();

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  // =====================================================
  // GREETING
  // =====================================================

  String _getGreeting() {
    final int hour = DateTime.now().hour;

    if (hour < 12) {
      return 'Good morning';
    }

    if (hour < 17) {
      return 'Good afternoon';
    }

    return 'Good evening';
  }

  // =====================================================
  // OPEN SCREEN
  // =====================================================

  void _openScreen(
      String route,
      ) {
    Navigator.pushNamed(
      context,
      route,
    );
  }

  // =====================================================
  // USER INITIAL
  // =====================================================

  String _getInitial(
      String name,
      ) {
    final String trimmed =
    name.trim();

    if (trimmed.isEmpty) {
      return 'C';
    }

    return trimmed
        .substring(0, 1)
        .toUpperCase();
  }

  // =====================================================
  // TOP SECTION
  // =====================================================

  Widget _buildTopSection(
      String userName,
      ) {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.fromLTRB(
        20,
        18,
        20,
        24,
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
          Row(
            children: [
              // =====================================
              // USER AVATAR
              // =====================================

              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: AppColors.orange,
                  borderRadius:
                  BorderRadius.circular(
                    17,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                      Colors.black.withValues(
                        alpha: 0.10,
                      ),
                      blurRadius: 10,
                      offset:
                      const Offset(
                        0,
                        4,
                      ),
                    ),
                  ],
                ),
                alignment:
                Alignment.center,
                child: Text(
                  _getInitial(userName),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight:
                    FontWeight.w800,
                  ),
                ),
              ),

              const SizedBox(
                width: 13,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getGreeting(),
                      style:
                      AppTextStyles.bodySmall
                          .copyWith(
                        color: Colors.white
                            .withValues(
                          alpha: 0.80,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 3,
                    ),

                    Text(
                      userName,
                      maxLines: 1,
                      overflow:
                      TextOverflow.ellipsis,
                      style:
                      AppTextStyles.titleLarge
                          .copyWith(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight:
                        FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),

              // =====================================
              // HEALTH ICON
              // =====================================

              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color:
                  Colors.white.withValues(
                    alpha: 0.13,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    16,
                  ),
                ),
                child: const Icon(
                  Icons
                      .health_and_safety_outlined,
                  color: Colors.white,
                  size: 25,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 22,
          ),

          // ===========================================
          // UPLOAD REPORT BANNER
          // ===========================================

          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                _openScreen(
                  AppRoutes.records,
                );
              },
              borderRadius:
              BorderRadius.circular(
                22,
              ),
              child: Container(
                width: double.infinity,
                padding:
                const EdgeInsets.all(
                  17,
                ),
                decoration:
                BoxDecoration(
                  color: AppColors.purple,
                  borderRadius:
                  BorderRadius.circular(
                    22,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                      Colors.black
                          .withValues(
                        alpha: 0.10,
                      ),
                      blurRadius: 14,
                      offset:
                      const Offset(
                        0,
                        6,
                      ),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration:
                      BoxDecoration(
                        color: Colors.white
                            .withValues(
                          alpha: 0.16,
                        ),
                        borderRadius:
                        BorderRadius
                            .circular(
                          15,
                        ),
                      ),
                      child:
                      const Icon(
                        Icons
                            .description_outlined,
                        color:
                        Colors.white,
                        size: 26,
                      ),
                    ),

                    const SizedBox(
                      width: 13,
                    ),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                        children: [
                          const Text(
                            'Upload your latest report',
                            style:
                            TextStyle(
                              color:
                              Colors.white,
                              fontWeight:
                              FontWeight
                                  .w800,
                              fontSize: 16,
                            ),
                          ),

                          const SizedBox(
                            height: 4,
                          ),

                          Text(
                            'Keep your medical files safe in one place',
                            style:
                            TextStyle(
                              color: Colors.white
                                  .withValues(
                                alpha: 0.82,
                              ),
                              fontSize: 12,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                      width: 10,
                    ),

                    Container(
                      width: 39,
                      height: 39,
                      decoration:
                      BoxDecoration(
                        color: Colors.white
                            .withValues(
                          alpha: 0.15,
                        ),
                        shape:
                        BoxShape.circle,
                      ),
                      child:
                      const Icon(
                        Icons
                            .arrow_forward_rounded,
                        color:
                        Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // QUICK ACCESS GRID
  // =====================================================

  Widget _quickAccessGrid() {
    final double width =
        MediaQuery.of(context).size.width;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics:
      const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 13,
      mainAxisSpacing: 13,
      childAspectRatio:
      width < 380 ? 0.92 : 1.0,
      children: [
        _QuickAccessCard(
          title: 'Profile',
          subtitle: 'Your details',
          imagePath:
          'assets/images/profile_icon.png',
          backgroundColor:
          AppColors.profileCard,
          onTap: () {
            _openScreen(
              AppRoutes.profiles,
            );
          },
        ),

        _QuickAccessCard(
          title: 'Medicine',
          subtitle:
          'Track & reminders',
          imagePath:
          'assets/images/medicine_icon.png',
          backgroundColor:
          AppColors.medicineCard,
          onTap: () {
            _openScreen(
              AppRoutes.medicines,
            );
          },
        ),

        _QuickAccessCard(
          title: 'Records',
          subtitle:
          'Reports & files',
          imagePath:
          'assets/images/records_icon.png',
          backgroundColor:
          AppColors.recordsCard,
          onTap: () {
            _openScreen(
              AppRoutes.records,
            );
          },
        ),

        _QuickAccessCard(
          title: 'QR Code',
          subtitle:
          'Quick share',
          imagePath:
          'assets/images/qr_icon.png',
          backgroundColor:
          AppColors.qrCard,
          onTap: () {
            _openScreen(
              AppRoutes.qr,
            );
          },
        ),
      ],
    );
  }

  // =====================================================
  // MEDICINE REMINDER CARD
  // =====================================================

  Widget _medicineReminderCard() {
    return StreamBuilder<
        QuerySnapshot<
            Map<String, dynamic>>>(
      stream:
      _firestoreService
          .medicinesStream(),
      builder: (
          context,
          snapshot,
          ) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final medicines =
        snapshot.data!.docs.where(
              (document) {
            final data =
            document.data();

            final bool isCurrent =
                data['isCurrent'] ==
                    true;

            final List<dynamic>
            times =
                data['reminderTimes']
                as List<dynamic>? ??
                    [];

            return isCurrent &&
                times.isNotEmpty;
          },
        ).toList();

        if (medicines.isEmpty) {
          return Container(
            padding:
            const EdgeInsets.all(
              15,
            ),
            decoration: BoxDecoration(
              color:
              AppColors.yellowLight,
              borderRadius:
              BorderRadius.circular(
                19,
              ),
            ),
            child: Row(
              children: [
                _smallIconBox(
                  icon:
                  Icons.alarm_rounded,
                  color:
                  AppColors.orange,
                ),

                const SizedBox(
                  width: 12,
                ),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                    children: [
                      Text(
                        'Medicine reminder',
                        style:
                        AppTextStyles
                            .bodyMedium
                            .copyWith(
                          fontWeight:
                          FontWeight
                              .w800,
                        ),
                      ),

                      const SizedBox(
                        height: 3,
                      ),

                      Text(
                        'No medicine reminder scheduled',
                        style:
                        AppTextStyles
                            .bodySmall
                            .copyWith(
                          color:
                          AppColors
                              .textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        final data =
        medicines.first.data();

        final String medicineName =
            data['medicineName']
                ?.toString()
                .trim() ??
                'Medicine';

        final String dosage =
            data['dosage']
                ?.toString()
                .trim() ??
                '';

        final List<dynamic> times =
            data['reminderTimes']
            as List<dynamic>? ??
                [];

        final String reminder =
        times.isNotEmpty
            ? times.first.toString()
            : '';

        return Container(
          padding:
          const EdgeInsets.all(
            15,
          ),
          decoration: BoxDecoration(
            color:
            AppColors.yellowLight,
            borderRadius:
            BorderRadius.circular(
              19,
            ),
          ),
          child: Row(
            children: [
              _smallIconBox(
                icon:
                Icons.alarm_rounded,
                color:
                AppColors.orange,
              ),

              const SizedBox(
                width: 12,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
                  children: [
                    Text(
                      'Time for your medicine',
                      style:
                      AppTextStyles
                          .bodyMedium
                          .copyWith(
                        fontWeight:
                        FontWeight
                            .w800,
                      ),
                    ),

                    const SizedBox(
                      height: 4,
                    ),

                    Text(
                      [
                        medicineName,
                        if (dosage
                            .isNotEmpty)
                          dosage,
                        if (reminder
                            .isNotEmpty)
                          reminder,
                      ].join(' • '),
                      style:
                      AppTextStyles
                          .bodySmall
                          .copyWith(
                        color:
                        AppColors
                            .textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // =====================================================
  // RECENT ACTIVITY
  // =====================================================

  Widget _recentActivity() {
    return StreamBuilder<
        QuerySnapshot<
            Map<String, dynamic>>>(
      stream:
      _firestoreService
          .recordsStream(),
      builder: (
          context,
          snapshot,
          ) {
        if (!snapshot.hasData ||
            snapshot
                .data!.docs.isEmpty) {
          return const SizedBox
              .shrink();
        }

        final data =
        snapshot.data!.docs.first
            .data();

        final String title =
            data['recordTitle']
                ?.toString()
                .trim() ??
                'Medical record';

        final String type =
            data['recordType']
                ?.toString()
                .trim() ??
                'Record';

        return Container(
          padding:
          const EdgeInsets.all(
            15,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
            BorderRadius.circular(
              19,
            ),
            border: Border.all(
              color:
              AppColors.border,
            ),
          ),
          child: Row(
            children: [
              _smallIconBox(
                icon: Icons
                    .description_outlined,
                color:
                AppColors.green,
              ),

              const SizedBox(
                width: 12,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow:
                      TextOverflow
                          .ellipsis,
                      style:
                      AppTextStyles
                          .bodyMedium
                          .copyWith(
                        fontWeight:
                        FontWeight
                            .w800,
                      ),
                    ),

                    const SizedBox(
                      height: 4,
                    ),

                    Text(
                      '$type • Recently added',
                      style:
                      AppTextStyles
                          .bodySmall
                          .copyWith(
                        color:
                        AppColors
                            .textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              Icon(
                Icons
                    .chevron_right_rounded,
                color:
                AppColors
                    .textSecondary,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _smallIconBox({
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: 43,
      height: 43,
      decoration: BoxDecoration(
        color:
        Colors.white.withValues(
          alpha: 0.78,
        ),
        borderRadius:
        BorderRadius.circular(
          13,
        ),
      ),
      child: Icon(
        icon,
        color: color,
        size: 22,
      ),
    );
  }

  // =====================================================
  // BUILD
  // =====================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      backgroundColor:
      AppColors.background,

      body: SafeArea(
        child: StreamBuilder<
            DocumentSnapshot<
                Map<String, dynamic>>>(
          stream:
          _firestoreService
              .userProfileStream(),
          builder: (
              context,
              snapshot,
              ) {
            final User? user =
                _auth.currentUser;

            final Map<String, dynamic>
            userData =
                snapshot.data
                    ?.data() ??
                    {};

            String userName =
                userData['fullName']
                    ?.toString()
                    .trim() ??
                    '';

            if (userName.isEmpty) {
              userName =
                  user?.displayName
                      ?.trim() ??
                      '';
            }

            if (userName.isEmpty) {
              userName =
              'Care Track User';
            }

            return ListView(
              padding:
              EdgeInsets.zero,
              children: [
                _buildTopSection(
                  userName,
                ),

                Padding(
                  padding:
                  const EdgeInsets
                      .fromLTRB(
                    18,
                    23,
                    18,
                    26,
                  ),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                    children: [
                      Text(
                        'Quick access',
                        style:
                        AppTextStyles
                            .bodyMedium
                            .copyWith(
                          fontSize: 18,
                          fontWeight:
                          FontWeight
                              .w800,
                          color:
                          AppColors
                              .textPrimary,
                        ),
                      ),

                      const SizedBox(
                        height: 10,
                      ),

                      _quickAccessGrid(),

                      const SizedBox(
                        height: 17,
                      ),

                      _medicineReminderCard(),

                      const SizedBox(
                        height: 13,
                      ),

                      _recentActivity(),

                      const SizedBox(
                        height: 8,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),

      bottomNavigationBar:
      CareTrackBottomNav(
        currentIndex: 0,
        onTap: (
            index,
            ) {
          if (index == 0) {
            return;
          }

          if (index == 1) {
            Navigator
                .pushReplacementNamed(
              context,
              AppRoutes.daily,
            );

            return;
          }

          if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const ChatScreen(),
              ),
            );

            return;
          }
        },
      ),
    );
  }
}

// =======================================================
// QUICK ACCESS CARD WITH CUSTOM IMAGE
// =======================================================

class _QuickAccessCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imagePath;
  final Color backgroundColor;
  final VoidCallback onTap;

  const _QuickAccessCard({
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.backgroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AppColors.border,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: 0.035,
                ),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // =====================================
              // BIG CENTERED CUSTOM ICON
              // =====================================

              Align(
                alignment: Alignment.center,
                child: Container(
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: 0.08,
                        ),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Image.asset(
                        imagePath,
                        fit: BoxFit.contain,
                        errorBuilder: (
                            context,
                            error,
                            stackTrace,
                            ) {
                          return Icon(
                            Icons.image_not_supported_outlined,
                            color: AppColors.primary,
                            size: 32,
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),

              const Spacer(),

              // =====================================
              // TITLE
              // =====================================

              Text(
                title,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),

              const SizedBox(height: 4),

              // =====================================
              // SUBTITLE
              // =====================================

              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}