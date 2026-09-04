import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:sehatfile/core/routes/app_routes.dart';
import 'package:sehatfile/core/theme/app_colors.dart';
import 'package:sehatfile/core/theme/app_text_styles.dart';

import 'package:sehatfile/services/firestore_service.dart';

import 'package:sehatfile/features/records/screens/records_screen.dart';

class RecordProfilesScreen extends StatefulWidget {
  const RecordProfilesScreen({
    super.key,
  });

  @override
  State<RecordProfilesScreen> createState() =>
      _RecordProfilesScreenState();
}

class _RecordProfilesScreenState
    extends State<RecordProfilesScreen> {
  final FirestoreService _firestoreService =
  FirestoreService();

  final TextEditingController _searchController =
  TextEditingController();

  String _searchText = '';

  // =====================================================
  // OPEN RECORDS
  // =====================================================

  void _openRecords({
    required String profileName,
    String? profileId,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecordsScreen(
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
    required String name,
    required String relationship,
    required String patientId,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 12,
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          18,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(
            18,
          ),
          child: Container(
            padding: const EdgeInsets.all(
              16,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                18,
              ),
              border: Border.all(
                color: AppColors.border,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(
                      15,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),

                const SizedBox(
                  width: 14,
                ),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(
                        height: 4,
                      ),

                      Text(
                        relationship,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),

                      if (patientId.isNotEmpty) ...[
                        const SizedBox(
                          height: 3,
                        ),
                        Text(
                          patientId,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
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
      ),
    );
  }

  // =====================================================
  // DISPOSE
  // =====================================================

  @override
  void dispose() {
    _searchController.dispose();

    super.dispose();
  }

  // =====================================================
  // SCREEN
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      body: SafeArea(
        child: Column(
          children: [
            // ===========================================
            // HEADER
            // ===========================================

            Padding(
              padding: const EdgeInsets.fromLTRB(
                18,
                14,
                18,
                14,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Material(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(
                      12,
                    ),
                    child: IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: Icon(
                        Icons.arrow_back_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 18,
                  ),

                  Text(
                    'Medical Records',
                    style: AppTextStyles.titleLarge.copyWith(
                      color: AppColors.primary,
                      fontSize: 25,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(
                    height: 5,
                  ),

                  Text(
                    'Choose whose medical records you want to view.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  // =====================================
                  // SEARCH
                  // =====================================

                  TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchText =
                            value.trim().toLowerCase();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search profiles',
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                      ),
                      suffixIcon: _searchText.isNotEmpty
                          ? IconButton(
                        onPressed: () {
                          _searchController.clear();

                          setState(() {
                            _searchText = '';
                          });
                        },
                        icon: const Icon(
                          Icons.close_rounded,
                        ),
                      )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          16,
                        ),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          16,
                        ),
                        borderSide: BorderSide(
                          color: AppColors.border,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          16,
                        ),
                        borderSide: BorderSide(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ===========================================
            // PROFILES
            // ===========================================

            Expanded(
              child: StreamBuilder<
                  DocumentSnapshot<Map<String, dynamic>>>(
                stream: _firestoreService.userProfileStream(),
                builder: (
                    context,
                    userSnapshot,
                    ) {
                  if (userSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    );
                  }

                  if (userSnapshot.hasError) {
                    return const Center(
                      child: Text(
                        'Unable to load your profile.',
                      ),
                    );
                  }

                  final Map<String, dynamic> userData =
                      userSnapshot.data?.data() ?? {};

                  String selfName =
                      userData['fullName']
                          ?.toString()
                          .trim() ??
                          '';

                  if (selfName.isEmpty) {
                    selfName = 'My Profile';
                  }

                  final String selfPatientId =
                      userData['patientId']
                          ?.toString()
                          .trim() ??
                          '';

                  return StreamBuilder<
                      QuerySnapshot<Map<String, dynamic>>>(
                    stream: _firestoreService.profilesStream(),
                    builder: (
                        context,
                        profilesSnapshot,
                        ) {
                      if (profilesSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        );
                      }

                      if (profilesSnapshot.hasError) {
                        return const Center(
                          child: Text(
                            'Unable to load profiles.',
                          ),
                        );
                      }

                      final profiles =
                          profilesSnapshot.data?.docs ?? [];

                      final bool showSelf =
                      selfName.toLowerCase().contains(
                        _searchText,
                      );

                      final filteredProfiles =
                      profiles.where(
                            (document) {
                          final data = document.data();

                          final String name =
                              data['fullName']
                                  ?.toString()
                                  .toLowerCase() ??
                                  '';

                          final String relationship =
                              data['relationship']
                                  ?.toString()
                                  .toLowerCase() ??
                                  '';

                          return name.contains(
                            _searchText,
                          ) ||
                              relationship.contains(
                                _searchText,
                              );
                        },
                      ).toList();

                      if (!showSelf &&
                          filteredProfiles.isEmpty) {
                        return const Center(
                          child: Text(
                            'No matching profiles found.',
                          ),
                        );
                      }

                      return ListView(
                        keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior
                            .onDrag,
                        padding: const EdgeInsets.fromLTRB(
                          18,
                          5,
                          18,
                          24,
                        ),
                        children: [
                          Text(
                            'Select Profile',
                            style:
                            AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),

                          const SizedBox(
                            height: 12,
                          ),

                          // =============================
                          // SELF
                          // =============================

                          if (showSelf)
                            _profileCard(
                              name: selfName,
                              relationship: 'Self',
                              patientId: selfPatientId,
                              icon: Icons.person_rounded,
                              onTap: () {
                                _openRecords(
                                  profileName: selfName,
                                );
                              },
                            ),

                          // =============================
                          // FAMILY PROFILES
                          // =============================

                          ...filteredProfiles.map(
                                (document) {
                              final data = document.data();

                              final String name =
                                  data['fullName']
                                      ?.toString()
                                      .trim() ??
                                      'Profile';

                              final String relationship =
                                  data['relationship']
                                      ?.toString()
                                      .trim() ??
                                      'Family';

                              final String patientId =
                                  data['patientId']
                                      ?.toString()
                                      .trim() ??
                                      '';

                              return _profileCard(
                                name: name,
                                relationship: relationship,
                                patientId: patientId,
                                icon: Icons
                                    .person_outline_rounded,
                                onTap: () {
                                  _openRecords(
                                    profileName: name,
                                    profileId: document.id,
                                  );
                                },
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
          ],
        ),
      ),
    );
  }
}