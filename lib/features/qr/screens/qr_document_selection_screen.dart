import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:sehatfile/core/theme/app_colors.dart';
import 'package:sehatfile/core/theme/app_text_styles.dart';
import 'package:sehatfile/services/firestore_service.dart';

class QrDocumentSelectionScreen extends StatefulWidget {
  final String profileName;
  final String? profileId;
  final List<String> initiallySelectedRecordIds;

  const QrDocumentSelectionScreen({
    super.key,
    required this.profileName,
    required this.initiallySelectedRecordIds,
    this.profileId,
  });

  @override
  State<QrDocumentSelectionScreen> createState() =>
      _QrDocumentSelectionScreenState();
}

class _QrDocumentSelectionScreenState
    extends State<QrDocumentSelectionScreen> {
  final FirestoreService _firestoreService =
  FirestoreService();

  late Set<String> _selectedRecordIds;

  @override
  void initState() {
    super.initState();

    _selectedRecordIds =
        widget.initiallySelectedRecordIds.toSet();
  }

  // =====================================================
  // SAVE
  // =====================================================

  void _saveSelection() {
    Navigator.pop(
      context,
      _selectedRecordIds.toList(),
    );
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
  // ICON
  // =====================================================

  IconData _recordIcon(String recordType) {
    switch (recordType.toLowerCase()) {
      case 'prescription':
        return Icons.receipt_long_outlined;

      case 'lab report':
        return Icons.science_outlined;

      case 'medical report':
        return Icons.description_outlined;

      case 'vaccination':
        return Icons.vaccines_outlined;

      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  // =====================================================
  // EMPTY STATE
  // =====================================================

  Widget _emptyState({
    required String title,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.folder_open_outlined,
                size: 34,
                color: AppColors.primary,
              ),
            ),

            const SizedBox(height: 15),

            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 7),

            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // DOCUMENT CARD
  // =====================================================

  Widget _documentCard(
      QueryDocumentSnapshot<Map<String, dynamic>> document,
      ) {
    final data = document.data();

    final String recordId = document.id;

    final String title =
        data['recordTitle']
            ?.toString()
            .trim() ??
            'Medical Record';

    final String recordType =
        data['recordType']
            ?.toString()
            .trim() ??
            'Medical Record';

    final String attachmentName =
        data['attachmentName']
            ?.toString()
            .trim() ??
            'Uploaded document';

    final String storagePath =
        data['storagePath']
            ?.toString()
            .trim() ??
            '';

    final bool selected =
    _selectedRecordIds.contains(recordId);

    return Card(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected
              ? AppColors.primary
              : AppColors.border,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: storagePath.isEmpty
            ? null
            : () {
          setState(() {
            if (selected) {
              _selectedRecordIds.remove(recordId);
            } else {
              _selectedRecordIds.add(recordId);
            }
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              // =========================================
              // ICON
              // =========================================

              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius:
                  BorderRadius.circular(12),
                ),
                child: Icon(
                  _recordIcon(recordType),
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(width: 12),

              // =========================================
              // TEXT
              // =========================================

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow:
                      TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight:
                        FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      recordType,
                      style:
                      AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight:
                        FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 7),

                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 14,
                          color:
                          AppColors.textSecondary,
                        ),

                        const SizedBox(width: 5),

                        Expanded(
                          child: Text(
                            _formatDate(
                              data['recordDate'],
                            ),
                            style:
                            AppTextStyles.bodySmall
                                .copyWith(
                              color: AppColors
                                  .textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    Container(
                      width: double.infinity,
                      padding:
                      const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color:
                        Colors.teal.shade50,
                        borderRadius:
                        BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.attach_file_rounded,
                            size: 16,
                            color:
                            AppColors.primary,
                          ),

                          const SizedBox(width: 5),

                          Expanded(
                            child: Text(
                              attachmentName,
                              maxLines: 1,
                              overflow:
                              TextOverflow.ellipsis,
                              style: AppTextStyles
                                  .bodySmall
                                  .copyWith(
                                color:
                                AppColors.primary,
                                fontWeight:
                                FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // =========================================
              // CHECKBOX
              // =========================================

              Checkbox(
                value: selected,
                activeColor:
                AppColors.primary,
                onChanged: storagePath.isEmpty
                    ? null
                    : (value) {
                  setState(() {
                    if (value == true) {
                      _selectedRecordIds.add(
                        recordId,
                      );
                    } else {
                      _selectedRecordIds.remove(
                        recordId,
                      );
                    }
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =====================================================
  // SCREEN
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      AppColors.background,

      // =================================================
      // APP BAR
      // =================================================

      appBar: AppBar(
        backgroundColor:
        AppColors.background,
        elevation: 0,
        title: const Text(
          'Choose Documents',
        ),
        actions: [
          TextButton(
            onPressed:
            _saveSelection,
            child: Text(
              'Done',
              style: TextStyle(
                color:
                AppColors.primary,
                fontWeight:
                FontWeight.w700,
              ),
            ),
          ),
        ],
      ),

      // =================================================
      // BODY
      // =================================================

      body: SafeArea(
        child: Column(
          children: [
            // ===========================================
            // HEADER
            // ===========================================

            Padding(
              padding:
              const EdgeInsets.fromLTRB(
                18,
                12,
                18,
                12,
              ),
              child: Container(
                width:
                double.infinity,
                padding:
                const EdgeInsets.all(
                  15,
                ),
                decoration:
                BoxDecoration(
                  color:
                  Colors.teal.shade50,
                  borderRadius:
                  BorderRadius.circular(
                    16,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons
                          .folder_copy_outlined,
                      color:
                      AppColors.primary,
                    ),

                    const SizedBox(
                      width: 10,
                    ),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                        children: [
                          const Text(
                            'Medical Documents',
                            style:
                            TextStyle(
                              fontWeight:
                              FontWeight.w800,
                            ),
                          ),

                          const SizedBox(
                            height: 4,
                          ),

                          Text(
                            'Documents saved for ${widget.profileName}',
                            style:
                            AppTextStyles
                                .bodySmall
                                .copyWith(
                              color: AppColors
                                  .textSecondary,
                            ),
                          ),

                          const SizedBox(
                            height: 4,
                          ),

                          Text(
                            '${_selectedRecordIds.length} selected',
                            style:
                            AppTextStyles
                                .bodySmall
                                .copyWith(
                              color:
                              AppColors.primary,
                              fontWeight:
                              FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ===========================================
            // DOCUMENT LIST
            // ===========================================

            Expanded(
              child: StreamBuilder<
                  QuerySnapshot<
                      Map<String, dynamic>>>(
                stream:
                _firestoreService
                    .qrShareableRecordsStream(
                  profileId:
                  widget.profileId,
                ),

                builder:
                    (context, snapshot) {
                  debugPrint(
                    'QR DOCUMENTS -> '
                        'profileId=${widget.profileId}, '
                        'docs=${snapshot.data?.docs.length ?? 0}, '
                        'error=${snapshot.error}',
                  );

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

                  if (snapshot.hasError) {
                    return _emptyState(
                      title:
                      'Unable to load documents',
                      message:
                      snapshot.error.toString(),
                    );
                  }

                  final allRecords =
                      snapshot.data?.docs ??
                          [];

                  final documents =
                  allRecords.where(
                        (document) {
                      final storagePath =
                          document
                              .data()['storagePath']
                              ?.toString()
                              .trim() ??
                              '';

                      return storagePath
                          .isNotEmpty;
                    },
                  ).toList();

                  if (allRecords.isEmpty) {
                    return _emptyState(
                      title:
                      'No medical records found',
                      message:
                      'There are no medical records saved for ${widget.profileName}.',
                    );
                  }

                  if (documents.isEmpty) {
                    return _emptyState(
                      title:
                      'No uploaded documents found',
                      message:
                      'Medical records exist for ${widget.profileName}, but no files are attached.',
                    );
                  }

                  return ListView.builder(
                    padding:
                    const EdgeInsets.fromLTRB(
                      18,
                      2,
                      18,
                      25,
                    ),
                    itemCount:
                    documents.length,
                    itemBuilder:
                        (context, index) {
                      return _documentCard(
                        documents[index],
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