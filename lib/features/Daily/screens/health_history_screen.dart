import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:sehatfile/core/theme/app_colors.dart';
import 'package:sehatfile/core/theme/app_text_styles.dart';
import 'package:sehatfile/services/firestore_service.dart';

class HealthHistoryScreen extends StatefulWidget {
  final String readingType;
  final String profileName;
  final String? profileId;

  const HealthHistoryScreen({
    super.key,
    required this.readingType,
    required this.profileName,
    this.profileId,
  });

  @override
  State<HealthHistoryScreen> createState() =>
      _HealthHistoryScreenState();
}

class _HealthHistoryScreenState
    extends State<HealthHistoryScreen> {
  final FirestoreService _firestoreService =
  FirestoreService();

  int? _selectedDays = 7;

  // =====================================================
  // TITLE
  // =====================================================

  String get _title {
    switch (widget.readingType) {
      case 'bloodPressure':
        return 'Blood Pressure';

      case 'bloodSugar':
        return 'Blood Sugar';

      case 'weight':
        return 'Weight';

      case 'heartRate':
        return 'Heart Rate';

      case 'spo2':
        return 'SpO₂';

      case 'temperature':
        return 'Temperature';

      default:
        return 'Health';
    }
  }

  // =====================================================
  // UNIT
  // =====================================================

  String get _unit {
    switch (widget.readingType) {
      case 'bloodPressure':
        return 'mmHg';

      case 'bloodSugar':
        return 'mg/dL';

      case 'weight':
        return 'kg';

      case 'heartRate':
        return 'bpm';

      case 'spo2':
        return '%';

      case 'temperature':
        return '°C';

      default:
        return '';
    }
  }

  // =====================================================
  // ICON
  // =====================================================

  IconData get _icon {
    switch (widget.readingType) {
      case 'bloodPressure':
        return Icons.favorite_outline_rounded;

      case 'bloodSugar':
        return Icons.water_drop_outlined;

      case 'weight':
        return Icons.monitor_weight_outlined;

      case 'heartRate':
        return Icons.monitor_heart_outlined;

      case 'spo2':
        return Icons.air_rounded;

      case 'temperature':
        return Icons.thermostat_outlined;

      default:
        return Icons.health_and_safety_outlined;
    }
  }

  // =====================================================
  // READING DATE
  // =====================================================

  DateTime? _readingDate(
      Map<String, dynamic> data,
      ) {
    final dynamic rawDate =
    data['recordedAt'];

    if (rawDate is Timestamp) {
      return rawDate.toDate();
    }

    if (rawDate is DateTime) {
      return rawDate;
    }

    return null;
  }

  // =====================================================
  // DATE RANGE
  // =====================================================

  bool _isInsideSelectedRange(
      Map<String, dynamic> data,
      ) {
    if (_selectedDays == null) {
      return true;
    }

    final DateTime? date =
    _readingDate(data);

    if (date == null) {
      return false;
    }

    final DateTime now =
    DateTime.now();

    final DateTime today =
    DateTime(
      now.year,
      now.month,
      now.day,
    );

    final DateTime readingDay =
    DateTime(
      date.year,
      date.month,
      date.day,
    );

    final DateTime firstDay =
    today.subtract(
      Duration(
        days: _selectedDays! - 1,
      ),
    );

    return !readingDay.isBefore(
      firstDay,
    );
  }

  // =====================================================
  // FORMAT DATE
  // =====================================================

  String _formatDate(
      DateTime? date,
      ) {
    if (date == null) {
      return 'Date unavailable';
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
  // SHORT DATE FOR GRAPH
  // =====================================================

  String _shortDate(
      DateTime? date,
      ) {
    if (date == null) {
      return '';
    }

    return '${date.day}/${date.month}';
  }

  // =====================================================
  // FORMAT TIME
  // =====================================================

  String _formatTime(
      DateTime? date,
      ) {
    if (date == null) {
      return '';
    }

    return TimeOfDay(
      hour: date.hour,
      minute: date.minute,
    ).format(context);
  }

  // =====================================================
  // READING VALUE
  // =====================================================

  String _readingValue(
      Map<String, dynamic> data,
      ) {
    switch (widget.readingType) {
      case 'bloodPressure':
        final String systolic =
            data['systolic']
                ?.toString() ??
                '--';

        final String diastolic =
            data['diastolic']
                ?.toString() ??
                '--';

        return '$systolic/$diastolic mmHg';

      case 'bloodSugar':
        return '${data['value'] ?? '--'} mg/dL';

      case 'weight':
        return '${data['value'] ?? '--'} kg';

      case 'heartRate':
        return '${data['value'] ?? '--'} bpm';

      case 'spo2':
        return '${data['value'] ?? '--'}%';

      case 'temperature':
        return '${data['value'] ?? '--'} °C';

      default:
        return data['value']
            ?.toString() ??
            '--';
    }
  }

  // =====================================================
  // EXTRA INFO
  // =====================================================

  String? _extraInfo(
      Map<String, dynamic> data,
      ) {
    if (widget.readingType ==
        'bloodSugar') {
      final String context =
          data['context']
              ?.toString()
              .trim() ??
              '';

      if (context.isNotEmpty) {
        return context;
      }
    }

    if (widget.readingType ==
        'bloodPressure') {
      final String pulse =
          data['pulse']
              ?.toString()
              .trim() ??
              '';

      if (pulse.isNotEmpty) {
        return 'Pulse: $pulse bpm';
      }
    }

    return null;
  }

  // =====================================================
  // FILTER
  // =====================================================

  Widget _filterChip({
    required String label,
    required int? days,
  }) {
    final bool selected =
        _selectedDays == days;

    return ChoiceChip(
      label:
      Text(label),
      selected:
      selected,
      selectedColor:
      AppColors.primary,
      backgroundColor:
      Colors.white,
      side:
      BorderSide(
        color: selected
            ? AppColors.primary
            : AppColors.border,
      ),
      labelStyle:
      TextStyle(
        color: selected
            ? Colors.white
            : AppColors.textSecondary,
        fontWeight:
        FontWeight.w600,
      ),
      onSelected:
          (_) {
        setState(() {
          _selectedDays =
              days;
        });
      },
    );
  }

  // =====================================================
  // CHART VALUE
  // =====================================================

  double? _chartValue(
      Map<String, dynamic> data,
      ) {
    final dynamic value =
    data['value'];

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value?.toString() ?? '',
    );
  }

  // =====================================================
  // TREND GRAPH
  // =====================================================

  Widget _trendChart(
      List<Map<String, dynamic>> readings,
      ) {
    if (readings.isEmpty) {
      return const SizedBox.shrink();
    }

    final List<Map<String, dynamic>>
    chartReadings =
    List<Map<String, dynamic>>.from(
      readings,
    );

    chartReadings.sort(
          (a, b) {
        final DateTime? first =
        _readingDate(a);

        final DateTime? second =
        _readingDate(b);

        if (first == null ||
            second == null) {
          return 0;
        }

        return first.compareTo(
          second,
        );
      },
    );

    if (widget.readingType ==
        'bloodPressure') {
      return _bloodPressureChart(
        chartReadings,
      );
    }

    return _singleValueChart(
      chartReadings,
    );
  }

  // =====================================================
  // SINGLE VALUE CHART
  // =====================================================

  Widget _singleValueChart(
      List<Map<String, dynamic>> readings,
      ) {
    final List<FlSpot> spots = [];

    final List<double> values = [];

    for (int index = 0;
    index < readings.length;
    index++) {
      final double? value =
      _chartValue(
        readings[index],
      );

      if (value == null) {
        continue;
      }

      spots.add(
        FlSpot(
          index.toDouble(),
          value,
        ),
      );

      values.add(
        value,
      );
    }

    if (spots.isEmpty) {
      return _chartEmptyState();
    }

    final double lowest =
    values.reduce(min);

    final double highest =
    values.reduce(max);

    double padding =
        (highest - lowest) * 0.20;

    if (padding < 2) {
      padding = 2;
    }

    final double minY =
        lowest - padding;

    final double maxY =
        highest + padding;

    return _chartContainer(
      child:
      LineChart(
        LineChartData(
          minY:
          minY,
          maxY:
          maxY,

          gridData:
          FlGridData(
            show:
            true,
            drawVerticalLine:
            false,
            horizontalInterval:
            _chartInterval(
              minY,
              maxY,
            ),
          ),

          borderData:
          FlBorderData(
            show:
            false,
          ),

          titlesData:
          FlTitlesData(
            topTitles:
            const AxisTitles(
              sideTitles:
              SideTitles(
                showTitles:
                false,
              ),
            ),

            rightTitles:
            const AxisTitles(
              sideTitles:
              SideTitles(
                showTitles:
                false,
              ),
            ),

            leftTitles:
            AxisTitles(
              sideTitles:
              SideTitles(
                showTitles:
                true,
                reservedSize:
                42,
                getTitlesWidget:
                    (
                    value,
                    meta,
                    ) {
                  return SideTitleWidget(
                    meta:
                    meta,
                    child:
                    Text(
                      value
                          .toStringAsFixed(
                        value % 1 == 0
                            ? 0
                            : 1,
                      ),
                      style:
                      AppTextStyles
                          .bodySmall
                          .copyWith(
                        color:
                        AppColors.textSecondary,
                        fontSize:
                        10,
                      ),
                    ),
                  );
                },
              ),
            ),

            bottomTitles:
            AxisTitles(
              sideTitles:
              SideTitles(
                showTitles:
                true,
                reservedSize:
                32,
                interval:
                1,
                getTitlesWidget:
                    (
                    value,
                    meta,
                    ) {
                  final int index =
                  value.toInt();

                  if (index < 0 ||
                      index >=
                          readings.length) {
                    return const SizedBox.shrink();
                  }

                  if (readings.length >
                      7 &&
                      index.isOdd) {
                    return const SizedBox.shrink();
                  }

                  return SideTitleWidget(
                    meta:
                    meta,
                    child:
                    Text(
                      _shortDate(
                        _readingDate(
                          readings[index],
                        ),
                      ),
                      style:
                      AppTextStyles
                          .bodySmall
                          .copyWith(
                        color:
                        AppColors.textSecondary,
                        fontSize:
                        9,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          lineTouchData:
          LineTouchData(
            touchTooltipData:
            LineTouchTooltipData(
              getTooltipItems:
                  (
                  touchedSpots,
                  ) {
                return touchedSpots
                    .map(
                      (
                      spot,
                      ) {
                    final int index =
                    spot.x.toInt();

                    if (index <
                        0 ||
                        index >=
                            readings.length) {
                      return null;
                    }

                    final DateTime? date =
                    _readingDate(
                      readings[index],
                    );

                    return LineTooltipItem(
                      '${spot.y.toStringAsFixed(1)} $_unit\n'
                          '${_formatDate(date)}',
                      const TextStyle(
                        color:
                        Colors.white,
                        fontWeight:
                        FontWeight.w600,
                        fontSize:
                        11,
                      ),
                    );
                  },
                ).toList();
              },
            ),
          ),

          lineBarsData: [
            LineChartBarData(
              spots:
              spots,
              isCurved:
              true,
              color:
              AppColors.primary,
              barWidth:
              3,
              dotData:
              FlDotData(
                show:
                true,
              ),
              belowBarData:
              BarAreaData(
                show:
                true,
                color:
                AppColors.primary
                    .withValues(
                  alpha:
                  0.08,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // BLOOD PRESSURE CHART
  // =====================================================

  Widget _bloodPressureChart(
      List<Map<String, dynamic>> readings,
      ) {
    final List<FlSpot> systolicSpots =
    [];

    final List<FlSpot> diastolicSpots =
    [];

    final List<double> allValues = [];

    for (int index = 0;
    index < readings.length;
    index++) {
      final double? systolic =
      double.tryParse(
        readings[index]['systolic']
            ?.toString() ??
            '',
      );

      final double? diastolic =
      double.tryParse(
        readings[index]['diastolic']
            ?.toString() ??
            '',
      );

      if (systolic != null) {
        systolicSpots.add(
          FlSpot(
            index.toDouble(),
            systolic,
          ),
        );

        allValues.add(
          systolic,
        );
      }

      if (diastolic != null) {
        diastolicSpots.add(
          FlSpot(
            index.toDouble(),
            diastolic,
          ),
        );

        allValues.add(
          diastolic,
        );
      }
    }

    if (allValues.isEmpty) {
      return _chartEmptyState();
    }

    final double lowest =
    allValues.reduce(min);

    final double highest =
    allValues.reduce(max);

    double padding =
        (highest - lowest) * 0.15;

    if (padding < 5) {
      padding = 5;
    }

    final double minY =
        lowest - padding;

    final double maxY =
        highest + padding;

    return Column(
      children: [
        Row(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            _legendItem(
              label:
              'Systolic',
              color:
              AppColors.primary,
            ),

            const SizedBox(
              width:
              20,
            ),

            _legendItem(
              label:
              'Diastolic',
              color:
              Colors.orange,
            ),
          ],
        ),

        const SizedBox(
          height:
          10,
        ),

        _chartContainer(
          child:
          LineChart(
            LineChartData(
              minY:
              minY,
              maxY:
              maxY,

              gridData:
              FlGridData(
                show:
                true,
                drawVerticalLine:
                false,
                horizontalInterval:
                _chartInterval(
                  minY,
                  maxY,
                ),
              ),

              borderData:
              FlBorderData(
                show:
                false,
              ),

              titlesData:
              FlTitlesData(
                topTitles:
                const AxisTitles(
                  sideTitles:
                  SideTitles(
                    showTitles:
                    false,
                  ),
                ),

                rightTitles:
                const AxisTitles(
                  sideTitles:
                  SideTitles(
                    showTitles:
                    false,
                  ),
                ),

                leftTitles:
                AxisTitles(
                  sideTitles:
                  SideTitles(
                    showTitles:
                    true,
                    reservedSize:
                    42,
                    getTitlesWidget:
                        (
                        value,
                        meta,
                        ) {
                      return SideTitleWidget(
                        meta:
                        meta,
                        child:
                        Text(
                          value.toStringAsFixed(
                            0,
                          ),
                          style:
                          AppTextStyles
                              .bodySmall
                              .copyWith(
                            color:
                            AppColors.textSecondary,
                            fontSize:
                            10,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                bottomTitles:
                AxisTitles(
                  sideTitles:
                  SideTitles(
                    showTitles:
                    true,
                    interval:
                    1,
                    reservedSize:
                    32,
                    getTitlesWidget:
                        (
                        value,
                        meta,
                        ) {
                      final int index =
                      value.toInt();

                      if (index < 0 ||
                          index >=
                              readings.length) {
                        return const SizedBox.shrink();
                      }

                      if (readings.length >
                          7 &&
                          index.isOdd) {
                        return const SizedBox.shrink();
                      }

                      return SideTitleWidget(
                        meta:
                        meta,
                        child:
                        Text(
                          _shortDate(
                            _readingDate(
                              readings[index],
                            ),
                          ),
                          style:
                          AppTextStyles
                              .bodySmall
                              .copyWith(
                            color:
                            AppColors.textSecondary,
                            fontSize:
                            9,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              lineBarsData: [
                LineChartBarData(
                  spots:
                  systolicSpots,
                  color:
                  AppColors.primary,
                  barWidth:
                  3,
                  isCurved:
                  true,
                  dotData:
                  FlDotData(
                    show:
                    true,
                  ),
                ),

                LineChartBarData(
                  spots:
                  diastolicSpots,
                  color:
                  Colors.orange,
                  barWidth:
                  3,
                  isCurved:
                  true,
                  dotData:
                  FlDotData(
                    show:
                    true,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // =====================================================
  // CHART INTERVAL
  // =====================================================

  double _chartInterval(
      double minY,
      double maxY,
      ) {
    final double range =
        maxY - minY;

    if (range <= 10) {
      return 2;
    }

    if (range <= 30) {
      return 5;
    }

    if (range <= 60) {
      return 10;
    }

    if (range <= 150) {
      return 20;
    }

    return 50;
  }

  // =====================================================
  // CHART CONTAINER
  // =====================================================

  Widget _chartContainer({
    required Widget child,
  }) {
    return Container(
      width:
      double.infinity,
      height:
      250,
      padding:
      const EdgeInsets.fromLTRB(
        8,
        18,
        14,
        8,
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
      child:
      child,
    );
  }

  // =====================================================
  // CHART EMPTY
  // =====================================================

  Widget _chartEmptyState() {
    return Container(
      height:
      150,
      width:
      double.infinity,
      alignment:
      Alignment.center,
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
      child:
      Text(
        'Not enough data to show a trend.',
        style:
        AppTextStyles.bodySmall
            .copyWith(
          color:
          AppColors.textSecondary,
        ),
      ),
    );
  }

  // =====================================================
  // LEGEND
  // =====================================================

  Widget _legendItem({
    required String label,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width:
          10,
          height:
          10,
          decoration:
          BoxDecoration(
            color:
            color,
            shape:
            BoxShape.circle,
          ),
        ),

        const SizedBox(
          width:
          6,
        ),

        Text(
          label,
          style:
          AppTextStyles.bodySmall
              .copyWith(
            color:
            AppColors.textSecondary,
            fontWeight:
            FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // =====================================================
  // HISTORY CARD
  // =====================================================

  Widget _historyCard(
      Map<String, dynamic> data,
      ) {
    final DateTime? date =
    _readingDate(data);

    final String? extraInfo =
    _extraInfo(data);

    return Container(
      margin:
      const EdgeInsets.only(
        bottom:
        12,
      ),
      padding:
      const EdgeInsets.all(
        15,
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
      child:
      Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Container(
            width:
            46,
            height:
            46,
            decoration:
            BoxDecoration(
              color:
              Colors.teal.shade50,
              borderRadius:
              BorderRadius.circular(
                13,
              ),
            ),
            child:
            Icon(
              _icon,
              color:
              AppColors.primary,
            ),
          ),

          const SizedBox(
            width:
            12,
          ),

          Expanded(
            child:
            Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  _readingValue(
                    data,
                  ),
                  style:
                  const TextStyle(
                    fontSize:
                    17,
                    fontWeight:
                    FontWeight.w800,
                  ),
                ),

                if (extraInfo != null) ...[
                  const SizedBox(
                    height:
                    4,
                  ),
                  Text(
                    extraInfo,
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

                const SizedBox(
                  height:
                  7,
                ),

                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size:
                      14,
                      color:
                      AppColors.textSecondary,
                    ),

                    const SizedBox(
                      width:
                      5,
                    ),

                    Text(
                      _formatDate(
                        date,
                      ),
                      style:
                      AppTextStyles.bodySmall
                          .copyWith(
                        color:
                        AppColors.textSecondary,
                      ),
                    ),

                    const SizedBox(
                      width:
                      12,
                    ),

                    Icon(
                      Icons.access_time_rounded,
                      size:
                      15,
                      color:
                      AppColors.textSecondary,
                    ),

                    const SizedBox(
                      width:
                      4,
                    ),

                    Text(
                      _formatTime(
                        date,
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // EMPTY STATE
  // =====================================================

  Widget _emptyState() {
    return Padding(
      padding:
      const EdgeInsets.symmetric(
        vertical:
        45,
      ),
      child:
      Column(
        children: [
          Container(
            width:
            72,
            height:
            72,
            decoration:
            BoxDecoration(
              color:
              Colors.teal.shade50,
              shape:
              BoxShape.circle,
            ),
            child:
            Icon(
              _icon,
              size:
              32,
              color:
              AppColors.primary,
            ),
          ),

          const SizedBox(
            height:
            14,
          ),

          Text(
            'No $_title history',
            style:
            const TextStyle(
              fontSize:
              16,
              fontWeight:
              FontWeight.w800,
            ),
          ),

          const SizedBox(
            height:
            6,
          ),

          Text(
            'Your previous $_title readings will appear here.',
            textAlign:
            TextAlign.center,
            style:
            AppTextStyles.bodySmall
                .copyWith(
              color:
              AppColors.textSecondary,
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

      appBar:
      AppBar(
        backgroundColor:
        AppColors.background,
        elevation:
        0,
        title:
        Text(
          '$_title History',
        ),
      ),

      body:
      SafeArea(
        child:
        StreamBuilder<
            QuerySnapshot<
                Map<String, dynamic>>>(
          stream:
          _firestoreService
              .healthReadingsStream(
            profileId:
            widget.profileId,
          ),

          builder: (
              context,
              snapshot,
              ) {
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
              return Center(
                child:
                Padding(
                  padding:
                  const EdgeInsets.all(
                    24,
                  ),
                  child:
                  Text(
                    'Unable to load history.\n'
                        '${snapshot.error}',
                    textAlign:
                    TextAlign.center,
                  ),
                ),
              );
            }

            final documents =
                snapshot.data?.docs ??
                    [];

            final List<Map<String, dynamic>>
            allReadings =
            documents
                .map(
                  (document) =>
                  document.data(),
            )
                .where(
                  (data) =>
              data['readingType'] ==
                  widget.readingType,
            )
                .toList();

            final List<Map<String, dynamic>>
            filteredReadings =
            allReadings
                .where(
              _isInsideSelectedRange,
            )
                .toList();

            return ListView(
              padding:
              const EdgeInsets.fromLTRB(
                18,
                16,
                18,
                28,
              ),
              children: [
                // =====================================
                // HEADER
                // =====================================

                Container(
                  padding:
                  const EdgeInsets.all(
                    17,
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
                  child:
                  Row(
                    children: [
                      Container(
                        width:
                        52,
                        height:
                        52,
                        decoration:
                        const BoxDecoration(
                          color:
                          Colors.white,
                          shape:
                          BoxShape.circle,
                        ),
                        child:
                        Icon(
                          _icon,
                          color:
                          AppColors.primary,
                        ),
                      ),

                      const SizedBox(
                        width:
                        13,
                      ),

                      Expanded(
                        child:
                        Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              _title,
                              style:
                              TextStyle(
                                color:
                                AppColors.primary,
                                fontSize:
                                17,
                                fontWeight:
                                FontWeight.w800,
                              ),
                            ),

                            const SizedBox(
                              height:
                              4,
                            ),

                            Text(
                              '${widget.profileName} • '
                                  '${allReadings.length} saved '
                                  'reading${allReadings.length == 1 ? '' : 's'}',
                              style:
                              AppTextStyles.bodySmall
                                  .copyWith(
                                color:
                                AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  height:
                  20,
                ),

                // =====================================
                // FILTER
                // =====================================

                const Text(
                  'History Range',
                  style:
                  TextStyle(
                    fontWeight:
                    FontWeight.w800,
                    fontSize:
                    15,
                  ),
                ),

                const SizedBox(
                  height:
                  10,
                ),

                Wrap(
                  spacing:
                  8,
                  runSpacing:
                  8,
                  children: [
                    _filterChip(
                      label:
                      '7 Days',
                      days:
                      7,
                    ),

                    _filterChip(
                      label:
                      '30 Days',
                      days:
                      30,
                    ),

                    _filterChip(
                      label:
                      '3 Months',
                      days:
                      90,
                    ),

                    _filterChip(
                      label:
                      'All',
                      days:
                      null,
                    ),
                  ],
                ),

                const SizedBox(
                  height:
                  24,
                ),

                // =====================================
                // TREND
                // =====================================

                Row(
                  children: [
                    Expanded(
                      child:
                      Text(
                        'Trend',
                        style:
                        TextStyle(
                          color:
                          AppColors.primary,
                          fontWeight:
                          FontWeight.w800,
                          fontSize:
                          17,
                        ),
                      ),
                    ),

                    Text(
                      _unit,
                      style:
                      AppTextStyles.bodySmall
                          .copyWith(
                        color:
                        AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height:
                  12,
                ),

                if (filteredReadings.length < 2)
                  _chartEmptyState()
                else
                  _trendChart(
                    filteredReadings,
                  ),

                const SizedBox(
                  height:
                  26,
                ),

                // =====================================
                // READINGS
                // =====================================

                Row(
                  children: [
                    Expanded(
                      child:
                      Text(
                        'Readings',
                        style:
                        TextStyle(
                          color:
                          AppColors.primary,
                          fontSize:
                          17,
                          fontWeight:
                          FontWeight.w800,
                        ),
                      ),
                    ),

                    Text(
                      '${filteredReadings.length}',
                      style:
                      AppTextStyles.bodySmall
                          .copyWith(
                        color:
                        AppColors.textSecondary,
                        fontWeight:
                        FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height:
                  12,
                ),

                if (filteredReadings.isEmpty)
                  _emptyState()
                else
                  ...filteredReadings.map(
                    _historyCard,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}