import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'medicine_details_screen.dart';
import 'package:sehatfile/core/routes/app_routes.dart';
import 'package:sehatfile/core/theme/app_colors.dart';
import 'package:sehatfile/core/theme/app_text_styles.dart';


import 'package:sehatfile/services/firestore_service.dart';

import 'add_medicine_screen.dart';

class MedicinesScreen extends StatefulWidget {
  final String? profileId;
  final String profileName;

  const MedicinesScreen({
    super.key,
    required this.profileName,
    this.profileId,
  });

  @override
  State<MedicinesScreen> createState() =>
      _MedicinesScreenState();
}

class _MedicinesScreenState extends State<MedicinesScreen> {
  final FirestoreService _firestoreService =
  FirestoreService();

  final TextEditingController searchController =
  TextEditingController();

  bool showCurrent = true;
  String searchText = '';

  // =====================================================
  // FORMAT DATE
  // =====================================================

  String _formatDate(dynamic value) {
    if (value is! Timestamp) {
      return 'Not set';
    }

    final DateTime date = value.toDate();

    const List<String> months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${date.day} '
        '${months[date.month - 1]} '
        '${date.year}';
  }

  // =====================================================
  // TAB BUTTON
  // =====================================================

  Widget _tabButton({
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(
            milliseconds: 180,
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            title,
            style: TextStyle(
              color: selected
                  ? Colors.white
                  : AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  // =====================================================
  // MEDICINE CARD
  // =====================================================

  Widget _medicineCard(
      QueryDocumentSnapshot<Map<String, dynamic>> document,
      ) {
    final Map<String, dynamic> data =
    document.data();

    final String medicineName =
        data['medicineName']?.toString() ??
            'Medicine';

    final String dosage =
        data['dosage']?.toString() ??
            '';

    final String quantity =
        data['quantityPerDose']?.toString() ??
            '';

    final String frequency =
        data['frequency']?.toString() ??
            '';

    final bool isCurrent =
        data['isCurrent'] == true;

    final bool reminderEnabled =
        data['reminderEnabled'] == true;

    final List<dynamic> reminderTimes =
        data['reminderTimes'] as List<dynamic>? ??
            [];

    return Container(
      margin: const EdgeInsets.only(
        bottom: 14,
      ),
      padding: const EdgeInsets.all(
        16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color: AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
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
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          // ===========================================
          // MEDICINE HEADER
          // ===========================================

          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color:
                  Colors.teal.shade50,
                  borderRadius:
                  BorderRadius.circular(
                    14,
                  ),
                ),
                child: Icon(
                  Icons.medication_rounded,
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      medicineName,
                      maxLines: 2,
                      overflow:
                      TextOverflow.ellipsis,
                      style: AppTextStyles
                          .bodyMedium
                          .copyWith(
                        fontWeight:
                        FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),

                    if (dosage.isNotEmpty)
                      Padding(
                        padding:
                        const EdgeInsets.only(
                          top: 2,
                        ),
                        child: Text(
                          dosage,
                          style: AppTextStyles
                              .bodySmall
                              .copyWith(
                            color: AppColors
                                .textSecondary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(
                width: 8,
              ),

              Container(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isCurrent
                      ? Colors.green.shade50
                      : Colors.grey.shade100,
                  borderRadius:
                  BorderRadius.circular(
                    20,
                  ),
                ),
                child: Text(
                  isCurrent
                      ? 'Active'
                      : 'Previous',
                  style: TextStyle(
                    color: isCurrent
                        ? Colors.green
                        : AppColors
                        .textSecondary,
                    fontSize: 11,
                    fontWeight:
                    FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 14,
          ),

          // ===========================================
          // QUANTITY
          // ===========================================

          if (quantity.isNotEmpty)
            Row(
              children: [
                Icon(
                  Icons.medication_outlined,
                  size: 17,
                  color: AppColors.primary,
                ),
                const SizedBox(
                  width: 6,
                ),
                Expanded(
                  child: Text(
                    quantity,
                    style: const TextStyle(
                      fontWeight:
                      FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),

          // ===========================================
          // FREQUENCY
          // ===========================================

          if (frequency.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(
                top: 6,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.repeat_rounded,
                    size: 17,
                    color:
                    AppColors.textSecondary,
                  ),
                  const SizedBox(
                    width: 6,
                  ),
                  Expanded(
                    child: Text(
                      frequency,
                      style: AppTextStyles
                          .bodySmall
                          .copyWith(
                        color: AppColors
                            .textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // ===========================================
          // REMINDER TIMES
          // ===========================================

          if (reminderTimes.isNotEmpty) ...[
            const SizedBox(
              height: 12,
            ),

            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: reminderTimes.map(
                    (time) {
                  return Container(
                    padding:
                    const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color:
                      Colors.teal.shade50,
                      borderRadius:
                      BorderRadius.circular(
                        16,
                      ),
                    ),
                    child: Row(
                      mainAxisSize:
                      MainAxisSize.min,
                      children: [
                        Icon(
                          reminderEnabled
                              ? Icons
                              .notifications_active_outlined
                              : Icons
                              .access_time_rounded,
                          size: 14,
                          color:
                          AppColors.primary,
                        ),
                        const SizedBox(
                          width: 4,
                        ),
                        Text(
                          time.toString(),
                          style: TextStyle(
                            color:
                            AppColors.primary,
                            fontSize: 11,
                            fontWeight:
                            FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ).toList(),
            ),
          ],

          const SizedBox(
            height: 12,
          ),

          Divider(
            color: AppColors.divider,
          ),

          const SizedBox(
            height: 4,
          ),

          // ===========================================
          // START DATE
          // ===========================================

          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 15,
                color:
                AppColors.textSecondary,
              ),
              const SizedBox(
                width: 6,
              ),
              Expanded(
                child: Text(
                  'Started: ${_formatDate(data['startDate'])}',
                  style: AppTextStyles
                      .bodySmall
                      .copyWith(
                    color:
                    AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =====================================================
  // EMPTY STATE
  // IMPORTANT: ListView prevents RenderFlex overflow
  // =====================================================

  Widget _emptyState() {
    return ListView(
      keyboardDismissBehavior:
      ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(
        30,
        18,
        30,
        30,
      ),
      children: [
        const SizedBox(
          height: 10,
        ),

        Center(
          child: Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.medication_outlined,
              color: AppColors.primary,
              size: 42,
            ),
          ),
        ),

        const SizedBox(
          height: 18,
        ),

        Text(
          showCurrent
              ? 'No current medicines'
              : 'No previous medicines',
          textAlign: TextAlign.center,
          style:
          AppTextStyles.titleLarge.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),

        const SizedBox(
          height: 8,
        ),

        Text(
          searchText.isNotEmpty
              ? 'No medicine matches your search.'
              : showCurrent
              ? 'Add a medicine to start tracking your current medications.'
              : 'Medicines you are no longer taking will appear here.',
          textAlign: TextAlign.center,
          style:
          AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  // =====================================================
  // DISPOSE
  // =====================================================

  @override
  void dispose() {
    searchController.dispose();

    super.dispose();
  }

  // =====================================================
  // SCREEN
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      AppColors.background,

      resizeToAvoidBottomInset: true,

      body: SafeArea(
        child: Column(
          children: [
            // ==========================================
            // HEADER
            // ==========================================

            Padding(
              padding:
              const EdgeInsets.fromLTRB(
                18,
                14,
                18,
                0,
              ),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  // ===================================
                  // BACK BUTTON
                  // ===================================

                  Material(
                    color:
                    Colors.teal.shade50,
                    borderRadius:
                    BorderRadius.circular(
                      12,
                    ),
                    child: IconButton(
                      onPressed: () {
                        Navigator.pop(
                          context,
                        );
                      },
                      icon: Icon(
                        Icons
                            .arrow_back_rounded,
                        color:
                        AppColors.primary,
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 18,
                  ),

                  // ===================================
                  // TITLE
                  // ===================================

                  Text(
                    '${widget.profileName}\'s Medicines',
                    maxLines: 2,
                    overflow:
                    TextOverflow.ellipsis,
                    style: AppTextStyles
                        .titleLarge
                        .copyWith(
                      color:
                      AppColors.primary,
                      fontSize: 24,
                      fontWeight:
                      FontWeight.w700,
                    ),
                  ),

                  const SizedBox(
                    height: 5,
                  ),

                  Text(
                    'Manage current and previous medications',
                    style: AppTextStyles
                        .bodySmall
                        .copyWith(
                      color: AppColors
                          .textSecondary,
                    ),
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  // ===================================
                  // SEARCH
                  // ===================================

                  TextField(
                    controller:
                    searchController,
                    textInputAction:
                    TextInputAction.search,
                    onChanged: (value) {
                      setState(() {
                        searchText = value
                            .trim()
                            .toLowerCase();
                      });
                    },
                    decoration: InputDecoration(
                      hintText:
                      'Search medicines',
                      prefixIcon:
                      const Icon(
                        Icons.search_rounded,
                      ),

                      suffixIcon:
                      searchText.isNotEmpty
                          ? IconButton(
                        onPressed: () {
                          searchController
                              .clear();

                          setState(() {
                            searchText =
                            '';
                          });

                          FocusScope.of(
                            context,
                          ).unfocus();
                        },
                        icon:
                        const Icon(
                          Icons
                              .close_rounded,
                        ),
                      )
                          : null,

                      filled: true,
                      fillColor:
                      Colors.white,

                      border:
                      OutlineInputBorder(
                        borderRadius:
                        BorderRadius.circular(
                          16,
                        ),
                        borderSide:
                        BorderSide.none,
                      ),

                      enabledBorder:
                      OutlineInputBorder(
                        borderRadius:
                        BorderRadius.circular(
                          16,
                        ),
                        borderSide:
                        BorderSide(
                          color:
                          AppColors.border,
                        ),
                      ),

                      focusedBorder:
                      OutlineInputBorder(
                        borderRadius:
                        BorderRadius.circular(
                          16,
                        ),
                        borderSide:
                        BorderSide(
                          color:
                          AppColors.primary,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 14,
                  ),

                  // ===================================
                  // CURRENT / PREVIOUS TABS
                  // ===================================

                  Container(
                    height: 48,
                    padding:
                    const EdgeInsets.all(
                      4,
                    ),
                    decoration: BoxDecoration(
                      color:
                      Colors.grey.shade100,
                      borderRadius:
                      BorderRadius.circular(
                        15,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _tabButton(
                            title: 'Current',
                            selected:
                            showCurrent,
                            onTap: () {
                              FocusScope.of(
                                context,
                              ).unfocus();

                              setState(() {
                                showCurrent =
                                true;
                              });
                            },
                          ),
                        ),

                        Expanded(
                          child: _tabButton(
                            title: 'Previous',
                            selected:
                            !showCurrent,
                            onTap: () {
                              FocusScope.of(
                                context,
                              ).unfocus();

                              setState(() {
                                showCurrent =
                                false;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            // ==========================================
            // FIRESTORE MEDICINES
            // ==========================================

            Expanded(
              child: StreamBuilder<
                  QuerySnapshot<
                      Map<String, dynamic>>>(
                stream: _firestoreService
                    .medicinesStream(
                  profileId:
                  widget.profileId,
                ),
                builder: (
                    context,
                    snapshot,
                    ) {
                  // ===================================
                  // LOADING
                  // ===================================

                  if (snapshot
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

                  // ===================================
                  // ERROR
                  // ===================================

                  if (snapshot.hasError) {
                    return ListView(
                      padding:
                      const EdgeInsets.all(
                        30,
                      ),
                      children: [
                        const SizedBox(
                          height: 30,
                        ),
                        Icon(
                          Icons
                              .error_outline_rounded,
                          color:
                          Colors.red.shade400,
                          size: 45,
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        const Text(
                          'Unable to load medicines.',
                          textAlign:
                          TextAlign.center,
                        ),
                      ],
                    );
                  }

                  final List<
                      QueryDocumentSnapshot<
                          Map<String,
                              dynamic>>>
                  documents =
                      snapshot.data?.docs ??
                          [];

                  // ===================================
                  // FILTER
                  // ===================================

                  final List<
                      QueryDocumentSnapshot<
                          Map<String,
                              dynamic>>>
                  filtered =
                  documents.where(
                        (document) {
                      final Map<String,
                          dynamic>
                      data =
                      document.data();

                      final bool isCurrent =
                          data['isCurrent'] ==
                              true;

                      final String name =
                          data['medicineName']
                              ?.toString()
                              .toLowerCase() ??
                              '';

                      return isCurrent ==
                          showCurrent &&
                          name.contains(
                            searchText,
                          );
                    },
                  ).toList();

                  // ===================================
                  // EMPTY STATE
                  // FIXED - NO COLUMN OVERFLOW
                  // ===================================

                  if (filtered.isEmpty) {
                    return _emptyState();
                  }

                  // ===================================
                  // MEDICINE LIST
                  // ===================================

                  return ListView.builder(
                    keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior
                        .onDrag,
                    padding:
                    const EdgeInsets.fromLTRB(
                      18,
                      10,
                      18,
                      18,
                    ),
                    itemCount:
                    filtered.length,
                    itemBuilder: (
                        context,
                        index,
                        ) {
                      final document = filtered[index];

                      return InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  MedicineDetailsScreen(
                                    medicineId: document.id,
                                    profileId: widget.profileId,
                                    profileName: widget.profileName,
                                    medicineData: document.data(),
                                  ),
                            ),
                          );
                        },
                        child: _medicineCard(
                          document,
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // ==========================================
            // ADD MEDICINE BUTTON
            // ==========================================

            Padding(
              padding:
              const EdgeInsets.fromLTRB(
                18,
                8,
                18,
                14,
              ),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child:
                FilledButton.icon(
                  style:
                  FilledButton.styleFrom(
                    backgroundColor:
                    AppColors.primary,
                    shape:
                    RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(
                        16,
                      ),
                    ),
                  ),

                  onPressed: () {
                    FocusScope.of(
                      context,
                    ).unfocus();

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (
                            context,
                            ) =>
                            AddMedicineScreen(
                              profileId:
                              widget.profileId,
                              profileName:
                              widget.profileName,
                            ),
                      ),
                    );
                  },

                  icon: const Icon(
                    Icons.add_rounded,
                  ),

                  label: const Text(
                    'Add Medicine',
                    style: TextStyle(
                      fontWeight:
                      FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      // ================================================
      // BOTTOM NAVIGATION
      // ================================================


    );
  }
}