import 'package:flutter/material.dart';

import 'package:sehatfile/core/theme/app_colors.dart';
import 'package:sehatfile/core/theme/app_text_styles.dart';
import 'package:sehatfile/services/firestore_service.dart';

import 'qr_document_selection_screen.dart';

class QrShareSettingsScreen extends StatefulWidget {
  final String profileName;
  final String? profileId;
  final Map<String, bool> initialSettings;

  const QrShareSettingsScreen({
    super.key,
    required this.profileName,
    required this.initialSettings,
    this.profileId,
  });

  @override
  State<QrShareSettingsScreen> createState() =>
      _QrShareSettingsScreenState();
}

class _QrShareSettingsScreenState
    extends State<QrShareSettingsScreen> {
  final FirestoreService _firestoreService =
  FirestoreService();

  late Map<String, bool> _settings;

  List<String> _selectedDocumentIds = [];

  bool _loadingDocuments = true;
  bool _saving = false;

  // =====================================================
  // INITIALIZE
  // =====================================================

  @override
  void initState() {
    super.initState();

    _settings = {
      'fullName':
      widget.initialSettings['fullName'] ?? true,

      'age':
      widget.initialSettings['age'] ?? true,

      'bloodGroup':
      widget.initialSettings['bloodGroup'] ?? true,

      'allergies':
      widget.initialSettings['allergies'] ?? false,

      'medicalConditions':
      widget.initialSettings['medicalConditions'] ?? false,

      'currentMedicines':
      widget.initialSettings['currentMedicines'] ?? false,

      'emergencyContact':
      widget.initialSettings['emergencyContact'] ?? false,

      'medicalDocuments':
      widget.initialSettings['medicalDocuments'] ?? false,
    };

    _loadSelectedDocuments();
  }

  // =====================================================
  // LOAD PREVIOUSLY SELECTED DOCUMENTS
  // =====================================================

  Future<void> _loadSelectedDocuments() async {
    try {
      final List<String> selectedIds =
      await _firestoreService
          .getQrSelectedDocumentIds(
        profileId: widget.profileId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _selectedDocumentIds = selectedIds;
        _loadingDocuments = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loadingDocuments = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to load selected documents: $e',
          ),
        ),
      );
    }
  }

  // =====================================================
  // UPDATE SETTING
  // =====================================================

  void _updateSetting(
      String key,
      bool value,
      ) {
    setState(() {
      _settings[key] = value;
    });
  }

  // =====================================================
  // CHOOSE MEDICAL DOCUMENTS
  // =====================================================

  Future<void> _chooseDocuments() async {
    final List<String>? selectedIds =
    await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            QrDocumentSelectionScreen(
              profileName: widget.profileName,
              profileId: widget.profileId,
              initiallySelectedRecordIds:
              _selectedDocumentIds,
            ),
      ),
    );

    if (!mounted) {
      return;
    }

    if (selectedIds == null) {
      return;
    }

    setState(() {
      _selectedDocumentIds = selectedIds;
    });
  }

  // =====================================================
  // SAVE SETTINGS + DOCUMENT IDS
  // =====================================================

  Future<void> _saveSettings() async {
    if (_saving) {
      return;
    }

    if (_settings['medicalDocuments'] == true &&
        _selectedDocumentIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please choose at least one medical document to share.',
          ),
        ),
      );

      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      await _firestoreService.saveQrSettings(
        profileId: widget.profileId,
        settings: _settings,

        // IMPORTANT:
        // These record IDs are now stored in Firestore.
        selectedDocumentIds:
        _settings['medicalDocuments'] == true
            ? _selectedDocumentIds
            : <String>[],
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _saving = false;
      });

      // Return settings to qr_code_screen.dart.
      //
      // That screen will call getOrCreateHealthShare(),
      // which will now read selectedRecordIds and create
      // sharedDocuments inside healthShares.
      Navigator.pop(
        context,
        _settings,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _saving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to save sharing settings: $e',
          ),
        ),
      );
    }
  }

  // =====================================================
  // NORMAL SETTING TILE
  // =====================================================

  Widget _settingTile({
    required String keyName,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final bool enabled =
        _settings[keyName] ?? false;

    return Container(
      margin: const EdgeInsets.only(
        bottom: 11,
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
      child: SwitchListTile(
        value: enabled,

        activeThumbColor:
        AppColors.primary,

        contentPadding:
        const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 5,
        ),

        secondary: Container(
          width: 44,
          height: 44,
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
            color:
            AppColors.primary,
          ),
        ),

        title: Text(
          title,
          style: const TextStyle(
            fontWeight:
            FontWeight.w700,
            fontSize: 14,
          ),
        ),

        subtitle: Padding(
          padding:
          const EdgeInsets.only(
            top: 4,
          ),
          child: Text(
            subtitle,
            style:
            AppTextStyles
                .bodySmall
                .copyWith(
              color:
              AppColors.textSecondary,
              height: 1.35,
            ),
          ),
        ),

        onChanged: (value) {
          _updateSetting(
            keyName,
            value,
          );
        },
      ),
    );
  }

  // =====================================================
  // MEDICAL DOCUMENTS TILE
  // =====================================================

  Widget _medicalDocumentsTile() {
    final bool enabled =
        _settings['medicalDocuments'] ??
            false;

    return Container(
      margin: const EdgeInsets.only(
        bottom: 11,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(
          17,
        ),
        border: Border.all(
          color: enabled
              ? AppColors.primary
              : AppColors.border,
          width:
          enabled ? 1.4 : 1,
        ),
      ),
      child: Column(
        children: [
          SwitchListTile(
            value: enabled,

            activeThumbColor:
            AppColors.primary,

            contentPadding:
            const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 5,
            ),

            secondary: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color:
                Colors.teal.shade50,
                borderRadius:
                BorderRadius.circular(
                  12,
                ),
              ),
              child: Icon(
                Icons
                    .folder_copy_outlined,
                color:
                AppColors.primary,
              ),
            ),

            title: const Text(
              'Medical Documents',
              style: TextStyle(
                fontWeight:
                FontWeight.w700,
                fontSize: 14,
              ),
            ),

            subtitle: Padding(
              padding:
              const EdgeInsets.only(
                top: 4,
              ),
              child: Text(
                'Share selected prescriptions, lab reports, medical reports or vaccination documents.',
                style:
                AppTextStyles
                    .bodySmall
                    .copyWith(
                  color:
                  AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
            ),

            onChanged: (value) {
              _updateSetting(
                'medicalDocuments',
                value,
              );
            },
          ),

          // =============================================
          // DOCUMENT CHOOSER
          // =============================================

          if (enabled)
            Padding(
              padding:
              const EdgeInsets.fromLTRB(
                14,
                0,
                14,
                14,
              ),
              child: Material(
                color:
                Colors.teal.shade50,
                borderRadius:
                BorderRadius.circular(
                  13,
                ),
                child: InkWell(
                  borderRadius:
                  BorderRadius.circular(
                    13,
                  ),
                  onTap:
                  _loadingDocuments
                      ? null
                      : _chooseDocuments,
                  child: Padding(
                    padding:
                    const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 13,
                    ),
                    child: Row(
                      children: [
                        if (_loadingDocuments)
                          SizedBox(
                            width: 22,
                            height: 22,
                            child:
                            CircularProgressIndicator(
                              strokeWidth: 2,
                              color:
                              AppColors.primary,
                            ),
                          )
                        else
                          Icon(
                            Icons
                                .description_outlined,
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
                              Text(
                                _loadingDocuments
                                    ? 'Loading Documents...'
                                    : _selectedDocumentIds
                                    .isEmpty
                                    ? 'Choose Documents'
                                    : '${_selectedDocumentIds.length} document${_selectedDocumentIds.length == 1 ? '' : 's'} selected',
                                style:
                                TextStyle(
                                  color:
                                  AppColors.primary,
                                  fontWeight:
                                  FontWeight.w700,
                                ),
                              ),

                              const SizedBox(
                                height: 3,
                              ),

                              if (!_loadingDocuments)
                                Text(
                                  _selectedDocumentIds
                                      .isEmpty
                                      ? 'Select the records this QR may share.'
                                      : 'Tap to change selected documents.',
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

                        if (!_loadingDocuments)
                          Icon(
                            Icons
                                .chevron_right_rounded,
                            color:
                            AppColors.primary,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
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
        elevation: 0,
        title: const Text(
          'Shared Information',
        ),
      ),

      body: SafeArea(
        child: ListView(
          padding:
          const EdgeInsets.fromLTRB(
            18,
            14,
            18,
            30,
          ),
          children: [
            // ===========================================
            // TITLE
            // ===========================================

            Text(
              'What do you want to share?',
              style:
              AppTextStyles
                  .titleLarge
                  .copyWith(
                color:
                AppColors.primary,
                fontSize: 23,
                fontWeight:
                FontWeight.w700,
              ),
            ),

            const SizedBox(
              height: 6,
            ),

            Text(
              'Choose what information will be available when someone scans ${widget.profileName}\'s Health QR.',
              style:
              AppTextStyles
                  .bodySmall
                  .copyWith(
                color:
                AppColors.textSecondary,
                height: 1.4,
              ),
            ),

            const SizedBox(
              height: 22,
            ),

            // ===========================================
            // BASIC INFORMATION
            // ===========================================

            Text(
              'Basic Information',
              style: TextStyle(
                color:
                AppColors.primary,
                fontWeight:
                FontWeight.w800,
                fontSize: 14,
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            _settingTile(
              keyName:
              'fullName',
              icon:
              Icons.person_outline_rounded,
              title:
              'Full Name',
              subtitle:
              'Share the patient\'s name.',
            ),

            _settingTile(
              keyName:
              'age',
              icon:
              Icons.cake_outlined,
              title:
              'Age',
              subtitle:
              'Share the patient\'s age.',
            ),

            _settingTile(
              keyName:
              'bloodGroup',
              icon:
              Icons.bloodtype_outlined,
              title:
              'Blood Group',
              subtitle:
              'Useful during emergency care.',
            ),

            const SizedBox(
              height: 10,
            ),

            // ===========================================
            // HEALTH INFORMATION
            // ===========================================

            Text(
              'Health Information',
              style: TextStyle(
                color:
                AppColors.primary,
                fontWeight:
                FontWeight.w800,
                fontSize: 14,
              ),
            ),

            const SizedBox(
              height: 10,
            ),


            _settingTile(
              keyName:
              'currentMedicines',
              icon:
              Icons.medication_outlined,
              title:
              'Current Medicines',
              subtitle:
              'Share medicines currently being taken.',
            ),



            // ===========================================
            // DOCUMENTS
            // ===========================================

            Text(
              'Documents',
              style: TextStyle(
                color:
                AppColors.primary,
                fontWeight:
                FontWeight.w800,
                fontSize: 14,
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            _medicalDocumentsTile(),

            const SizedBox(
              height: 12,
            ),

            // ===========================================
            // PRIVACY
            // ===========================================

            Container(
              padding:
              const EdgeInsets.all(
                15,
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
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons
                        .lock_outline_rounded,
                    color:
                    AppColors.primary,
                  ),

                  const SizedBox(
                    width: 10,
                  ),

                  Expanded(
                    child: Text(
                      'Only the information and documents you choose will be shared through this Health QR.',
                      style:
                      AppTextStyles
                          .bodySmall
                          .copyWith(
                        color: AppColors
                            .textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 24,
            ),

            // ===========================================
            // SAVE
            // ===========================================

            SizedBox(
              height: 54,
              child: FilledButton.icon(
                onPressed:
                _saving
                    ? null
                    : _saveSettings,

                style:
                FilledButton
                    .styleFrom(
                  backgroundColor:
                  AppColors.primary,

                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(
                      15,
                    ),
                  ),
                ),

                icon:
                _saving
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child:
                  CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
                    : const Icon(
                  Icons.check_rounded,
                ),

                label: Text(
                  _saving
                      ? 'Saving...'
                      : 'Save Sharing Settings',
                  style:
                  const TextStyle(
                    fontWeight:
                    FontWeight.w700,
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