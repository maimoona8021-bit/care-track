import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sehatfile/core/routes/app_routes.dart';
import 'package:sehatfile/core/widgets/dashboard_back_app_bar.dart';
import 'package:sehatfile/services/firestore_service.dart';
import 'package:sehatfile/services/health_analysis_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController =
  TextEditingController();

  final ScrollController _scrollController =
  ScrollController();

  final FirestoreService _firestoreService =
  FirestoreService();

  final HealthAnalysisService _healthAnalysisService =
  const HealthAnalysisService();

  final List<_VisualHealthMetric> _visualHealthMetrics = [];

  String? _selectedProfileId;

  String _selectedProfileName = 'My Profile';

  String _selectedRelationship = 'Self';

  bool _isLoading = false;

  final List<_ChatMessage> _messages = [
    const _ChatMessage(
      message:
      'Hi! I’m Care Guide 👋\n\nI can help you understand the health information saved in Care Track. Ask about medicines, medical records, daily readings, reminders, or your latest health information.',
      isUser: false,
    ),
  ];

  final List<String> _quickActions = [
    'Analyze Health',
    'My Medicines',
    'Health Readings',
    'My Records',
  ];

  @override
  void initState() {
    super.initState();

    _loadMainProfileName();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();

    super.dispose();
  }

  // =====================================================
  // LOAD MAIN PROFILE NAME
  // =====================================================

  Future<void> _loadMainProfileName() async {
    try {
      final data =
      await _firestoreService.getProfile();

      if (!mounted) {
        return;
      }

      final String name =
          data?['fullName']
              ?.toString()
              .trim() ??
              '';

      if (name.isNotEmpty &&
          _selectedProfileId == null) {
        setState(() {
          _selectedProfileName = name;
          _selectedRelationship = 'Self';
        });
      }
    } catch (_) {
      // Keep "My Profile" if name cannot be loaded.
    }
  }

  // =====================================================
  // SELECT PROFILE
  // =====================================================

  void _selectProfile({
    required String? profileId,
    required String profileName,
    required String relationship,
  }) {
    final bool changed =
        profileId != _selectedProfileId;

    setState(() {
      _selectedProfileId = profileId;
      _selectedProfileName = profileName;
      _selectedRelationship = relationship;
      _visualHealthMetrics.clear();
    });

    if (changed) {
      _messages.add(
        _ChatMessage(
          message:
          'Now using $profileName\'s health profile. Medicines, records, readings and reminders will be loaded for this profile.',
          isUser: false,
        ),
      );

      setState(() {});

      _scrollToBottom();
    }
  }

  // =====================================================
  // FIND PROFILE FROM TYPED QUESTION
  // Example:
  // "Show Maimoona's medicines"
  // =====================================================

  Future<void> _detectProfileFromQuestion(
      String question,
      ) async {
    try {
      // Explicit request for the main profile.
      if (_containsAny(
        question,
        [
          'my profile',
          'self profile',
          'main profile',
        ],
      )) {
        final data =
        await _firestoreService.getProfile();

        final String name =
            data?['fullName']
                ?.toString()
                .trim() ??
                'My Profile';

        if (!mounted) {
          return;
        }

        setState(() {
          _selectedProfileId = null;
          _selectedProfileName =
          name.isEmpty
              ? 'My Profile'
              : name;
          _selectedRelationship =
          'Self';
        });

        return;
      }

      final profileSnapshot =
      await _firestoreService
          .profilesStream()
          .first;

      // ---------------------------------------------
      // First preference:
      // Match exact family profile name.
      // ---------------------------------------------

      for (final document
      in profileSnapshot.docs) {
        final data =
        document.data();

        final String name =
            data['fullName']
                ?.toString()
                .trim() ??
                '';

        if (name.isEmpty) {
          continue;
        }

        final String normalizedName =
        _normalize(name);

        if (question.contains(
          normalizedName,
        )) {
          final String relationship =
              data['relationship']
                  ?.toString()
                  .trim() ??
                  'Family';

          if (!mounted) {
            return;
          }

          setState(() {
            _selectedProfileId =
                document.id;

            _selectedProfileName =
                name;

            _selectedRelationship =
                relationship;
          });

          return;
        }
      }

      // ---------------------------------------------
      // Second preference:
      // Relationship, e.g. "my sister's medicines".
      // Only automatically select if relationship
      // identifies ONE profile.
      // ---------------------------------------------

      final Map<String,
          List<
              QueryDocumentSnapshot<
                  Map<String, dynamic>>>>
      relationshipGroups = {};

      for (final document
      in profileSnapshot.docs) {
        final String relationship =
            document
                .data()['relationship']
                ?.toString()
                .trim()
                .toLowerCase() ??
                '';

        if (relationship.isEmpty ||
            relationship == 'family') {
          continue;
        }

        relationshipGroups
            .putIfAbsent(
          relationship,
              () => [],
        )
            .add(document);
      }

      for (final entry
      in relationshipGroups.entries) {
        if (entry.value.length != 1) {
          continue;
        }

        if (!question.contains(
          entry.key,
        )) {
          continue;
        }

        final document =
            entry.value.first;

        final data =
        document.data();

        final String name =
            data['fullName']
                ?.toString()
                .trim() ??
                'Profile';

        if (!mounted) {
          return;
        }

        setState(() {
          _selectedProfileId =
              document.id;

          _selectedProfileName =
              name;

          _selectedRelationship =
              data['relationship']
                  ?.toString()
                  .trim() ??
                  'Family';
        });

        return;
      }
    } catch (_) {
      // Continue using currently selected profile.
    }
  }

  // =====================================================
  // SEND MESSAGE
  // =====================================================

  Future<void> _sendMessage() async {
    final String text =
    _messageController.text.trim();

    if (text.isEmpty ||
        _isLoading) {
      return;
    }

    _messageController.clear();

    final String question =
    _normalize(text);

    // Detect names such as:
    // "Show Maimoona's medicines"
    await _detectProfileFromQuestion(
      question,
    );

    // ===================================================
    // URGENT / EMERGENCY MESSAGE
    // ===================================================

    if (_containsAny(
      question,
      [
        'chest pain',
        'cannot breathe',
        'cant breathe',
        'difficulty breathing',
        'not breathing',
        'unconscious',
        'severe bleeding',
        'heavy bleeding',
        'face drooping',
        'sudden weakness',
        'seizure',
        'collapsed',
        'suicide',
        'kill myself',
        'self harm',
      ],
    )) {
      _addConversation(
        userMessage: text,
        assistantMessage:
        'This may require urgent medical attention. Care Track cannot diagnose emergencies. Please contact your local emergency medical service or go to the nearest emergency department immediately.',
      );

      return;
    }

    // ===================================================
    // GREETINGS
    // ===================================================

    if (_containsAny(
      question,
      [
        'hello',
        'hi',
        'hey',
        'good morning',
        'good afternoon',
        'good evening',
        'assalam',
        'salam',
      ],
    )) {
      _addConversation(
        userMessage: text,
        assistantMessage:
        'Hello! I’m currently viewing $_selectedProfileName\'s health profile. How can I help?',
      );

      return;
    }

    // ===================================================
    // THANK YOU
    // ===================================================

    if (_containsAny(
      question,
      [
        'thank you',
        'thanks',
        'thankyou',
        'jazakallah',
      ],
    )) {
      _addConversation(
        userMessage: text,
        assistantMessage:
        'You’re welcome. I’m here whenever you need help with Care Track.',
      );

      return;
    }

    // ===================================================
    // CHANGE PROFILE HELP
    // ===================================================

    if (_containsAny(
      question,
      [
        'change profile',
        'switch profile',
        'select profile',
        'another profile',
      ],
    )) {
      _addConversation(
        userMessage: text,
        assistantMessage:
        'Use the “Health data for” selector at the top of this screen to choose your profile or a family member.',
      );

      return;
    }

    // ===================================================
    // HELP
    // ===================================================

    if (_containsAny(
      question,
      [
        'help',
        'what can you do',
        'what do you do',
        'how can you help',
        'what can i ask',
        'options',
      ],
    )) {
      _addConversation(
        userMessage: text,
        assistantMessage:
        'I can help with $_selectedProfileName\'s:\n\n'
            '• Current medicines\n'
            '• Previous medicines\n'
            '• Medicine reminder times\n'
            '• Medical records\n'
            '• Prescriptions\n'
            '• Lab reports\n'
            '• Medical reports\n'
            '• Blood pressure\n'
            '• Blood sugar\n'
            '• Weight\n'
            '• Heart rate\n'
            '• SpO₂\n'
            '• Temperature\n'
            '• Health summary\n\n'
            'You can also type a family member\'s name, for example: “Show Maimoona\'s medicines.”',
      );

      return;
    }

    // ===================================================
    // HEALTH ANALYSIS
    // ===================================================

    if (_containsAny(
      question,
      [
        'analyze my health',
        'analyse my health',
        'analyze health',
        'analyse health',
        'health analysis',
        'how is my health',
        'how are my readings',
        'are my readings okay',
        'are my readings ok',
        'check my health',
        'review my health',
        'health condition',
        'health status',
      ],
    )) {
      await _analyzeHealth(
        userMessage: text,
      );

      return;
    }

    // ===================================================
    // HEALTH SUMMARY
    // ===================================================

    if (_containsAny(
      question,
      [
        'health summary',
        'my summary',
        'summary of health',
        'show health data',
        'show all health data',
        'health information',
        'health info',
      ],
    )) {
      await _loadHealthSummary(
        userMessage: text,
      );

      return;
    }

    // ===================================================
    // REMINDERS
    // Must be checked before general medicine
    // ===================================================

    if (_containsAny(
      question,
      [
        'reminder',
        'reminders',
        'next dose',
        'next medicine',
        'medicine time',
        'medication time',
        'dose time',
        'when do i take',
        'when should i take',
        'when is medicine',
        'what time',
        'medicine schedule',
        'medication schedule',
      ],
    )) {
      await _loadReminders(
        userMessage: text,
      );

      return;
    }

    // ===================================================
    // RECORDS
    // ===================================================

    if (_containsAny(
      question,
      [
        'record',
        'records',
        'medical record',
        'prescription',
        'prescriptions',
        'report',
        'reports',
        'lab',
        'labs',
        'lab result',
        'lab results',
        'test result',
        'test results',
        'medical file',
        'document',
        'documents',
      ],
    )) {
      await _loadMyRecords(
        userMessage: text,
        query: question,
      );

      return;
    }

    // ===================================================
    // BLOOD PRESSURE
    // ===================================================

    if (_containsAny(
      question,
      [
        'blood pressure',
        'bp',
        'systolic',
        'diastolic',
      ],
    )) {
      if (_containsAny(
        question,
        [
          'high',
          'low',
          'normal',
          'stable',
          'okay',
          'ok',
          'good',
          'bad',
          'condition',
          'status',
          'analyze',
          'analyse',
          'should i worry',
          'concern',
        ],
      )) {
        await _analyzeSingleReading(
          userMessage: text,
          requestedType: 'bloodPressure',
        );
      } else {
        await _loadHealthReadings(
          userMessage: text,
          requestedType: 'bloodPressure',
        );
      }

      return;
    }

    // ===================================================
    // BLOOD SUGAR
    // ===================================================

    if (_containsAny(
      question,
      [
        'blood sugar',
        'sugar level',
        'glucose',
        'glucose level',
        'blood glucose',
      ],
    )) {
      if (_containsAny(
        question,
        [
          'high',
          'low',
          'normal',
          'stable',
          'okay',
          'ok',
          'good',
          'bad',
          'condition',
          'status',
          'analyze',
          'analyse',
          'should i worry',
          'concern',
        ],
      )) {
        await _analyzeSingleReading(
          userMessage: text,
          requestedType: 'bloodSugar',
        );
      } else {
        await _loadHealthReadings(
          userMessage: text,
          requestedType: 'bloodSugar',
        );
      }

      return;
    }

    // ===================================================
    // WEIGHT
    // ===================================================

    if (_containsAny(
      question,
      [
        'weight',
        'body weight',
        'my kg',
      ],
    )) {
      await _loadHealthReadings(
        userMessage: text,
        requestedType:
        'weight',
      );

      return;
    }

    // ===================================================
    // HEART RATE
    // ===================================================

    if (_containsAny(
      question,
      [
        'heart rate',
        'pulse',
        'pulse rate',
        'heartbeat',
      ],
    )) {
      if (_containsAny(
        question,
        [
          'high',
          'low',
          'normal',
          'stable',
          'okay',
          'ok',
          'good',
          'bad',
          'condition',
          'status',
          'analyze',
          'analyse',
          'should i worry',
          'concern',
        ],
      )) {
        await _analyzeSingleReading(
          userMessage: text,
          requestedType: 'heartRate',
        );
      } else {
        await _loadHealthReadings(
          userMessage: text,
          requestedType: 'heartRate',
        );
      }

      return;
    }

    // ===================================================
    // SPO2
    // ===================================================

    if (_containsAny(
      question,
      [
        'spo2',
        'oxygen',
        'oxygen level',
        'oxygen saturation',
      ],
    )) {
      if (_containsAny(
        question,
        [
          'high',
          'low',
          'normal',
          'stable',
          'okay',
          'ok',
          'good',
          'bad',
          'condition',
          'status',
          'analyze',
          'analyse',
          'should i worry',
          'concern',
        ],
      )) {
        await _analyzeSingleReading(
          userMessage: text,
          requestedType: 'spo2',
        );
      } else {
        await _loadHealthReadings(
          userMessage: text,
          requestedType: 'spo2',
        );
      }

      return;
    }

    // ===================================================
    // TEMPERATURE
    // ===================================================

    if (_containsAny(
      question,
      [
        'temperature',
        'body temperature',
        'temp',
      ],
    )) {
      if (_containsAny(
        question,
        [
          'high',
          'low',
          'normal',
          'stable',
          'okay',
          'ok',
          'good',
          'bad',
          'condition',
          'status',
          'analyze',
          'analyse',
          'should i worry',
          'concern',
          'fever',
        ],
      )) {
        await _analyzeSingleReading(
          userMessage: text,
          requestedType: 'temperature',
        );
      } else {
        await _loadHealthReadings(
          userMessage: text,
          requestedType: 'temperature',
        );
      }

      return;
    }

    // ===================================================
    // GENERAL HEALTH READINGS
    // ===================================================

    if (_containsAny(
      question,
      [
        'health reading',
        'health readings',
        'vitals',
        'vital signs',
        'latest reading',
        'latest readings',
        'measurements',
      ],
    )) {
      await _loadHealthReadings(
        userMessage: text,
      );

      return;
    }

    // ===================================================
    // MEDICINES
    // ===================================================

    if (_containsAny(
      question,
      [
        'medicine',
        'medicines',
        'medication',
        'medications',
        'drug',
        'drugs',
        'tablet',
        'tablets',
        'capsule',
        'capsules',
        'what am i taking',
        'what is taking',
        'current treatment',
      ],
    )) {
      await _loadMyMedicines(
        userMessage: text,
        query: question,
      );

      return;
    }

    // ===================================================
    // GENERAL MEDICAL SYMPTOM
    // ===================================================

    if (_containsAny(
      question,
      [
        'pain',
        'fever',
        'headache',
        'cough',
        'vomiting',
        'nausea',
        'dizziness',
        'rash',
        'swelling',
        'diarrhea',
        'constipation',
        'infection',
        'sick',
        'symptom',
        'symptoms',
        'diagnose',
        'diagnosis',
        'what disease',
        'what illness',
      ],
    )) {
      _addConversation(
        userMessage: text,
        assistantMessage:
        'I can help review information saved in Care Track, but I cannot diagnose a medical condition from symptoms. If the symptoms are persistent, worsening, or concerning, please contact a qualified healthcare professional.',
      );

      return;
    }

    // ===================================================
    // UNKNOWN
    // ===================================================

    _addConversation(
      userMessage: text,
      assistantMessage:
      'I did not fully understand that yet.\n\n'
          'I’m currently viewing $_selectedProfileName\'s profile. You can ask about medicines, records, prescriptions, reports, health readings, reminders or a health summary.',
    );
  }

  // =====================================================
  // NORMALIZE
  // =====================================================

  String _normalize(
      String text,
      ) {
    return text
        .toLowerCase()
        .replaceAll(
      RegExp(r'[^\w\s₂]'),
      ' ',
    )
        .replaceAll(
      RegExp(r'\s+'),
      ' ',
    )
        .trim();
  }

  // =====================================================
  // MATCH KEYWORDS
  // =====================================================

  bool _containsAny(
      String text,
      List<String> phrases,
      ) {
    for (final phrase in phrases) {
      if (text.contains(phrase)) {
        return true;
      }
    }

    return false;
  }

  // =====================================================
  // QUICK ACTIONS
  // =====================================================

  Future<void> _handleQuickAction(
      String action,
      ) async {
    if (_isLoading) {
      return;
    }

    if (action == 'Analyze Health') {
      await _analyzeHealth(
        userMessage: 'Analyze my health',
      );
      return;
    }

    if (action == 'My Medicines') {
      await _loadMyMedicines();
      return;
    }

    if (action == 'My Records') {
      await _loadMyRecords();
      return;
    }

    if (action == 'Health Readings') {
      await _loadHealthReadings();
      return;
    }

    if (action == 'Reminders') {
      await _loadReminders();
    }
  }

  // =====================================================
  // ADD NORMAL CONVERSATION
  // =====================================================

  void _addConversation({
    required String userMessage,
    required String assistantMessage,
  }) {
    if (!mounted) {
      return;
    }

    setState(() {
      _messages.add(
        _ChatMessage(
          message: userMessage,
          isUser: true,
        ),
      );

      _messages.add(
        _ChatMessage(
          message: assistantMessage,
          isUser: false,
        ),
      );
    });

    _scrollToBottom();
  }

  // =====================================================
  // LOADING
  // =====================================================

  void _showLoading({
    required String userMessage,
    required String loadingMessage,
  }) {
    setState(() {
      _isLoading = true;

      _messages.add(
        _ChatMessage(
          message: userMessage,
          isUser: true,
        ),
      );

      _messages.add(
        _ChatMessage(
          message: loadingMessage,
          isUser: false,
          isLoading: true,
        ),
      );
    });

    _scrollToBottom();
  }

  // =====================================================
  // RESULT
  // =====================================================

  void _showResult(
      String response,
      ) {
    if (!mounted) {
      return;
    }

    setState(() {
      _removeLoadingMessage();

      _messages.add(
        _ChatMessage(
          message: response,
          isUser: false,
        ),
      );

      _isLoading = false;
    });

    _scrollToBottom();
  }

  // =====================================================
  // ERROR
  // =====================================================

  void _showError(
      String message,
      ) {
    if (!mounted) {
      return;
    }

    setState(() {
      _removeLoadingMessage();

      _messages.add(
        _ChatMessage(
          message: message,
          isUser: false,
        ),
      );

      _isLoading = false;
    });

    _scrollToBottom();
  }

  // =====================================================
  // SUBJECT NAME
  // =====================================================

  String get _subjectName {
    if (_selectedProfileId == null) {
      return 'You';
    }

    return _selectedProfileName;
  }

  String get _possessiveName {
    if (_selectedProfileId == null) {
      return 'your';
    }

    return '$_selectedProfileName\'s';
  }

  // =====================================================
  // MEDICINES
  // =====================================================

  Future<void> _loadMyMedicines({
    String userMessage = 'My Medicines',
    String query = '',
  }) async {
    _showLoading(
      userMessage: userMessage,
      loadingMessage:
      'Checking $_possessiveName medicines...',
    );

    try {
      final snapshot =
      await _firestoreService
          .medicinesStream(
        profileId:
        _selectedProfileId,
      )
          .first;

      var medicines =
      snapshot.docs.toList();

      final bool wantsPrevious =
      _containsAny(
        query,
        [
          'previous',
          'past',
          'old',
          'stopped',
          'inactive',
        ],
      );

      final bool wantsAll =
      _containsAny(
        query,
        [
          'all medicine',
          'all medicines',
          'medicine history',
          'medication history',
        ],
      );

      if (wantsPrevious) {
        medicines =
            medicines.where(
                  (document) {
                return document
                    .data()['isCurrent'] !=
                    true;
              },
            ).toList();
      } else if (!wantsAll) {
        medicines =
            medicines.where(
                  (document) {
                return document
                    .data()['isCurrent'] ==
                    true;
              },
            ).toList();
      }

      if (medicines.isEmpty) {
        if (_selectedProfileId ==
            null) {
          _showResult(
            wantsPrevious
                ? 'You do not have any previous medicines saved in Care Track.'
                : 'You do not have any current medicines saved in Care Track.',
          );
        } else {
          _showResult(
            wantsPrevious
                ? '$_selectedProfileName does not have any previous medicines saved in Care Track.'
                : '$_selectedProfileName does not have any current medicines saved in Care Track.',
          );
        }

        return;
      }

      final StringBuffer buffer =
      StringBuffer();

      if (_selectedProfileId ==
          null) {
        if (wantsPrevious) {
          buffer.writeln(
            'Your previous medicines:',
          );
        } else if (wantsAll) {
          buffer.writeln(
            'Your saved medicines:',
          );
        } else {
          buffer.writeln(
            'You have ${medicines.length} current medicine${medicines.length == 1 ? '' : 's'}:',
          );
        }
      } else {
        if (wantsPrevious) {
          buffer.writeln(
            '$_selectedProfileName\'s previous medicines:',
          );
        } else if (wantsAll) {
          buffer.writeln(
            '$_selectedProfileName\'s saved medicines:',
          );
        } else {
          buffer.writeln(
            '$_selectedProfileName has ${medicines.length} current medicine${medicines.length == 1 ? '' : 's'}:',
          );
        }
      }

      buffer.writeln();

      for (int i = 0;
      i < medicines.length;
      i++) {
        final data =
        medicines[i].data();

        final String medicineName =
            data['medicineName']
                ?.toString()
                .trim() ??
                'Medicine';

        final String dosage =
            data['dosage']
                ?.toString()
                .trim() ??
                '';

        final String frequency =
            data['frequency']
                ?.toString()
                .trim() ??
                '';

        final List<dynamic>
        reminderTimes =
            data['reminderTimes']
            as List<dynamic>? ??
                [];

        buffer.writeln(
          '${i + 1}. $medicineName',
        );

        if (dosage.isNotEmpty) {
          buffer.writeln(
            '   Dosage: $dosage',
          );
        }

        if (frequency.isNotEmpty) {
          buffer.writeln(
            '   Frequency: $frequency',
          );
        }

        if (reminderTimes.isNotEmpty) {
          buffer.writeln(
            '   Reminder: ${reminderTimes.join(', ')}',
          );
        }

        if (i !=
            medicines.length - 1) {
          buffer.writeln();
        }
      }

      _showResult(
        buffer.toString().trim(),
      );
    } catch (_) {
      _showError(
        'I could not load $_possessiveName medicines right now. Please try again.',
      );
    }
  }

  // =====================================================
  // RECORDS
  // =====================================================

  Future<void> _loadMyRecords({
    String userMessage = 'My Records',
    String query = '',
  }) async {
    _showLoading(
      userMessage: userMessage,
      loadingMessage:
      'Checking $_possessiveName medical records...',
    );

    try {
      final snapshot =
      await _firestoreService
          .recordsStream(
        profileId:
        _selectedProfileId,
      )
          .first;

      var records =
      snapshot.docs.toList();

      // Prescription
      if (query.contains(
        'prescription',
      )) {
        records =
            records.where(
                  (document) {
                final data =
                document.data();

                final String text =
                '${data['recordType'] ?? ''} '
                    '${data['recordTitle'] ?? ''}'
                    .toLowerCase();

                return text.contains(
                  'prescription',
                );
              },
            ).toList();
      }

      // Lab
      else if (_containsAny(
        query,
        [
          'lab',
          'labs',
          'lab result',
          'test result',
        ],
      )) {
        records =
            records.where(
                  (document) {
                final data =
                document.data();

                final String text =
                '${data['recordType'] ?? ''} '
                    '${data['recordTitle'] ?? ''}'
                    .toLowerCase();

                return text.contains(
                  'lab',
                ) ||
                    text.contains(
                      'test',
                    );
              },
            ).toList();
      }

      // Reports
      else if (query.contains(
        'report',
      )) {
        records =
            records.where(
                  (document) {
                final data =
                document.data();

                final String text =
                '${data['recordType'] ?? ''} '
                    '${data['recordTitle'] ?? ''}'
                    .toLowerCase();

                return text.contains(
                  'report',
                );
              },
            ).toList();
      }

      if (records.isEmpty) {
        _showResult(
          'I could not find matching medical records for $_selectedProfileName.',
        );

        return;
      }

      final bool wantsLatest =
      _containsAny(
        query,
        [
          'latest',
          'newest',
          'most recent',
          'recent',
        ],
      );

      if (wantsLatest &&
          records.length > 1) {
        records = [
          records.first,
        ];
      }

      final StringBuffer buffer =
      StringBuffer();

      if (wantsLatest) {
        buffer.writeln(
          'Latest matching record for $_selectedProfileName:',
        );
      } else {
        buffer.writeln(
          '$_selectedProfileName has ${records.length} matching medical record${records.length == 1 ? '' : 's'}:',
        );
      }

      buffer.writeln();

      for (int i = 0;
      i < records.length;
      i++) {
        final data =
        records[i].data();

        final String title =
            data['recordTitle']
                ?.toString()
                .trim() ??
                'Medical Record';

        final String type =
            data['recordType']
                ?.toString()
                .trim() ??
                '';

        final String doctor =
            data['doctorName']
                ?.toString()
                .trim() ??
                '';

        final String facility =
            data['facilityName']
                ?.toString()
                .trim() ??
                '';

        buffer.writeln(
          '${i + 1}. $title',
        );

        if (type.isNotEmpty) {
          buffer.writeln(
            '   Type: $type',
          );
        }

        if (doctor.isNotEmpty) {
          buffer.writeln(
            '   Doctor: $doctor',
          );
        }

        if (facility.isNotEmpty) {
          buffer.writeln(
            '   Facility: $facility',
          );
        }

        if (i !=
            records.length - 1) {
          buffer.writeln();
        }
      }

      _showResult(
        buffer.toString().trim(),
      );
    } catch (_) {
      _showError(
        'I could not load $_possessiveName medical records right now. Please try again.',
      );
    }
  }

  // =====================================================
  // HEALTH ANALYSIS
  // =====================================================

  Future<void> _analyzeHealth({
    String userMessage = 'Analyze my health',
  }) async {
    _showLoading(
      userMessage: userMessage,
      loadingMessage:
      'Analyzing $_possessiveName latest health readings...',
    );

    try {
      final snapshot =
      await _firestoreService.healthReadingsStream(
        profileId: _selectedProfileId,
      ).first;

      final documents = snapshot.docs;

      if (documents.isEmpty) {
        if (mounted) {
          setState(() {
            _visualHealthMetrics.clear();
          });
        }

        _showResult(
          _selectedProfileId == null
              ? 'You do not have any health readings saved yet. Add readings in Daily Health first, then Care Guide can analyze them.'
              : '$_selectedProfileName does not have any health readings saved yet. Add readings in Daily Health first, then Care Guide can analyze them.',
        );
        return;
      }

      const List<String> types = [
        'bloodPressure',
        'bloodSugar',
        'heartRate',
        'spo2',
        'temperature',
        'weight',
      ];

      final List<_VisualHealthMetric> visualMetrics = [];
      final StringBuffer buffer = StringBuffer();

      buffer.writeln(
        'Health analysis for $_selectedProfileName',
      );
      buffer.writeln();

      int highestSeverity = 0;

      for (final type in types) {
        final data = _findLatestReadingData(
          documents,
          type,
        );

        if (data == null) {
          continue;
        }

        final HealthAnalysisResult result =
        _healthAnalysisService.analyzeReading(
          readingType: type,
          data: data,
        );

        if (result.severity > highestSeverity) {
          highestSeverity = result.severity;
        }

        visualMetrics.add(
          _VisualHealthMetric(
            readingType: type,
            data: data,
            result: result,
            trend: _buildReadingTrend(
              documents: documents,
              readingType: type,
            ),
          ),
        );

        buffer.writeln(
          _formatSingleReading(
            type,
            data,
          ),
        );
        buffer.writeln(
          '${_statusIcon(result.severity)} ${result.status}',
        );
        buffer.writeln(
          result.summary,
        );
        buffer.writeln();
      }

      if (visualMetrics.isEmpty) {
        if (mounted) {
          setState(() {
            _visualHealthMetrics.clear();
          });
        }

        _showResult(
          'I found health data for $_selectedProfileName, but I could not identify any supported reading types.',
        );
        return;
      }

      if (mounted) {
        setState(() {
          _visualHealthMetrics
            ..clear()
            ..addAll(visualMetrics);
        });
      }

      buffer.writeln('Overall');

      if (highestSeverity >= 3) {
        buffer.writeln(
          'At least one reading may need urgent attention. Review the red-zone card above and follow its guidance.',
        );
      } else if (highestSeverity == 2) {
        buffer.writeln(
          'At least one reading needs attention. Recheck unusual measurements and monitor repeated abnormal readings.',
        );
      } else if (highestSeverity == 1) {
        buffer.writeln(
          'Most readings do not appear urgent, but at least one is worth monitoring.',
        );
      } else {
        buffer.writeln(
          'The latest supported readings are generally within the reference ranges used by Care Guide.',
        );
      }

      buffer.writeln();
      buffer.writeln('💡 Recommendation');
      buffer.writeln(
        _overallRecommendation(
          highestSeverity,
        ),
      );

      buffer.writeln();
      buffer.writeln(
        'Care Guide provides general reference-based guidance and does not replace medical diagnosis or personal treatment targets.',
      );

      _showResult(
        buffer.toString().trim(),
      );
    } catch (_) {
      _showError(
        'I could not analyze $_possessiveName health readings right now. Please try again.',
      );
    }
  }

  // =====================================================
  // ANALYZE ONE READING
  // =====================================================

  Future<void> _analyzeSingleReading({
    required String userMessage,
    required String requestedType,
  }) async {
    _showLoading(
      userMessage: userMessage,
      loadingMessage:
      'Analyzing $_possessiveName ${_readingLabel(requestedType)} reading...',
    );

    try {
      final snapshot =
      await _firestoreService.healthReadingsStream(
        profileId: _selectedProfileId,
      ).first;

      final documents = snapshot.docs;

      final latest = _findLatestReadingData(
        documents,
        requestedType,
      );

      if (latest == null) {
        if (mounted) {
          setState(() {
            _visualHealthMetrics.clear();
          });
        }

        _showResult(
          'I could not find a saved ${_readingLabel(requestedType)} reading for $_selectedProfileName.',
        );
        return;
      }

      final HealthAnalysisResult result =
      _healthAnalysisService.analyzeReading(
        readingType: requestedType,
        data: latest,
      );

      final _VisualHealthMetric metric =
      _VisualHealthMetric(
        readingType: requestedType,
        data: latest,
        result: result,
        trend: _buildReadingTrend(
          documents: documents,
          readingType: requestedType,
        ),
      );

      if (mounted) {
        setState(() {
          _visualHealthMetrics
            ..clear()
            ..add(metric);
        });
      }

      final StringBuffer buffer = StringBuffer();

      buffer.writeln(
        _formatSingleReading(
          requestedType,
          latest,
        ),
      );

      buffer.writeln();
      buffer.writeln(
        '${_statusIcon(result.severity)} ${result.status}',
      );
      buffer.writeln(
        result.summary,
      );

      buffer.writeln();
      buffer.writeln(
        result.guidance,
      );

      buffer.writeln();
      buffer.writeln(
        'This is general reference-based guidance, not a diagnosis.',
      );

      _showResult(
        buffer.toString().trim(),
      );
    } catch (_) {
      _showError(
        'I could not analyze $_possessiveName ${_readingLabel(requestedType)} reading right now.',
      );
    }
  }

  String _statusIcon(
      int severity,
      ) {
    if (severity >= 3) {
      return '🔴';
    }

    if (severity == 2) {
      return '🟠';
    }

    if (severity == 1) {
      return '🟡';
    }

    return '🟢';
  }

  // =====================================================
  // OVERALL RECOMMENDATION
  // =====================================================

  String _overallRecommendation(
      int highestSeverity,
      ) {
    if (highestSeverity >= 3) {
      return 'Repeat the unusual reading if it is safe to do so. If it remains in the urgent range, or there are concerning symptoms such as chest pain, severe shortness of breath, fainting, confusion, weakness, seizure, or difficulty speaking, seek urgent medical care.';
    }

    if (highestSeverity == 2) {
      return 'Recheck the abnormal reading, keep recording the next few measurements, and arrange medical review if the value stays abnormal or symptoms develop.';
    }

    if (highestSeverity == 1) {
      return 'Continue daily monitoring, compare several readings rather than one value, take medicines as prescribed, and discuss persistent abnormal trends with a healthcare professional.';
    }

    return 'Continue your usual health routine, take medicines as prescribed, stay active as appropriate, and keep recording readings so Care Guide can identify changes over time.';
  }

  // =====================================================
  // VISUAL ANALYSIS HELPERS
  // =====================================================

  Map<String, dynamic>? _findLatestReadingData(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
      String readingType,
      ) {
    for (final document in documents) {
      final data = document.data();

      if (data['readingType'] == readingType) {
        return data;
      }
    }

    return null;
  }

  String _buildReadingTrend({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
    required String readingType,
  }) {
    final matching = documents.where(
          (document) =>
      document.data()['readingType'] == readingType,
    ).toList();

    if (matching.length < 2) {
      return 'Add another reading to start seeing a trend.';
    }

    final latest = matching.first.data();
    final older = matching[
    matching.length > 4 ? 4 : matching.length - 1]
        .data();

    final double? latestValue =
    _trendNumber(
      readingType,
      latest,
    );

    final double? olderValue =
    _trendNumber(
      readingType,
      older,
    );

    if (latestValue == null || olderValue == null) {
      return 'More readings are needed for a reliable trend.';
    }

    double threshold;

    switch (readingType) {
      case 'bloodPressure':
        threshold = 5;
        break;

      case 'bloodSugar':
        threshold = 10;
        break;

      case 'heartRate':
        threshold = 5;
        break;

      case 'spo2':
        threshold = 1;
        break;

      case 'temperature':
        threshold = 0.3;
        break;

      case 'weight':
        threshold = 0.5;
        break;

      default:
        threshold = 1;
    }

    final double difference =
        latestValue - olderValue;

    final String label =
    readingType == 'bloodPressure'
        ? 'Systolic pressure'
        : _readingLabel(readingType);

    if (difference.abs() <= threshold) {
      return '$label is fairly stable across the recent readings.';
    }

    if (difference > 0) {
      return '$label is trending upward across the recent readings.';
    }

    return '$label is trending downward across the recent readings.';
  }

  double? _trendNumber(
      String readingType,
      Map<String, dynamic> data,
      ) {
    dynamic rawValue;

    if (readingType == 'bloodPressure') {
      rawValue = data['systolic'];
    } else {
      rawValue = data['value'];
    }

    if (rawValue is num) {
      return rawValue.toDouble();
    }

    return double.tryParse(
      rawValue?.toString() ?? '',
    );
  }

  // =====================================================
  // HEALTH READINGS
  // =====================================================

  Future<void> _loadHealthReadings({
    String userMessage =
    'Health Readings',
    String? requestedType,
  }) async {
    _showLoading(
      userMessage: userMessage,
      loadingMessage:
      'Checking $_possessiveName latest health readings...',
    );

    try {
      final snapshot =
      await _firestoreService
          .healthReadingsStream(
        profileId:
        _selectedProfileId,
      )
          .first;

      final documents =
          snapshot.docs;

      if (documents.isEmpty) {
        _showResult(
          _selectedProfileId == null
              ? 'You do not have any health readings saved yet.'
              : '$_selectedProfileName does not have any health readings saved yet.',
        );

        return;
      }

      Map<String, dynamic>?
      findLatestReading(
          String type,
          ) {
        for (final document
        in documents) {
          final data =
          document.data();

          if (data['readingType'] ==
              type) {
            return data;
          }
        }

        return null;
      }

      if (requestedType != null) {
        final data =
        findLatestReading(
          requestedType,
        );

        if (data == null) {
          _showResult(
            'I could not find a saved ${_readingLabel(requestedType)} reading for $_selectedProfileName.',
          );

          return;
        }

        _showResult(
          '${_selectedProfileName}:\n'
              '${_formatSingleReading(requestedType, data)}',
        );

        return;
      }

      final List<String>
      readingTypes = [
        'bloodPressure',
        'bloodSugar',
        'weight',
        'heartRate',
        'spo2',
        'temperature',
      ];

      final StringBuffer buffer =
      StringBuffer();

      buffer.writeln(
        'Latest health readings for $_selectedProfileName:',
      );

      buffer.writeln();

      bool found = false;

      for (final type
      in readingTypes) {
        final data =
        findLatestReading(type);

        if (data != null) {
          found = true;

          buffer.writeln(
            _formatSingleReading(
              type,
              data,
            ),
          );
        }
      }

      if (!found) {
        _showResult(
          'Health readings exist for $_selectedProfileName, but I could not identify their types.',
        );

        return;
      }

      _showResult(
        buffer.toString().trim(),
      );
    } catch (_) {
      _showError(
        'I could not load $_possessiveName health readings right now. Please try again.',
      );
    }
  }

  // =====================================================
  // READING LABEL
  // =====================================================

  String _readingLabel(
      String type,
      ) {
    switch (type) {
      case 'bloodPressure':
        return 'blood pressure';

      case 'bloodSugar':
        return 'blood sugar';

      case 'weight':
        return 'weight';

      case 'heartRate':
        return 'heart rate';

      case 'spo2':
        return 'SpO₂';

      case 'temperature':
        return 'temperature';

      default:
        return 'health';
    }
  }

  // =====================================================
  // FORMAT READING
  // =====================================================

  String _formatSingleReading(
      String type,
      Map<String, dynamic> data,
      ) {
    switch (type) {
      case 'bloodPressure':
        return 'Blood Pressure: '
            '${data['systolic'] ?? '--'}/'
            '${data['diastolic'] ?? '--'} mmHg';

      case 'bloodSugar':
        final String context =
            data['context']
                ?.toString()
                .trim() ??
                '';

        if (context.isNotEmpty) {
          return 'Blood Sugar: '
              '${data['value'] ?? '--'} mg/dL '
              '($context)';
        }

        return 'Blood Sugar: '
            '${data['value'] ?? '--'} mg/dL';

      case 'weight':
        return 'Weight: '
            '${data['value'] ?? '--'} kg';

      case 'heartRate':
        return 'Heart Rate: '
            '${data['value'] ?? '--'} bpm';

      case 'spo2':
        return 'SpO₂: '
            '${data['value'] ?? '--'}%';

      case 'temperature':
        return 'Temperature: '
            '${data['value'] ?? '--'} °C';

      default:
        return 'Health reading available.';
    }
  }

  // =====================================================
  // REMINDERS
  // =====================================================

  Future<void> _loadReminders({
    String userMessage = 'Reminders',
  }) async {
    _showLoading(
      userMessage: userMessage,
      loadingMessage:
      'Checking $_possessiveName medicine reminders...',
    );

    try {
      final snapshot =
      await _firestoreService
          .medicinesStream(
        profileId:
        _selectedProfileId,
      )
          .first;

      final medicines =
      snapshot.docs.where(
            (document) {
          final data =
          document.data();

          final bool isCurrent =
              data['isCurrent'] ==
                  true;

          final bool reminderEnabled =
              data['reminderEnabled'] !=
                  false;

          final List<dynamic>
          reminderTimes =
              data['reminderTimes']
              as List<dynamic>? ??
                  [];

          return isCurrent &&
              reminderEnabled &&
              reminderTimes.isNotEmpty;
        },
      ).toList();

      if (medicines.isEmpty) {
        _showResult(
          _selectedProfileId == null
              ? 'You do not have any active medicine reminders.'
              : '$_selectedProfileName does not have any active medicine reminders.',
        );

        return;
      }

      final StringBuffer buffer =
      StringBuffer();

      buffer.writeln(
        'Medicine reminders for $_selectedProfileName:',
      );

      buffer.writeln();

      for (int i = 0;
      i < medicines.length;
      i++) {
        final data =
        medicines[i].data();

        final String medicineName =
            data['medicineName']
                ?.toString()
                .trim() ??
                'Medicine';

        final String dosage =
            data['dosage']
                ?.toString()
                .trim() ??
                '';

        final String frequency =
            data['frequency']
                ?.toString()
                .trim() ??
                '';

        final List<dynamic>
        reminderTimes =
            data['reminderTimes']
            as List<dynamic>? ??
                [];

        buffer.writeln(
          '${i + 1}. $medicineName',
        );

        if (dosage.isNotEmpty) {
          buffer.writeln(
            '   Dosage: $dosage',
          );
        }

        if (frequency.isNotEmpty) {
          buffer.writeln(
            '   Frequency: $frequency',
          );
        }

        buffer.writeln(
          '   Time: ${reminderTimes.join(', ')}',
        );

        if (i !=
            medicines.length - 1) {
          buffer.writeln();
        }
      }

      _showResult(
        buffer.toString().trim(),
      );
    } catch (_) {
      _showError(
        'I could not load $_possessiveName reminders right now. Please try again.',
      );
    }
  }

  // =====================================================
  // HEALTH SUMMARY
  // =====================================================

  Future<void> _loadHealthSummary({
    required String userMessage,
  }) async {
    _showLoading(
      userMessage: userMessage,
      loadingMessage:
      'Preparing $_selectedProfileName\'s health summary...',
    );

    try {
      final medicineSnapshot =
      await _firestoreService
          .medicinesStream(
        profileId:
        _selectedProfileId,
      )
          .first;

      final recordSnapshot =
      await _firestoreService
          .recordsStream(
        profileId:
        _selectedProfileId,
      )
          .first;

      final readingSnapshot =
      await _firestoreService
          .healthReadingsStream(
        profileId:
        _selectedProfileId,
      )
          .first;

      final int currentMedicines =
          medicineSnapshot.docs.where(
                (document) =>
            document
                .data()['isCurrent'] ==
                true,
          ).length;

      final StringBuffer buffer =
      StringBuffer();

      buffer.writeln(
        'Care Track health summary for $_selectedProfileName:',
      );

      buffer.writeln();

      buffer.writeln(
        'Current Medicines: $currentMedicines',
      );

      buffer.writeln(
        'Medical Records: ${recordSnapshot.docs.length}',
      );

      buffer.writeln(
        'Health Readings: ${readingSnapshot.docs.length}',
      );

      buffer.writeln();

      buffer.writeln(
        'You can ask me for details about any of these.',
      );

      _showResult(
        buffer.toString().trim(),
      );
    } catch (_) {
      _showError(
        'I could not prepare $_selectedProfileName\'s health summary right now.',
      );
    }
  }

  // =====================================================
  // REMOVE LOADING
  // =====================================================

  void _removeLoadingMessage() {
    if (_messages.isNotEmpty &&
        _messages.last.isLoading) {
      _messages.removeLast();
    }
  }

  // =====================================================
  // SCROLL
  // =====================================================

  void _scrollToBottom() {
    WidgetsBinding.instance
        .addPostFrameCallback(
          (_) {
        if (!_scrollController
            .hasClients) {
          return;
        }

        _scrollController.animateTo(
          _scrollController
              .position.maxScrollExtent,
          duration:
          const Duration(
            milliseconds: 300,
          ),
          curve:
          Curves.easeOut,
        );
      },
    );
  }

  // =====================================================
  // GO TO DASHBOARD
  // =====================================================

  void _goToDashboard() {
    Navigator.of(
      context,
      rootNavigator: true,
    ).pushNamedAndRemoveUntil(
      AppRoutes.home,
          (route) => false,
    );
  }

  // =====================================================
  // PROFILE SELECTOR
  // =====================================================

  Widget _buildProfileSelector(
      BuildContext context,
      ) {
    final theme =
    Theme.of(context);

    final colorScheme =
        theme.colorScheme;

    return StreamBuilder<
        DocumentSnapshot<
            Map<String, dynamic>>>(
      stream:
      _firestoreService
          .userProfileStream(),
      builder: (
          context,
          userSnapshot,
          ) {
        final userData =
            userSnapshot.data?.data() ??
                {};

        String selfName =
            userData['fullName']
                ?.toString()
                .trim() ??
                '';

        if (selfName.isEmpty) {
          selfName = 'My Profile';
        }

        return StreamBuilder<
            QuerySnapshot<
                Map<String, dynamic>>>(
          stream:
          _firestoreService
              .profilesStream(),
          builder: (
              context,
              profileSnapshot,
              ) {
            final profiles =
                profileSnapshot
                    .data?.docs ??
                    [];

            String displayName =
                _selectedProfileName;

            String relationship =
                _selectedRelationship;

            if (_selectedProfileId ==
                null) {
              displayName =
                  selfName;

              relationship =
              'Self';
            } else {
              for (final document
              in profiles) {
                if (document.id !=
                    _selectedProfileId) {
                  continue;
                }

                final data =
                document.data();

                displayName =
                    data['fullName']
                        ?.toString()
                        .trim() ??
                        _selectedProfileName;

                relationship =
                    data['relationship']
                        ?.toString()
                        .trim() ??
                        'Family';

                break;
              }
            }

            return Container(
              margin:
              const EdgeInsets.only(
                bottom: 16,
              ),
              padding:
              const EdgeInsets
                  .fromLTRB(
                14,
                10,
                8,
                10,
              ),
              decoration:
              BoxDecoration(
                color:
                colorScheme.primary
                    .withOpacity(
                  0.06,
                ),
                borderRadius:
                BorderRadius.circular(
                  16,
                ),
                border: Border.all(
                  color:
                  colorScheme.primary
                      .withOpacity(
                    0.18,
                  ),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 21,
                    backgroundColor:
                    colorScheme.primary
                        .withOpacity(
                      0.12,
                    ),
                    child: Icon(
                      _selectedProfileId ==
                          null
                          ? Icons
                          .person_rounded
                          : Icons
                          .person_outline_rounded,
                      color:
                      colorScheme.primary,
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
                          'Health data for',
                          style: theme
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                            color:
                            theme
                                .textTheme
                                .bodySmall
                                ?.color,
                          ),
                        ),

                        const SizedBox(
                          height: 2,
                        ),

                        Text(
                          displayName,
                          maxLines: 1,
                          overflow:
                          TextOverflow
                              .ellipsis,
                          style: theme
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                            fontWeight:
                            FontWeight
                                .w700,
                          ),
                        ),

                        Text(
                          relationship,
                          style: theme
                              .textTheme
                              .bodySmall,
                        ),
                      ],
                    ),
                  ),

                  PopupMenuButton<
                      _ProfileChoice>(
                    tooltip:
                    'Select profile',
                    icon: Icon(
                      Icons
                          .keyboard_arrow_down_rounded,
                      color:
                      colorScheme.primary,
                    ),
                    onSelected:
                        (choice) {
                      _selectProfile(
                        profileId:
                        choice
                            .profileId,
                        profileName:
                        choice.name,
                        relationship:
                        choice
                            .relationship,
                      );
                    },
                    itemBuilder:
                        (context) {
                      return [
                        _ProfileChoice(
                          profileId:
                          null,
                          name:
                          selfName,
                          relationship:
                          'Self',
                        ),

                        ...profiles.map(
                              (
                              document,
                              ) {
                            final data =
                            document
                                .data();

                            final String
                            name =
                                data['fullName']
                                    ?.toString()
                                    .trim() ??
                                    'Profile';

                            final String
                            relation =
                                data['relationship']
                                    ?.toString()
                                    .trim() ??
                                    'Family';

                            return _ProfileChoice(
                              profileId:
                              document
                                  .id,
                              name:
                              name,
                              relationship:
                              relation,
                            );
                          },
                        ),
                      ].map(
                            (
                            choice,
                            ) {
                          final bool
                          selected =
                              choice.profileId ==
                                  _selectedProfileId;

                          return PopupMenuItem<
                              _ProfileChoice>(
                            value:
                            choice,
                            child: Row(
                              children: [
                                Icon(
                                  choice.profileId ==
                                      null
                                      ? Icons
                                      .person_rounded
                                      : Icons
                                      .person_outline_rounded,
                                  color:
                                  selected
                                      ? colorScheme.primary
                                      : null,
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
                                        choice.name,
                                        style:
                                        TextStyle(
                                          fontWeight:
                                          selected
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                        ),
                                      ),

                                      Text(
                                        choice.relationship,
                                        style:
                                        theme.textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),

                                if (selected)
                                  Icon(
                                    Icons
                                        .check_rounded,
                                    color:
                                    colorScheme.primary,
                                  ),
                              ],
                            ),
                          );
                        },
                      ).toList();
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // =====================================================
  // ASK A SUGGESTED QUESTION
  // =====================================================

  Future<void> _askSuggestedQuestion(
      String question,
      ) async {
    if (_isLoading) {
      return;
    }

    _messageController.text = question;
    await _sendMessage();
  }

  // =====================================================
  // LATEST READING FOR SNAPSHOT
  // =====================================================

  Map<String, dynamic>? _latestSnapshotReading(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
      String type,
      ) {
    for (final document in documents) {
      final data = document.data();

      if (data['readingType'] == type) {
        return data;
      }
    }

    return null;
  }

  String _snapshotValue(
      String type,
      Map<String, dynamic>? data,
      ) {
    if (data == null) {
      return '--';
    }

    switch (type) {
      case 'bloodPressure':
        return '${data['systolic'] ?? '--'}/${data['diastolic'] ?? '--'}';

      case 'bloodSugar':
        return '${data['value'] ?? '--'}';

      case 'spo2':
        return '${data['value'] ?? '--'}%';

      case 'heartRate':
        return '${data['value'] ?? '--'}';

      default:
        return '--';
    }
  }

  // =====================================================
  // SCREEN
  // =====================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    final ThemeData theme = Theme.of(context);

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
        backgroundColor: theme.scaffoldBackgroundColor,

        appBar: const DashboardBackAppBar(
          title: 'Care Guide',
        ),

        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    18,
                  ),
                  children: [
                    _buildProfileSelector(
                      context,
                    ),

                    _buildCareGuideHero(
                      context,
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    _buildHealthSnapshot(
                      context,
                    ),

                    if (_visualHealthMetrics.isNotEmpty) ...[
                      const SizedBox(
                        height: 18,
                      ),
                      _buildVisualHealthAnalysis(
                        context,
                      ),
                    ],

                    const SizedBox(
                      height: 22,
                    ),

                    Text(
                      '⚡ Quick actions',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(
                      height: 4,
                    ),

                    Text(
                      'Quickly open the health information you use most.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _quickActions.length,
                      gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.45,
                      ),
                      itemBuilder: (
                          context,
                          index,
                          ) {
                        return _buildQuickActionCard(
                          context,
                          _quickActions[index],
                        );
                      },
                    ),

                    const SizedBox(
                      height: 22,
                    ),

                    Text(
                      '✨ Try asking',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildSuggestionChip(
                          context,
                          'Analyze my health today',
                        ),
                        _buildSuggestionChip(
                          context,
                          'Is my blood pressure normal?',
                        ),
                        _buildSuggestionChip(
                          context,
                          'What medicines am I taking?',
                        ),
                        _buildSuggestionChip(
                          context,
                          'Show my latest report',
                        ),
                        _buildSuggestionChip(
                          context,
                          'When is my next medicine?',
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 24,
                    ),

                    Row(
                      children: [
                        Icon(
                          Icons.forum_outlined,
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(
                          width: 8,
                        ),
                        Text(
                          '💬 Conversation',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    ..._messages.map(
                          (
                          message,
                          ) =>
                          _buildMessageBubble(
                            context,
                            message,
                          ),
                    ),
                  ],
                ),
              ),

              _buildMessageInput(
                context,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =====================================================
  // CARE GUIDE HERO
  // =====================================================

  Widget _buildCareGuideHero(
      BuildContext context,
      ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        18,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary,
            colorScheme.primary.withOpacity(
              0.78,
            ),
          ],
        ),
        borderRadius: BorderRadius.circular(
          22,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(
              0.18,
            ),
            blurRadius: 18,
            offset: const Offset(
              0,
              8,
            ),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(
                0.16,
              ),
              borderRadius: BorderRadius.circular(
                16,
              ),
            ),
            child: const Center(
              child: Text(
                '🩺',
                style: TextStyle(
                  fontSize: 28,
                ),
              ),
            ),
          ),

          const SizedBox(
            width: 14,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Care Guide ✨',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(
                  height: 6,
                ),

                Text(
                  'Your personal health companion for $_selectedProfileName 💚\nAsk about medicines, records, readings, reminders and health analysis.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(
                      0.90,
                    ),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // HEALTH SNAPSHOT
  // =====================================================

  Widget _buildHealthSnapshot(
      BuildContext context,
      ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestoreService.healthReadingsStream(
        profileId: _selectedProfileId,
      ),
      builder: (
          context,
          snapshot,
          ) {
        final documents = snapshot.data?.docs ?? [];

        final bloodPressure =
        _latestSnapshotReading(
          documents,
          'bloodPressure',
        );

        final bloodSugar =
        _latestSnapshotReading(
          documents,
          'bloodSugar',
        );

        final spo2 =
        _latestSnapshotReading(
          documents,
          'spo2',
        );

        final heartRate =
        _latestSnapshotReading(
          documents,
          'heartRate',
        );

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(
            16,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(
              20,
            ),
            border: Border.all(
              color: colorScheme.outlineVariant.withOpacity(
                0.65,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(
                        0.10,
                      ),
                      borderRadius: BorderRadius.circular(
                        12,
                      ),
                    ),
                    child: Icon(
                      Icons.monitor_heart_outlined,
                      color: colorScheme.primary,
                      size: 21,
                    ),
                  ),

                  const SizedBox(
                    width: 10,
                  ),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '❤️ Latest Health Snapshot',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(
                          height: 2,
                        ),
                        Text(
                          'For $_selectedProfileName',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color:
                            colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (snapshot.connectionState ==
                      ConnectionState.waiting)
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.primary,
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
                    child: _snapshotMetric(
                      context: context,
                      icon: Icons.favorite_outline_rounded,
                      label: 'BP',
                      accentColor: Colors.redAccent,
                      value: _snapshotValue(
                        'bloodPressure',
                        bloodPressure,
                      ),
                      unit: 'mmHg',
                    ),
                  ),

                  const SizedBox(
                    width: 8,
                  ),

                  Expanded(
                    child: _snapshotMetric(
                      context: context,
                      icon: Icons.water_drop_outlined,
                      label: 'Sugar',
                      accentColor: Colors.orange,
                      value: _snapshotValue(
                        'bloodSugar',
                        bloodSugar,
                      ),
                      unit: 'mg/dL',
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
                    child: _snapshotMetric(
                      context: context,
                      icon: Icons.air_rounded,
                      label: 'SpO₂',
                      accentColor: Colors.blue,
                      value: _snapshotValue(
                        'spo2',
                        spo2,
                      ),
                      unit: '',
                    ),
                  ),

                  const SizedBox(
                    width: 8,
                  ),

                  Expanded(
                    child: _snapshotMetric(
                      context: context,
                      icon: Icons.monitor_heart_outlined,
                      label: 'Heart Rate',
                      accentColor: Colors.pinkAccent,
                      value: _snapshotValue(
                        'heartRate',
                        heartRate,
                      ),
                      unit: 'bpm',
                    ),
                  ),
                ],
              ),

              if (documents.isEmpty &&
                  snapshot.connectionState !=
                      ConnectionState.waiting) ...[
                const SizedBox(
                  height: 12,
                ),
                Text(
                  'No health readings have been recorded for this profile yet.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _snapshotMetric({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color accentColor,
    required String value,
    required String unit,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(
          0.055,
        ),
        borderRadius: BorderRadius.circular(
          14,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: accentColor,
              size: 19,
            ),
          ),

          const SizedBox(
            width: 8,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(
                  height: 3,
                ),

                Text(
                  unit.isEmpty || value == '--'
                      ? value
                      : '$value $unit',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // VISUAL HEALTH ANALYSIS
  // =====================================================

  Widget _buildVisualHealthAnalysis(
      BuildContext context,
      ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final int highestSeverity =
    _visualHealthMetrics.fold<int>(
      0,
          (current, metric) =>
      metric.result.severity > current
          ? metric.result.severity
          : current,
    );

    final Color overallColor =
    _statusColor(highestSeverity);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: overallColor.withOpacity(0.22),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: overallColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Center(
                  child: Text(
                    '📊',
                    style: TextStyle(
                      fontSize: 22,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 11),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Care Guide Health Analysis',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Latest readings for $_selectedProfileName',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            'The colored bar shows how much attention each reading may need — from stable to urgent.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 14),

          ..._visualHealthMetrics.map(
                (metric) => _buildHealthZoneCard(
              context,
              metric,
            ),
          ),

          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(
              bottom: 12,
            ),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.deepPurple.withOpacity(0.07),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.deepPurple.withOpacity(0.16),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '💡',
                  style: TextStyle(
                    fontSize: 25,
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Recommendation',
                        style: TextStyle(
                          color: Colors.deepPurple,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      Text(
                        _overallRecommendation(
                          highestSeverity,
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.055),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: colorScheme.primary,
                  size: 19,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Reference-based guidance only. Care Guide does not diagnose medical conditions or replace your healthcare professional.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthZoneCard(
      BuildContext context,
      _VisualHealthMetric metric,
      ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final HealthAnalysisResult result = metric.result;
    final Color statusColor =
    _statusColor(result.severity);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.65),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  _metricIcon(metric.readingType),
                  color: statusColor,
                  size: 20,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  _readingTitle(metric.readingType),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  result.status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            _readingValueOnly(
              metric.readingType,
              metric.data,
            ),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: colorScheme.onSurface,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            result.summary,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 14),

          LayoutBuilder(
            builder: (
                context,
                constraints,
                ) {
              final double markerPosition =
              _severityMarkerPosition(
                result.severity,
              );

              final double markerLeft =
              (constraints.maxWidth * markerPosition)
                  .clamp(
                8.0,
                constraints.maxWidth - 8.0,
              );

              return Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Row(
                      children: [
                        _zoneSegment(
                          Colors.green,
                        ),
                        _zoneSegment(
                          Colors.amber,
                        ),
                        _zoneSegment(
                          Colors.orange,
                        ),
                        _zoneSegment(
                          Colors.red,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(
                    height: 23,
                    child: Stack(
                      children: [
                        Positioned(
                          left: markerLeft - 10,
                          top: -1,
                          child: Icon(
                            Icons.arrow_drop_up_rounded,
                            size: 28,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),

          Row(
            children: [
              _zoneLabel(
                context,
                'Stable',
              ),
              _zoneLabel(
                context,
                'Watch',
              ),
              _zoneLabel(
                context,
                'Attention',
              ),
              _zoneLabel(
                context,
                'Urgent',
              ),
            ],
          ),

          const SizedBox(height: 12),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              result.guidance,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.42,
              ),
            ),
          ),

          const SizedBox(height: 10),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                _trendIcon(metric.trend),
                size: 18,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  metric.trend,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _zoneSegment(
      Color color,
      ) {
    return Expanded(
      child: Container(
        height: 10,
        color: color,
      ),
    );
  }

  Widget _zoneLabel(
      BuildContext context,
      String text,
      ) {
    return Expanded(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(
          fontSize: 9,
          color: Theme.of(context)
              .colorScheme
              .onSurfaceVariant,
        ),
      ),
    );
  }

  double _severityMarkerPosition(
      int severity,
      ) {
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

  Color _statusColor(
      int severity,
      ) {
    switch (severity) {
      case 0:
        return Colors.green;
      case 1:
        return Colors.amber.shade700;
      case 2:
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  IconData _metricIcon(
      String readingType,
      ) {
    switch (readingType) {
      case 'bloodPressure':
        return Icons.favorite_outline_rounded;
      case 'bloodSugar':
        return Icons.water_drop_outlined;
      case 'heartRate':
        return Icons.monitor_heart_outlined;
      case 'spo2':
        return Icons.air_rounded;
      case 'temperature':
        return Icons.thermostat_outlined;
      case 'weight':
        return Icons.monitor_weight_outlined;
      default:
        return Icons.health_and_safety_outlined;
    }
  }

  String _readingTitle(
      String readingType,
      ) {
    switch (readingType) {
      case 'bloodPressure':
        return 'Blood Pressure';
      case 'bloodSugar':
        return 'Blood Sugar';
      case 'heartRate':
        return 'Heart Rate';
      case 'spo2':
        return 'SpO₂';
      case 'temperature':
        return 'Temperature';
      case 'weight':
        return 'Weight';
      default:
        return 'Health Reading';
    }
  }

  String _readingValueOnly(
      String readingType,
      Map<String, dynamic> data,
      ) {
    switch (readingType) {
      case 'bloodPressure':
        return '${data['systolic'] ?? '--'}/${data['diastolic'] ?? '--'} mmHg';

      case 'bloodSugar':
        final String context =
            data['context']?.toString().trim() ?? '';

        if (context.isEmpty) {
          return '${data['value'] ?? '--'} mg/dL';
        }

        return '${data['value'] ?? '--'} mg/dL • $context';

      case 'heartRate':
        return '${data['value'] ?? '--'} bpm';

      case 'spo2':
        return '${data['value'] ?? '--'}%';

      case 'temperature':
        return '${data['value'] ?? '--'} °C';

      case 'weight':
        return '${data['value'] ?? '--'} kg';

      default:
        return '${data['value'] ?? '--'}';
    }
  }

  IconData _trendIcon(
      String trend,
      ) {
    final String normalized =
    trend.toLowerCase();

    if (normalized.contains('upward')) {
      return Icons.trending_up_rounded;
    }

    if (normalized.contains('downward')) {
      return Icons.trending_down_rounded;
    }

    if (normalized.contains('stable')) {
      return Icons.trending_flat_rounded;
    }

    return Icons.show_chart_rounded;
  }

  // =====================================================
  // QUICK ACTION CARD
  // =====================================================

  Widget _buildQuickActionCard(
      BuildContext context,
      String action,
      ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    late final String emoji;
    late final Color accentColor;
    late final String title;
    late final String subtitle;

    switch (action) {
      case 'Analyze Health':
        emoji = '🩺';
        accentColor = Colors.deepPurple;
        title = 'Analyze Health';
        subtitle = 'Review latest readings';
        break;

      case 'My Medicines':
        emoji = '💊';
        accentColor = Colors.orange;
        title = 'Medicines';
        subtitle = 'Current treatment';
        break;

      case 'My Records':
        emoji = '📁';
        accentColor = Colors.blue;
        title = 'Records';
        subtitle = 'Reports & prescriptions';
        break;

      case 'Health Readings':
        emoji = '📈';
        accentColor = Colors.pinkAccent;
        title = 'Readings';
        subtitle = 'Latest measurements';
        break;

      case 'Reminders':
        emoji = '⏰';
        accentColor = Colors.amber.shade700;
        title = 'Reminders';
        subtitle = 'Medicine schedule';
        break;

      default:
        emoji = '✨';
        accentColor = colorScheme.primary;
        title = action;
        subtitle = '';
    }

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(
        18,
      ),
      child: InkWell(
        onTap: _isLoading
            ? null
            : () {
          _handleQuickAction(
            action,
          );
        },
        borderRadius: BorderRadius.circular(
          18,
        ),
        child: Container(
          padding: const EdgeInsets.all(
            14,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              18,
            ),
            border: Border.all(
              color: accentColor.withOpacity(
                0.18,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 43,
                height: 43,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.11),
                  borderRadius: BorderRadius.circular(
                    13,
                  ),
                ),
                child: Text(
                  emoji,
                  style: const TextStyle(
                    fontSize: 23,
                  ),
                ),
              ),

              const Spacer(),

              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(
                height: 3,
              ),

              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =====================================================
  // SUGGESTION CHIP
  // =====================================================

  Widget _buildSuggestionChip(
      BuildContext context,
      String question,
      ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ActionChip(
      avatar: const Text(
        '✨',
        style: TextStyle(
          fontSize: 16,
        ),
      ),
      label: Text(
        question,
      ),
      backgroundColor: colorScheme.primary.withOpacity(
        0.055,
      ),
      side: BorderSide(
        color: colorScheme.primary.withOpacity(
          0.16,
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          20,
        ),
      ),
      onPressed: _isLoading
          ? null
          : () {
        _askSuggestedQuestion(
          question,
        );
      },
    );
  }

  // =====================================================
  // MESSAGE
  // =====================================================

  Widget _buildMessageBubble(
      BuildContext context,
      _ChatMessage message,
      ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Align(
      alignment: message.isUser
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Row(
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.teal.withOpacity(
                0.10,
              ),
              child: const Text(
                '🩺',
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(
              width: 7,
            ),
          ],

          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(
                  context,
                ).size.width *
                    0.76,
              ),
              margin: const EdgeInsets.only(
                bottom: 12,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 11,
              ),
              decoration: BoxDecoration(
                color: message.isUser
                    ? colorScheme.primary
                    : colorScheme.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(
                    17,
                  ),
                  topRight: const Radius.circular(
                    17,
                  ),
                  bottomLeft: Radius.circular(
                    message.isUser ? 17 : 5,
                  ),
                  bottomRight: Radius.circular(
                    message.isUser ? 5 : 17,
                  ),
                ),
                border: message.isUser
                    ? null
                    : Border.all(
                  color: colorScheme.outlineVariant.withOpacity(
                    0.60,
                  ),
                ),
              ),
              child: message.isLoading
                  ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.primary,
                    ),
                  ),

                  const SizedBox(
                    width: 10,
                  ),

                  Flexible(
                    child: Text(
                      message.message,
                    ),
                  ),
                ],
              )
                  : Text(
                message.message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: message.isUser
                      ? colorScheme.onPrimary
                      : colorScheme.onSurface,
                  height: 1.42,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // INPUT
  // =====================================================

  Widget _buildMessageInput(
      BuildContext context,
      ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        14,
        10,
        14,
        12,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: theme.dividerColor.withOpacity(
              0.5,
            ),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) {
                  _sendMessage();
                },
                decoration: InputDecoration(
                  hintText: 'Ask Care Guide...',
                  prefixIcon: Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: colorScheme.primary,
                  ),
                  filled: true,
                  fillColor: colorScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      24,
                    ),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      24,
                    ),
                    borderSide: BorderSide(
                      color: colorScheme.outlineVariant.withOpacity(
                        0.55,
                      ),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      24,
                    ),
                    borderSide: BorderSide(
                      color: colorScheme.primary,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),

            const SizedBox(
              width: 8,
            ),

            IconButton.filled(
              onPressed: _isLoading
                  ? null
                  : _sendMessage,
              icon: const Icon(
                Icons.send_rounded,
              ),
            ),
          ],
        ),
      ),
    );
  }

}

// =======================================================
// CHAT MESSAGE MODEL
// =======================================================

class _ChatMessage {
  final String message;
  final bool isUser;
  final bool isLoading;

  const _ChatMessage({
    required this.message,
    required this.isUser,
    this.isLoading = false,
  });
}

// =======================================================
// PROFILE CHOICE MODEL
// =======================================================

class _ProfileChoice {
  final String? profileId;
  final String name;
  final String relationship;

  const _ProfileChoice({
    required this.profileId,
    required this.name,
    required this.relationship,
  });
}

// =======================================================
// VISUAL HEALTH METRIC MODEL
// =======================================================

class _VisualHealthMetric {
  final String readingType;
  final Map<String, dynamic> data;
  final HealthAnalysisResult result;
  final String trend;

  const _VisualHealthMetric({
    required this.readingType,
    required this.data,
    required this.result,
    required this.trend,
  });
}

