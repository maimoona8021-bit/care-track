import 'package:flutter/material.dart';

import 'package:sehatfile/core/theme/app_colors.dart';
import 'package:sehatfile/core/theme/app_text_styles.dart';
import 'package:sehatfile/services/firestore_service.dart';

class AddHealthReadingScreen extends StatefulWidget {
  final String readingType;
  final String profileName;
  final String? profileId;

  const AddHealthReadingScreen({
    super.key,
    required this.readingType,
    required this.profileName,
    this.profileId,
  });

  @override
  State<AddHealthReadingScreen> createState() =>
      _AddHealthReadingScreenState();
}

class _AddHealthReadingScreenState
    extends State<AddHealthReadingScreen> {
  final FirestoreService _firestoreService =
  FirestoreService();

  final GlobalKey<FormState> _formKey =
  GlobalKey<FormState>();

  final TextEditingController firstController =
  TextEditingController();

  final TextEditingController secondController =
  TextEditingController();

  final TextEditingController pulseController =
  TextEditingController();

  String sugarContext = 'Fasting';

  bool _saving = false;

  // =====================================================
  // LABELS
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
        return 'Health Reading';
    }
  }

  String get _firstLabel {
    switch (widget.readingType) {
      case 'bloodPressure':
        return 'Systolic';

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
        return 'Value';
    }
  }

  String get _firstHint {
    switch (widget.readingType) {
      case 'bloodPressure':
        return 'e.g. 120';

      case 'bloodSugar':
        return 'e.g. 95';

      case 'weight':
        return 'e.g. 72.5';

      case 'heartRate':
        return 'e.g. 76';

      case 'spo2':
        return 'e.g. 98';

      case 'temperature':
        return 'e.g. 36.8';

      default:
        return 'Enter value';
    }
  }

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
  // INPUT
  // =====================================================

  InputDecoration _decoration(
      String hint,
      String suffix,
      ) {
    return InputDecoration(
      hintText: hint,
      suffixText: suffix,
      filled: true,
      fillColor: Colors.white,
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
          width:
          2,
        ),
      ),
    );
  }

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
          fontWeight:
          FontWeight.w700,
          fontSize:
          13,
        ),
      ),
    );
  }

  // =====================================================
  // VALIDATOR
  // =====================================================

  String? _validateNumber(
      String? value,
      ) {
    if (value == null ||
        value.trim().isEmpty) {
      return 'Required';
    }

    if (double.tryParse(
      value.trim(),
    ) ==
        null) {
      return 'Enter a valid number';
    }

    return null;
  }

  // =====================================================
  // SAVE
  // =====================================================

  Future<void> _save() async {
    if (_saving) {
      return;
    }

    if (!_formKey.currentState!
        .validate()) {
      return;
    }

    final Map<String, dynamic>
    data = {};

    switch (widget.readingType) {
      case 'bloodPressure':
        data['systolic'] =
            int.parse(
              firstController.text.trim(),
            );

        data['diastolic'] =
            int.parse(
              secondController.text.trim(),
            );

        if (pulseController.text
            .trim()
            .isNotEmpty) {
          data['pulse'] =
              int.parse(
                pulseController.text.trim(),
              );
        }

        break;

      case 'bloodSugar':
        data['value'] =
            double.parse(
              firstController.text.trim(),
            );

        data['context'] =
            sugarContext;

        data['unit'] =
        'mg/dL';

        break;

      case 'weight':
        data['value'] =
            double.parse(
              firstController.text.trim(),
            );

        data['unit'] =
        'kg';

        break;

      case 'heartRate':
        data['value'] =
            int.parse(
              firstController.text.trim(),
            );

        data['unit'] =
        'bpm';

        break;

      case 'spo2':
        data['value'] =
            double.parse(
              firstController.text.trim(),
            );

        data['unit'] =
        '%';

        break;

      case 'temperature':
        data['value'] =
            double.parse(
              firstController.text.trim(),
            );

        data['unit'] =
        '°C';

        break;
    }

    setState(() {
      _saving = true;
    });

    try {
      await _firestoreService
          .createHealthReading(
        profileId:
        widget.profileId,
        readingType:
        widget.readingType,
        data:
        data,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _saving = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            '$_title saved successfully.',
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
        _saving = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Unable to save reading: $e',
          ),
        ),
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
    return Scaffold(
      backgroundColor:
      AppColors.background,

      appBar: AppBar(
        backgroundColor:
        AppColors.background,
        title:
        Text(
          'Add $_title',
        ),
      ),

      body: SafeArea(
        child:
        SingleChildScrollView(
          padding:
          const EdgeInsets.all(
            18,
          ),
          child: Form(
            key:
            _formKey,
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Container(
                  width:
                  double.infinity,
                  padding:
                  const EdgeInsets.all(
                    16,
                  ),
                  decoration:
                  BoxDecoration(
                    color: Colors
                        .teal.shade50,
                    borderRadius:
                    BorderRadius.circular(
                      17,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons
                            .health_and_safety_outlined,
                        color:
                        AppColors.primary,
                      ),

                      const SizedBox(
                        width:
                        10,
                      ),

                      Expanded(
                        child:
                        Text(
                          'Record $_title for ${widget.profileName}',
                          style:
                          TextStyle(
                            color:
                            AppColors.primary,
                            fontWeight:
                            FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  height:
                  24,
                ),

                _label(
                  _firstLabel,
                ),

                TextFormField(
                  controller:
                  firstController,
                  keyboardType:
                  const TextInputType
                      .numberWithOptions(
                    decimal:
                    true,
                  ),
                  validator:
                  _validateNumber,
                  decoration:
                  _decoration(
                    _firstHint,
                    _unit,
                  ),
                ),

                // =====================================
                // BLOOD PRESSURE
                // =====================================

                if (widget.readingType ==
                    'bloodPressure') ...[
                  const SizedBox(
                    height:
                    18,
                  ),

                  _label(
                    'Diastolic',
                  ),

                  TextFormField(
                    controller:
                    secondController,
                    keyboardType:
                    TextInputType.number,
                    validator:
                    _validateNumber,
                    decoration:
                    _decoration(
                      'e.g. 80',
                      'mmHg',
                    ),
                  ),

                  const SizedBox(
                    height:
                    18,
                  ),

                  _label(
                    'Pulse (Optional)',
                  ),

                  TextFormField(
                    controller:
                    pulseController,
                    keyboardType:
                    TextInputType.number,
                    decoration:
                    _decoration(
                      'e.g. 76',
                      'bpm',
                    ),
                  ),
                ],

                // =====================================
                // BLOOD SUGAR TYPE
                // =====================================

                if (widget.readingType ==
                    'bloodSugar') ...[
                  const SizedBox(
                    height:
                    18,
                  ),

                  _label(
                    'Reading Type',
                  ),

                  DropdownButtonFormField<
                      String>(
                    initialValue:
                    sugarContext,
                    decoration:
                    _decoration(
                      '',
                      '',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value:
                        'Fasting',
                        child:
                        Text(
                          'Fasting',
                        ),
                      ),
                      DropdownMenuItem(
                        value:
                        'Before Meal',
                        child:
                        Text(
                          'Before Meal',
                        ),
                      ),
                      DropdownMenuItem(
                        value:
                        'After Meal',
                        child:
                        Text(
                          'After Meal',
                        ),
                      ),
                      DropdownMenuItem(
                        value:
                        'Random',
                        child:
                        Text(
                          'Random',
                        ),
                      ),
                    ],
                    onChanged:
                        (value) {
                      if (value ==
                          null) {
                        return;
                      }

                      setState(() {
                        sugarContext =
                            value;
                      });
                    },
                  ),
                ],

                const SizedBox(
                  height:
                  30,
                ),

                SizedBox(
                  width:
                  double.infinity,
                  height:
                  54,
                  child:
                  FilledButton.icon(
                    onPressed:
                    _saving
                        ? null
                        : _save,

                    style:
                    FilledButton
                        .styleFrom(
                      backgroundColor:
                      AppColors.primary,
                    ),

                    icon:
                    _saving
                        ? const SizedBox(
                      width:
                      20,
                      height:
                      20,
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
                          .save_outlined,
                    ),

                    label:
                    Text(
                      _saving
                          ? 'Saving...'
                          : 'Save Reading',
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
  // DISPOSE
  // =====================================================

  @override
  void dispose() {
    firstController.dispose();
    secondController.dispose();
    pulseController.dispose();

    super.dispose();
  }
}