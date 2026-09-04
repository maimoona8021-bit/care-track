import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:sehatfile/core/routes/app_routes.dart';
import 'package:sehatfile/core/theme/app_colors.dart';
import 'package:sehatfile/core/theme/app_text_styles.dart';
import 'package:sehatfile/core/widgets/dashboard_back_app_bar.dart';
import 'package:sehatfile/features/daily/screens/add_health_reading_screen.dart';
import 'package:sehatfile/features/daily/screens/health_history_screen.dart';
import 'package:sehatfile/services/firestore_service.dart';

class DailyScreen extends StatefulWidget {
  final String? profileId;
  final String profileName;

  const DailyScreen({
    super.key,
    this.profileId,
    this.profileName = 'My Health',
  });

  @override
  State<DailyScreen> createState() => _DailyScreenState();
}

class _DailyScreenState extends State<DailyScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  // =====================================================
  // TODAY
  // =====================================================

  DateTime get _today {
    final DateTime now = DateTime.now();

    return DateTime(
      now.year,
      now.month,
      now.day,
    );
  }

  // =====================================================
  // FORMAT TODAY
  // =====================================================

  String _formattedToday() {
    const List<String> weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    const List<String> months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    final DateTime now = DateTime.now();

    return '${weekdays[now.weekday - 1]}, '
        '${now.day} ${months[now.month - 1]}';
  }

  // =====================================================
  // MEDICINE ACTIVE TODAY
  // =====================================================

  bool _isMedicineForToday(
      Map<String, dynamic> data,
      ) {
    if (data['isCurrent'] != true) {
      return false;
    }

    DateTime? startDate;
    DateTime? endDate;

    final dynamic rawStart = data['startDate'];
    final dynamic rawEnd = data['endDate'];

    if (rawStart is Timestamp) {
      final DateTime value = rawStart.toDate();

      startDate = DateTime(
        value.year,
        value.month,
        value.day,
      );
    }

    if (rawEnd is Timestamp) {
      final DateTime value = rawEnd.toDate();

      endDate = DateTime(
        value.year,
        value.month,
        value.day,
      );
    }

    if (startDate != null && _today.isBefore(startDate)) {
      return false;
    }

    if (endDate != null && _today.isAfter(endDate)) {
      return false;
    }

    return true;
  }

  // =====================================================
  // TIME HELPERS
  // =====================================================

  int _timeMinutes(
      String value,
      ) {
    final List<String> parts = value.split(':');

    if (parts.length != 2) {
      return 0;
    }

    final int hour = int.tryParse(parts[0]) ?? 0;
    final int minute = int.tryParse(parts[1]) ?? 0;

    return hour * 60 + minute;
  }

  String _formatTime(
      String value,
      ) {
    final List<String> parts = value.split(':');

    if (parts.length != 2) {
      return value;
    }

    final int hour = int.tryParse(parts[0]) ?? 0;
    final int minute = int.tryParse(parts[1]) ?? 0;

    return TimeOfDay(
      hour: hour,
      minute: minute,
    ).format(context);
  }

  String _periodForTime(
      String value,
      ) {
    final int hour = _timeMinutes(value) ~/ 60;

    if (hour < 12) {
      return 'Morning';
    }

    if (hour < 17) {
      return 'Afternoon';
    }

    if (hour < 21) {
      return 'Evening';
    }

    return 'Night';
  }

  IconData _periodIcon(
      String period,
      ) {
    switch (period) {
      case 'Morning':
        return Icons.wb_sunny_outlined;

      case 'Afternoon':
        return Icons.light_mode_outlined;

      case 'Evening':
        return Icons.wb_twilight_outlined;

      case 'Night':
        return Icons.nightlight_outlined;

      default:
        return Icons.access_time_rounded;
    }
  }

  // =====================================================
  // BUILD TODAY'S MEDICINE DOSES
  // =====================================================

  List<Map<String, dynamic>> _buildTodayDoses(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> medicines,
      ) {
    final List<Map<String, dynamic>> doses = [];

    for (final document in medicines) {
      final Map<String, dynamic> data = document.data();

      if (!_isMedicineForToday(data)) {
        continue;
      }

      final dynamic rawTimes = data['reminderTimes'];

      if (rawTimes is! Iterable) {
        continue;
      }

      for (final dynamic rawTime in rawTimes) {
        final String time = rawTime.toString().trim();

        if (time.isEmpty) {
          continue;
        }

        doses.add({
          'medicineId': document.id,
          'time': time,
          'period': _periodForTime(time),
          'medicineName':
          data['medicineName']?.toString().trim() ?? 'Medicine',
          'dosage': data['dosage']?.toString().trim() ?? '',
          'quantityPerDose':
          data['quantityPerDose']?.toString().trim() ?? '',
          'instructions': data['instructions']?.toString().trim() ?? '',
        });
      }
    }

    doses.sort(
          (a, b) => _timeMinutes(
        a['time'].toString(),
      ).compareTo(
        _timeMinutes(
          b['time'].toString(),
        ),
      ),
    );

    return doses;
  }

  // =====================================================
  // DOSE LOG KEY
  // =====================================================

  String _doseKey({
    required String medicineId,
    required String time,
  }) {
    return '${medicineId}_$time';
  }

  // =====================================================
  // BUILD DOSE LOG MAP
  // =====================================================

  Map<String, Map<String, dynamic>> _buildDoseLogMap(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
      ) {
    final Map<String, Map<String, dynamic>> logs = {};

    for (final document in documents) {
      final Map<String, dynamic> data = document.data();

      final String medicineId =
          data['medicineId']?.toString().trim() ?? '';

      final String scheduledTime =
          data['scheduledTime']?.toString().trim() ?? '';

      if (medicineId.isEmpty || scheduledTime.isEmpty) {
        continue;
      }

      logs[
      _doseKey(
        medicineId: medicineId,
        time: scheduledTime,
      )] = data;
    }

    return logs;
  }

  // =====================================================
  // MARK DOSE
  // =====================================================

  Future<void> _markDose({
    required Map<String, dynamic> dose,
    required String status,
  }) async {
    try {
      await _firestoreService.saveMedicineDoseStatus(
        profileId: widget.profileId,
        medicineId: dose['medicineId'].toString(),
        medicineName: dose['medicineName'].toString(),
        scheduledTime: dose['time'].toString(),
        date: _today,
        status: status,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to update medicine: $e',
          ),
        ),
      );
    }
  }

  // =====================================================
  // FORMAT MARKED TIME
  // =====================================================

  String _formatMarkedTime(
      dynamic value,
      ) {
    if (value is! Timestamp) {
      return '';
    }

    final DateTime date = value.toDate();

    return TimeOfDay(
      hour: date.hour,
      minute: date.minute,
    ).format(context);
  }

  // =====================================================
  // CHECK IF READING IS TODAY
  // =====================================================

  bool _isTodayReading(
      Map<String, dynamic> data,
      ) {
    final dynamic rawDate = data['recordedAt'];

    if (rawDate is! Timestamp) {
      return false;
    }

    final DateTime date = rawDate.toDate();

    return date.year == _today.year &&
        date.month == _today.month &&
        date.day == _today.day;
  }

  // =====================================================
  // GET LATEST TODAY READING
  // =====================================================

  Map<String, dynamic>? _latestReading(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
      String readingType,
      ) {
    for (final document in documents) {
      final Map<String, dynamic> data = document.data();

      if (data['readingType'] == readingType && _isTodayReading(data)) {
        return data;
      }
    }

    return null;
  }

  // =====================================================
  // FORMAT HEALTH VALUE
  // =====================================================

  String _healthValue({
    required String readingType,
    required Map<String, dynamic>? reading,
  }) {
    if (reading == null) {
      return 'Not recorded today';
    }

    switch (readingType) {
      case 'bloodPressure':
        final String systolic =
            reading['systolic']?.toString() ?? '--';

        final String diastolic =
            reading['diastolic']?.toString() ?? '--';

        return '$systolic/$diastolic mmHg';

      case 'bloodSugar':
        final String value =
            reading['value']?.toString() ?? '--';

        final String readingContext =
            reading['context']?.toString() ?? '';

        if (readingContext.isEmpty) {
          return '$value mg/dL';
        }

        return '$value mg/dL • $readingContext';

      case 'weight':
        return '${reading['value'] ?? '--'} kg';

      case 'heartRate':
        return '${reading['value'] ?? '--'} bpm';

      case 'spo2':
        return '${reading['value'] ?? '--'}%';

      case 'temperature':
        return '${reading['value'] ?? '--'} °C';

      default:
        return 'Recorded';
    }
  }

  // =====================================================
  // OPEN HEALTH FORM
  // =====================================================

  Future<void> _openHealthReading(
      String readingType,
      ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddHealthReadingScreen(
          readingType: readingType,
          profileName: widget.profileName,
          profileId: widget.profileId,
        ),
      ),
    );
  }

  // =====================================================
  // OPEN HEALTH HISTORY
  // =====================================================

  Future<void> _openHealthHistory(
      String readingType,
      ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HealthHistoryScreen(
          readingType: readingType,
          profileName: widget.profileName,
          profileId: widget.profileId,
        ),
      ),
    );
  }

  // =====================================================
  // GO TO DASHBOARD
  // =====================================================

  void _goToDashboard() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.home,
          (route) => false,
    );
  }

  // =====================================================
  // SUMMARY CARD
  // =====================================================

  Widget _summaryCard({
    required IconData icon,
    required String number,
    required String label,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(
          14,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
            17,
          ),
          border: Border.all(
            color: AppColors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(
                  11,
                ),
              ),
              child: Icon(
                icon,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(
              height: 11,
            ),
            Text(
              number,
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(
              height: 2,
            ),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // MEDICINE CARD
  // =====================================================

  Widget _medicineCard({
    required Map<String, dynamic> dose,
    required Map<String, Map<String, dynamic>> doseLogs,
  }) {
    final String medicineId =
    dose['medicineId'].toString();

    final String scheduledTime =
    dose['time'].toString();

    final Map<String, dynamic>? log =
    doseLogs[
    _doseKey(
      medicineId: medicineId,
      time: scheduledTime,
    )];

    final String status =
        log?['status']?.toString().trim() ?? '';

    final bool isTaken = status == 'taken';
    final bool isSkipped = status == 'skipped';

    final String markedTime =
    _formatMarkedTime(
      log?['markedAt'],
    );

    final String dosage =
        dose['dosage']?.toString() ?? '';

    final String quantity =
        dose['quantityPerDose']?.toString() ?? '';

    final String instructions =
        dose['instructions']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(
        bottom: 11,
      ),
      padding: const EdgeInsets.all(
        14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          17,
        ),
        border: Border.all(
          color: isTaken
              ? AppColors.primary
              : isSkipped
              ? Colors.orange
              : AppColors.border,
          width: status.isEmpty ? 1 : 1.4,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(
                    13,
                  ),
                ),
                child: Icon(
                  Icons.medication_outlined,
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            dose['medicineName'].toString(),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),

                        Text(
                          _formatTime(
                            scheduledTime,
                          ),
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),

                    if (dosage.isNotEmpty || quantity.isNotEmpty) ...[
                      const SizedBox(
                        height: 5,
                      ),

                      Text(
                        [
                          dosage,
                          quantity,
                        ]
                            .where(
                              (value) => value.isNotEmpty,
                        )
                            .join(
                          ' • ',
                        ),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],

                    if (instructions.isNotEmpty) ...[
                      const SizedBox(
                        height: 7,
                      ),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),

                          const SizedBox(
                            width: 5,
                          ),

                          Expanded(
                            child: Text(
                              instructions,
                              style:
                              AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          if (isTaken || isSkipped) ...[
            const SizedBox(
              height: 12,
            ),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 11,
                vertical: 9,
              ),
              decoration: BoxDecoration(
                color: isTaken
                    ? Colors.teal.shade50
                    : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(
                  11,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isTaken
                        ? Icons.check_circle_outline_rounded
                        : Icons.remove_circle_outline_rounded,
                    size: 19,
                    color: isTaken
                        ? AppColors.primary
                        : Colors.orange,
                  ),

                  const SizedBox(
                    width: 7,
                  ),

                  Expanded(
                    child: Text(
                      isTaken
                          ? markedTime.isEmpty
                          ? 'Taken'
                          : 'Taken at $markedTime'
                          : markedTime.isEmpty
                          ? 'Skipped'
                          : 'Skipped at $markedTime',
                      style: TextStyle(
                        color: isTaken
                            ? AppColors.primary
                            : Colors.orange,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(
            height: 12,
          ),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    _markDose(
                      dose: dose,
                      status: 'taken',
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isTaken
                        ? Colors.white
                        : AppColors.primary,
                    backgroundColor: isTaken
                        ? AppColors.primary
                        : Colors.white,
                    side: BorderSide(
                      color: AppColors.primary,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        12,
                      ),
                    ),
                  ),
                  icon: const Icon(
                    Icons.check_rounded,
                    size: 18,
                  ),
                  label: const Text(
                    'Taken',
                  ),
                ),
              ),

              const SizedBox(
                width: 9,
              ),

              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    _markDose(
                      dose: dose,
                      status: 'skipped',
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isSkipped
                        ? Colors.white
                        : Colors.orange,
                    backgroundColor: isSkipped
                        ? Colors.orange
                        : Colors.white,
                    side: const BorderSide(
                      color: Colors.orange,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        12,
                      ),
                    ),
                  ),
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 18,
                  ),
                  label: const Text(
                    'Skip',
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
  // TODAY PROGRESS
  // =====================================================

  Widget _todayProgress({
    required int total,
    required int taken,
    required int skipped,
  }) {
    final int marked = taken + skipped;

    final int pending = total - marked;

    final double progress =
    total == 0 ? 0 : marked / total;

    return Container(
      padding: const EdgeInsets.all(
        16,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Today\'s Progress',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),

              Text(
                '$marked / $total',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 6,
          ),

          Text(
            total == 0
                ? 'No medicine doses scheduled today.'
                : '$marked of $total scheduled doses reviewed',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(
            height: 13,
          ),

          ClipRRect(
            borderRadius: BorderRadius.circular(
              20,
            ),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.teal.shade50,
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
            ),
          ),

          const SizedBox(
            height: 15,
          ),

          Row(
            children: [
              _progressItem(
                label: 'Taken',
                value: taken,
                icon: Icons.check_circle_outline_rounded,
                color: AppColors.primary,
              ),

              const SizedBox(
                width: 8,
              ),

              _progressItem(
                label: 'Skipped',
                value: skipped,
                icon: Icons.remove_circle_outline_rounded,
                color: Colors.orange,
              ),

              const SizedBox(
                width: 8,
              ),

              _progressItem(
                label: 'Pending',
                value: pending,
                icon: Icons.schedule_rounded,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =====================================================
  // PROGRESS ITEM
  // =====================================================

  Widget _progressItem({
    required String label,
    required int value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 10,
          horizontal: 6,
        ),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(
            12,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 19,
            ),
            const SizedBox(
              height: 5,
            ),
            Text(
              '$value',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
            const SizedBox(
              height: 2,
            ),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // HEALTH CARD
  // =====================================================

  Widget _healthCheck({
    required IconData icon,
    required String title,
    required String readingType,
    required Map<String, dynamic>? reading,
  }) {
    final bool recorded = reading != null;

    return Container(
      margin: const EdgeInsets.only(
        bottom: 11,
      ),
      padding: const EdgeInsets.all(
        14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          17,
        ),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius: BorderRadius.circular(
                12,
              ),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(
                  height: 4,
                ),

                Text(
                  _healthValue(
                    readingType: readingType,
                    reading: reading,
                  ),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: recorded
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    fontWeight: recorded
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            width: 6,
          ),

          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: () {
                  _openHealthReading(
                    readingType,
                  );
                },
                child: Text(
                  recorded ? 'Update' : 'Add',
                ),
              ),

              TextButton(
                onPressed: () {
                  _openHealthHistory(
                    readingType,
                  );
                },
                child: const Text(
                  'History',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =====================================================
  // EMPTY MEDICINES
  // =====================================================

  Widget _emptyMedicines() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        24,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          17,
        ),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.medication_outlined,
              color: AppColors.primary,
              size: 29,
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          const Text(
            'No medicines scheduled today',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),

          const SizedBox(
            height: 5,
          ),

          Text(
            'Your scheduled medicines will appear here.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (
          bool didPop,
          Object? result,
          ) {
        if (didPop) {
          return;
        }

        _goToDashboard();
      },

      child: Scaffold(
        backgroundColor: AppColors.background,

        // =================================================
        // TOP BACK BUTTON
        // =================================================

        appBar: DashboardBackAppBar(
          title: widget.profileName,
        ),

        body: SafeArea(
          child: StreamBuilder<
              QuerySnapshot<Map<String, dynamic>>>(
            stream: _firestoreService.medicinesStream(
              profileId: widget.profileId,
            ),

            builder: (
                context,
                medicineSnapshot,
                ) {
              if (medicineSnapshot.connectionState ==
                  ConnectionState.waiting &&
                  !medicineSnapshot.hasData) {
                return Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                );
              }

              if (medicineSnapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(
                      24,
                    ),
                    child: Text(
                      'Unable to load Daily information.\n'
                          '${medicineSnapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              final medicines =
                  medicineSnapshot.data?.docs ?? [];

              final activeMedicines =
              medicines.where(
                    (document) {
                  return _isMedicineForToday(
                    document.data(),
                  );
                },
              ).toList();

              final todayDoses =
              _buildTodayDoses(
                medicines,
              );

              // =========================================
              // DOSE LOG STREAM
              // =========================================

              return StreamBuilder<
                  QuerySnapshot<Map<String, dynamic>>>(
                stream:
                _firestoreService.medicineDoseLogsStream(
                  profileId: widget.profileId,
                  date: _today,
                ),

                builder: (
                    context,
                    doseLogSnapshot,
                    ) {
                  final doseLogDocuments =
                      doseLogSnapshot.data?.docs ?? [];

                  final doseLogs =
                  _buildDoseLogMap(
                    doseLogDocuments,
                  );

                  int takenCount = 0;
                  int skippedCount = 0;

                  for (final dose in todayDoses) {
                    final String key =
                    _doseKey(
                      medicineId:
                      dose['medicineId'].toString(),
                      time:
                      dose['time'].toString(),
                    );

                    final String status =
                        doseLogs[key]?['status']
                            ?.toString() ??
                            '';

                    if (status == 'taken') {
                      takenCount++;
                    }

                    if (status == 'skipped') {
                      skippedCount++;
                    }
                  }

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(
                      18,
                      18,
                      18,
                      30,
                    ),
                    children: [
                      // =================================
                      // HEADER
                      // =================================

                      Text(
                        'Daily',
                        style:
                        AppTextStyles.titleLarge.copyWith(
                          color: AppColors.primary,
                          fontSize: 27,
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      const SizedBox(
                        height: 4,
                      ),

                      Text(
                        _formattedToday(),
                        style:
                        AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),

                      const SizedBox(
                        height: 22,
                      ),

                      // =================================
                      // SUMMARY
                      // =================================

                      Row(
                        children: [
                          _summaryCard(
                            icon:
                            Icons.medication_outlined,
                            number:
                            '${activeMedicines.length}',
                            label:
                            'Active Medicines',
                          ),

                          const SizedBox(
                            width: 10,
                          ),

                          _summaryCard(
                            icon:
                            Icons.schedule_rounded,
                            number:
                            '${todayDoses.length}',
                            label:
                            'Doses Today',
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 26,
                      ),

                      // =================================
                      // MEDICINES
                      // =================================

                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Today\'s Medicines',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight:
                                FontWeight.w800,
                                fontSize: 17,
                              ),
                            ),
                          ),

                          Text(
                            '${todayDoses.length} scheduled',
                            style:
                            AppTextStyles.bodySmall.copyWith(
                              color:
                              AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 13,
                      ),

                      if (todayDoses.isEmpty)
                        _emptyMedicines()
                      else
                        ...[
                          'Morning',
                          'Afternoon',
                          'Evening',
                          'Night',
                        ].expand(
                              (period) {
                            final List<
                                Map<String, dynamic>>
                            periodDoses =
                            todayDoses
                                .where(
                                  (dose) =>
                              dose['period'] ==
                                  period,
                            )
                                .toList();

                            if (periodDoses.isEmpty) {
                              return <Widget>[];
                            }

                            return <Widget>[
                              Padding(
                                padding:
                                const EdgeInsets.only(
                                  top: 8,
                                  bottom: 9,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _periodIcon(
                                        period,
                                      ),
                                      color:
                                      AppColors.primary,
                                      size: 19,
                                    ),

                                    const SizedBox(
                                      width: 7,
                                    ),

                                    Text(
                                      period,
                                      style:
                                      const TextStyle(
                                        fontWeight:
                                        FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              ...periodDoses.map(
                                    (dose) =>
                                    _medicineCard(
                                      dose: dose,
                                      doseLogs:
                                      doseLogs,
                                    ),
                              ),
                            ];
                          },
                        ),

                      const SizedBox(
                        height: 21,
                      ),

                      // =================================
                      // TODAY'S PROGRESS
                      // =================================

                      _todayProgress(
                        total: todayDoses.length,
                        taken: takenCount,
                        skipped: skippedCount,
                      ),

                      const SizedBox(
                        height: 27,
                      ),

                      // =================================
                      // HEALTH CHECK
                      // =================================

                      Text(
                        'Today\'s Health Check',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                        ),
                      ),

                      const SizedBox(
                        height: 5,
                      ),

                      Text(
                        'Record the health measurements that matter to you today.',
                        style:
                        AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),

                      const SizedBox(
                        height: 14,
                      ),

                      // =================================
                      // HEALTH READINGS
                      // =================================

                      StreamBuilder<
                          QuerySnapshot<
                              Map<String, dynamic>>>(
                        stream: _firestoreService
                            .healthReadingsStream(
                          profileId: widget.profileId,
                        ),

                        builder: (
                            context,
                            healthSnapshot,
                            ) {
                          if (healthSnapshot
                              .connectionState ==
                              ConnectionState.waiting &&
                              !healthSnapshot.hasData) {
                            return Padding(
                              padding:
                              const EdgeInsets.all(
                                25,
                              ),
                              child: Center(
                                child:
                                CircularProgressIndicator(
                                  color:
                                  AppColors.primary,
                                ),
                              ),
                            );
                          }

                          if (healthSnapshot.hasError) {
                            return Container(
                              padding:
                              const EdgeInsets.all(
                                16,
                              ),
                              decoration:
                              BoxDecoration(
                                color: Colors.white,
                                borderRadius:
                                BorderRadius.circular(
                                  16,
                                ),
                                border: Border.all(
                                  color:
                                  AppColors.border,
                                ),
                              ),
                              child: Text(
                                'Unable to load health readings.\n'
                                    '${healthSnapshot.error}',
                              ),
                            );
                          }

                          final documents =
                              healthSnapshot.data?.docs ??
                                  [];

                          final bloodPressure =
                          _latestReading(
                            documents,
                            'bloodPressure',
                          );

                          final bloodSugar =
                          _latestReading(
                            documents,
                            'bloodSugar',
                          );

                          final weight =
                          _latestReading(
                            documents,
                            'weight',
                          );

                          final heartRate =
                          _latestReading(
                            documents,
                            'heartRate',
                          );

                          final spo2 =
                          _latestReading(
                            documents,
                            'spo2',
                          );

                          final temperature =
                          _latestReading(
                            documents,
                            'temperature',
                          );

                          return Column(
                            children: [
                              _healthCheck(
                                icon: Icons
                                    .favorite_outline_rounded,
                                title:
                                'Blood Pressure',
                                readingType:
                                'bloodPressure',
                                reading:
                                bloodPressure,
                              ),

                              _healthCheck(
                                icon: Icons
                                    .water_drop_outlined,
                                title:
                                'Blood Sugar',
                                readingType:
                                'bloodSugar',
                                reading:
                                bloodSugar,
                              ),

                              _healthCheck(
                                icon: Icons
                                    .monitor_weight_outlined,
                                title: 'Weight',
                                readingType:
                                'weight',
                                reading: weight,
                              ),

                              _healthCheck(
                                icon: Icons
                                    .monitor_heart_outlined,
                                title:
                                'Heart Rate',
                                readingType:
                                'heartRate',
                                reading:
                                heartRate,
                              ),

                              _healthCheck(
                                icon:
                                Icons.air_rounded,
                                title: 'SpO₂',
                                readingType:
                                'spo2',
                                reading: spo2,
                              ),

                              _healthCheck(
                                icon: Icons
                                    .thermostat_outlined,
                                title:
                                'Temperature',
                                readingType:
                                'temperature',
                                reading:
                                temperature,
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),

        // Bottom navigation intentionally removed.
      ),
    );
  }
}