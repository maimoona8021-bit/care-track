class HealthAnalysisResult {
  final String status;
  final String summary;
  final String guidance;
  final int severity;

  const HealthAnalysisResult({
    required this.status,
    required this.summary,
    required this.guidance,
    required this.severity,
  });

  bool get isUrgent => severity >= 3;
}

// ---------------------------------------------------------------------------
// Backward-compatible models.
// These keep health_zone_card.dart valid even though the new Care Guide
// builds its visual cards directly inside chat_screen.dart.
// ---------------------------------------------------------------------------

class MetricAnalysis {
  final String title;
  final String valueText;
  final String status;
  final String advice;
  final int severity;
  final double markerPosition;

  const MetricAnalysis({
    required this.title,
    required this.valueText,
    required this.status,
    required this.advice,
    required this.severity,
    required this.markerPosition,
  });
}

class HealthSummary {
  final List<MetricAnalysis> metrics;
  final String overallMessage;
  final String trendMessage;

  const HealthSummary({
    required this.metrics,
    required this.overallMessage,
    required this.trendMessage,
  });
}

class HealthAnalysisService {
  const HealthAnalysisService();

  // =========================================================================
  // API USED BY chat_screen.dart
  // =========================================================================

  HealthAnalysisResult analyzeReading({
    required String readingType,
    required Map<String, dynamic> data,
  }) {
    switch (readingType) {
      case 'bloodPressure':
        return analyzeBloodPressure(
          systolic: _toDouble(data['systolic']),
          diastolic: _toDouble(data['diastolic']),
        );

      case 'bloodSugar':
        return analyzeBloodSugar(
          value: _toDouble(data['value']),
          context: data['context']?.toString() ?? '',
        );

      case 'heartRate':
        return analyzeHeartRate(
          value: _toDouble(data['value']),
        );

      case 'spo2':
        return analyzeSpo2(
          value: _toDouble(data['value']),
        );

      case 'temperature':
        return analyzeTemperature(
          value: _toDouble(data['value']),
        );

      case 'weight':
        return const HealthAnalysisResult(
          status: 'Recorded',
          summary:
          'Weight is best interpreted as a trend rather than from one reading alone.',
          guidance:
          'Compare several recent weight readings to see whether the value is stable, increasing, or decreasing.',
          severity: 0,
        );

      default:
        return const HealthAnalysisResult(
          status: 'Recorded',
          summary: 'This health reading is saved in Care Track.',
          guidance:
          'Care Guide does not currently have a reference rule for this measurement.',
          severity: 0,
        );
    }
  }

  // =========================================================================
  // BLOOD PRESSURE
  // =========================================================================

  HealthAnalysisResult analyzeBloodPressure({
    required double? systolic,
    required double? diastolic,
  }) {
    if (systolic == null || diastolic == null) {
      return _missingResult();
    }

    if (systolic <= 0 ||
        diastolic <= 0 ||
        systolic <= diastolic) {
      return const HealthAnalysisResult(
        status: 'Check reading',
        summary: 'This blood-pressure value does not look valid.',
        guidance:
        'Check the measurement and enter the systolic and diastolic values again.',
        severity: 1,
      );
    }

    if (systolic > 180 || diastolic > 120) {
      return const HealthAnalysisResult(
        status: 'Urgent',
        summary:
        'This reading is in the severe high blood-pressure range.',
        guidance:
        'Repeat the reading after resting quietly. If it remains this high, contact a healthcare professional promptly. If there is chest pain, shortness of breath, weakness, vision change, difficulty speaking, or another severe symptom, seek emergency medical help.',
        severity: 3,
      );
    }

    if (systolic >= 140 || diastolic >= 90) {
      return const HealthAnalysisResult(
        status: 'Needs attention',
        summary:
        'This reading is in the Stage 2 high blood-pressure range.',
        guidance:
        'One reading does not confirm a diagnosis. Recheck it correctly and discuss repeated readings in this range with a healthcare professional.',
        severity: 2,
      );
    }

    if (systolic >= 130 || diastolic >= 80) {
      return const HealthAnalysisResult(
        status: 'Watch',
        summary:
        'This reading is in the Stage 1 high blood-pressure range.',
        guidance:
        'Continue monitoring. Repeated readings in this range are worth discussing with a healthcare professional.',
        severity: 1,
      );
    }

    if (systolic >= 120 && diastolic < 80) {
      return const HealthAnalysisResult(
        status: 'Watch',
        summary: 'The systolic pressure is in the elevated range.',
        guidance:
        'Continue monitoring your blood pressure and focus on the trend across several readings.',
        severity: 1,
      );
    }

    if (systolic < 90 || diastolic < 60) {
      return const HealthAnalysisResult(
        status: 'Low reading',
        summary:
        'This reading is below the common adult low blood-pressure threshold.',
        guidance:
        'Low blood pressure does not always cause a problem. If there is dizziness, fainting, confusion, weakness, or repeated low readings, contact a healthcare professional.',
        severity: 2,
      );
    }

    return const HealthAnalysisResult(
      status: 'Within range',
      summary:
      'This blood-pressure reading is within the normal adult category.',
      guidance:
      'Keep monitoring over time because trends are more useful than a single reading.',
      severity: 0,
    );
  }

  // =========================================================================
  // BLOOD SUGAR
  // =========================================================================

  HealthAnalysisResult analyzeBloodSugar({
    required double? value,
    required String context,
  }) {
    if (value == null || value <= 0) {
      return _missingResult();
    }

    if (value < 54) {
      return const HealthAnalysisResult(
        status: 'Urgent low',
        summary:
        'This glucose reading is below 54 mg/dL, which is a clinically significant low level.',
        guidance:
        'Take immediate action according to the person’s prescribed low-glucose plan. If the person is confused, unconscious, having a seizure, or cannot safely take glucose, seek emergency medical help.',
        severity: 3,
      );
    }

    if (value < 70) {
      return const HealthAnalysisResult(
        status: 'Low',
        summary: 'This glucose reading is below 70 mg/dL.',
        guidance:
        'Follow the prescribed low-glucose plan and recheck as directed. Repeated low readings should be discussed with a healthcare professional.',
        severity: 2,
      );
    }

    final String normalized = context.toLowerCase().trim();

    final bool beforeMeal =
        normalized.contains('fast') ||
            normalized.contains('before') ||
            normalized.contains('pre meal') ||
            normalized.contains('pre-meal') ||
            normalized.contains('premeal');

    final bool afterMeal =
        normalized.contains('after') ||
            normalized.contains('post meal') ||
            normalized.contains('post-meal') ||
            normalized.contains('postmeal');

    if (beforeMeal) {
      if (value >= 80 && value <= 130) {
        return const HealthAnalysisResult(
          status: 'Within target',
          summary:
          'This is within a common pre-meal target used for many nonpregnant adults with diabetes.',
          guidance:
          'Personal glucose targets can be different, so follow the range given by the healthcare professional.',
          severity: 0,
        );
      }

      if (value > 250) {
        return const HealthAnalysisResult(
          status: 'Needs attention',
          summary:
          'This pre-meal glucose reading is well above the common diabetes-management target.',
          guidance:
          'Recheck as directed by the care plan and contact a healthcare professional if readings remain very high or the person feels unwell.',
          severity: 2,
        );
      }

      if (value > 130) {
        return const HealthAnalysisResult(
          status: 'Watch',
          summary:
          'This pre-meal glucose reading is above a common target used for many adults with diabetes.',
          guidance:
          'One reading alone does not diagnose a condition. Continue monitoring and follow the personal glucose target.',
          severity: 1,
        );
      }

      return const HealthAnalysisResult(
        status: 'Watch',
        summary:
        'This pre-meal reading is below the common 80–130 mg/dL diabetes-management target, but it is not below the 70 mg/dL low-glucose threshold.',
        guidance:
        'Monitor symptoms and follow the target range given by the healthcare professional.',
        severity: 1,
      );
    }

    if (afterMeal) {
      if (value < 180) {
        return const HealthAnalysisResult(
          status: 'Within target',
          summary:
          'This is below a common 1–2 hour post-meal target used for many nonpregnant adults with diabetes.',
          guidance:
          'Personal glucose goals can differ, so use the target set by the healthcare professional.',
          severity: 0,
        );
      }

      if (value > 250) {
        return const HealthAnalysisResult(
          status: 'Needs attention',
          summary:
          'This post-meal glucose reading is well above the common diabetes-management target.',
          guidance:
          'Recheck as directed by the care plan and contact a healthcare professional if readings remain very high or the person feels unwell.',
          severity: 2,
        );
      }

      return const HealthAnalysisResult(
        status: 'Watch',
        summary:
        'This post-meal glucose reading is above a common target used for many adults with diabetes.',
        guidance:
        'Continue monitoring and compare with the personal glucose target.',
        severity: 1,
      );
    }

    return const HealthAnalysisResult(
      status: 'Needs context',
      summary:
      'The glucose value is recorded, but meal timing is needed to judge whether it is above a usual target.',
      guidance:
      'Record whether the reading was fasting, before a meal, or 1–2 hours after a meal so Care Guide can interpret it more accurately.',
      severity: 0,
    );
  }

  // =========================================================================
  // HEART RATE
  // =========================================================================

  HealthAnalysisResult analyzeHeartRate({
    required double? value,
  }) {
    if (value == null || value <= 0) {
      return _missingResult();
    }

    if (value >= 60 && value <= 100) {
      return const HealthAnalysisResult(
        status: 'Within range',
        summary:
        'This is within the common resting heart-rate range for most adults.',
        guidance:
        'Heart rate can change with exercise, stress, medicines, illness, and fitness level.',
        severity: 0,
      );
    }

    return const HealthAnalysisResult(
      status: 'Watch',
      summary:
      'This is outside the common resting heart-rate range of 60–100 bpm for most adults.',
      guidance:
      'Repeat the measurement while resting. If the reading stays unusual or there are symptoms such as chest pain, fainting, severe shortness of breath, or marked dizziness, seek medical advice promptly.',
      severity: 1,
    );
  }

  // =========================================================================
  // SPO2
  // =========================================================================

  HealthAnalysisResult analyzeSpo2({
    required double? value,
  }) {
    if (value == null || value <= 0 || value > 100) {
      return _missingResult();
    }

    if (value >= 95) {
      return const HealthAnalysisResult(
        status: 'Within range',
        summary:
        'This oxygen-saturation reading is within the typical 95–100% range for most healthy people.',
        guidance:
        'Some people with lung disease or who live at higher altitude may have different expected values.',
        severity: 0,
      );
    }

    if (value >= 90) {
      return const HealthAnalysisResult(
        status: 'Watch',
        summary:
        'This oxygen-saturation reading is below the typical range for most healthy people.',
        guidance:
        'Repeat the measurement carefully and consider symptoms and the person’s usual baseline. Contact a healthcare professional if concerned or the reading stays low.',
        severity: 1,
      );
    }

    return const HealthAnalysisResult(
      status: 'Needs attention',
      summary:
      'This oxygen-saturation reading is substantially below the typical range.',
      guidance:
      'Repeat the reading carefully. If it remains this low, or there is shortness of breath, chest pain, blue lips or face, confusion, or worsening symptoms, seek urgent medical care.',
      severity: 2,
    );
  }

  // =========================================================================
  // TEMPERATURE (°C)
  // =========================================================================

  HealthAnalysisResult analyzeTemperature({
    required double? value,
  }) {
    if (value == null || value <= 0) {
      return _missingResult();
    }

    if (value < 35.0) {
      return const HealthAnalysisResult(
        status: 'Urgent',
        summary:
        'A body temperature below 35°C is in the hypothermia range.',
        guidance:
        'This can be a medical emergency. Seek urgent medical help.',
        severity: 3,
      );
    }

    if (value >= 40.6) {
      return const HealthAnalysisResult(
        status: 'Urgent',
        summary: 'This is a very high body temperature.',
        guidance:
        'Seek prompt medical assessment, especially if there are severe symptoms, confusion, breathing difficulty, seizure, dehydration, or worsening illness.',
        severity: 3,
      );
    }

    if (value >= 39.4) {
      return const HealthAnalysisResult(
        status: 'Needs attention',
        summary: 'This is a high fever-range temperature.',
        guidance:
        'Monitor symptoms and contact a healthcare professional, particularly if the fever persists or the person feels very unwell.',
        severity: 2,
      );
    }

    if (value >= 38.0) {
      return const HealthAnalysisResult(
        status: 'Fever range',
        summary: 'This temperature is in the fever range.',
        guidance:
        'Rest, stay hydrated, monitor symptoms, and seek medical advice if the fever persists, worsens, or is accompanied by concerning symptoms.',
        severity: 1,
      );
    }

    if (value >= 36.1 && value <= 37.2) {
      return const HealthAnalysisResult(
        status: 'Within range',
        summary:
        'This temperature is within a common normal adult range.',
        guidance:
        'Body temperature varies by person, time of day, and measurement method.',
        severity: 0,
      );
    }

    return const HealthAnalysisResult(
      status: 'Watch',
      summary:
      'This temperature is outside a common average adult range.',
      guidance:
      'Measurement method and time of day can affect temperature. Recheck if needed and consider symptoms.',
      severity: 1,
    );
  }

  // =========================================================================
  // BACKWARD-COMPATIBLE analyze() API
  // =========================================================================

  HealthSummary analyze({
    required Map<String, dynamic> latestReading,
    List<Map<String, dynamic>> history = const [],
  }) {
    final List<MetricAnalysis> metrics = [];

    void addMetric({
      required String title,
      required String valueText,
      required HealthAnalysisResult result,
    }) {
      metrics.add(
        MetricAnalysis(
          title: title,
          valueText: valueText,
          status: result.status,
          advice: result.guidance,
          severity: result.severity,
          markerPosition: _markerPosition(result.severity),
        ),
      );
    }

    final double? systolic = _toDouble(
      latestReading['systolic'] ??
          latestReading['bpSystolic'] ??
          latestReading['bloodPressureSystolic'],
    );

    final double? diastolic = _toDouble(
      latestReading['diastolic'] ??
          latestReading['bpDiastolic'] ??
          latestReading['bloodPressureDiastolic'],
    );

    if (systolic != null && diastolic != null) {
      final result = analyzeBloodPressure(
        systolic: systolic,
        diastolic: diastolic,
      );

      addMetric(
        title: 'Blood Pressure',
        valueText:
        '${systolic.toInt()}/${diastolic.toInt()} mmHg',
        result: result,
      );
    }

    final double? sugar = _toDouble(
      latestReading['bloodSugar'] ??
          latestReading['sugar'] ??
          latestReading['sugarLevel'] ??
          latestReading['glucose'],
    );

    if (sugar != null) {
      final result = analyzeBloodSugar(
        value: sugar,
        context: latestReading['context']?.toString() ?? '',
      );

      addMetric(
        title: 'Blood Sugar',
        valueText: '${sugar.toStringAsFixed(0)} mg/dL',
        result: result,
      );
    }

    final double? spo2 = _toDouble(
      latestReading['spo2'] ??
          latestReading['oxygenLevel'] ??
          latestReading['oxygenSaturation'],
    );

    if (spo2 != null) {
      final result = analyzeSpo2(
        value: spo2,
      );

      addMetric(
        title: 'SpO₂',
        valueText: '${spo2.toStringAsFixed(0)}%',
        result: result,
      );
    }

    final double? heartRate = _toDouble(
      latestReading['heartRate'] ??
          latestReading['pulse'] ??
          latestReading['pulseRate'],
    );

    if (heartRate != null) {
      final result = analyzeHeartRate(
        value: heartRate,
      );

      addMetric(
        title: 'Heart Rate',
        valueText: '${heartRate.toStringAsFixed(0)} bpm',
        result: result,
      );
    }

    return HealthSummary(
      metrics: metrics,
      overallMessage: _buildOverallMessage(metrics),
      trendMessage: _buildLegacyTrendMessage(history),
    );
  }

  // =========================================================================
  // HELPERS
  // =========================================================================

  double? _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value?.toString() ?? '',
    );
  }

  HealthAnalysisResult _missingResult() {
    return const HealthAnalysisResult(
      status: 'Check reading',
      summary: 'I could not safely interpret this value.',
      guidance:
      'Check that the reading was entered correctly and try again.',
      severity: 1,
    );
  }

  double _markerPosition(int severity) {
    switch (severity) {
      case 0:
        return 0.125;
      case 1:
        return 0.375;
      case 2:
        return 0.625;
      default:
        return 0.875;
    }
  }

  String _buildOverallMessage(List<MetricAnalysis> metrics) {
    if (metrics.isEmpty) {
      return 'No health readings are available yet.';
    }

    final int highestSeverity = metrics.fold<int>(
      0,
          (current, metric) =>
      metric.severity > current ? metric.severity : current,
    );

    if (highestSeverity >= 3) {
      return 'At least one reading may need urgent attention.';
    }

    if (highestSeverity == 2) {
      return 'At least one reading needs attention.';
    }

    if (highestSeverity == 1) {
      return 'Most readings do not appear urgent, but at least one should be monitored.';
    }

    return 'The available readings are generally within the reference ranges used by Care Guide.';
  }

  String _buildLegacyTrendMessage(
      List<Map<String, dynamic>> history,
      ) {
    if (history.length < 2) {
      return 'Add more readings to see a recent trend.';
    }

    return 'Care Guide can compare recent readings to show whether values are stable, increasing, or decreasing.';
  }
}
