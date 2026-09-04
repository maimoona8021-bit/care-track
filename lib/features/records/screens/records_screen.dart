import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:sehatfile/core/routes/app_routes.dart';
import 'package:sehatfile/core/theme/app_colors.dart';
import 'package:sehatfile/core/theme/app_text_styles.dart';

import 'package:sehatfile/services/firestore_service.dart';

import 'package:sehatfile/features/records/screens/add_record_screen.dart';
import 'package:sehatfile/features/records/screens/record_category_screen.dart';
import 'package:sehatfile/features/records/screens/record_details_screen.dart';

class RecordsScreen extends StatefulWidget {
  final String? profileId;
  final String profileName;

  const RecordsScreen({
    super.key,
    required this.profileName,
    this.profileId,
  });

  @override
  State<RecordsScreen> createState() =>
      _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  final FirestoreService _firestoreService =
  FirestoreService();

  final TextEditingController _searchController =
  TextEditingController();

  String _searchText = '';

  final List<_RecordCategory> _categories = const [
    _RecordCategory(
      title: 'Prescriptions',
      recordType: 'Prescription',
      subtitle: 'Doctor prescriptions and medication orders',
      icon: Icons.receipt_long_outlined,
    ),
    _RecordCategory(
      title: 'Lab Reports',
      recordType: 'Lab Report',
      subtitle: 'Blood tests, lab results and investigations',
      icon: Icons.science_outlined,
    ),
    _RecordCategory(
      title: 'Medical Reports',
      recordType: 'Medical Report',
      subtitle: 'Scans, reports and discharge summaries',
      icon: Icons.description_outlined,
    ),
    _RecordCategory(
      title: 'Vaccinations',
      recordType: 'Vaccination',
      subtitle: 'Vaccination records and certificates',
      icon: Icons.vaccines_outlined,
    ),
    _RecordCategory(
      title: 'Other Documents',
      recordType: 'Other',
      subtitle: 'Other important health documents',
      icon: Icons.folder_copy_outlined,
    ),
  ];

  // =====================================================
  // OPEN CATEGORY
  // =====================================================

  void _openCategory(
      _RecordCategory category,
      ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            RecordCategoryScreen(
              profileId: widget.profileId,
              profileName: widget.profileName,
              categoryTitle: category.title,
              recordType: category.recordType,
            ),
      ),
    );
  }

  // =====================================================
  // ADD RECORD
  // =====================================================

  Future<void> _openAddRecord() async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AddRecordScreen(
              profileId: widget.profileId,
              profileName: widget.profileName,
            ),
      ),
    );
  }

  // =====================================================
  // OPEN RECORD DETAILS
  // =====================================================

  void _openRecordDetails(
      DocumentSnapshot<Map<String, dynamic>>
      document,
      ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            RecordDetailsScreen(
              recordId: document.id,
              profileId: widget.profileId,
              profileName: widget.profileName,
              recordData: document.data() ?? {},
            ),
      ),
    );
  }

  // =====================================================
  // COUNT CATEGORY RECORDS
  // =====================================================

  int _categoryCount({
    required List<
        QueryDocumentSnapshot<
            Map<String, dynamic>>>
    records,
    required String recordType,
  }) {
    return records.where(
          (document) {
        return document
            .data()['recordType']
            ?.toString() ==
            recordType;
      },
    ).length;
  }

  // =====================================================
  // FORMAT DATE
  // =====================================================

  String _formatDate(dynamic value) {
    DateTime? date;

    if (value is Timestamp) {
      date = value.toDate();
    } else if (value is DateTime) {
      date = value;
    }

    if (date == null) {
      return 'No date';
    }

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
  // RECORD ICON
  // =====================================================

  IconData _recordIcon(
      String type,
      ) {
    switch (type) {
      case 'Prescription':
        return Icons.receipt_long_outlined;

      case 'Lab Report':
        return Icons.science_outlined;

      case 'Medical Report':
        return Icons.description_outlined;

      case 'Vaccination':
        return Icons.vaccines_outlined;

      default:
        return Icons.folder_copy_outlined;
    }
  }

  // =====================================================
  // CATEGORY CARD
  // =====================================================

  Widget _categoryCard({
    required _RecordCategory category,
    required int count,
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
          onTap: () {
            _openCategory(category);
          },
          borderRadius: BorderRadius.circular(
            18,
          ),
          child: Container(
            padding: const EdgeInsets.all(
              15,
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
                  width: 51,
                  height: 51,
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(
                      14,
                    ),
                  ),
                  child: Icon(
                    category.icon,
                    color: AppColors.primary,
                    size: 25,
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
                        category.title,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),

                      const SizedBox(
                        height: 4,
                      ),

                      Text(
                        category.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  width: 8,
                ),

                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(
                          20,
                        ),
                      ),
                      child: Text(
                        count.toString(),
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 5,
                    ),

                    Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =====================================================
  // RECENT RECORD CARD
  // =====================================================

  Widget _recentRecordCard(
      QueryDocumentSnapshot<Map<String, dynamic>>
      document,
      ) {
    final data = document.data();

    final String title =
        data['recordTitle']
            ?.toString()
            .trim() ??
            'Medical Record';

    final String recordType =
        data['recordType']
            ?.toString()
            .trim() ??
            'Record';

    return Padding(
      padding: const EdgeInsets.only(
        bottom: 10,
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          16,
        ),
        child: InkWell(
          onTap: () {
            _openRecordDetails(document);
          },
          borderRadius: BorderRadius.circular(
            16,
          ),
          child: Container(
            padding: const EdgeInsets.all(
              14,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                16,
              ),
              border: Border.all(
                color: AppColors.border,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(
                      12,
                    ),
                  ),
                  child: Icon(
                    _recordIcon(recordType),
                    color: AppColors.primary,
                    size: 22,
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
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),

                      const SizedBox(
                        height: 4,
                      ),

                      Text(
                        '$recordType • ${_formatDate(data['recordDate'])}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
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
      ),
    );
  }

  // =====================================================
  // EMPTY RECENT STATE
  // =====================================================

  Widget _emptyRecentState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 25,
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
              Icons.folder_open_outlined,
              color: AppColors.primary,
              size: 29,
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          const Text(
            'No records yet',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),

          const SizedBox(
            height: 5,
          ),

          Text(
            'Your recently added medical records will appear here.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
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
    final filteredCategories =
    _categories.where(
          (category) {
        return category.title
            .toLowerCase()
            .contains(_searchText) ||
            category.subtitle
                .toLowerCase()
                .contains(_searchText);
      },
    ).toList();

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
                10,
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
                    '${widget.profileName}\'s medical records',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchText =
                            value.trim().toLowerCase();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search record categories',
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
            // FIRESTORE RECORDS
            // ===========================================

            Expanded(
              child: StreamBuilder<
                  QuerySnapshot<Map<String, dynamic>>>(
                stream: _firestoreService.recordsStream(
                  profileId: widget.profileId,
                ),
                builder: (
                    context,
                    snapshot,
                    ) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return const Center(
                      child: Text(
                        'Unable to load medical records.',
                      ),
                    );
                  }

                  final records =
                      snapshot.data?.docs ?? [];

                  final recentRecords =
                  records.take(3).toList();

                  return ListView(
                    keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior
                        .onDrag,
                    padding: const EdgeInsets.fromLTRB(
                      18,
                      6,
                      18,
                      25,
                    ),
                    children: [
                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Record Categories',
                            style:
                            AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),

                          Text(
                            '${records.length} records',
                            style:
                            AppTextStyles.bodySmall.copyWith(
                              color:
                              AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      if (filteredCategories.isEmpty)
                        Padding(
                          padding:
                          const EdgeInsets.symmetric(
                            vertical: 30,
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.search_off_rounded,
                                size: 42,
                                color: AppColors
                                    .textSecondary,
                              ),

                              const SizedBox(
                                height: 10,
                              ),

                              Text(
                                'No matching category found.',
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

                      ...filteredCategories.map(
                            (category) {
                          return _categoryCard(
                            category: category,
                            count: _categoryCount(
                              records: records,
                              recordType:
                              category.recordType,
                            ),
                          );
                        },
                      ),

                      const SizedBox(
                        height: 5,
                      ),

                      // =================================
                      // ADD RECORD
                      // =================================

                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: FilledButton.icon(
                          onPressed: _openAddRecord,
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
                          icon: const Icon(
                            Icons.add_rounded,
                          ),
                          label: const Text(
                            'Add Record',
                            style: TextStyle(
                              fontWeight:
                              FontWeight.w700,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 26,
                      ),

                      // =================================
                      // RECENT RECORDS
                      // =================================

                      Text(
                        'Recent Records',
                        style:
                        AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      if (recentRecords.isEmpty)
                        _emptyRecentState()
                      else
                        ...recentRecords.map(
                          _recentRecordCard,
                        ),
                    ],
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

// =======================================================
// RECORD CATEGORY MODEL
// =======================================================

class _RecordCategory {
  final String title;
  final String recordType;
  final String subtitle;
  final IconData icon;

  const _RecordCategory({
    required this.title,
    required this.recordType,
    required this.subtitle,
    required this.icon,
  });
}