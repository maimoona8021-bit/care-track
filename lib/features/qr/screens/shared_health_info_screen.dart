import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:sehatfile/core/theme/app_colors.dart';
import 'package:sehatfile/core/theme/app_text_styles.dart';
import 'package:sehatfile/features/records/screens/document_viewer_screen.dart';
import 'package:sehatfile/services/firestore_service.dart';
import 'package:sehatfile/services/storage_service.dart';

class SharedHealthInfoScreen extends StatefulWidget {
  final String shareId;
  final String profileName;
  final Map<String, dynamic> sharedData;
  final List<Map<String, dynamic>> sharedDocuments;

  const SharedHealthInfoScreen({
    super.key,
    required this.shareId,
    required this.profileName,
    required this.sharedData,
    this.sharedDocuments = const [],
  });

  @override
  State<SharedHealthInfoScreen> createState() =>
      _SharedHealthInfoScreenState();
}

class _SharedHealthInfoScreenState
    extends State<SharedHealthInfoScreen> {
  final FirestoreService _firestoreService =
  FirestoreService();

  String? _openingStoragePath;

  // =====================================================
  // VALUE
  // =====================================================

  String _value(
      String key, {
        String fallback = 'Not shared',
      }) {
    final dynamic value =
    widget.sharedData[key];

    if (value == null) {
      return fallback;
    }

    final String text =
    value.toString().trim();

    if (text.isEmpty) {
      return fallback;
    }

    return text;
  }

  // =====================================================
  // FORMAT DATE
  // =====================================================

  String _formatDate(
      dynamic value,
      ) {
    DateTime? date;

    if (value is Timestamp) {
      date = value.toDate();
    } else if (value is DateTime) {
      date = value;
    } else if (value != null) {
      date = DateTime.tryParse(
        value.toString(),
      );
    }

    if (date == null) {
      return 'Date not available';
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
  // DOCUMENT ICON
  // =====================================================

  IconData _documentIcon(
      String type,
      ) {
    switch (type.toLowerCase()) {
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
  // OPEN SHARED DOCUMENT
  // =====================================================

  Future<void> _openDocument(
      Map<String, dynamic> document,
      ) async {
    final String storagePath =
        document['storagePath']
            ?.toString()
            .trim() ??
            '';

    final String attachmentName =
        document['attachmentName']
            ?.toString()
            .trim() ??
            'Medical document';

    final String attachmentType =
        document['attachmentType']
            ?.toString()
            .trim() ??
            '';

    if (storagePath.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'This shared document is not available.',
          ),
        ),
      );

      return;
    }

    if (_openingStoragePath != null) {
      return;
    }

    setState(() {
      _openingStoragePath =
          storagePath;
    });

    try {
      final String signedUrl =
      await StorageService.instance
          .getSharedDocumentUrl(
        shareId: widget.shareId,
        storagePath: storagePath,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _openingStoragePath = null;
      });

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              DocumentViewerScreen(
                documentUrl:
                signedUrl,
                documentName:
                attachmentName,
                documentType:
                attachmentType,
              ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _openingStoragePath = null;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Unable to open shared document: $e',
          ),
        ),
      );
    }
  }

  // =====================================================
  // INFORMATION CARD
  // =====================================================

  Widget _informationCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      padding: const EdgeInsets.all(
        15,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(
          17,
        ),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color:
              Colors.teal.shade50,
              borderRadius:
              BorderRadius.circular(
                12,
              ),
            ),
            child: Icon(
              icon,
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
                  style:
                  AppTextStyles.bodySmall
                      .copyWith(
                    color:
                    AppColors.textSecondary,
                  ),
                ),

                const SizedBox(
                  height: 4,
                ),

                Text(
                  value,
                  style:
                  const TextStyle(
                    fontSize: 15,
                    fontWeight:
                    FontWeight.w700,
                    height: 1.4,
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
  // SHARED DOCUMENT CARD
  // =====================================================

  Widget _documentCard(
      Map<String, dynamic> document,
      ) {
    final String title =
        document['recordTitle']
            ?.toString()
            .trim() ??
            'Medical Record';

    final String type =
        document['recordType']
            ?.toString()
            .trim() ??
            'Medical Document';

    final String attachmentName =
        document['attachmentName']
            ?.toString()
            .trim() ??
            'Attached document';

    final String doctorName =
        document['doctorName']
            ?.toString()
            .trim() ??
            '';

    final String facilityName =
        document['facilityName']
            ?.toString()
            .trim() ??
            '';

    final String storagePath =
        document['storagePath']
            ?.toString()
            .trim() ??
            '';

    final bool isOpening =
        _openingStoragePath ==
            storagePath;

    return Container(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      padding: const EdgeInsets.all(
        15,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(
          17,
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
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Container(
                width: 45,
                height: 45,
                decoration:
                BoxDecoration(
                  color:
                  Colors.teal.shade50,
                  borderRadius:
                  BorderRadius.circular(
                    12,
                  ),
                ),
                child: Icon(
                  _documentIcon(
                    type,
                  ),
                  color:
                  AppColors.primary,
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
                      style:
                      const TextStyle(
                        fontSize: 15,
                        fontWeight:
                        FontWeight.w800,
                      ),
                    ),

                    const SizedBox(
                      height: 4,
                    ),

                    Text(
                      type,
                      style:
                      AppTextStyles.bodySmall
                          .copyWith(
                        color:
                        AppColors.primary,
                        fontWeight:
                        FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 13,
          ),

          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color:
                AppColors.textSecondary,
              ),

              const SizedBox(
                width: 7,
              ),

              Text(
                _formatDate(
                  document[
                  'recordDate'],
                ),
                style:
                AppTextStyles.bodySmall
                    .copyWith(
                  color:
                  AppColors.textSecondary,
                ),
              ),
            ],
          ),

          if (doctorName.isNotEmpty) ...[
            const SizedBox(
              height: 8,
            ),

            Row(
              children: [
                Icon(
                  Icons
                      .medical_services_outlined,
                  size: 16,
                  color:
                  AppColors.textSecondary,
                ),

                const SizedBox(
                  width: 7,
                ),

                Expanded(
                  child: Text(
                    doctorName,
                    style:
                    AppTextStyles.bodySmall
                        .copyWith(
                      color:
                      AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],

          if (facilityName.isNotEmpty) ...[
            const SizedBox(
              height: 8,
            ),

            Row(
              children: [
                Icon(
                  Icons
                      .local_hospital_outlined,
                  size: 16,
                  color:
                  AppColors.textSecondary,
                ),

                const SizedBox(
                  width: 7,
                ),

                Expanded(
                  child: Text(
                    facilityName,
                    style:
                    AppTextStyles.bodySmall
                        .copyWith(
                      color:
                      AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(
            height: 11,
          ),

          Container(
            padding:
            const EdgeInsets.symmetric(
              horizontal: 11,
              vertical: 9,
            ),
            decoration:
            BoxDecoration(
              color:
              Colors.teal.shade50,
              borderRadius:
              BorderRadius.circular(
                10,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.attach_file_rounded,
                  size: 18,
                  color:
                  AppColors.primary,
                ),

                const SizedBox(
                  width: 7,
                ),

                Expanded(
                  child: Text(
                    attachmentName,
                    maxLines: 1,
                    overflow:
                    TextOverflow.ellipsis,
                    style:
                    AppTextStyles.bodySmall
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

          const SizedBox(
            height: 12,
          ),

          SizedBox(
            width:
            double.infinity,
            height: 45,
            child:
            OutlinedButton.icon(
              onPressed:
              storagePath.isEmpty ||
                  _openingStoragePath !=
                      null
                  ? null
                  : () {
                _openDocument(
                  document,
                );
              },

              icon: isOpening
                  ? const SizedBox(
                width: 18,
                height: 18,
                child:
                CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
                  : const Icon(
                Icons
                    .visibility_outlined,
              ),

              label: Text(
                isOpening
                    ? 'Opening...'
                    : 'View Document',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // SHARING STOPPED SCREEN
  // =====================================================

  Widget _sharingStoppedScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(
          30,
        ),
        child: Column(
          mainAxisSize:
          MainAxisSize.min,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration:
              BoxDecoration(
                color:
                Colors.red.shade50,
                shape:
                BoxShape.circle,
              ),
              child: const Icon(
                Icons
                    .visibility_off_outlined,
                color: Colors.red,
                size: 38,
              ),
            ),

            const SizedBox(
              height: 18,
            ),

            const Text(
              'Sharing Stopped',
              textAlign:
              TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight:
                FontWeight.w800,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            Text(
              'The profile owner has stopped sharing this health information.',
              textAlign:
              TextAlign.center,
              style:
              AppTextStyles.bodySmall
                  .copyWith(
                color:
                AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // SHARED CONTENT
  // =====================================================

  Widget _sharedContent() {
    return ListView(
      padding:
      const EdgeInsets.fromLTRB(
        18,
        18,
        18,
        30,
      ),
      children: [
        // ==========================================
        // PERSON
        // ==========================================

        Center(
          child: Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color:
              Colors.teal.shade50,
              shape:
              BoxShape.circle,
            ),
            child: Icon(
              Icons.person_rounded,
              size: 40,
              color:
              AppColors.primary,
            ),
          ),
        ),

        const SizedBox(
          height: 12,
        ),

        Text(
          widget.profileName,
          textAlign:
          TextAlign.center,
          style:
          AppTextStyles.titleLarge
              .copyWith(
            color:
            AppColors.primary,
            fontSize: 23,
            fontWeight:
            FontWeight.w800,
          ),
        ),

        const SizedBox(
          height: 6,
        ),

        Text(
          'Shared through Care Track Health QR',
          textAlign:
          TextAlign.center,
          style:
          AppTextStyles.bodySmall
              .copyWith(
            color:
            AppColors.textSecondary,
          ),
        ),

        const SizedBox(
          height: 25,
        ),

        // ==========================================
        // HEALTH INFORMATION
        //
        // ONLY:
        // AGE
        // BLOOD GROUP
        // CURRENT MEDICINES
        // ==========================================

        if (widget.sharedData.containsKey(
          'age',
        ) ||
            widget.sharedData.containsKey(
              'bloodGroup',
            ) ||
            widget.sharedData.containsKey(
              'currentMedicines',
            )) ...[
          Text(
            'Health Information',
            style: TextStyle(
              color:
              AppColors.primary,
              fontSize: 16,
              fontWeight:
              FontWeight.w800,
            ),
          ),

          const SizedBox(
            height: 12,
          ),
        ],

        // ==========================================
        // AGE
        // ==========================================

        if (widget.sharedData.containsKey(
          'age',
        ))
          _informationCard(
            icon:
            Icons.cake_outlined,
            title:
            'Age',
            value:
            _value(
              'age',
            ),
          ),

        // ==========================================
        // BLOOD GROUP
        // ==========================================

        if (widget.sharedData.containsKey(
          'bloodGroup',
        ))
          _informationCard(
            icon:
            Icons.bloodtype_outlined,
            title:
            'Blood Group',
            value:
            _value(
              'bloodGroup',
            ),
          ),

        // ==========================================
        // CURRENT MEDICINES
        // ==========================================

        if (widget.sharedData.containsKey(
          'currentMedicines',
        ))
          _informationCard(
            icon:
            Icons.medication_outlined,
            title:
            'Current Medicines',
            value:
            _value(
              'currentMedicines',
            ),
          ),

        // =================================================
        // IMPORTANT:
        //
        // Allergies
        // Medical Conditions
        // Emergency Contact
        //
        // ARE INTENTIONALLY NOT DISPLAYED.
        // =================================================

        // ==========================================
        // SHARED DOCUMENTS
        // ==========================================

        if (widget.sharedDocuments
            .isNotEmpty) ...[
          const SizedBox(
            height: 12,
          ),

          Row(
            children: [
              Expanded(
                child: Text(
                  'Shared Documents',
                  style: TextStyle(
                    color:
                    AppColors.primary,
                    fontSize: 16,
                    fontWeight:
                    FontWeight.w800,
                  ),
                ),
              ),

              Container(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration:
                BoxDecoration(
                  color:
                  Colors.teal.shade50,
                  borderRadius:
                  BorderRadius.circular(
                    20,
                  ),
                ),
                child: Text(
                  '${widget.sharedDocuments.length}',
                  style:
                  TextStyle(
                    color:
                    AppColors.primary,
                    fontSize: 12,
                    fontWeight:
                    FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 12,
          ),

          ...widget.sharedDocuments.map(
            _documentCard,
          ),
        ],

        const SizedBox(
          height: 12,
        ),

        // ==========================================
        // SECURITY
        // ==========================================

        Container(
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
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Icon(
                Icons
                    .verified_user_outlined,
                color:
                AppColors.primary,
              ),

              const SizedBox(
                width: 10,
              ),

              Expanded(
                child: Text(
                  'This information was intentionally shared by the profile owner through a Care Track Health QR.',
                  style:
                  AppTextStyles.bodySmall
                      .copyWith(
                    color:
                    AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =====================================================
  // SCREEN
  // =====================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      backgroundColor:
      AppColors.background,

      appBar: AppBar(
        backgroundColor:
        AppColors.background,
        title: const Text(
          'Shared Health Information',
        ),
      ),

      body: SafeArea(
        // =============================================
        // LIVE QR STATUS
        //
        // If owner presses Stop Sharing while this
        // screen is already open, access disappears.
        // =============================================

        child: StreamBuilder<
            DocumentSnapshot<
                Map<String, dynamic>>>(
          stream:
          _firestoreService
              .healthShareStream(
            shareId:
            widget.shareId,
          ),

          builder:
              (context, snapshot) {
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

            // If Firestore rules stop access after
            // the owner disables the share.
            if (snapshot.hasError) {
              return _sharingStoppedScreen();
            }

            if (!snapshot.hasData ||
                !snapshot.data!.exists) {
              return _sharingStoppedScreen();
            }

            final Map<String, dynamic>
            shareData =
                snapshot.data!.data() ??
                    {};

            if (shareData['active'] !=
                true) {
              return _sharingStoppedScreen();
            }

            return _sharedContent();
          },
        ),
      ),
    );
  }
}