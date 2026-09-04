import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:sehatfile/core/routes/app_routes.dart';
import 'package:sehatfile/core/theme/app_colors.dart';
import 'package:sehatfile/core/theme/app_text_styles.dart';

import 'package:sehatfile/services/firestore_service.dart';

import 'add_record_screen.dart';
import 'record_details_screen.dart';

class RecordCategoryScreen extends StatefulWidget {
  final String? profileId;
  final String profileName;
  final String categoryTitle;
  final String recordType;

  const RecordCategoryScreen({
    super.key,
    required this.profileName,
    required this.categoryTitle,
    required this.recordType,
    this.profileId,
  });

  @override
  State<RecordCategoryScreen> createState() =>
      _RecordCategoryScreenState();
}

class _RecordCategoryScreenState
    extends State<RecordCategoryScreen> {
  final FirestoreService _firestoreService =
  FirestoreService();

  final TextEditingController _searchController =
  TextEditingController();

  String _searchText = '';

  String _filter = 'All';

  final List<String> _filters = [
    'All',
    'Recent',
    'Oldest',
  ];

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

    const months = [
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
  // GET DATE
  // =====================================================

  DateTime _getDate(
      DocumentSnapshot<Map<String, dynamic>> document,
      ) {
    final dynamic value =
    document.data()?['recordDate'];

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return DateTime(2000);
  }

  // =====================================================
  // ICON
  // =====================================================

  IconData _recordIcon() {
    switch (widget.recordType) {
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
  // OPEN ADD
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
  // OPEN DETAILS
  // =====================================================

  Future<void> _openDetails(
      DocumentSnapshot<Map<String, dynamic>>
      document,
      ) async {
    await Navigator.push<bool>(
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
  // RECORD CARD
  // =====================================================

  Widget _recordCard(
      DocumentSnapshot<Map<String, dynamic>>
      document,
      ) {
    final data = document.data() ?? {};

    final String title =
        data['recordTitle']?.toString() ??
            'Medical Record';

    final String doctor =
        data['doctorName']?.toString() ?? '';

    final String facility =
        data['facilityName']?.toString() ?? '';

    return Padding(
      padding: const EdgeInsets.only(
        bottom: 12,
      ),
      child: Material(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(18),
        child: InkWell(
          onTap: () {
            _openDetails(document);
          },
          borderRadius:
          BorderRadius.circular(18),
          child: Container(
            padding:
            const EdgeInsets.all(15),
            decoration: BoxDecoration(
              borderRadius:
              BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.border,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color:
                    Colors.teal.shade50,
                    borderRadius:
                    BorderRadius.circular(
                      15,
                    ),
                  ),
                  child: Icon(
                    _recordIcon(),
                    color: AppColors.primary,
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
                      Text(
                        title,
                        maxLines: 1,
                        overflow:
                        TextOverflow
                            .ellipsis,
                        style:
                        const TextStyle(
                          fontWeight:
                          FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),

                      const SizedBox(
                        height: 4,
                      ),

                      Text(
                        _formatDate(
                          data['recordDate'],
                        ),
                        style: AppTextStyles
                            .bodySmall
                            .copyWith(
                          color: AppColors
                              .textSecondary,
                        ),
                      ),

                      if (doctor.isNotEmpty ||
                          facility.isNotEmpty) ...[
                        const SizedBox(
                          height: 3,
                        ),
                        Text(
                          doctor.isNotEmpty
                              ? doctor
                              : facility,
                          maxLines: 1,
                          overflow:
                          TextOverflow
                              .ellipsis,
                          style: AppTextStyles
                              .bodySmall
                              .copyWith(
                            color: AppColors
                                .textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                Icon(
                  Icons.chevron_right_rounded,
                  color:
                  AppColors.textSecondary,
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
  // BUILD
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      AppColors.background,

      appBar: AppBar(
        backgroundColor:
        AppColors.background,
        elevation: 0,
        leading: Padding(
          padding:
          const EdgeInsets.all(8),
          child: Material(
            color:
            Colors.teal.shade50,
            borderRadius:
            BorderRadius.circular(12),
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
        ),
      ),

      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding:
              const EdgeInsets.fromLTRB(
                18,
                4,
                18,
                12,
              ),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment
                    .start,
                children: [
                  Text(
                    widget.categoryTitle,
                    style: AppTextStyles
                        .titleLarge
                        .copyWith(
                      color:
                      AppColors.primary,
                      fontSize: 25,
                      fontWeight:
                      FontWeight.w700,
                    ),
                  ),

                  const SizedBox(
                    height: 5,
                  ),

                  Text(
                    '${widget.profileName}\'s ${widget.categoryTitle.toLowerCase()}',
                    style: AppTextStyles
                        .bodySmall
                        .copyWith(
                      color: AppColors
                          .textSecondary,
                    ),
                  ),

                  const SizedBox(
                    height: 18,
                  ),

                  TextField(
                    controller:
                    _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchText =
                            value
                                .trim()
                                .toLowerCase();
                      });
                    },
                    decoration:
                    InputDecoration(
                      hintText:
                      'Search records',
                      prefixIcon:
                      const Icon(
                        Icons.search_rounded,
                      ),
                      suffixIcon:
                      _searchText.isNotEmpty
                          ? IconButton(
                        onPressed:
                            () {
                          _searchController
                              .clear();

                          setState(() {
                            _searchText =
                            '';
                          });
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
                        BorderRadius
                            .circular(16),
                        borderSide:
                        BorderSide.none,
                      ),
                      enabledBorder:
                      OutlineInputBorder(
                        borderRadius:
                        BorderRadius
                            .circular(16),
                        borderSide:
                        BorderSide(
                          color:
                          AppColors.border,
                        ),
                      ),
                      focusedBorder:
                      OutlineInputBorder(
                        borderRadius:
                        BorderRadius
                            .circular(16),
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
                    height: 13,
                  ),

                  Wrap(
                    spacing: 8,
                    children:
                    _filters.map(
                          (filter) {
                        final bool selected =
                            _filter ==
                                filter;

                        return ChoiceChip(
                          label:
                          Text(filter),
                          selected:
                          selected,
                          selectedColor:
                          AppColors
                              .primary,
                          backgroundColor:
                          Colors.white,
                          labelStyle:
                          TextStyle(
                            color: selected
                                ? Colors
                                .white
                                : AppColors
                                .textSecondary,
                            fontWeight:
                            FontWeight
                                .w600,
                          ),
                          onSelected: (_) {
                            setState(() {
                              _filter =
                                  filter;
                            });
                          },
                        );
                      },
                    ).toList(),
                  ),
                ],
              ),
            ),

            Expanded(
              child: StreamBuilder<
                  QuerySnapshot<
                      Map<String, dynamic>>>(
                stream: _firestoreService
                    .recordsStream(
                  profileId:
                  widget.profileId,
                ),
                builder:
                    (context, snapshot) {
                  if (snapshot
                      .connectionState ==
                      ConnectionState
                          .waiting) {
                    return Center(
                      child:
                      CircularProgressIndicator(
                        color:
                        AppColors.primary,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return const Center(
                      child: Text(
                        'Unable to load records.',
                      ),
                    );
                  }

                  List<
                      DocumentSnapshot<
                          Map<String,
                              dynamic>>>
                  records =
                  (snapshot.data?.docs ??
                      [])
                      .where(
                        (document) {
                      final data =
                      document.data();

                      return data[
                      'recordType']
                          ?.toString() ==
                          widget.recordType;
                    },
                  ).toList();

                  if (_searchText
                      .isNotEmpty) {
                    records =
                        records.where(
                              (document) {
                            final data =
                                document.data() ??
                                    {};

                            final String
                            title =
                                data['recordTitle']
                                    ?.toString()
                                    .toLowerCase() ??
                                    '';

                            final String
                            doctor =
                                data['doctorName']
                                    ?.toString()
                                    .toLowerCase() ??
                                    '';

                            final String
                            facility =
                                data['facilityName']
                                    ?.toString()
                                    .toLowerCase() ??
                                    '';

                            return title.contains(
                              _searchText,
                            ) ||
                                doctor.contains(
                                  _searchText,
                                ) ||
                                facility.contains(
                                  _searchText,
                                );
                          },
                        ).toList();
                  }

                  if (_filter ==
                      'Recent') {
                    final DateTime
                    thirtyDaysAgo =
                    DateTime.now()
                        .subtract(
                      const Duration(
                        days: 30,
                      ),
                    );

                    records =
                        records.where(
                              (document) {
                            return _getDate(
                              document,
                            ).isAfter(
                              thirtyDaysAgo,
                            );
                          },
                        ).toList();
                  }

                  if (_filter ==
                      'Oldest') {
                    records.sort(
                          (a, b) =>
                          _getDate(a)
                              .compareTo(
                            _getDate(b),
                          ),
                    );
                  }

                  if (records.isEmpty) {
                    return ListView(
                      padding:
                      const EdgeInsets
                          .all(24),
                      children: [
                        const SizedBox(
                          height: 60,
                        ),

                        Icon(
                          _recordIcon(),
                          size: 64,
                          color: AppColors
                              .textSecondary,
                        ),

                        const SizedBox(
                          height: 18,
                        ),

                        Text(
                          'No ${widget.categoryTitle.toLowerCase()} yet',
                          textAlign:
                          TextAlign.center,
                          style:
                          const TextStyle(
                            fontSize: 18,
                            fontWeight:
                            FontWeight
                                .w700,
                          ),
                        ),

                        const SizedBox(
                          height: 7,
                        ),

                        Text(
                          'Your saved ${widget.categoryTitle.toLowerCase()} will appear here.',
                          textAlign:
                          TextAlign.center,
                          style: AppTextStyles
                              .bodySmall
                              .copyWith(
                            color: AppColors
                                .textSecondary,
                          ),
                        ),

                        const SizedBox(
                          height: 22,
                        ),

                        FilledButton.icon(
                          onPressed:
                          _openAddRecord,
                          icon: const Icon(
                            Icons
                                .add_rounded,
                          ),
                          label: const Text(
                            'Add Your First Record',
                          ),
                        ),
                      ],
                    );
                  }

                  return ListView(
                    keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior
                        .onDrag,
                    padding:
                    const EdgeInsets
                        .fromLTRB(
                      18,
                      5,
                      18,
                      90,
                    ),
                    children: records
                        .map(
                      _recordCard,
                    )
                        .toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),

      floatingActionButton:
      FloatingActionButton.extended(
        onPressed: _openAddRecord,
        backgroundColor:
        AppColors.primary,
        foregroundColor:
        Colors.white,
        icon:
        const Icon(Icons.add_rounded),
        label:
        const Text('Add Record'),
      ),

    );
  }
}