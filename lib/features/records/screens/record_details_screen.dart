import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sehatfile/features/records/screens/edit_record_screen.dart';
import 'package:sehatfile/core/theme/app_colors.dart';
import 'package:sehatfile/core/theme/app_text_styles.dart';
import 'package:sehatfile/services/firestore_service.dart';
import 'package:sehatfile/features/records/screens/document_viewer_screen.dart';
import 'package:sehatfile/services/storage_service.dart';

class RecordDetailsScreen extends StatefulWidget {
  final String recordId;
  final String? profileId;
  final String profileName;
  final Map<String, dynamic> recordData;

  const RecordDetailsScreen({
    super.key,
    required this.recordId,
    required this.profileName,
    required this.recordData,
    this.profileId,
  });

  @override
  State<RecordDetailsScreen> createState() =>
      _RecordDetailsScreenState();
}

class _RecordDetailsScreenState
    extends State<RecordDetailsScreen> {
  final FirestoreService _firestoreService =
  FirestoreService();

  bool _isDeleting = false;

  // =====================================================
  // SAFE VALUE
  // =====================================================

  String _value(
      String key, {
        String fallback = 'Not provided',
      }) {
    final dynamic rawValue =
    widget.recordData[key];

    if (rawValue == null) {
      return fallback;
    }

    final String value =
    rawValue.toString().trim();

    if (value.isEmpty ||
        value.toLowerCase() == 'null') {
      return fallback;
    }

    return value;
  }

  // =====================================================
  // DATE
  // =====================================================

  String _formatDate(dynamic value) {
    DateTime? date;

    if (value is Timestamp) {
      date = value.toDate();
    } else if (value is DateTime) {
      date = value;
    }

    if (date == null) {
      return 'Not provided';
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
  // DETAIL ROW
  // =====================================================

  Widget _detailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 11,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius: BorderRadius.circular(
                12,
              ),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 21,
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
                  label,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(
                  height: 3,
                ),

                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // EDIT RECORD
  // =====================================================

  Future<void> _editRecord() async {
    final bool? updated =
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            EditRecordScreen(
              recordId: widget.recordId,
              profileId: widget.profileId,
              profileName: widget.profileName,
              recordData: widget.recordData,
            ),
      ),
    );

    if (!mounted) {
      return;
    }

    if (updated == true) {
      Navigator.pop(
        context,
        true,
      );
    }
  }

  // =====================================================
  // DELETE RECORD
  // ====================================================
  Future<void> _deleteRecord() async {
    if (_isDeleting) {
      return;
    }

    // =====================================================
    // CONFIRM DELETE
    // =====================================================

    final bool? confirm =
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Delete Record?',
          ),
          content: const Text(
            'This medical record and its attached document will be permanently deleted.',
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
              style: FilledButton.styleFrom(
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

    if (confirm != true) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isDeleting = true;
    });

    // =====================================================
    // GET SUPABASE STORAGE PATH BEFORE FIRESTORE DELETE
    // =====================================================

    final String storagePath =
        widget.recordData['storagePath']
            ?.toString()
            .trim() ??
            '';

    try {
      // ===================================================
      // 1. DELETE FIRESTORE RECORD FIRST
      // ===================================================

      await _firestoreService.deleteRecord(
        recordId:
        widget.recordId,
        profileId:
        widget.profileId,
      );

      // ===================================================
      // 2. DELETE SUPABASE FILE
      // ===================================================
      //
      // Firestore deletion already succeeded.
      // If Storage cleanup fails, we do NOT restore
      // the deleted medical record.
      // ===================================================

      if (storagePath.isNotEmpty) {
        await StorageService.instance.deleteFile(
          storagePath: storagePath,
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _isDeleting = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Medical record deleted successfully.',
          ),
        ),
      );

      Navigator.pop(
        context,
        true,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isDeleting = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Unable to delete record: $e',
          ),
        ),
      );
    }
  }

  // =====================================================
  // OPEN DOCUMENT
  // =====================================================

  Future<void> _openDocument() async {
    final String storagePath =
        widget.recordData['storagePath']
            ?.toString()
            .trim() ??
            '';

    final String documentName =
        widget.recordData['attachmentName']
            ?.toString()
            .trim() ??
            'Medical Document';

    final String documentType =
        widget.recordData['attachmentType']
            ?.toString()
            .trim() ??
            '';

    // No attachment
    if (storagePath.isEmpty) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No document is attached to this record.',
          ),
        ),
      );

      return;
    }

    try {
      // Temporary private URL from Supabase.
      // It expires automatically after 1 hour.
      final String signedUrl =
      await StorageService.instance.createSignedUrl(
        storagePath: storagePath,
        expiresInSeconds: 3600,
      );

      if (!mounted) {
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              DocumentViewerScreen(
                documentUrl: signedUrl,
                documentName: documentName,
                documentType: documentType,
              ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to open document: $e',
          ),
        ),
      );
    }
  }

  // =====================================================
  // SCREEN
  // =====================================================

  @override
  Widget build(BuildContext context) {
    final String title =
    _value(
      'recordTitle',
      fallback: 'Medical Record',
    );

    final String recordType =
    _value(
      'recordType',
      fallback: 'Record',
    );

    final String doctor =
    _value(
      'doctorName',
    );

    final String facility =
    _value(
      'facilityName',
    );

    final String description =
    _value(
      'description',
      fallback: '',
    );

    final String attachmentName =
    _value(
      'attachmentName',
      fallback: '',
    );

    final bool hasAttachment =
        attachmentName.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(
            8,
          ),
          child: Material(
            color: Colors.teal.shade50,
            borderRadius: BorderRadius.circular(
              12,
            ),
            child: IconButton(
              onPressed: _isDeleting
                  ? null
                  : () {
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
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            18,
            4,
            18,
            30,
          ),
          children: [
            // ==========================================
            // TITLE
            // ==========================================

            Text(
              'Record Details',
              style: AppTextStyles.titleLarge.copyWith(
                color: AppColors.primary,
                fontSize: 25,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(
              height: 22,
            ),

            // ==========================================
            // RECORD ICON
            // ==========================================

            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _recordIcon(recordType),
                  size: 39,
                  color: AppColors.primary,
                ),
              ),
            ),

            const SizedBox(
              height: 14,
            ),

            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(
              height: 5,
            ),

            Text(
              recordType,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(
              height: 24,
            ),

            // ==========================================
            // DETAILS CARD
            // ==========================================

            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 5,
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
                  _detailRow(
                    icon: Icons.person_outline_rounded,
                    label: 'Doctor',
                    value: doctor,
                  ),

                  const Divider(),

                  _detailRow(
                    icon: Icons.local_hospital_outlined,
                    label: recordType == 'Lab Report'
                        ? 'Laboratory'
                        : 'Hospital / Facility',
                    value: facility,
                  ),

                  const Divider(),

                  _detailRow(
                    icon: Icons.folder_outlined,
                    label: 'Record Type',
                    value: recordType,
                  ),

                  const Divider(),

                  _detailRow(
                    icon: Icons.calendar_month_outlined,
                    label: 'Date',
                    value: _formatDate(
                      widget.recordData['recordDate'],
                    ),
                  ),
                ],
              ),
            ),

            // ==========================================
            // DESCRIPTION
            // ==========================================

            if (description.isNotEmpty) ...[
              const SizedBox(
                height: 18,
              ),

              Container(
                padding: const EdgeInsets.all(
                  17,
                ),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(
                    18,
                  ),
                ),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Description / Notes',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    Text(
                      description,
                      style: const TextStyle(
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(
              height: 18,
            ),

            // ==========================================
            // DOCUMENT
            // ==========================================

            Container(
              padding: const EdgeInsets.all(
                17,
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
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.attach_file_rounded,
                        color: AppColors.primary,
                      ),

                      const SizedBox(
                        width: 8,
                      ),

                      const Text(
                        'Attached Document',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 15,
                  ),

                  if (!hasAttachment)
                    Text(
                      'No document attached yet.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    )
                  else
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.teal.shade50,
                            borderRadius:
                            BorderRadius.circular(
                              12,
                            ),
                          ),
                          child: Icon(
                            Icons.description_outlined,
                            color: AppColors.primary,
                          ),
                        ),

                        const SizedBox(
                          width: 10,
                        ),

                        Expanded(
                          child: Text(
                            attachmentName,
                            maxLines: 2,
                            overflow:
                            TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight:
                              FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(
                    height: 14,
                  ),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _openDocument,
                      icon: const Icon(
                        Icons.visibility_outlined,
                      ),
                      label: const Text(
                        'View Document',
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 22,
            ),

            // ==========================================
            // EDIT
            // ==========================================

            SizedBox(
              height: 54,
              child: FilledButton.icon(
                onPressed: _isDeleting
                    ? null
                    : _editRecord,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      15,
                    ),
                  ),
                ),
                icon: const Icon(
                  Icons.edit_outlined,
                ),
                label: const Text(
                  'Edit Record',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            // ==========================================
            // DELETE
            // ==========================================

            SizedBox(
              height: 54,
              child: OutlinedButton.icon(
                onPressed: _isDeleting
                    ? null
                    : _deleteRecord,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(
                    color: Colors.red,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      15,
                    ),
                  ),
                ),
                icon: _isDeleting
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child:
                  CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
                    : const Icon(
                  Icons.delete_outline_rounded,
                ),
                label: Text(
                  _isDeleting
                      ? 'Deleting...'
                      : 'Delete Record',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}