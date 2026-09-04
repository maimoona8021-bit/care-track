import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'edit_medicine_screen.dart';
import 'package:sehatfile/core/theme/app_colors.dart';
import 'package:sehatfile/core/theme/app_text_styles.dart';
import 'package:sehatfile/services/firestore_service.dart';

class MedicineDetailsScreen extends StatefulWidget {
  final String medicineId;
  final String? profileId;
  final String profileName;
  final Map<String, dynamic> medicineData;

  const MedicineDetailsScreen({
    super.key,
    required this.medicineId,
    required this.profileName,
    required this.medicineData,
    this.profileId,
  });

  @override
  State<MedicineDetailsScreen> createState() =>
      _MedicineDetailsScreenState();
}

class _MedicineDetailsScreenState
    extends State<MedicineDetailsScreen> {
  final FirestoreService _firestoreService =
  FirestoreService();

  bool isDeleting = false;

  // =====================================================
  // GET VALUE SAFELY
  // =====================================================

  String _getValue(
      String key, {
        String fallback = 'Not set',
      }) {
    final dynamic value =
    widget.medicineData[key];

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

  String _formatDate(dynamic value) {
    if (value == null) {
      return 'Not set';
    }

    DateTime? date;

    if (value is Timestamp) {
      date = value.toDate();
    } else if (value is DateTime) {
      date = value;
    }

    if (date == null) {
      return 'Not set';
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
  // FORMAT REMINDER TIMES
  // 08:00 -> 8:00 AM
  // =====================================================

  String _formatSingleTime(
      String value,
      ) {
    try {
      final List<String> parts =
      value.split(':');

      if (parts.length != 2) {
        return value;
      }

      final int hour =
      int.parse(parts[0]);

      final int minute =
      int.parse(parts[1]);

      final TimeOfDay time =
      TimeOfDay(
        hour: hour,
        minute: minute,
      );

      return time.format(context);
    } catch (_) {
      return value;
    }
  }

  String _formatReminderTimes() {
    final dynamic rawTimes =
    widget.medicineData[
    'reminderTimes'];

    if (rawTimes is! List ||
        rawTimes.isEmpty) {
      return 'Not set';
    }

    return rawTimes
        .map(
          (time) =>
          _formatSingleTime(
            time.toString(),
          ),
    )
        .join('  •  ');
  }

  // =====================================================
  // DETAIL ROW
  // =====================================================

  Widget _detailRow({
    required String label,
    required String value,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        Padding(
          padding:
          const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),
          child: Row(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 105,
                child: Text(
                  label,
                  style:
                  AppTextStyles.bodySmall
                      .copyWith(
                    color: AppColors
                        .textSecondary,
                    fontWeight:
                    FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              Expanded(
                child: Text(
                  value,
                  textAlign:
                  TextAlign.right,
                  style:
                  AppTextStyles.bodyMedium
                      .copyWith(
                    fontWeight:
                    FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),

        if (showDivider)
          Padding(
            padding:
            const EdgeInsets.symmetric(
              horizontal: 16,
            ),
            child: Divider(
              height: 1,
              color: AppColors.divider,
            ),
          ),
      ],
    );
  }

  // =====================================================
  // DELETE MEDICINE
  // =====================================================

  Future<void> _deleteMedicine() async {
    final String medicineName =
    _getValue(
      'medicineName',
      fallback: 'this medicine',
    );

    final bool? shouldDelete =
    await showDialog<bool>(
      context: context,
      builder: (
          BuildContext dialogContext,
          ) {
        return AlertDialog(
          shape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(
              20,
            ),
          ),
          title: const Row(
            children: [
              Icon(
                Icons
                    .warning_amber_rounded,
                color: Colors.red,
              ),
              SizedBox(
                width: 10,
              ),
              Text(
                'Delete Medicine?',
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to permanently delete $medicineName?\n\n'
                'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child:
              const Text(
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
              child:
              const Text(
                'Delete',
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    setState(() {
      isDeleting = true;
    });

    try {
      await _firestoreService
          .deleteMedicine(
        medicineId:
        widget.medicineId,
        profileId:
        widget.profileId,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Medicine deleted successfully.',
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
        isDeleting = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Unable to delete medicine: $e',
          ),
        ),
      );
    }
  }

  // =====================================================
  // EDIT MEDICINE
  // =====================================================

  Future<void> _openEditMedicine() async {
    final bool? updated =
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            EditMedicineScreen(
              medicineId:
              widget.medicineId,
              profileId:
              widget.profileId,
              profileName:
              widget.profileName,
              medicineData:
              widget.medicineData,
            ),
      ),
    );

    if (updated == true &&
        mounted) {
      // Return to medicines list.
      // The Firestore StreamBuilder there
      // automatically displays the updated data.
      Navigator.pop(
        context,
        true,
      );
    }
  }

  // =====================================================
  // SCREEN
  // =====================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    final String medicineName =
    _getValue(
      'medicineName',
      fallback: 'Medicine',
    );

    final String dosage =
    _getValue(
      'dosage',
      fallback: '',
    );

    final String quantity =
    _getValue(
      'quantityPerDose',
    );

    final String frequency =
    _getValue(
      'frequency',
    );

    final String prescribedBy =
    _getValue(
      'prescribedBy',
    );

    final String instructions =
    _getValue(
      'instructions',
      fallback:
      'No instructions added.',
    );

    final bool isCurrent =
        widget.medicineData[
        'isCurrent'] ==
            true;

    final String medicineType =
    _getValue(
      'medicineType',
      fallback: 'Medicine',
    );

    return Scaffold(
      backgroundColor:
      AppColors.background,

      body: SafeArea(
        child:
        SingleChildScrollView(
          padding:
          const EdgeInsets.fromLTRB(
            18,
            14,
            18,
            28,
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              // =====================================
              // BACK BUTTON
              // =====================================

              Material(
                color:
                Colors.teal.shade50,
                borderRadius:
                BorderRadius.circular(
                  12,
                ),
                child: IconButton(
                  onPressed: isDeleting
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

              const SizedBox(
                height: 20,
              ),

              // =====================================
              // TITLE
              // =====================================

              Text(
                'Medicine Details',
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
                height: 25,
              ),

              // =====================================
              // MEDICINE HEADER
              // =====================================

              Center(
                child: Column(
                  children: [
                    Container(
                      width: 74,
                      height: 74,
                      decoration:
                      BoxDecoration(
                        color: Colors
                            .teal.shade50,
                        borderRadius:
                        BorderRadius.circular(
                          22,
                        ),
                      ),
                      child: Icon(
                        Icons
                            .medication_rounded,
                        size: 35,
                        color:
                        AppColors.primary,
                      ),
                    ),

                    const SizedBox(
                      height: 14,
                    ),

                    Text(
                      medicineName,
                      textAlign:
                      TextAlign.center,
                      style: AppTextStyles
                          .titleLarge
                          .copyWith(
                        fontSize: 21,
                        fontWeight:
                        FontWeight.w700,
                      ),
                    ),

                    if (dosage
                        .isNotEmpty) ...[
                      const SizedBox(
                        height: 4,
                      ),

                      Text(
                        dosage,
                        style: AppTextStyles
                            .bodyMedium
                            .copyWith(
                          color: AppColors
                              .textSecondary,
                        ),
                      ),
                    ],

                    const SizedBox(
                      height: 10,
                    ),

                    Container(
                      padding:
                      const EdgeInsets
                          .symmetric(
                        horizontal: 13,
                        vertical: 6,
                      ),
                      decoration:
                      BoxDecoration(
                        color: isCurrent
                            ? Colors
                            .teal.shade100
                            : Colors
                            .grey.shade200,
                        borderRadius:
                        BorderRadius.circular(
                          18,
                        ),
                      ),
                      child: Text(
                        isCurrent
                            ? 'Status: Active'
                            : 'Status: Previous',
                        style:
                        TextStyle(
                          color: isCurrent
                              ? AppColors
                              .primary
                              : AppColors
                              .textSecondary,
                          fontWeight:
                          FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 26,
              ),

              // =====================================
              // DETAILS CARD
              // =====================================

              Container(
                width:
                double.infinity,
                decoration:
                BoxDecoration(
                  color:
                  Colors.white,
                  borderRadius:
                  BorderRadius.circular(
                    20,
                  ),
                  border: Border.all(
                    color:
                    AppColors.border,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withValues(
                        alpha: 0.04,
                      ),
                      blurRadius: 10,
                      offset:
                      const Offset(
                        0,
                        4,
                      ),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _detailRow(
                      label:
                      'Type',
                      value:
                      medicineType,
                    ),

                    _detailRow(
                      label:
                      'Dosage',
                      value:
                      quantity,
                    ),

                    _detailRow(
                      label:
                      'Frequency',
                      value:
                      frequency,
                    ),

                    _detailRow(
                      label:
                      'Time',
                      value:
                      _formatReminderTimes(),
                    ),

                    _detailRow(
                      label:
                      'Start Date',
                      value:
                      _formatDate(
                        widget
                            .medicineData[
                        'startDate'],
                      ),
                    ),

                    _detailRow(
                      label:
                      'End Date',
                      value:
                      _formatDate(
                        widget
                            .medicineData[
                        'endDate'],
                      ),
                    ),

                    _detailRow(
                      label:
                      'Prescribed By',
                      value:
                      prescribedBy,
                      showDivider:
                      false,
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 18,
              ),

              // =====================================
              // INSTRUCTIONS
              // =====================================

              Container(
                width:
                double.infinity,
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
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
                  children: [
                    Text(
                      'Instructions',
                      style:
                      TextStyle(
                        color: AppColors
                            .primary,
                        fontWeight:
                        FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(
                      height: 5,
                    ),

                    Text(
                      instructions,
                      style:
                      AppTextStyles
                          .bodySmall
                          .copyWith(
                        height: 1.5,
                        color: AppColors
                            .textPrimary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 24,
              ),

              // =====================================
              // EDIT BUTTON
              // =====================================

              SizedBox(
                width:
                double.infinity,
                height: 54,
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
                      BorderRadius.circular(
                        16,
                      ),
                    ),
                  ),
                  onPressed:
                  isDeleting
                      ? null
                      : _openEditMedicine,
                  icon:
                  const Icon(
                    Icons.edit_outlined,
                  ),
                  label:
                  const Text(
                    'Edit Medicine',
                    style:
                    TextStyle(
                      fontWeight:
                      FontWeight.w700,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height: 12,
              ),

              // =====================================
              // DELETE BUTTON
              // =====================================

              SizedBox(
                width:
                double.infinity,
                height: 52,
                child:
                OutlinedButton.icon(
                  style:
                  OutlinedButton
                      .styleFrom(
                    backgroundColor:
                    Colors.red.shade50,
                    foregroundColor:
                    Colors.red,
                    side:
                    BorderSide.none,
                    shape:
                    RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(
                        16,
                      ),
                    ),
                  ),
                  onPressed:
                  isDeleting
                      ? null
                      : _deleteMedicine,
                  icon: isDeleting
                      ? const SizedBox(
                    width: 19,
                    height: 19,
                    child:
                    CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                      : const Icon(
                    Icons
                        .delete_outline_rounded,
                  ),
                  label: Text(
                    isDeleting
                        ? 'Deleting...'
                        : 'Delete Medicine',
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
      ),
    );
  }
}