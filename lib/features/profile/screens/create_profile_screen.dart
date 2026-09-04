import 'package:flutter/material.dart';

import 'package:sehatfile/core/routes/app_routes.dart';
import 'package:sehatfile/core/theme/app_colors.dart';
import 'package:sehatfile/core/theme/app_text_styles.dart';


import 'package:sehatfile/services/firestore_service.dart';

class CreateProfileScreen extends StatefulWidget {
  const CreateProfileScreen({
    super.key,
  });

  @override
  State<CreateProfileScreen> createState() =>
      _CreateProfileScreenState();
}

class _CreateProfileScreenState
    extends State<CreateProfileScreen> {
  final GlobalKey<FormState> _formKey =
  GlobalKey<FormState>();

  final TextEditingController fullNameController =
  TextEditingController();

  final TextEditingController dateOfBirthController =
  TextEditingController();

  final FirestoreService _firestoreService =
  FirestoreService();

  String? selectedRelationship;
  String? selectedGender;

  bool isCreating = false;

  // ==========================================
  // RELATIONSHIPS
  // ==========================================
  final List<String> relationships = [
    'Father',
    'Mother',
    'Spouse',
    'Son',
    'Daughter',
    'Brother',
    'Sister',
    'Other',
  ];

  // ==========================================
  // GENDER
  // ==========================================
  final List<String> genders = [
    'Male',
    'Female',
    'Other',
  ];

  // ==========================================
  // INPUT FIELD DESIGN
  // ==========================================
  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,

      prefixIcon: Icon(
        icon,
        color: AppColors.primary,
      ),

      filled: true,
      fillColor: Colors.white,

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: AppColors.border,
        ),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: AppColors.primary,
          width: 2,
        ),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Colors.red,
        ),
      ),

      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 2,
        ),
      ),
    );
  }

  // ==========================================
  // FORMAT DATE
  // ==========================================
  String _formatDate(DateTime date) {
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

  // ==========================================
  // SELECT DATE OF BIRTH
  // ==========================================
  Future<void> _selectDate() async {
    final DateTime? selectedDate =
    await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );

    if (selectedDate != null) {
      setState(() {
        dateOfBirthController.text =
            _formatDate(selectedDate);
      });
    }
  }

  // ==========================================
  // CREATE PROFILE
  // ==========================================
  Future<void> _createProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (selectedRelationship == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select a relationship.',
          ),
        ),
      );

      return;
    }

    if (selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select gender.',
          ),
        ),
      );

      return;
    }

    setState(() {
      isCreating = true;
    });

    try {
      await _firestoreService.createProfile(
        fullName:
        fullNameController.text.trim(),
        relationship:
        selectedRelationship!,
        gender:
        selectedGender!,
        dateOfBirth:
        dateOfBirthController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Profile created successfully.',
          ),
        ),
      );

      // Return to Profiles Screen
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to create profile: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isCreating = false;
        });
      }
    }
  }

  // ==========================================
  // DISPOSE CONTROLLERS
  // ==========================================
  @override
  void dispose() {
    fullNameController.dispose();
    dateOfBirthController.dispose();

    super.dispose();
  }

  // ==========================================
  // SCREEN
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      AppColors.background,

      // ========================================
      // BODY
      // ========================================
      body: SafeArea(
        child: Column(
          children: [
            // ==================================
            // HEADER
            // ==================================
            Container(
              width: double.infinity,

              padding: const EdgeInsets.fromLTRB(
                18,
                16,
                18,
                26,
              ),

              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryDark,
                    AppColors.primary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),

                borderRadius:
                const BorderRadius.only(
                  bottomLeft:
                  Radius.circular(30),
                  bottomRight:
                  Radius.circular(30),
                ),
              ),

              child: Column(
                children: [
                  // ==============================
                  // TOP BAR
                  // ==============================
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius:
                          BorderRadius.circular(
                            12,
                          ),
                        ),

                        child: IconButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },

                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                          ),
                        ),
                      ),

                      Expanded(
                        child: Text(
                          'Create Profile',

                          textAlign:
                          TextAlign.center,

                          style: AppTextStyles
                              .titleLarge
                              .copyWith(
                            color: Colors.white,
                            fontWeight:
                            FontWeight.w700,
                          ),
                        ),
                      ),

                      const SizedBox(
                        width: 48,
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  // ==============================
                  // PROFILE ICON
                  // ==============================
                  Container(
                    width: 86,
                    height: 86,

                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,

                      border: Border.all(
                        color: Colors.white54,
                        width: 4,
                      ),
                    ),

                    child: Icon(
                      Icons
                          .person_add_alt_1_rounded,
                      color: AppColors.primary,
                      size: 40,
                    ),
                  ),

                  const SizedBox(height: 14),

                  Text(
                    'Add a new health profile',

                    style: AppTextStyles
                        .titleMedium
                        .copyWith(
                      color: Colors.white,
                      fontWeight:
                      FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    'Create a separate profile for a family member.',

                    textAlign:
                    TextAlign.center,

                    style: AppTextStyles
                        .bodySmall
                        .copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            // ==================================
            // FORM
            // ==================================
            Expanded(
              child: SingleChildScrollView(
                padding:
                const EdgeInsets.all(18),

                child: Form(
                  key: _formKey,

                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,

                    children: [
                      // ============================
                      // TITLE
                      // ============================
                      Text(
                        'BASIC INFORMATION',

                        style: AppTextStyles
                            .bodySmall
                            .copyWith(
                          color:
                          AppColors.primaryDark,
                          fontWeight:
                          FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ============================
                      // FULL NAME
                      // ============================
                      TextFormField(
                        controller:
                        fullNameController,

                        textCapitalization:
                        TextCapitalization.words,

                        decoration:
                        _inputDecoration(
                          label: 'Full name',
                          icon:
                          Icons.person_outline,
                        ),

                        validator: (value) {
                          if (value == null ||
                              value
                                  .trim()
                                  .isEmpty) {
                            return 'Please enter full name.';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 15),

                      // ============================
                      // RELATIONSHIP
                      // ============================
                      DropdownButtonFormField<String>(
                        initialValue: selectedRelationship,

                        decoration:
                        _inputDecoration(
                          label: 'Relationship',
                          icon: Icons
                              .family_restroom_rounded,
                        ),

                        items: relationships
                            .map(
                              (relationship) =>
                              DropdownMenuItem<
                                  String>(
                                value:
                                relationship,

                                child: Text(
                                  relationship,
                                ),
                              ),
                        )
                            .toList(),

                        onChanged: (value) {
                          setState(() {
                            selectedRelationship =
                                value;
                          });
                        },
                      ),

                      const SizedBox(height: 15),

                      // ============================
                      // GENDER
                      // ============================
                      DropdownButtonFormField<String>(
                        initialValue: selectedGender,

                        decoration:
                        _inputDecoration(
                          label: 'Gender',
                          icon:
                          Icons.people_outline,
                        ),

                        items: genders
                            .map(
                              (gender) =>
                              DropdownMenuItem<
                                  String>(
                                value: gender,

                                child:
                                Text(gender),
                              ),
                        )
                            .toList(),

                        onChanged: (value) {
                          setState(() {
                            selectedGender =
                                value;
                          });
                        },
                      ),

                      const SizedBox(height: 15),

                      // ============================
                      // DATE OF BIRTH
                      // ============================
                      TextFormField(
                        controller:
                        dateOfBirthController,

                        readOnly: true,

                        onTap: _selectDate,

                        decoration:
                        _inputDecoration(
                          label:
                          'Date of birth',
                          icon: Icons
                              .calendar_month_outlined,
                        ).copyWith(
                          suffixIcon:
                          const Icon(
                            Icons
                                .keyboard_arrow_down_rounded,
                          ),
                        ),

                        validator: (value) {
                          if (value == null ||
                              value.isEmpty) {
                            return 'Please select date of birth.';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 22),

                      // ============================
                      // INFORMATION CARD
                      // ============================
                      Container(
                        width: double.infinity,

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
                            Container(
                              width: 42,
                              height: 42,

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
                                Icons
                                    .health_and_safety_outlined,
                                color: AppColors
                                    .primary,
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
                                    'Health details',

                                    style: AppTextStyles
                                        .bodyMedium
                                        .copyWith(
                                      fontWeight:
                                      FontWeight
                                          .w700,
                                    ),
                                  ),

                                  const SizedBox(
                                    height: 4,
                                  ),

                                  Text(
                                    'Blood group, height and weight can be added later from Edit Profile.',

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
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      // ============================
                      // CREATE PROFILE BUTTON
                      // ============================
                      SizedBox(
                        width: double.infinity,
                        height: 55,

                        child: FilledButton.icon(
                          style:
                          FilledButton.styleFrom(
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

                          onPressed: isCreating
                              ? null
                              : _createProfile,

                          icon: isCreating
                              ? const SizedBox(
                            width: 20,
                            height: 20,

                            child:
                            CircularProgressIndicator(
                              strokeWidth: 2,
                              color:
                              Colors.white,
                            ),
                          )
                              : const Icon(
                            Icons
                                .person_add_alt_1_rounded,
                          ),

                          label: Text(
                            isCreating
                                ? 'Creating Profile...'
                                : 'Create Profile',

                            style: const TextStyle(
                              fontWeight:
                              FontWeight.w700,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      // ========================================
      // SAME BOTTOM NAVIGATION
      // ========================================

    );
  }
}
