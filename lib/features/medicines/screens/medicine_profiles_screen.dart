import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:sehatfile/core/routes/app_routes.dart';
import 'package:sehatfile/core/theme/app_colors.dart';
import 'package:sehatfile/core/theme/app_text_styles.dart';

import 'medicines_screen.dart';
import 'package:sehatfile/services/firestore_service.dart';

class  MedicineProfilesScreen
    extends StatefulWidget {
  const MedicineProfilesScreen({
    super.key,
  });

  @override
  State<MedicineProfilesScreen>
  createState() =>
      _MedicineProfilesScreenState();
}

class _MedicineProfilesScreenState
    extends State<MedicineProfilesScreen> {
  final FirestoreService _firestoreService =
  FirestoreService();

  final TextEditingController searchController =
  TextEditingController();

  String searchText = '';

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

  bool _matchesSearch(String name) {
    return name
        .toLowerCase()
        .contains(searchText.toLowerCase());
  }

  void _openMedicines({
    required String profileName,
    String? profileId,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>  MedicinesScreen(
          profileId: profileId,
          profileName: profileName,
        ),
      ),
    );
  }

  Widget _profileCard({
    required String name,
    required String relationship,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color:
            Colors.black.withValues(
              alpha: 0.04,
            ),
            blurRadius: 8,
            offset: const Offset(
              0,
              3,
            ),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius:
          BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding:
            const EdgeInsets.all(15),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  alignment:
                  Alignment.center,
                  decoration:
                  BoxDecoration(
                    color:
                    Colors.teal.shade50,
                    shape:
                    BoxShape.circle,
                  ),
                  child: Text(
                    _initials(name),
                    style: TextStyle(
                      color:
                      AppColors.primary,
                      fontWeight:
                      FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
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

                      const SizedBox(
                        height: 4,
                      ),

                      Text(
                        relationship,
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

                Container(
                  width: 38,
                  height: 38,
                  decoration:
                  BoxDecoration(
                    color:
                    Colors.teal.shade50,
                    borderRadius:
                    BorderRadius.circular(
                      11,
                    ),
                  ),
                  child: Icon(
                    Icons
                        .arrow_forward_ios_rounded,
                    size: 16,
                    color:
                    AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      AppColors.background,

      body: SafeArea(
        child: Column(
          children: [
            // ========================================
            // HEADER
            // ========================================
            Container(
              width: double.infinity,
              padding:
              const EdgeInsets.fromLTRB(
                18,
                16,
                18,
                24,
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
                  Radius.circular(28),
                  bottomRight:
                  Radius.circular(28),
                ),
              ),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration:
                    BoxDecoration(
                      color: Colors.white24,
                      borderRadius:
                      BorderRadius.circular(
                        12,
                      ),
                    ),
                    child: IconButton(
                      onPressed: () {
                        Navigator.pop(
                          context,
                        );
                      },
                      icon: const Icon(
                        Icons
                            .arrow_back_rounded,
                        color:
                        Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 18,
                  ),

                  Text(
                    'Medicines',
                    style: AppTextStyles
                        .titleLarge
                        .copyWith(
                      color:
                      Colors.white,
                      fontSize: 25,
                      fontWeight:
                      FontWeight.w700,
                    ),
                  ),

                  const SizedBox(
                    height: 5,
                  ),

                  Text(
                    'Manage your current and previous medications',
                    style: AppTextStyles
                        .bodySmall
                        .copyWith(
                      color:
                      Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            // ========================================
            // BODY
            // ========================================
            Expanded(
              child:
              SingleChildScrollView(
                padding:
                const EdgeInsets.all(
                  18,
                ),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
                  children: [
                    // SEARCH
                    TextField(
                      controller:
                      searchController,
                      onChanged: (value) {
                        setState(() {
                          searchText =
                              value.trim();
                        });
                      },
                      decoration:
                      InputDecoration(
                        hintText:
                        'Search profiles',
                        prefixIcon: Icon(
                          Icons
                              .search_rounded,
                          color: AppColors
                              .primary,
                        ),
                        filled: true,
                        fillColor:
                        Colors.white,
                        border:
                        OutlineInputBorder(
                          borderRadius:
                          BorderRadius
                              .circular(
                            16,
                          ),
                          borderSide:
                          BorderSide.none,
                        ),
                        enabledBorder:
                        OutlineInputBorder(
                          borderRadius:
                          BorderRadius
                              .circular(
                            16,
                          ),
                          borderSide:
                          BorderSide(
                            color: AppColors
                                .border,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 24,
                    ),

                    Text(
                      'SELECT HEALTH PROFILE',
                      style: AppTextStyles
                          .bodySmall
                          .copyWith(
                        color: AppColors
                            .primaryDark,
                        fontWeight:
                        FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),

                    const SizedBox(
                      height: 14,
                    ),

                    // ==================================
                    // MAIN USER
                    // ==================================
                    StreamBuilder<
                        DocumentSnapshot<
                            Map<String,
                                dynamic>>>(
                      stream:
                      _firestoreService
                          .userProfileStream(),
                      builder: (
                          context,
                          snapshot,
                          ) {
                        if (!snapshot
                            .hasData) {
                          return const SizedBox();
                        }

                        final data =
                            snapshot.data!
                                .data() ??
                                {};

                        final String name =
                            data['fullName']
                                ?.toString() ??
                                'Care Track User';

                        if (!_matchesSearch(
                          name,
                        )) {
                          return const SizedBox();
                        }

                        return _profileCard(
                          name: name,
                          relationship:
                          'Self',
                          onTap: () {
                            _openMedicines(
                              profileName:
                              name,
                              profileId:
                              null,
                            );
                          },
                        );
                      },
                    ),

                    // ==================================
                    // CREATED PROFILES
                    // ==================================
                    StreamBuilder<
                        QuerySnapshot<
                            Map<String,
                                dynamic>>>(
                      stream:
                      _firestoreService
                          .profilesStream(),
                      builder: (
                          context,
                          snapshot,
                          ) {
                        if (snapshot
                            .connectionState ==
                            ConnectionState
                                .waiting) {
                          return Padding(
                            padding:
                            const EdgeInsets
                                .all(
                              20,
                            ),
                            child: Center(
                              child:
                              CircularProgressIndicator(
                                color:
                                AppColors.primary,
                              ),
                            ),
                          );
                        }

                        if (snapshot.hasError) {
                          return const Text(
                            'Unable to load profiles.',
                          );
                        }

                        final profiles =
                            snapshot.data?.docs ??
                                [];

                        final filtered =
                        profiles.where(
                              (document) {
                            final data =
                            document.data();

                            final name =
                                data['fullName']
                                    ?.toString() ??
                                    '';

                            return _matchesSearch(
                              name,
                            );
                          },
                        ).toList();

                        if (filtered
                            .isEmpty &&
                            searchText
                                .isNotEmpty) {
                          return Padding(
                            padding:
                            const EdgeInsets
                                .symmetric(
                              vertical: 20,
                            ),
                            child: Center(
                              child: Text(
                                'No matching profile found.',
                                style: AppTextStyles
                                    .bodySmall
                                    .copyWith(
                                  color: AppColors
                                      .textSecondary,
                                ),
                              ),
                            ),
                          );
                        }

                        return Column(
                          children:
                          filtered.map(
                                (document) {
                              final data =
                              document
                                  .data();

                              final String
                              name =
                                  data['fullName']
                                      ?.toString() ??
                                      'Profile';

                              final String
                              relationship =
                                  data['relationship']
                                      ?.toString() ??
                                      'Family Member';

                              return _profileCard(
                                name: name,
                                relationship:
                                relationship,
                                onTap: () {
                                  _openMedicines(
                                    profileName:
                                    name,
                                    profileId:
                                    document.id,
                                  );
                                },
                              );
                            },
                          ).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // ========================================
      // SAME BOTTOM NAV
      // ========================================

    );
  }
}