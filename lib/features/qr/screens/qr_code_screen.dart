import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import 'package:sehatfile/core/routes/app_routes.dart';
import 'package:sehatfile/core/theme/app_colors.dart';
import 'package:sehatfile/core/theme/app_text_styles.dart';

import 'package:sehatfile/services/firestore_service.dart';

import 'qr_scanner_screen.dart';
import 'qr_share_settings_screen.dart';
import 'shared_health_info_screen.dart';

class QrCodeScreen extends StatefulWidget {
  final String profileName;
  final String? profileId;

  const QrCodeScreen({
    super.key,
    required this.profileName,
    this.profileId,
  });

  @override
  State<QrCodeScreen> createState() =>
      _QrCodeScreenState();
}

class _QrCodeScreenState
    extends State<QrCodeScreen> {
  final FirestoreService _firestoreService =
  FirestoreService();

  bool _loading = true;
  bool _loadingScannedData = false;

  bool _sharingActive = true;
  bool _changingSharingStatus = false;

  String? _shareId;

  // =====================================================
  // SHARED SETTINGS
  //
  // ONLY THESE 5 ARE NOW USED
  // =====================================================

  Map<String, bool> _sharedSettings = {
    'fullName': true,
    'age': true,
    'bloodGroup': true,
    'currentMedicines': false,
    'medicalDocuments': false,
  };

  // =====================================================
  // CLEAN OLD SETTINGS
  // =====================================================

  Map<String, bool> _sanitizeSettings(
      Map<String, bool> settings,
      ) {
    return {
      'fullName':
      settings['fullName'] ?? true,

      'age':
      settings['age'] ?? true,

      'bloodGroup':
      settings['bloodGroup'] ?? true,

      'currentMedicines':
      settings['currentMedicines'] ?? false,

      'medicalDocuments':
      settings['medicalDocuments'] ?? false,
    };
  }

  // =====================================================
  // QR DATA
  // =====================================================

  String get _qrData {
    final String shareId =
        _shareId?.trim() ?? '';

    if (shareId.isEmpty) {
      return '';
    }

    return 'caretrack://health-share/$shareId';
  }

  // =====================================================
  // INITIALIZE
  // =====================================================

  @override
  void initState() {
    super.initState();

    _initializeQr();
  }

  // =====================================================
  // INITIALIZE QR
  // =====================================================

  Future<void> _initializeQr() async {
    try {
      final Map<String, bool> rawSettings =
      await _firestoreService
          .getQrSettings(
        profileId: widget.profileId,
      );

      final Map<String, bool> settings =
      _sanitizeSettings(
        rawSettings,
      );

      final String shareId =
      await _firestoreService
          .getOrCreateHealthShare(
        profileId: widget.profileId,
        profileName: widget.profileName,
        settings: settings,
      );

      final bool sharingActive =
      await _firestoreService
          .getHealthShareActive(
        profileId: widget.profileId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _sharedSettings = settings;
        _shareId = shareId;
        _sharingActive = sharingActive;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Unable to create Health QR: $e',
          ),
        ),
      );
    }
  }

  // =====================================================
  // MANAGE SHARED INFORMATION
  // =====================================================

  Future<void>
  _manageSharedInformation() async {
    final Map<String, bool>? result =
    await Navigator.push<
        Map<String, bool>>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            QrShareSettingsScreen(
              profileName:
              widget.profileName,
              profileId:
              widget.profileId,
              initialSettings:
              _sharedSettings,
            ),
      ),
    );

    if (!mounted) {
      return;
    }

    if (result == null) {
      return;
    }

    final Map<String, bool>
    updatedSettings =
    _sanitizeSettings(
      result,
    );

    try {
      await _firestoreService
          .saveQrSettings(
        profileId:
        widget.profileId,
        settings:
        updatedSettings,
      );

      final String shareId =
      await _firestoreService
          .getOrCreateHealthShare(
        profileId:
        widget.profileId,
        profileName:
        widget.profileName,
        settings:
        updatedSettings,
      );

      final bool sharingActive =
      await _firestoreService
          .getHealthShareActive(
        profileId:
        widget.profileId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _sharedSettings =
            updatedSettings;

        _shareId =
            shareId;

        _sharingActive =
            sharingActive;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'QR sharing information updated.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Unable to update QR: $e',
          ),
        ),
      );
    }
  }

  // =====================================================
  // STOP / RESUME SHARING
  // =====================================================

  Future<void>
  _toggleSharingStatus() async {
    if (_changingSharingStatus) {
      return;
    }

    final bool newStatus =
    !_sharingActive;

    // ===============================================
    // STOP CONFIRMATION
    // ===============================================

    if (!newStatus) {
      final bool? confirmed =
      await showDialog<bool>(
        context: context,
        builder: (
            dialogContext,
            ) {
          return AlertDialog(
            title: const Text(
              'Stop QR Sharing?',
            ),
            content: const Text(
              'People will no longer be able to access the health information shared through this QR. You can resume sharing at any time.',
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
                style:
                FilledButton.styleFrom(
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
                  'Stop Sharing',
                ),
              ),
            ],
          );
        },
      );

      if (!mounted) {
        return;
      }

      if (confirmed != true) {
        return;
      }
    }

    setState(() {
      _changingSharingStatus = true;
    });

    try {
      await _firestoreService
          .setHealthShareActive(
        profileId:
        widget.profileId,
        active:
        newStatus,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _sharingActive =
            newStatus;

        _changingSharingStatus =
        false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            newStatus
                ? 'Health QR sharing resumed.'
                : 'Health QR sharing stopped.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _changingSharingStatus =
        false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Unable to change sharing status: $e',
          ),
        ),
      );
    }
  }

  // =====================================================
  // GENERATE QR IMAGE
  // =====================================================

  Future<Uint8List>
  _generateQrPng() async {
    if (_qrData.isEmpty) {
      throw Exception(
        'QR data is not available.',
      );
    }

    final QrPainter painter =
    QrPainter(
      data: _qrData,
      version:
      QrVersions.auto,
      gapless: true,
    );

    final byteData =
    await painter.toImageData(
      1024,
    );

    if (byteData == null) {
      throw Exception(
        'Unable to generate QR image.',
      );
    }

    return byteData.buffer
        .asUint8List();
  }

  // =====================================================
  // QR FILE NAME
  // =====================================================

  String _qrFileName() {
    final String safeName =
    widget.profileName
        .trim()
        .replaceAll(
      ' ',
      '_',
    )
        .replaceAll(
      RegExp(
        r'[^a-zA-Z0-9_-]',
      ),
      '',
    );

    return 'care_track_${safeName.isEmpty ? 'health' : safeName}_qr.png';
  }

  // =====================================================
  // SHARE QR
  // =====================================================

  Future<void> _shareQr() async {
    if (!_sharingActive) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'QR sharing is paused. Resume sharing first.',
          ),
        ),
      );

      return;
    }

    if (_qrData.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'QR is not ready yet.',
          ),
        ),
      );

      return;
    }

    try {
      final Uint8List pngBytes =
      await _generateQrPng();

      await SharePlus.instance.share(
        ShareParams(
          title:
          'Care Track Health QR',
          text:
          '${widget.profileName} - Care Track Health QR',
          files: [
            XFile.fromData(
              pngBytes,
              mimeType:
              'image/png',
            ),
          ],
          fileNameOverrides: [
            _qrFileName(),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Unable to share QR: $e',
          ),
        ),
      );
    }
  }

  // =====================================================
  // SAVE QR
  // =====================================================

  Future<void> _saveQr() async {
    if (_qrData.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'QR is not ready yet.',
          ),
        ),
      );

      return;
    }

    try {
      bool hasAccess =
      await Gal.hasAccess();

      if (!hasAccess) {
        hasAccess =
        await Gal.requestAccess();
      }

      if (!hasAccess) {
        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'Gallery permission was not granted.',
            ),
          ),
        );

        return;
      }

      final Uint8List pngBytes =
      await _generateQrPng();

      await Gal.putImageBytes(
        pngBytes,
        name:
        _qrFileName()
            .replaceAll(
          '.png',
          '',
        ),
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Health QR saved to gallery.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Unable to save QR: $e',
          ),
        ),
      );
    }
  }

  // =====================================================
  // SCAN QR
  // =====================================================

  Future<void> _scanQr() async {
    if (_loadingScannedData) {
      return;
    }

    final String? shareId =
    await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) =>
        const QrScannerScreen(),
      ),
    );

    if (!mounted) {
      return;
    }

    if (shareId == null ||
        shareId.trim().isEmpty) {
      return;
    }

    setState(() {
      _loadingScannedData =
      true;
    });

    try {
      final Map<String, dynamic>?
      healthShare =
      await _firestoreService
          .getHealthShare(
        shareId:
        shareId.trim(),
      );

      if (!mounted) {
        return;
      }

      if (healthShare == null) {
        setState(() {
          _loadingScannedData =
          false;
        });

        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'This Health QR is invalid or sharing has been stopped by the owner.',
            ),
          ),
        );

        return;
      }

      // ===============================================
      // PROFILE NAME
      // ===============================================

      final String profileName =
          healthShare['profileName']
              ?.toString()
              .trim() ??
              '';

      final String safeProfileName =
      profileName.isEmpty
          ? 'Care Track Patient'
          : profileName;

      // ===============================================
      // SHARED DATA
      // ===============================================

      final dynamic rawSharedData =
      healthShare['sharedData'];

      final Map<String, dynamic>
      sharedData;

      if (rawSharedData is Map) {
        sharedData =
        Map<String, dynamic>.from(
          rawSharedData,
        );
      } else {
        sharedData =
        <String, dynamic>{};
      }

      // ===============================================
      // SHARED DOCUMENTS
      // ===============================================

      final dynamic
      rawSharedDocuments =
      healthShare[
      'sharedDocuments'];

      final List<
          Map<String, dynamic>>
      sharedDocuments = [];

      if (rawSharedDocuments
      is Iterable) {
        for (final dynamic item
        in rawSharedDocuments) {
          if (item is Map) {
            sharedDocuments.add(
              Map<String, dynamic>.from(
                item,
              ),
            );
          }
        }
      }

      if (sharedData.isEmpty &&
          sharedDocuments.isEmpty) {
        setState(() {
          _loadingScannedData =
          false;
        });

        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'No information is currently shared through this QR.',
            ),
          ),
        );

        return;
      }

      setState(() {
        _loadingScannedData =
        false;
      });

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              SharedHealthInfoScreen(
                shareId:
                shareId.trim(),
                profileName:
                safeProfileName,
                sharedData:
                sharedData,
                sharedDocuments:
                sharedDocuments,
              ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loadingScannedData =
        false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Unable to load Health QR: $e',
          ),
        ),
      );
    }
  }

  // =====================================================
  // SETTING TITLE
  // =====================================================

  String _settingTitle(
      String key,
      ) {
    switch (key) {
      case 'fullName':
        return 'Full Name';

      case 'age':
        return 'Age';

      case 'bloodGroup':
        return 'Blood Group';

      case 'currentMedicines':
        return 'Current Medicines';

      case 'medicalDocuments':
        return 'Medical Documents';

      default:
        return key;
    }
  }

  // =====================================================
  // SELECTED ITEMS
  // =====================================================

  List<String> _selectedItems() {
    return _sharedSettings.entries
        .where(
          (entry) =>
      entry.value,
    )
        .map(
          (entry) =>
          _settingTitle(
            entry.key,
          ),
    )
        .toList();
  }

  // =====================================================
  // SHARED ITEM
  // =====================================================

  Widget _sharedItem(
      String title,
      ) {
    return Padding(
      padding:
      const EdgeInsets.only(
        bottom: 10,
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration:
            BoxDecoration(
              color:
              Colors.teal.shade50,
              shape:
              BoxShape.circle,
            ),
            child: Icon(
              Icons.check_rounded,
              size: 15,
              color:
              AppColors.primary,
            ),
          ),

          const SizedBox(
            width: 10,
          ),

          Expanded(
            child: Text(
              title,
              style:
              const TextStyle(
                fontSize: 13,
                fontWeight:
                FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // SHARING STATUS CARD
  // =====================================================

  Widget _sharingStatusCard() {
    final Color statusColor =
    _sharingActive
        ? AppColors.primary
        : Colors.red;

    return Container(
      width:
      double.infinity,
      padding:
      const EdgeInsets.all(
        16,
      ),
      decoration:
      BoxDecoration(
        color:
        _sharingActive
            ? Colors.teal.shade50
            : Colors.red.shade50,
        borderRadius:
        BorderRadius.circular(
          18,
        ),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration:
                BoxDecoration(
                  color:
                  Colors.white,
                  borderRadius:
                  BorderRadius.circular(
                    12,
                  ),
                ),
                child: Icon(
                  _sharingActive
                      ? Icons
                      .visibility_outlined
                      : Icons
                      .visibility_off_outlined,
                  color:
                  statusColor,
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
                      _sharingActive
                          ? 'QR Sharing Active'
                          : 'QR Sharing Paused',
                      style:
                      TextStyle(
                        color:
                        statusColor,
                        fontSize:
                        15,
                        fontWeight:
                        FontWeight.w800,
                      ),
                    ),

                    const SizedBox(
                      height: 5,
                    ),

                    Text(
                      _sharingActive
                          ? 'People who scan this QR can view the information you selected.'
                          : 'People who scan this QR cannot access your shared health information.',
                      style:
                      AppTextStyles
                          .bodySmall
                          .copyWith(
                        color:
                        AppColors
                            .textSecondary,
                        height:
                        1.4,
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

          SizedBox(
            width:
            double.infinity,
            height:
            46,
            child:
            OutlinedButton.icon(
              onPressed:
              _changingSharingStatus
                  ? null
                  : _toggleSharingStatus,
              style:
              OutlinedButton
                  .styleFrom(
                foregroundColor:
                _sharingActive
                    ? Colors.red
                    : AppColors.primary,
                side:
                BorderSide(
                  color:
                  _sharingActive
                      ? Colors.red
                      : AppColors.primary,
                ),
                shape:
                RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(
                    13,
                  ),
                ),
              ),
              icon:
              _changingSharingStatus
                  ? SizedBox(
                width: 18,
                height: 18,
                child:
                CircularProgressIndicator(
                  strokeWidth:
                  2,
                  color:
                  statusColor,
                ),
              )
                  : Icon(
                _sharingActive
                    ? Icons
                    .stop_circle_outlined
                    : Icons
                    .play_circle_outline,
              ),
              label: Text(
                _changingSharingStatus
                    ? 'Updating...'
                    : _sharingActive
                    ? 'Stop Sharing'
                    : 'Resume Sharing',
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
    );
  }

  // =====================================================
  // SCREEN
  // =====================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    if (_loading) {
      return Scaffold(
        backgroundColor:
        AppColors.background,
        body: Center(
          child:
          CircularProgressIndicator(
            color:
            AppColors.primary,
          ),
        ),
      );
    }

    final List<String>
    selectedItems =
    _selectedItems();

    return Scaffold(
      backgroundColor:
      AppColors.background,

      body: SafeArea(
        child: ListView(
          padding:
          const EdgeInsets.fromLTRB(
            18,
            14,
            18,
            28,
          ),
          children: [
            // ==========================================
            // BACK
            // ==========================================

            Align(
              alignment:
              Alignment.centerLeft,
              child: Material(
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
                    Icons.arrow_back_rounded,
                    color:
                    AppColors.primary,
                  ),
                ),
              ),
            ),

            const SizedBox(
              height: 18,
            ),

            // ==========================================
            // TITLE
            // ==========================================

            Text(
              'Health QR',
              style:
              AppTextStyles
                  .titleLarge
                  .copyWith(
                color:
                AppColors.primary,
                fontSize:
                25,
                fontWeight:
                FontWeight.w700,
              ),
            ),

            const SizedBox(
              height: 5,
            ),

            Text(
              'Share important health information securely.',
              style:
              AppTextStyles
                  .bodySmall
                  .copyWith(
                color:
                AppColors
                    .textSecondary,
              ),
            ),

            const SizedBox(
              height: 22,
            ),

            // ==========================================
            // PROFILE
            // ==========================================

            Container(
              padding:
              const EdgeInsets.all(
                14,
              ),
              decoration:
              BoxDecoration(
                color:
                Colors.white,
                borderRadius:
                BorderRadius.circular(
                  17,
                ),
                border:
                Border.all(
                  color:
                  AppColors.border,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration:
                    BoxDecoration(
                      color:
                      Colors.teal.shade50,
                      borderRadius:
                      BorderRadius.circular(
                        13,
                      ),
                    ),
                    child: Icon(
                      Icons.person_rounded,
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
                          widget.profileName,
                          maxLines: 1,
                          overflow:
                          TextOverflow
                              .ellipsis,
                          style:
                          const TextStyle(
                            fontSize: 15,
                            fontWeight:
                            FontWeight.w700,
                          ),
                        ),

                        const SizedBox(
                          height: 3,
                        ),

                        Text(
                          widget.profileId ==
                              null
                              ? 'Personal Health QR'
                              : 'Health Profile QR',
                          style:
                          AppTextStyles
                              .bodySmall
                              .copyWith(
                            color:
                            AppColors
                                .textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Icon(
                    Icons
                        .verified_user_outlined,
                    color:
                    AppColors.primary,
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            // ==========================================
            // QR CARD
            // ==========================================

            Container(
              padding:
              const EdgeInsets.all(
                22,
              ),
              decoration:
              BoxDecoration(
                color:
                Colors.white,
                borderRadius:
                BorderRadius.circular(
                  22,
                ),
                border:
                Border.all(
                  color:
                  AppColors.border,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    widget.profileName,
                    textAlign:
                    TextAlign.center,
                    style:
                    const TextStyle(
                      fontSize: 17,
                      fontWeight:
                      FontWeight.w800,
                    ),
                  ),

                  const SizedBox(
                    height: 18,
                  ),

                  if (_qrData.isNotEmpty)
                    Opacity(
                      opacity:
                      _sharingActive
                          ? 1
                          : 0.35,
                      child: Container(
                        padding:
                        const EdgeInsets.all(
                          12,
                        ),
                        decoration:
                        BoxDecoration(
                          color:
                          Colors.white,
                          borderRadius:
                          BorderRadius.circular(
                            18,
                          ),
                          border:
                          Border.all(
                            color:
                            AppColors.border,
                          ),
                        ),
                        child: QrImageView(
                          data:
                          _qrData,
                          version:
                          QrVersions.auto,
                          size:
                          205,
                        ),
                      ),
                    )
                  else
                    const SizedBox(
                      width: 205,
                      height: 205,
                      child: Center(
                        child: Text(
                          'Unable to generate QR.',
                        ),
                      ),
                    ),

                  const SizedBox(
                    height: 16,
                  ),

                  Text(
                    _sharingActive
                        ? 'Scan to view shared health information'
                        : 'QR access is currently paused',
                    textAlign:
                    TextAlign.center,
                    style:
                    AppTextStyles
                        .bodySmall
                        .copyWith(
                      color:
                      _sharingActive
                          ? AppColors
                          .textSecondary
                          : Colors.red,
                      fontWeight:
                      _sharingActive
                          ? FontWeight.normal
                          : FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 14,
            ),

            // ==========================================
            // SHARE / SAVE
            // ==========================================

            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child:
                    FilledButton.icon(
                      onPressed:
                      _sharingActive
                          ? _shareQr
                          : null,
                      style:
                      FilledButton
                          .styleFrom(
                        backgroundColor:
                        AppColors.primary,
                      ),
                      icon:
                      const Icon(
                        Icons.share_outlined,
                      ),
                      label:
                      const Text(
                        'Share QR',
                      ),
                    ),
                  ),
                ),

                const SizedBox(
                  width: 10,
                ),

                Expanded(
                  child: SizedBox(
                    height: 48,
                    child:
                    OutlinedButton.icon(
                      onPressed:
                      _saveQr,
                      icon:
                      const Icon(
                        Icons
                            .download_outlined,
                      ),
                      label:
                      const Text(
                        'Save QR',
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 18,
            ),

            // ==========================================
            // STOP / RESUME
            // ==========================================

            _sharingStatusCard(),

            const SizedBox(
              height: 24,
            ),

            // ==========================================
            // SHARED INFORMATION
            // ==========================================

            Container(
              padding:
              const EdgeInsets.all(
                17,
              ),
              decoration:
              BoxDecoration(
                color:
                Colors.white,
                borderRadius:
                BorderRadius.circular(
                  18,
                ),
                border:
                Border.all(
                  color:
                  AppColors.border,
                ),
              ),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Information Being Shared',
                          style:
                          TextStyle(
                            fontWeight:
                            FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ),

                      Text(
                        '${selectedItems.length} selected',
                        style:
                        AppTextStyles
                            .bodySmall
                            .copyWith(
                          color:
                          AppColors.primary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 15,
                  ),

                  if (selectedItems.isEmpty)
                    Text(
                      'No information selected.',
                      style:
                      AppTextStyles
                          .bodySmall
                          .copyWith(
                        color:
                        AppColors
                            .textSecondary,
                      ),
                    )
                  else
                    ...selectedItems.map(
                      _sharedItem,
                    ),

                  const Divider(),

                  GestureDetector(
                    behavior:
                    HitTestBehavior.opaque,
                    onTap:
                    _manageSharedInformation,
                    child: Padding(
                      padding:
                      const EdgeInsets.symmetric(
                        vertical: 13,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Manage Shared Information',
                              style:
                              TextStyle(
                                color:
                                AppColors.primary,
                                fontWeight:
                                FontWeight.w700,
                              ),
                            ),
                          ),

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
                ],
              ),
            ),

            const SizedBox(
              height: 18,
            ),

            // ==========================================
            // PRIVACY
            // ==========================================

            Container(
              padding:
              const EdgeInsets.all(
                16,
              ),
              decoration:
              BoxDecoration(
                color:
                Colors.teal.shade50,
                borderRadius:
                BorderRadius.circular(
                  18,
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
                      _sharingActive
                          ? 'Only the information and medical documents you choose are available through this QR.'
                          : 'QR sharing is paused. Other users cannot access the shared information until you resume sharing.',
                      style:
                      AppTextStyles
                          .bodySmall
                          .copyWith(
                        color:
                        AppColors
                            .textSecondary,
                        height:
                        1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 18,
            ),

            // ==========================================
            // SCANNER
            // ==========================================

            SizedBox(
              height: 51,
              child:
              OutlinedButton.icon(
                onPressed:
                _loadingScannedData
                    ? null
                    : _scanQr,
                icon:
                _loadingScannedData
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child:
                  CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
                    : const Icon(
                  Icons
                      .qr_code_scanner_rounded,
                ),
                label: Text(
                  _loadingScannedData
                      ? 'Loading Health Information...'
                      : 'Scan Someone\'s QR',
                ),
              ),
            ),
          ],
        ),
      ),

    );
  }
}