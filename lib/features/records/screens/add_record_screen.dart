import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:sehatfile/core/theme/app_colors.dart';
import 'package:sehatfile/core/theme/app_text_styles.dart';
import 'package:sehatfile/services/firestore_service.dart';
import 'package:sehatfile/services/storage_service.dart';

class AddRecordScreen extends StatefulWidget {
  final String? profileId;
  final String profileName;

  const AddRecordScreen({
    super.key,
    required this.profileName,
    this.profileId,
  });

  @override
  State<AddRecordScreen> createState() =>
      _AddRecordScreenState();
}

class _AddRecordScreenState
    extends State<AddRecordScreen> {
  final GlobalKey<FormState> _formKey =
  GlobalKey<FormState>();

  final FirestoreService _firestoreService =
  FirestoreService();

  final ImagePicker _imagePicker =
  ImagePicker();

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

  String selectedRecordType =
      'Prescription';

  final List<String> recordTypes = [
    'Prescription',
    'Lab Report',
    'Medical Report',
    'Vaccination',
    'Other',
  ];

  DateTime selectedDate =
  DateTime.now();

  bool isSaving = false;

  // =====================================================
  // SELECTED ATTACHMENT
  // =====================================================

  File? selectedFile;

  String? selectedFileName;

  String? selectedAttachmentType;

  bool get isImageAttachment {
    final String fileName =
        selectedFileName
            ?.toLowerCase() ??
            '';

    return fileName.endsWith('.jpg') ||
        fileName.endsWith('.jpeg') ||
        fileName.endsWith('.png');
  }

  // =====================================================
  // INITIALIZE
  // =====================================================

  @override
  void initState() {
    super.initState();

    dateController.text =
        _formatDate(
          selectedDate,
        );
  }

  // =====================================================
  // INPUT DECORATION
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
        BorderRadius.circular(
          14,
        ),
        borderSide: BorderSide(
          color:
          AppColors.border,
        ),
      ),
      enabledBorder:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(
          14,
        ),
        borderSide: BorderSide(
          color:
          AppColors.border,
        ),
      ),
      focusedBorder:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(
          14,
        ),
        borderSide: BorderSide(
          color:
          AppColors.primary,
          width: 2,
        ),
      ),
      errorBorder:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(
          14,
        ),
        borderSide:
        const BorderSide(
          color: Colors.red,
        ),
      ),
      focusedErrorBorder:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(
          14,
        ),
        borderSide:
        const BorderSide(
          color: Colors.red,
          width: 2,
        ),
      ),
    );
  }

  // =====================================================
  // LABEL
  // =====================================================

  Widget _label(
      String text, {
        bool optional = false,
      }) {
    return Padding(
      padding:
      const EdgeInsets.only(
        bottom: 7,
      ),
      child: Row(
        children: [
          Text(
            text,
            style:
            const TextStyle(
              fontSize: 13,
              fontWeight:
              FontWeight.w700,
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
                color: AppColors
                    .textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // =====================================================
  // FORMAT DATE
  // =====================================================

  String _formatDate(
      DateTime date,
      ) {
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
    final DateTime? date =
    await showDatePicker(
      context: context,
      initialDate:
      selectedDate,
      firstDate:
      DateTime(2000),
      lastDate:
      DateTime.now().add(
        const Duration(
          days: 3650,
        ),
      ),
    );

    if (date == null) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      selectedDate =
          date;

      dateController.text =
          _formatDate(
            date,
          );
    });
  }

  // =====================================================
  // ATTACHMENT TYPE
  // =====================================================

  String? _getAttachmentType(
      String fileName,
      ) {
    final String lowerName =
    fileName.toLowerCase();

    if (lowerName.endsWith(
      '.jpg',
    )) {
      return 'image/jpeg';
    }

    if (lowerName.endsWith(
      '.jpeg',
    )) {
      return 'image/jpeg';
    }

    if (lowerName.endsWith(
      '.png',
    )) {
      return 'image/png';
    }

    if (lowerName.endsWith(
      '.pdf',
    )) {
      return 'application/pdf';
    }

    return null;
  }

  // =====================================================
  // TAKE PHOTO
  // =====================================================

  Future<void> _takePhoto() async {
    if (isSaving) {
      return;
    }

    try {
      final XFile? image =
      await _imagePicker.pickImage(
        source:
        ImageSource.camera,
        imageQuality: 85,
      );

      if (image == null) {
        return;
      }

      if (!mounted) {
        return;
      }

      final File file =
      File(
        image.path,
      );

      final String fileName =
      image.name.isNotEmpty
          ? image.name
          : 'record_photo.jpg';

      setState(() {
        selectedFile =
            file;

        selectedFileName =
            fileName;

        selectedAttachmentType =
            _getAttachmentType(
              fileName,
            );
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
  // CHOOSE FILE
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

      final String? path = pickedFile.path;

      if (path == null) {
        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
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
        selectedFile = File(path);
        selectedFileName = pickedFile.name;
        selectedAttachmentType =
            _getAttachmentType(
              pickedFile.name,
            );
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to select file: $e',
          ),
        ),
      );
    }
  }

  // =====================================================
  // REMOVE ATTACHMENT
  // =====================================================

  void _removeAttachment() {
    if (isSaving) {
      return;
    }

    setState(() {
      selectedFile =
      null;

      selectedFileName =
      null;

      selectedAttachmentType =
      null;
    });
  }

  // =====================================================
  // SAVE RECORD
  // =====================================================

  Future<void> _saveRecord() async {
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

    String? uploadedStoragePath;

    try {
      // ===============================================
      // 1. UPLOAD ATTACHMENT TO SUPABASE
      // ===============================================

      if (selectedFile != null &&
          selectedFileName != null) {
        uploadedStoragePath =
        await StorageService
            .instance
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
      // 2. SAVE RECORD METADATA TO FIRESTORE
      // ===============================================

      await _firestoreService.createRecord(
        profileId:
        widget.profileId,
        data: {
          'recordType':
          selectedRecordType,

          'recordTitle':
          recordTitleController
              .text
              .trim(),

          'recordDate':
          Timestamp.fromDate(
            selectedDate,
          ),

          'doctorName':
          doctorController
              .text
              .trim(),

          'facilityName':
          facilityController
              .text
              .trim(),

          'description':
          descriptionController
              .text
              .trim(),

          // ==========================================
          // SUPABASE ATTACHMENT
          // ==========================================

          'storagePath':
          uploadedStoragePath,

          'attachmentName':
          selectedFileName,

          'attachmentType':
          selectedAttachmentType,

          // Keep temporarily for compatibility with
          // older record screens.
          'attachmentUrl':
          null,
        },
      );

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
            'Medical record saved successfully.',
          ),
        ),
      );

      Navigator.pop(
        context,
        true,
      );
    } catch (e) {
      // ===============================================
      // ROLLBACK UPLOAD IF FIRESTORE SAVE FAILS
      // ===============================================

      if (uploadedStoragePath != null) {
        try {
          await StorageService.instance
              .deleteFile(
            storagePath:
            uploadedStoragePath,
          );
        } catch (_) {
          // Ignore rollback failure.
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
            'Unable to save record: $e',
          ),
        ),
      );
    }
  }

  // =====================================================
  // ATTACHMENT UI
  // =====================================================

  Widget _attachmentSection() {
    if (selectedFile == null ||
        selectedFileName == null) {
      return Material(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(
          18,
        ),
        child: Container(
          width: double.infinity,
          padding:
          const EdgeInsets.all(
            18,
          ),
          decoration: BoxDecoration(
            borderRadius:
            BorderRadius.circular(
              18,
            ),
            border: Border.all(
              color:
              AppColors.border,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 62,
                height: 62,
                decoration:
                BoxDecoration(
                  color: Colors
                      .teal.shade50,
                  borderRadius:
                  BorderRadius
                      .circular(
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
                'Upload Document',
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
                style: AppTextStyles
                    .bodySmall
                    .copyWith(
                  color: AppColors
                      .textSecondary,
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
                      style:
                      OutlinedButton
                          .styleFrom(
                        foregroundColor:
                        AppColors
                            .primary,
                        side:
                        BorderSide(
                          color: AppColors
                              .primary,
                        ),
                        shape:
                        RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius
                              .circular(
                            12,
                          ),
                        ),
                      ),
                      icon:
                      const Icon(
                        Icons
                            .camera_alt_outlined,
                        size: 19,
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
                      style:
                      OutlinedButton
                          .styleFrom(
                        foregroundColor:
                        AppColors
                            .primary,
                        side:
                        BorderSide(
                          color: AppColors
                              .primary,
                        ),
                        shape:
                        RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius
                              .circular(
                            12,
                          ),
                        ),
                      ),
                      icon:
                      const Icon(
                        Icons
                            .folder_open_outlined,
                        size: 19,
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
        ),
      );
    }

    // =================================================
    // SELECTED FILE PREVIEW
    // =================================================

    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(
        14,
      ),
      decoration:
      BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color:
          AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          // ===========================================
          // IMAGE PREVIEW
          // ===========================================

          if (isImageAttachment)
            ClipRRect(
              borderRadius:
              BorderRadius.circular(
                14,
              ),
              child: Image.file(
                selectedFile!,
                width:
                double.infinity,
                height: 190,
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              width:
              double.infinity,
              height: 130,
              decoration:
              BoxDecoration(
                color: Colors
                    .teal.shade50,
                borderRadius:
                BorderRadius
                    .circular(
                  14,
                ),
              ),
              child: Icon(
                Icons
                    .picture_as_pdf_outlined,
                size: 55,
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
                width: 42,
                height: 42,
                decoration:
                BoxDecoration(
                  color: Colors
                      .teal.shade50,
                  borderRadius:
                  BorderRadius
                      .circular(
                    11,
                  ),
                ),
                child: Icon(
                  isImageAttachment
                      ? Icons
                      .image_outlined
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
                        fontSize: 13,
                        fontWeight:
                        FontWeight
                            .w700,
                      ),
                    ),

                    const SizedBox(
                      height: 3,
                    ),

                    Text(
                      isImageAttachment
                          ? 'Image selected'
                          : 'PDF selected',
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

              IconButton(
                tooltip:
                'Remove attachment',
                onPressed:
                isSaving
                    ? null
                    : _removeAttachment,
                icon:
                const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 8,
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

  // =====================================================
  // DISPOSE
  // =====================================================

  @override
  void dispose() {
    recordTitleController
        .dispose();

    dateController.dispose();

    doctorController.dispose();

    facilityController
        .dispose();

    descriptionController
        .dispose();

    super.dispose();
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
        elevation: 0,
        leading: Padding(
          padding:
          const EdgeInsets.all(
            8,
          ),
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
            28,
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
                  'Add Medical Record',
                  style: AppTextStyles
                      .titleLarge
                      .copyWith(
                    color:
                    AppColors.primary,
                    fontSize: 25,
                    fontWeight:
                    FontWeight
                        .w700,
                  ),
                ),

                const SizedBox(
                  height: 5,
                ),

                Text(
                  'Add a medical record for ${widget.profileName}',
                  style: AppTextStyles
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
                      final bool
                      selected =
                          selectedRecordType ==
                              type;

                      return ChoiceChip(
                        label:
                        Text(type),
                        selected:
                        selected,
                        selectedColor:
                        AppColors
                            .primary,
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
                  readOnly: true,
                  enabled:
                  !isSaving,
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
                  textCapitalization:
                  TextCapitalization
                      .sentences,
                  maxLines: 4,
                  decoration:
                  _decoration(
                    'Add any important notes about this record',
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
                  height: 28,
                ),

                // =====================================
                // SAVE
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
                      AppColors
                          .primary,
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
                        : _saveRecord,
                    icon: isSaving
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child:
                      CircularProgressIndicator(
                        strokeWidth:
                        2,
                        color: Colors
                            .white,
                      ),
                    )
                        : const Icon(
                      Icons
                          .save_outlined,
                    ),
                    label: Text(
                      isSaving
                          ? 'Uploading & Saving...'
                          : 'Save Record',
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

  // =====================================================
  // DYNAMIC TEXT
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

  String _facilityLabel() {
    if (selectedRecordType ==
        'Lab Report') {
      return 'Laboratory';
    }

    return 'Hospital / Clinic / Facility';
  }

  String _facilityHint() {
    if (selectedRecordType ==
        'Lab Report') {
      return 'e.g. IDC Laboratory';
    }

    return 'e.g. City Medical Center';
  }
}