import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:sehatfile/core/theme/app_colors.dart';
import 'package:sehatfile/core/theme/app_text_styles.dart';
import 'package:sehatfile/services/firestore_service.dart';
import 'package:sehatfile/services/storage_service.dart';

class EditRecordScreen extends StatefulWidget {
  final String recordId;
  final String? profileId;
  final String profileName;
  final Map<String, dynamic> recordData;

  const EditRecordScreen({
    super.key,
    required this.recordId,
    required this.profileName,
    required this.recordData,
    this.profileId,
  });

  @override
  State<EditRecordScreen> createState() =>
      _EditRecordScreenState();
}

class _EditRecordScreenState extends State<EditRecordScreen> {
  final GlobalKey<FormState> _formKey =
  GlobalKey<FormState>();

  final FirestoreService _firestoreService =
  FirestoreService();

  final ImagePicker _imagePicker =
  ImagePicker();

  // =====================================================
  // CONTROLLERS
  // =====================================================

  final TextEditingController recordTitleController =
  TextEditingController();

  final TextEditingController dateController =
  TextEditingController();

  final TextEditingController doctorController =
  TextEditingController();

  final TextEditingController facilityController =
  TextEditingController();

  final TextEditingController descriptionController =
  TextEditingController();

  // =====================================================
  // RECORD TYPE
  // =====================================================

  final List<String> recordTypes = [
    'Prescription',
    'Lab Report',
    'Medical Report',
    'Vaccination',
    'Other',
  ];

  String selectedRecordType = 'Prescription';

  // =====================================================
  // DATE
  // =====================================================

  DateTime selectedDate = DateTime.now();

  // =====================================================
  // STATUS
  // =====================================================

  bool isSaving = false;

  // =====================================================
  // NEW / REPLACEMENT ATTACHMENT
  // =====================================================

  File? selectedFile;

  String? selectedFileName;

  String? selectedAttachmentType;

  bool removeExistingAttachment = false;

  // =====================================================
  // EXISTING ATTACHMENT
  // =====================================================

  String get _existingStoragePath {
    return widget.recordData['storagePath']
        ?.toString()
        .trim() ??
        '';
  }

  String get _existingAttachmentName {
    return widget.recordData['attachmentName']
        ?.toString()
        .trim() ??
        '';
  }

  String get _existingAttachmentType {
    return widget.recordData['attachmentType']
        ?.toString()
        .trim() ??
        '';
  }

  bool get _hasExistingAttachment {
    return _existingStoragePath.isNotEmpty ||
        _existingAttachmentName.isNotEmpty;
  }

  bool get _selectedFileIsImage {
    final String name =
        selectedFileName?.toLowerCase() ?? '';

    return name.endsWith('.jpg') ||
        name.endsWith('.jpeg') ||
        name.endsWith('.png');
  }

  // =====================================================
  // INITIALIZE EXISTING RECORD
  // =====================================================

  @override
  void initState() {
    super.initState();

    // Record Type
    final String storedRecordType =
        widget.recordData['recordType']
            ?.toString()
            .trim() ??
            '';

    if (recordTypes.contains(storedRecordType)) {
      selectedRecordType = storedRecordType;
    } else {
      selectedRecordType = 'Other';
    }

    // Record Title
    recordTitleController.text =
        widget.recordData['recordTitle']
            ?.toString() ??
            '';

    // Doctor
    doctorController.text =
        widget.recordData['doctorName']
            ?.toString() ??
            '';

    // Facility
    facilityController.text =
        widget.recordData['facilityName']
            ?.toString() ??
            '';

    // Description
    descriptionController.text =
        widget.recordData['description']
            ?.toString() ??
            '';

    // Record Date
    final dynamic storedDate =
    widget.recordData['recordDate'];

    if (storedDate is Timestamp) {
      selectedDate = storedDate.toDate();
    } else if (storedDate is DateTime) {
      selectedDate = storedDate;
    }

    dateController.text =
        _formatDate(selectedDate);
  }

  // =====================================================
  // DATE FORMAT
  // =====================================================

  String _formatDate(DateTime date) {
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
  // DATE PICKER
  // =====================================================

  Future<void> _selectDate() async {
    final DateTime? pickedDate =
    await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(
        const Duration(
          days: 3650,
        ),
      ),
    );

    if (pickedDate == null) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      selectedDate = pickedDate;

      dateController.text =
          _formatDate(pickedDate);
    });
  }

  // =====================================================
  // LABEL
  // =====================================================

  Widget _label(
      String text, {
        bool optional = false,
      }) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 7,
      ),
      child: Row(
        children: [
          Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (optional) ...[
            const SizedBox(
              width: 4,
            ),
            Text(
              '(Optional)',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // =====================================================
  // TEXT FIELD STYLE
  // =====================================================

  InputDecoration _decoration(
      String hint,
      ) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding:
      const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 15,
      ),
      border: OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(14),
        borderSide: BorderSide(
          color: AppColors.border,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(14),
        borderSide: BorderSide(
          color: AppColors.border,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(14),
        borderSide: BorderSide(
          color: AppColors.primary,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Colors.red,
        ),
      ),
      focusedErrorBorder:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 2,
        ),
      ),
    );
  }

  // =====================================================
  // FACILITY LABEL
  // =====================================================

  String _facilityLabel() {
    switch (selectedRecordType) {
      case 'Lab Report':
        return 'Laboratory';

      case 'Vaccination':
        return 'Hospital / Vaccination Center';

      default:
        return 'Hospital / Clinic / Facility';
    }
  }

  // =====================================================
  // FACILITY HINT
  // =====================================================

  String _facilityHint() {
    switch (selectedRecordType) {
      case 'Lab Report':
        return 'e.g. IDC Laboratory';

      case 'Vaccination':
        return 'e.g. City Vaccination Center';

      default:
        return 'e.g. City Medical Center';
    }
  }

  // =====================================================
  // TITLE HINT
  // =====================================================

  String _recordTitleHint() {
    switch (selectedRecordType) {
      case 'Prescription':
        return 'e.g. Prescription - Dr. Ahmed Khan';

      case 'Lab Report':
        return 'e.g. Complete Blood Count';

      case 'Medical Report':
        return 'e.g. Chest X-Ray Report';

      case 'Vaccination':
        return 'e.g. Hepatitis B Vaccination';

      default:
        return 'Enter record title';
    }
  }

  // =====================================================
  // ATTACHMENT TYPE
  // =====================================================

  String? _getAttachmentType(
      String fileName,
      ) {
    final String lowerName =
    fileName.toLowerCase();

    if (lowerName.endsWith('.jpg') ||
        lowerName.endsWith('.jpeg')) {
      return 'image/jpeg';
    }

    if (lowerName.endsWith('.png')) {
      return 'image/png';
    }

    if (lowerName.endsWith('.pdf')) {
      return 'application/pdf';
    }

    return null;
  }

  // =====================================================
  // TAKE NEW PHOTO
  // =====================================================

  Future<void> _takePhoto() async {
    if (isSaving) {
      return;
    }

    try {
      final XFile? image =
      await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image == null) {
        return;
      }

      if (!mounted) {
        return;
      }

      final String fileName =
      image.name.isNotEmpty
          ? image.name
          : 'record_photo.jpg';

      setState(() {
        selectedFile =
            File(image.path);

        selectedFileName =
            fileName;

        selectedAttachmentType =
            _getAttachmentType(
              fileName,
            );

        // User chose a replacement,
        // so don't remove everything.
        removeExistingAttachment =
        false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Unable to take photo: $e',
          ),
        ),
      );
    }
  }

  // =====================================================
  // CHOOSE NEW FILE
  // =====================================================

  Future<void> _chooseFile() async {
    if (isSaving) {
      return;
    }

    try {
      final PlatformFile? pickedFile =
      await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: [
          'pdf',
          'jpg',
          'jpeg',
          'png',
        ],
      );

      if (pickedFile == null) {
        return;
      }

      final String? path =
          pickedFile.path;

      if (path == null) {
        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to access the selected file.',
            ),
          ),
        );

        return;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        selectedFile =
            File(path);

        selectedFileName =
            pickedFile.name;

        selectedAttachmentType =
            _getAttachmentType(
              pickedFile.name,
            );

        removeExistingAttachment =
        false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Unable to select file: $e',
          ),
        ),
      );
    }
  }

  // =====================================================
  // CANCEL NEW REPLACEMENT
  // =====================================================

  void _cancelReplacement() {
    if (isSaving) {
      return;
    }

    setState(() {
      selectedFile = null;
      selectedFileName = null;
      selectedAttachmentType = null;
      removeExistingAttachment = false;
    });
  }

  // =====================================================
  // REMOVE EXISTING ATTACHMENT
  // =====================================================

  void _removeAttachment() {
    if (isSaving) {
      return;
    }

    setState(() {
      selectedFile = null;
      selectedFileName = null;
      selectedAttachmentType = null;
      removeExistingAttachment = true;
    });
  }

  // =====================================================
  // UNDO REMOVE
  // =====================================================

  void _undoRemoveAttachment() {
    if (isSaving) {
      return;
    }

    setState(() {
      removeExistingAttachment = false;
    });
  }

  // =====================================================
  // UPDATE RECORD
  // =====================================================

  Future<void> _updateRecord() async {
    if (isSaving) {
      return;
    }

    if (!_formKey.currentState!
        .validate()) {
      return;
    }

    setState(() {
      isSaving = true;
    });

    final String oldStoragePath =
        _existingStoragePath;

    String? newlyUploadedPath;

    bool firestoreUpdated = false;

    try {
      // ===============================================
      // 1. UPLOAD NEW FILE IF USER SELECTED ONE
      // ===============================================

      if (selectedFile != null &&
          selectedFileName != null) {
        newlyUploadedPath =
        await StorageService.instance
            .uploadRecordFile(
          file: selectedFile!,
          fileName:
          selectedFileName!,
          recordType:
          selectedRecordType,
          profileId:
          widget.profileId,
        );
      }

      // ===============================================
      // 2. DECIDE FINAL ATTACHMENT VALUES
      // ===============================================

      final bool hasReplacement =
          newlyUploadedPath != null;

      final bool shouldRemove =
          removeExistingAttachment &&
              !hasReplacement;

      final String? finalStoragePath;

      final String? finalAttachmentName;

      final String? finalAttachmentType;

      if (hasReplacement) {
        finalStoragePath =
            newlyUploadedPath;

        finalAttachmentName =
            selectedFileName;

        finalAttachmentType =
            selectedAttachmentType;
      } else if (shouldRemove) {
        finalStoragePath = null;
        finalAttachmentName = null;
        finalAttachmentType = null;
      } else {
        finalStoragePath =
        _existingStoragePath.isEmpty
            ? null
            : _existingStoragePath;

        finalAttachmentName =
        _existingAttachmentName.isEmpty
            ? null
            : _existingAttachmentName;

        finalAttachmentType =
        _existingAttachmentType.isEmpty
            ? null
            : _existingAttachmentType;
      }

      // ===============================================
      // 3. UPDATE FIRESTORE
      // ===============================================

      await _firestoreService.updateRecord(
        recordId: widget.recordId,
        profileId: widget.profileId,
        data: {
          'recordType':
          selectedRecordType,

          'recordTitle':
          recordTitleController.text
              .trim(),

          'recordDate':
          Timestamp.fromDate(
            selectedDate,
          ),

          'doctorName':
          doctorController.text
              .trim(),

          'facilityName':
          facilityController.text
              .trim(),

          'description':
          descriptionController.text
              .trim(),

          // ==========================================
          // ATTACHMENT
          // ==========================================

          'storagePath':
          finalStoragePath,

          'attachmentName':
          finalAttachmentName,

          'attachmentType':
          finalAttachmentType,

          // Legacy field remains unused.
          'attachmentUrl':
          null,
        },
      );

      firestoreUpdated = true;
    } catch (e) {
      // ===============================================
      // ROLLBACK NEW FILE IF FIRESTORE FAILED
      // ===============================================

      if (!firestoreUpdated &&
          newlyUploadedPath != null) {
        try {
          await StorageService.instance
              .deleteFile(
            storagePath:
            newlyUploadedPath,
          );
        } catch (_) {
          // Ignore rollback cleanup failure.
        }
      }

      if (!mounted) {
        return;
      }

      setState(() {
        isSaving = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Unable to update record: $e',
          ),
        ),
      );

      return;
    }

    // ===================================================
    // 4. FIRESTORE UPDATED SUCCESSFULLY
    //
    // Delete old Supabase file only AFTER Firestore
    // safely points to the new file / no file.
    // ===================================================

    final bool attachmentChanged =
        newlyUploadedPath != null ||
            removeExistingAttachment;

    if (attachmentChanged &&
        oldStoragePath.isNotEmpty) {
      try {
        await StorageService.instance
            .deleteFile(
          storagePath:
          oldStoragePath,
        );
      } catch (_) {
        // Record update already succeeded.
        // Do not fail the whole update just because
        // old-file cleanup failed.
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      isSaving = false;
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          'Medical record updated successfully.',
        ),
      ),
    );

    Navigator.pop(
      context,
      true,
    );
  }

  // =====================================================
  // ATTACHMENT SECTION
  // =====================================================

  Widget _attachmentSection() {
    // ===================================================
    // NEW REPLACEMENT FILE SELECTED
    // ===================================================

    if (selectedFile != null &&
        selectedFileName != null) {
      return Container(
        width: double.infinity,
        padding:
        const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
          BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            if (_selectedFileIsImage)
              ClipRRect(
                borderRadius:
                BorderRadius.circular(
                  14,
                ),
                child: Image.file(
                  selectedFile!,
                  width: double.infinity,
                  height: 190,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                width: double.infinity,
                height: 125,
                decoration:
                BoxDecoration(
                  color:
                  Colors.teal.shade50,
                  borderRadius:
                  BorderRadius.circular(
                    14,
                  ),
                ),
                child: Icon(
                  Icons
                      .picture_as_pdf_outlined,
                  size: 52,
                  color:
                  AppColors.primary,
                ),
              ),

            const SizedBox(
              height: 12,
            ),

            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
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
                    _selectedFileIsImage
                        ? Icons.image_outlined
                        : Icons
                        .picture_as_pdf_outlined,
                    color:
                    AppColors.primary,
                  ),
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
                      Text(
                        selectedFileName!,
                        maxLines: 1,
                        overflow:
                        TextOverflow
                            .ellipsis,
                        style:
                        const TextStyle(
                          fontWeight:
                          FontWeight
                              .w700,
                        ),
                      ),
                      const SizedBox(
                        height: 3,
                      ),
                      Text(
                        'New document selected',
                        style:
                        AppTextStyles
                            .bodySmall
                            .copyWith(
                          color: AppColors
                              .textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                IconButton(
                  tooltip:
                  'Cancel replacement',
                  onPressed:
                  isSaving
                      ? null
                      : _cancelReplacement,
                  icon:
                  const Icon(
                    Icons.close_rounded,
                    color: Colors.red,
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 10,
            ),

            Row(
              children: [
                Expanded(
                  child:
                  OutlinedButton.icon(
                    onPressed:
                    isSaving
                        ? null
                        : _takePhoto,
                    icon:
                    const Icon(
                      Icons
                          .camera_alt_outlined,
                    ),
                    label:
                    const Text(
                      'Photo',
                    ),
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                Expanded(
                  child:
                  OutlinedButton.icon(
                    onPressed:
                    isSaving
                        ? null
                        : _chooseFile,
                    icon:
                    const Icon(
                      Icons
                          .folder_open_outlined,
                    ),
                    label:
                    const Text(
                      'Replace',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // ===================================================
    // EXISTING ATTACHMENT WILL BE REMOVED
    // ===================================================

    if (removeExistingAttachment) {
      return Container(
        width: double.infinity,
        padding:
        const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
          Colors.red.shade50,
          borderRadius:
          BorderRadius.circular(16),
          border: Border.all(
            color:
            Colors.red.shade100,
          ),
        ),
        child: Column(
          children: [
            const Icon(
              Icons
                  .delete_outline_rounded,
              color: Colors.red,
              size: 34,
            ),

            const SizedBox(
              height: 8,
            ),

            const Text(
              'Document will be removed',
              style: TextStyle(
                fontWeight:
                FontWeight.w700,
              ),
            ),

            const SizedBox(
              height: 5,
            ),

            Text(
              'The current document will be deleted when you save your changes.',
              textAlign:
              TextAlign.center,
              style:
              AppTextStyles.bodySmall
                  .copyWith(
                color: AppColors
                    .textSecondary,
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            TextButton.icon(
              onPressed:
              isSaving
                  ? null
                  : _undoRemoveAttachment,
              icon: const Icon(
                Icons.undo_rounded,
              ),
              label:
              const Text(
                'Undo Remove',
              ),
            ),

            Row(
              children: [
                Expanded(
                  child:
                  OutlinedButton.icon(
                    onPressed:
                    isSaving
                        ? null
                        : _takePhoto,
                    icon:
                    const Icon(
                      Icons
                          .camera_alt_outlined,
                    ),
                    label:
                    const Text(
                      'Photo',
                    ),
                  ),
                ),

                const SizedBox(
                  width: 10,
                ),

                Expanded(
                  child:
                  OutlinedButton.icon(
                    onPressed:
                    isSaving
                        ? null
                        : _chooseFile,
                    icon:
                    const Icon(
                      Icons
                          .folder_open_outlined,
                    ),
                    label:
                    const Text(
                      'Choose File',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // ===================================================
    // EXISTING ATTACHMENT
    // ===================================================

    if (_hasExistingAttachment) {
      return Container(
        width: double.infinity,
        padding:
        const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
          Colors.teal.shade50,
          borderRadius:
          BorderRadius.circular(16),
          border: Border.all(
            color:
            AppColors.border,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration:
                  BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                    BorderRadius.circular(
                      13,
                    ),
                  ),
                  child: Icon(
                    _existingAttachmentType ==
                        'application/pdf'
                        ? Icons
                        .picture_as_pdf_outlined
                        : Icons
                        .description_outlined,
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
                    CrossAxisAlignment
                        .start,
                    children: [
                      Text(
                        _existingAttachmentName
                            .isEmpty
                            ? 'Attached document'
                            : _existingAttachmentName,
                        maxLines: 2,
                        overflow:
                        TextOverflow
                            .ellipsis,
                        style:
                        const TextStyle(
                          fontWeight:
                          FontWeight
                              .w700,
                        ),
                      ),

                      const SizedBox(
                        height: 4,
                      ),

                      Text(
                        'Current document',
                        style:
                        AppTextStyles
                            .bodySmall
                            .copyWith(
                          color: AppColors
                              .textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 14,
            ),

            Row(
              children: [
                Expanded(
                  child:
                  OutlinedButton.icon(
                    onPressed:
                    isSaving
                        ? null
                        : _takePhoto,
                    icon:
                    const Icon(
                      Icons
                          .camera_alt_outlined,
                    ),
                    label:
                    const Text(
                      'Photo',
                    ),
                  ),
                ),

                const SizedBox(
                  width: 10,
                ),

                Expanded(
                  child:
                  OutlinedButton.icon(
                    onPressed:
                    isSaving
                        ? null
                        : _chooseFile,
                    icon:
                    const Icon(
                      Icons
                          .folder_open_outlined,
                    ),
                    label:
                    const Text(
                      'Replace',
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 8,
            ),

            SizedBox(
              width:
              double.infinity,
              child:
              TextButton.icon(
                onPressed:
                isSaving
                    ? null
                    : _removeAttachment,
                icon:
                const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                ),
                label:
                const Text(
                  'Remove Document',
                  style: TextStyle(
                    color: Colors.red,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // ===================================================
    // NO ATTACHMENT
    // ===================================================

    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration:
            BoxDecoration(
              color:
              Colors.teal.shade50,
              borderRadius:
              BorderRadius.circular(
                18,
              ),
            ),
            child: Icon(
              Icons
                  .upload_file_outlined,
              size: 30,
              color:
              AppColors.primary,
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          const Text(
            'Add Document',
            style: TextStyle(
              fontWeight:
              FontWeight.w700,
            ),
          ),

          const SizedBox(
            height: 5,
          ),

          Text(
            'Add a photo, report or PDF to this record.',
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
            height: 16,
          ),

          Row(
            children: [
              Expanded(
                child:
                OutlinedButton.icon(
                  onPressed:
                  isSaving
                      ? null
                      : _takePhoto,
                  icon:
                  const Icon(
                    Icons
                        .camera_alt_outlined,
                  ),
                  label:
                  const Text(
                    'Take Photo',
                  ),
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              Expanded(
                child:
                OutlinedButton.icon(
                  onPressed:
                  isSaving
                      ? null
                      : _chooseFile,
                  icon:
                  const Icon(
                    Icons
                        .folder_open_outlined,
                  ),
                  label:
                  const Text(
                    'Choose File',
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
  // DISPOSE
  // =====================================================

  @override
  void dispose() {
    recordTitleController.dispose();
    dateController.dispose();
    doctorController.dispose();
    facilityController.dispose();
    descriptionController.dispose();

    super.dispose();
  }

  // =====================================================
  // BUILD SCREEN
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
            BorderRadius.circular(
              12,
            ),
            child: IconButton(
              onPressed:
              isSaving
                  ? null
                  : () {
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
        ),
      ),

      body: SafeArea(
        child:
        SingleChildScrollView(
          padding:
          const EdgeInsets.fromLTRB(
            18,
            4,
            18,
            30,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment
                  .start,
              children: [
                // =====================================
                // TITLE
                // =====================================

                Text(
                  'Edit Medical Record',
                  style:
                  AppTextStyles
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
                  'Update medical record for ${widget.profileName}',
                  style:
                  AppTextStyles
                      .bodySmall
                      .copyWith(
                    color: AppColors
                        .textSecondary,
                  ),
                ),

                const SizedBox(
                  height: 24,
                ),

                // =====================================
                // RECORD TYPE
                // =====================================

                _label(
                  'Record Type',
                ),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                  recordTypes.map(
                        (type) {
                      final bool selected =
                          selectedRecordType ==
                              type;

                      return ChoiceChip(
                        label: Text(type),
                        selected:
                        selected,
                        selectedColor:
                        AppColors.primary,
                        backgroundColor:
                        Colors.white,
                        side:
                        BorderSide(
                          color: selected
                              ? AppColors
                              .primary
                              : AppColors
                              .border,
                        ),
                        labelStyle:
                        TextStyle(
                          color: selected
                              ? Colors.white
                              : AppColors
                              .textSecondary,
                          fontWeight:
                          FontWeight
                              .w600,
                        ),
                        onSelected:
                        isSaving
                            ? null
                            : (_) {
                          setState(
                                () {
                              selectedRecordType =
                                  type;
                            },
                          );
                        },
                      );
                    },
                  ).toList(),
                ),

                const SizedBox(
                  height: 22,
                ),

                // =====================================
                // RECORD TITLE
                // =====================================

                _label(
                  'Record Title',
                ),

                TextFormField(
                  controller:
                  recordTitleController,
                  enabled:
                  !isSaving,
                  textCapitalization:
                  TextCapitalization
                      .words,
                  decoration:
                  _decoration(
                    _recordTitleHint(),
                  ),
                  validator:
                      (value) {
                    if (value ==
                        null ||
                        value
                            .trim()
                            .isEmpty) {
                      return 'Please enter a record title.';
                    }

                    return null;
                  },
                ),

                const SizedBox(
                  height: 18,
                ),

                // =====================================
                // DATE
                // =====================================

                _label(
                  'Date',
                ),

                TextFormField(
                  controller:
                  dateController,
                  enabled:
                  !isSaving,
                  readOnly: true,
                  onTap:
                  _selectDate,
                  decoration:
                  _decoration(
                    'Select date',
                  ).copyWith(
                    suffixIcon:
                    const Icon(
                      Icons
                          .calendar_month_outlined,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 18,
                ),

                // =====================================
                // DOCTOR
                // =====================================

                _label(
                  'Doctor Name',
                  optional: true,
                ),

                TextFormField(
                  controller:
                  doctorController,
                  enabled:
                  !isSaving,
                  textCapitalization:
                  TextCapitalization
                      .words,
                  decoration:
                  _decoration(
                    'e.g. Dr. Ahmed Khan',
                  ),
                ),

                const SizedBox(
                  height: 18,
                ),

                // =====================================
                // FACILITY
                // =====================================

                _label(
                  _facilityLabel(),
                  optional: true,
                ),

                TextFormField(
                  controller:
                  facilityController,
                  enabled:
                  !isSaving,
                  textCapitalization:
                  TextCapitalization
                      .words,
                  decoration:
                  _decoration(
                    _facilityHint(),
                  ),
                ),

                const SizedBox(
                  height: 18,
                ),

                // =====================================
                // DESCRIPTION
                // =====================================

                _label(
                  'Description / Notes',
                  optional: true,
                ),

                TextFormField(
                  controller:
                  descriptionController,
                  enabled:
                  !isSaving,
                  maxLines: 4,
                  textCapitalization:
                  TextCapitalization
                      .sentences,
                  decoration:
                  _decoration(
                    'Add important notes about this record',
                  ),
                ),

                const SizedBox(
                  height: 22,
                ),

                // =====================================
                // ATTACHMENT
                // =====================================

                _label(
                  'Attached Document',
                  optional: true,
                ),

                _attachmentSection(),

                const SizedBox(
                  height: 30,
                ),

                // =====================================
                // SAVE CHANGES
                // =====================================

                SizedBox(
                  width:
                  double.infinity,
                  height: 55,
                  child:
                  FilledButton.icon(
                    style:
                    FilledButton
                        .styleFrom(
                      backgroundColor:
                      AppColors.primary,
                      shape:
                      RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius
                            .circular(
                          16,
                        ),
                      ),
                    ),
                    onPressed:
                    isSaving
                        ? null
                        : _updateRecord,
                    icon: isSaving
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child:
                      CircularProgressIndicator(
                        strokeWidth: 2,
                        color:
                        Colors.white,
                      ),
                    )
                        : const Icon(
                      Icons
                          .save_outlined,
                    ),
                    label: Text(
                      isSaving
                          ? 'Saving Changes...'
                          : 'Save Changes',
                      style:
                      const TextStyle(
                        fontWeight:
                        FontWeight
                            .w700,
                      ),
                    ),
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

                // =====================================
                // CANCEL
                // =====================================

                Center(
                  child:
                  TextButton(
                    onPressed:
                    isSaving
                        ? null
                        : () {
                      Navigator.pop(
                        context,
                      );
                    },
                    child:
                    const Text(
                      'Cancel',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}