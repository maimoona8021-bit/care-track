import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:sehatfile/core/theme/app_colors.dart';
import 'package:sehatfile/core/theme/app_text_styles.dart';
import 'package:sehatfile/services/firestore_service.dart';
import 'package:sehatfile/services/notification_service.dart';

class EditMedicineScreen extends StatefulWidget {
  final String medicineId;
  final String? profileId;
  final String profileName;
  final Map<String, dynamic> medicineData;

  const EditMedicineScreen({
    super.key,
    required this.medicineId,
    required this.profileName,
    required this.medicineData,
    this.profileId,
  });

  @override
  State<EditMedicineScreen> createState() =>
      _EditMedicineScreenState();
}

class _EditMedicineScreenState
    extends State<EditMedicineScreen> {
  final GlobalKey<FormState> _formKey =
  GlobalKey<FormState>();

  final FirestoreService _firestoreService =
  FirestoreService();

  final NotificationService _notificationService =
      NotificationService.instance;

  final FlutterLocalNotificationsPlugin
  _localNotifications =
  FlutterLocalNotificationsPlugin();

  // =====================================================
  // CONTROLLERS
  // =====================================================

  final TextEditingController medicineNameController =
  TextEditingController();

  final TextEditingController dosageController =
  TextEditingController();

  final TextEditingController quantityController =
  TextEditingController();

  final TextEditingController frequencyController =
  TextEditingController();

  final TextEditingController doctorController =
  TextEditingController();

  final TextEditingController instructionsController =
  TextEditingController();

  final TextEditingController startDateController =
  TextEditingController();

  final TextEditingController endDateController =
  TextEditingController();

  // =====================================================
  // MEDICINE TYPES
  // =====================================================

  final List<String> medicineTypes = [
    'Tablet',
    'Capsule',
    'Syrup',
    'Injection',
    'Drops',
    'Other',
  ];

  String selectedMedicineType = 'Tablet';

  // =====================================================
  // REMINDER TIMES
  // =====================================================

  bool morningSelected = false;
  bool afternoonSelected = false;
  bool eveningSelected = false;
  bool nightSelected = false;

  TimeOfDay morningTime =
  const TimeOfDay(
    hour: 8,
    minute: 0,
  );

  TimeOfDay afternoonTime =
  const TimeOfDay(
    hour: 13,
    minute: 0,
  );

  TimeOfDay eveningTime =
  const TimeOfDay(
    hour: 20,
    minute: 0,
  );

  TimeOfDay nightTime =
  const TimeOfDay(
    hour: 22,
    minute: 0,
  );

  // =====================================================
  // DATES
  // =====================================================

  DateTime? selectedStartDate;
  DateTime? selectedEndDate;

  // =====================================================
  // STATUS
  // =====================================================

  bool currentlyTaking = true;
  bool reminderEnabled = true;
  bool isSaving = false;

  // Old scheduled notification IDs.
  final List<int> oldNotificationIds = [];

  // =====================================================
  // INITIALIZE EXISTING MEDICINE DATA
  // =====================================================

  @override
  void initState() {
    super.initState();

    final Map<String, dynamic> data =
        widget.medicineData;

    medicineNameController.text =
        data['medicineName']?.toString() ?? '';

    dosageController.text =
        data['dosage']?.toString() ?? '';

    quantityController.text =
        data['quantityPerDose']?.toString() ?? '';

    frequencyController.text =
        data['frequency']?.toString() ?? '';

    doctorController.text =
        data['prescribedBy']?.toString() ?? '';

    instructionsController.text =
        data['instructions']?.toString() ?? '';

    // ===============================================
    // MEDICINE TYPE
    // ===============================================

    final String medicineType =
        data['medicineType']?.toString() ??
            'Tablet';

    if (medicineTypes.contains(medicineType)) {
      selectedMedicineType = medicineType;
    } else {
      selectedMedicineType = 'Other';
    }

    // ===============================================
    // CURRENT STATUS
    // ===============================================

    currentlyTaking =
        data['isCurrent'] == true;

    reminderEnabled =
        data['reminderEnabled'] == true;

    // ===============================================
    // START DATE
    // ===============================================

    selectedStartDate =
        _dateFromValue(
          data['startDate'],
        );

    selectedStartDate ??= DateTime.now();

    startDateController.text =
        _formatDate(
          selectedStartDate!,
        );

    // ===============================================
    // END DATE
    // ===============================================

    selectedEndDate =
        _dateFromValue(
          data['endDate'],
        );

    if (selectedEndDate != null) {
      endDateController.text =
          _formatDate(
            selectedEndDate!,
          );
    }

    // ===============================================
    // OLD NOTIFICATION IDS
    // ===============================================

    final dynamic rawIds =
    data['notificationIds'];

    if (rawIds is List) {
      for (final dynamic id in rawIds) {
        if (id is int) {
          oldNotificationIds.add(id);
        } else {
          final int? parsed =
          int.tryParse(
            id.toString(),
          );

          if (parsed != null) {
            oldNotificationIds.add(parsed);
          }
        }
      }
    }

    // ===============================================
    // EXISTING REMINDER TIMES
    // ===============================================

    final dynamic rawTimes =
    data['reminderTimes'];

    if (rawTimes is List) {
      for (final dynamic rawTime
      in rawTimes) {
        _loadReminderTime(
          rawTime.toString(),
        );
      }
    }
  }

  // =====================================================
  // DATE FROM FIRESTORE
  // =====================================================

  DateTime? _dateFromValue(
      dynamic value,
      ) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return null;
  }

  // =====================================================
  // LOAD SAVED REMINDER TIME
  //
  // Example:
  // 08:00 -> Morning
  // 13:00 -> Afternoon
  // 20:00 -> Evening
  // 22:00 -> Night
  // =====================================================

  void _loadReminderTime(
      String value,
      ) {
    try {
      final List<String> parts =
      value.split(':');

      if (parts.length != 2) {
        return;
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

      if (hour < 12) {
        morningSelected = true;
        morningTime = time;
      } else if (hour < 17) {
        afternoonSelected = true;
        afternoonTime = time;
      } else if (hour < 21) {
        eveningSelected = true;
        eveningTime = time;
      } else {
        nightSelected = true;
        nightTime = time;
      }
    } catch (_) {
      // Invalid reminder time is ignored safely.
    }
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
        borderSide:
        const BorderSide(
          color: Colors.red,
        ),
      ),
      focusedErrorBorder:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(14),
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
      String text,
      ) {
    return Padding(
      padding:
      const EdgeInsets.only(
        bottom: 7,
      ),
      child: Text(
        text,
        style:
        const TextStyle(
          fontSize: 13,
          fontWeight:
          FontWeight.w700,
        ),
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

  Future<DateTime?> _selectDate({
    required DateTime initialDate,
  }) async {
    return showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate:
      DateTime.now().add(
        const Duration(
          days: 3650,
        ),
      ),
    );
  }

  // =====================================================
  // TIME PICKER
  // =====================================================

  Future<TimeOfDay?> _selectTime(
      TimeOfDay currentTime,
      ) async {
    return showTimePicker(
      context: context,
      initialTime:
      currentTime,
    );
  }

  // =====================================================
  // TIME TO STRING
  // =====================================================

  String _timeToString(
      TimeOfDay time,
      ) {
    final String hour =
    time.hour
        .toString()
        .padLeft(
      2,
      '0',
    );

    final String minute =
    time.minute
        .toString()
        .padLeft(
      2,
      '0',
    );

    return '$hour:$minute';
  }

  // =====================================================
  // SELECTED REMINDER TIMES
  // =====================================================

  List<String> _getReminderTimes() {
    final List<String> times = [];

    if (morningSelected) {
      times.add(
        _timeToString(
          morningTime,
        ),
      );
    }

    if (afternoonSelected) {
      times.add(
        _timeToString(
          afternoonTime,
        ),
      );
    }

    if (eveningSelected) {
      times.add(
        _timeToString(
          eveningTime,
        ),
      );
    }

    if (nightSelected) {
      times.add(
        _timeToString(
          nightTime,
        ),
      );
    }

    return times;
  }

  // =====================================================
  // CANCEL OLD NOTIFICATIONS
  // =====================================================

  Future<void>
  _cancelOldNotifications() async {
    for (final int id
    in oldNotificationIds) {
      try {
        await _localNotifications
            .cancel(id);
      } catch (_) {
        // Continue cancelling other IDs.
      }
    }
  }

  // =====================================================
  // TIME CARD
  // =====================================================

  Widget _timeChip({
    required String label,
    required IconData icon,
    required bool selected,
    required TimeOfDay time,
    required VoidCallback onSelect,
    required VoidCallback onTimeTap,
  }) {
    return Material(
      color:
      Colors.transparent,
      borderRadius:
      BorderRadius.circular(14),
      child: InkWell(
        borderRadius:
        BorderRadius.circular(14),
        onTap: onSelect,
        child:
        AnimatedContainer(
          duration:
          const Duration(
            milliseconds: 160,
          ),
          padding:
          const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 12,
          ),
          decoration:
          BoxDecoration(
            color: selected
                ? Colors
                .teal.shade50
                : Colors.white,
            borderRadius:
            BorderRadius.circular(
              14,
            ),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : AppColors.border,
              width:
              selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment:
                MainAxisAlignment
                    .center,
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: selected
                        ? AppColors
                        .primary
                        : AppColors
                        .textSecondary,
                  ),
                  const SizedBox(
                    width: 5,
                  ),
                  Flexible(
                    child: Text(
                      label,
                      style:
                      TextStyle(
                        fontWeight:
                        FontWeight
                            .w700,
                        fontSize: 12,
                        color: selected
                            ? AppColors
                            .primary
                            : AppColors
                            .textSecondary,
                      ),
                    ),
                  ),
                ],
              ),

              if (selected) ...[
                const SizedBox(
                  height: 8,
                ),

                Material(
                  color:
                  Colors.white,
                  borderRadius:
                  BorderRadius
                      .circular(
                    10,
                  ),
                  child: InkWell(
                    borderRadius:
                    BorderRadius
                        .circular(
                      10,
                    ),
                    onTap:
                    onTimeTap,
                    child: Padding(
                      padding:
                      const EdgeInsets
                          .symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      child: Row(
                        mainAxisSize:
                        MainAxisSize
                            .min,
                        children: [
                          Icon(
                            Icons
                                .access_time_rounded,
                            size: 14,
                            color: AppColors
                                .primary,
                          ),
                          const SizedBox(
                            width: 4,
                          ),
                          Text(
                            time.format(
                              context,
                            ),
                            style:
                            TextStyle(
                              color:
                              AppColors
                                  .primary,
                              fontWeight:
                              FontWeight
                                  .w700,
                              fontSize:
                              11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // =====================================================
  // UPDATE MEDICINE
  // =====================================================

  Future<void> _updateMedicine() async {
    if (isSaving) {
      return;
    }

    if (!_formKey.currentState!
        .validate()) {
      return;
    }

    if (selectedStartDate == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Please select a start date.',
          ),
        ),
      );

      return;
    }

    if (selectedEndDate != null &&
        selectedEndDate!.isBefore(
          selectedStartDate!,
        )) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'End date cannot be before start date.',
          ),
        ),
      );

      return;
    }

    final List<String> reminderTimes =
    _getReminderTimes();

    if (currentlyTaking &&
        reminderEnabled &&
        reminderTimes.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Please select at least one reminder time.',
          ),
        ),
      );

      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      bool shouldScheduleReminder =
          currentlyTaking &&
              reminderEnabled &&
              reminderTimes.isNotEmpty;

      // =================================================
      // ASK FOR NOTIFICATION PERMISSION
      // =================================================

      if (shouldScheduleReminder) {
        final bool permissionGranted =
        await _notificationService
            .requestPermissions();

        if (!permissionGranted) {
          shouldScheduleReminder =
          false;
        }
      }

      // =================================================
      // CANCEL OLD REMINDERS
      // =================================================

      await _cancelOldNotifications();

      // =================================================
      // UPDATE FIRESTORE MEDICINE
      // =================================================

      await _firestoreService.updateMedicine(
        medicineId:
        widget.medicineId,
        profileId:
        widget.profileId,
        data: {
          'medicineName':
          medicineNameController.text
              .trim(),

          'dosage':
          dosageController.text
              .trim(),

          'medicineType':
          selectedMedicineType,

          'quantityPerDose':
          quantityController.text
              .trim(),

          'frequency':
          frequencyController.text
              .trim(),

          'reminderTimes':
          reminderTimes,

          'startDate':
          Timestamp.fromDate(
            selectedStartDate!,
          ),

          'endDate':
          selectedEndDate == null
              ? null
              : Timestamp.fromDate(
            selectedEndDate!,
          ),

          'prescribedBy':
          doctorController.text
              .trim(),

          'instructions':
          instructionsController.text
              .trim(),

          'isCurrent':
          currentlyTaking,

          // Temporarily false until
          // reminders are successfully scheduled.
          'reminderEnabled':
          false,

          'notificationIds':
          <int>[],
        },
      );

      // =================================================
      // SCHEDULE NEW REMINDERS
      // =================================================

      if (shouldScheduleReminder) {
        try {
          final List<int>
          newNotificationIds =
          await _notificationService
              .scheduleMedicineReminders(
            medicineId:
            widget.medicineId,

            medicineName:
            medicineNameController
                .text
                .trim(),

            profileName:
            widget.profileName,

            dosage:
            dosageController
                .text
                .trim(),

            quantity:
            quantityController
                .text
                .trim(),

            reminderTimes:
            reminderTimes,

            startDate:
            selectedStartDate!,

            endDate:
            selectedEndDate,
          );

          await _firestoreService
              .updateMedicine(
            medicineId:
            widget.medicineId,
            profileId:
            widget.profileId,
            data: {
              'reminderEnabled':
              true,
              'notificationIds':
              newNotificationIds,
            },
          );
        } catch (_) {
          await _firestoreService
              .updateMedicine(
            medicineId:
            widget.medicineId,
            profileId:
            widget.profileId,
            data: {
              'reminderEnabled':
              false,
              'notificationIds':
              <int>[],
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
                'Medicine updated, but the reminder could not be scheduled.',
              ),
            ),
          );

          Navigator.pop(
            context,
            true,
          );

          return;
        }
      }

      if (!mounted) {
        return;
      }

      setState(() {
        isSaving = false;
      });

      if (shouldScheduleReminder) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'Medicine updated and reminder rescheduled.',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'Medicine updated successfully.',
            ),
          ),
        );
      }

      // true = medicine was updated.
      Navigator.pop(
        context,
        true,
      );
    } catch (e) {
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
            'Unable to update medicine: $e',
          ),
        ),
      );
    }
  }

  // =====================================================
  // DISPOSE
  // =====================================================

  @override
  void dispose() {
    medicineNameController.dispose();
    dosageController.dispose();
    quantityController.dispose();
    frequencyController.dispose();
    doctorController.dispose();
    instructionsController.dispose();
    startDateController.dispose();
    endDateController.dispose();

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
              onPressed: isSaving
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
                  'Edit Medicine',
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
                  'Update medicine for ${widget.profileName}',
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
                // MEDICINE NAME
                // =====================================

                _label(
                  'Medicine Name',
                ),

                TextFormField(
                  controller:
                  medicineNameController,
                  textCapitalization:
                  TextCapitalization
                      .words,
                  decoration:
                  _decoration(
                    'e.g. Amoxicillin',
                  ),
                  validator: (value) {
                    if (value == null ||
                        value
                            .trim()
                            .isEmpty) {
                      return 'Please enter medicine name.';
                    }

                    return null;
                  },
                ),

                const SizedBox(
                  height: 16,
                ),

                // =====================================
                // DOSAGE
                // =====================================

                _label(
                  'Dosage / Strength',
                ),

                TextFormField(
                  controller:
                  dosageController,
                  decoration:
                  _decoration(
                    'e.g. 500 mg',
                  ),
                  validator: (value) {
                    if (value == null ||
                        value
                            .trim()
                            .isEmpty) {
                      return 'Please enter dosage.';
                    }

                    return null;
                  },
                ),

                const SizedBox(
                  height: 18,
                ),

                // =====================================
                // MEDICINE TYPE
                // =====================================

                _label(
                  'Medicine Type',
                ),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                  medicineTypes.map(
                        (type) {
                      final bool selected =
                          selectedMedicineType ==
                              type;

                      return ChoiceChip(
                        label:
                        Text(type),
                        selected:
                        selected,
                        selectedColor:
                        AppColors.primary,
                        backgroundColor:
                        Colors.white,
                        side: BorderSide(
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
                          FontWeight.w600,
                        ),
                        onSelected: (_) {
                          setState(() {
                            selectedMedicineType =
                                type;
                          });
                        },
                      );
                    },
                  ).toList(),
                ),

                const SizedBox(
                  height: 20,
                ),

                // =====================================
                // QUANTITY + FREQUENCY
                // =====================================

                Row(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                        children: [
                          _label(
                            'Quantity per dose',
                          ),
                          TextFormField(
                            controller:
                            quantityController,
                            decoration:
                            _decoration(
                              'e.g. 1 tablet',
                            ),
                            validator:
                                (value) {
                              if (value ==
                                  null ||
                                  value
                                      .trim()
                                      .isEmpty) {
                                return 'Required';
                              }

                              return null;
                            },
                          ),
                        ],
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
                          _label(
                            'Frequency',
                          ),
                          TextFormField(
                            controller:
                            frequencyController,
                            decoration:
                            _decoration(
                              'e.g. Twice daily',
                            ),
                            validator:
                                (value) {
                              if (value ==
                                  null ||
                                  value
                                      .trim()
                                      .isEmpty) {
                                return 'Required';
                              }

                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 22,
                ),

                // =====================================
                // REMINDER TIMES
                // =====================================

                _label(
                  'Reminder Times',
                ),

                Text(
                  'Change when this medicine should be taken. Tap the time to edit it.',
                  style: AppTextStyles
                      .bodySmall
                      .copyWith(
                    color: AppColors
                        .textSecondary,
                    height: 1.4,
                  ),
                ),

                const SizedBox(
                  height: 13,
                ),

                Row(
                  children: [
                    Expanded(
                      child: _timeChip(
                        label: 'Morning',
                        icon: Icons
                            .wb_sunny_outlined,
                        selected:
                        morningSelected,
                        time:
                        morningTime,
                        onSelect: () {
                          setState(() {
                            morningSelected =
                            !morningSelected;
                          });
                        },
                        onTimeTap:
                            () async {
                          final TimeOfDay?
                          selected =
                          await _selectTime(
                            morningTime,
                          );

                          if (selected !=
                              null) {
                            setState(() {
                              morningTime =
                                  selected;
                            });
                          }
                        },
                      ),
                    ),

                    const SizedBox(
                      width: 8,
                    ),

                    Expanded(
                      child: _timeChip(
                        label:
                        'Afternoon',
                        icon: Icons
                            .light_mode_outlined,
                        selected:
                        afternoonSelected,
                        time:
                        afternoonTime,
                        onSelect: () {
                          setState(() {
                            afternoonSelected =
                            !afternoonSelected;
                          });
                        },
                        onTimeTap:
                            () async {
                          final TimeOfDay?
                          selected =
                          await _selectTime(
                            afternoonTime,
                          );

                          if (selected !=
                              null) {
                            setState(() {
                              afternoonTime =
                                  selected;
                            });
                          }
                        },
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
                      child: _timeChip(
                        label:
                        'Evening',
                        icon: Icons
                            .wb_twilight_outlined,
                        selected:
                        eveningSelected,
                        time:
                        eveningTime,
                        onSelect: () {
                          setState(() {
                            eveningSelected =
                            !eveningSelected;
                          });
                        },
                        onTimeTap:
                            () async {
                          final TimeOfDay?
                          selected =
                          await _selectTime(
                            eveningTime,
                          );

                          if (selected !=
                              null) {
                            setState(() {
                              eveningTime =
                                  selected;
                            });
                          }
                        },
                      ),
                    ),

                    const SizedBox(
                      width: 8,
                    ),

                    Expanded(
                      child: _timeChip(
                        label: 'Night',
                        icon: Icons
                            .nightlight_outlined,
                        selected:
                        nightSelected,
                        time:
                        nightTime,
                        onSelect: () {
                          setState(() {
                            nightSelected =
                            !nightSelected;
                          });
                        },
                        onTimeTap:
                            () async {
                          final TimeOfDay?
                          selected =
                          await _selectTime(
                            nightTime,
                          );

                          if (selected !=
                              null) {
                            setState(() {
                              nightTime =
                                  selected;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 22,
                ),

                // =====================================
                // DATES
                // =====================================

                Row(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                        children: [
                          _label(
                            'Start Date',
                          ),
                          TextFormField(
                            controller:
                            startDateController,
                            readOnly: true,
                            onTap:
                                () async {
                              final DateTime?
                              date =
                              await _selectDate(
                                initialDate:
                                selectedStartDate ??
                                    DateTime
                                        .now(),
                              );

                              if (date !=
                                  null) {
                                setState(() {
                                  selectedStartDate =
                                      date;

                                  startDateController
                                      .text =
                                      _formatDate(
                                        date,
                                      );

                                  if (selectedEndDate !=
                                      null &&
                                      selectedEndDate!
                                          .isBefore(
                                        date,
                                      )) {
                                    selectedEndDate =
                                    null;

                                    endDateController
                                        .clear();
                                  }
                                });
                              }
                            },
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
                        ],
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
                          _label(
                            'End Date (Optional)',
                          ),
                          TextFormField(
                            controller:
                            endDateController,
                            readOnly: true,
                            onTap:
                                () async {
                              final DateTime
                              start =
                                  selectedStartDate ??
                                      DateTime
                                          .now();

                              final DateTime?
                              date =
                              await _selectDate(
                                initialDate:
                                selectedEndDate ??
                                    start,
                              );

                              if (date !=
                                  null) {
                                if (date
                                    .isBefore(
                                  start,
                                )) {
                                  if (!mounted) {
                                    return;
                                  }

                                  ScaffoldMessenger
                                      .of(context)
                                      .showSnackBar(
                                    const SnackBar(
                                      content:
                                      Text(
                                        'End date cannot be before start date.',
                                      ),
                                    ),
                                  );

                                  return;
                                }

                                setState(() {
                                  selectedEndDate =
                                      date;

                                  endDateController
                                      .text =
                                      _formatDate(
                                        date,
                                      );
                                });
                              }
                            },
                            decoration:
                            _decoration(
                              'Optional',
                            ).copyWith(
                              suffixIcon:
                              Row(
                                mainAxisSize:
                                MainAxisSize
                                    .min,
                                children: [
                                  if (selectedEndDate !=
                                      null)
                                    IconButton(
                                      onPressed:
                                          () {
                                        setState(
                                              () {
                                            selectedEndDate =
                                            null;

                                            endDateController
                                                .clear();
                                          },
                                        );
                                      },
                                      icon:
                                      const Icon(
                                        Icons
                                            .close_rounded,
                                        size: 18,
                                      ),
                                    ),
                                  const Padding(
                                    padding:
                                    EdgeInsets.only(
                                      right: 10,
                                    ),
                                    child: Icon(
                                      Icons
                                          .calendar_month_outlined,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 18,
                ),

                // =====================================
                // DOCTOR
                // =====================================

                _label(
                  'Prescribed By / Doctor Name (Optional)',
                ),

                TextFormField(
                  controller:
                  doctorController,
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
                // INSTRUCTIONS
                // =====================================

                _label(
                  'Instructions / Notes',
                ),

                TextFormField(
                  controller:
                  instructionsController,
                  maxLines: 4,
                  textCapitalization:
                  TextCapitalization
                      .sentences,
                  decoration:
                  _decoration(
                    'e.g. Take after meal with water',
                  ),
                ),

                const SizedBox(
                  height: 20,
                ),

                // =====================================
                // CURRENT MEDICINE
                // =====================================

                Material(
                  color:
                  Colors.teal.shade50,
                  borderRadius:
                  BorderRadius.circular(
                    16,
                  ),
                  clipBehavior:
                  Clip.antiAlias,
                  child:
                  SwitchListTile(
                    contentPadding:
                    const EdgeInsets
                        .symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    activeThumbColor:
                    AppColors.primary,
                    title:
                    const Text(
                      'Currently Taking This Medicine',
                      style:
                      TextStyle(
                        fontWeight:
                        FontWeight
                            .w700,
                        fontSize: 14,
                      ),
                    ),
                    subtitle:
                    const Text(
                      'Turn this off to move the medicine to Previous.',
                    ),
                    value:
                    currentlyTaking,
                    onChanged: (value) {
                      setState(() {
                        currentlyTaking =
                            value;

                        if (!value) {
                          reminderEnabled =
                          false;
                        }
                      });
                    },
                  ),
                ),

                const SizedBox(
                  height: 12,
                ),

                // =====================================
                // MEDICINE REMINDER
                // =====================================

                Material(
                  color:
                  Colors.teal.shade50,
                  borderRadius:
                  BorderRadius.circular(
                    16,
                  ),
                  clipBehavior:
                  Clip.antiAlias,
                  child:
                  SwitchListTile(
                    contentPadding:
                    const EdgeInsets
                        .symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    activeThumbColor:
                    AppColors.primary,
                    secondary:
                    Icon(
                      Icons
                          .notifications_active_outlined,
                      color:
                      AppColors.primary,
                    ),
                    title:
                    const Text(
                      'Medicine Reminder',
                      style:
                      TextStyle(
                        fontWeight:
                        FontWeight
                            .w700,
                        fontSize: 14,
                      ),
                    ),
                    subtitle:
                    const Text(
                      'Update your device notification schedule.',
                    ),
                    value:
                    reminderEnabled,
                    onChanged:
                    currentlyTaking
                        ? (value) {
                      setState(
                            () {
                          reminderEnabled =
                              value;
                        },
                      );
                    }
                        : null,
                  ),
                ),

                const SizedBox(
                  height: 28,
                ),

                // =====================================
                // UPDATE BUTTON
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
                        : _updateMedicine,
                    icon: isSaving
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child:
                      CircularProgressIndicator(
                        strokeWidth:
                        2,
                        color:
                        Colors.white,
                      ),
                    )
                        : const Icon(
                      Icons
                          .check_rounded,
                    ),
                    label: Text(
                      isSaving
                          ? 'Updating...'
                          : 'Update Medicine',
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
}