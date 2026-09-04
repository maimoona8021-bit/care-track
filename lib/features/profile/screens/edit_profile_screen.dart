import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:sehatfile/core/theme/app_colors.dart';
import 'package:sehatfile/core/theme/app_text_styles.dart';
import 'package:sehatfile/features/profile/widgets/profile_page_scaffold.dart';
import 'package:sehatfile/services/auth_service.dart';
import 'package:sehatfile/services/firestore_service.dart';

class EditProfileScreen extends StatefulWidget {
  final String? profileId;

  const EditProfileScreen({
    super.key,
    this.profileId,
  });

  @override
  State<EditProfileScreen> createState() =>
      _EditProfileScreenState();
}

class _EditProfileScreenState
    extends State<EditProfileScreen> {
  final GlobalKey<FormState> _formKey =
  GlobalKey<FormState>();

  final TextEditingController fullNameController =
  TextEditingController();

  final TextEditingController dateOfBirthController =
  TextEditingController();

  final TextEditingController heightController =
  TextEditingController();

  final TextEditingController weightController =
  TextEditingController();

  final FirestoreService _firestoreService =
  FirestoreService();

  final AuthService _authService =
  AuthService();

  String? selectedGender;
  String? selectedBloodGroup;
  String? selectedRelationship;

  bool isLoading = true;
  bool isSaving = false;

  // ==========================================
  // GENDER OPTIONS
  // ==========================================
  final List<String> genders = [
    'Male',
    'Female',
    'Other',
  ];

  // ==========================================
  // BLOOD GROUP OPTIONS
  // ==========================================
  final List<String> bloodGroups = [
    'A positive',
    'A negative',
    'B positive',
    'B negative',
    'AB positive',
    'AB negative',
    'O positive',
    'O negative',
  ];

  // ==========================================
  // RELATIONSHIP OPTIONS
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

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // ==========================================
  // LOAD PROFILE
  // ==========================================
  Future<void> _loadProfile() async {
    try {
      final Map<String, dynamic>? data =
      await _firestoreService.getProfile(
        profileId: widget.profileId,
      );

      if (data == null) {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }

        return;
      }

      // NAME
      fullNameController.text =
          data['fullName']?.toString() ??
              FirebaseAuth
                  .instance
                  .currentUser
                  ?.displayName ??
              '';

      // DATE OF BIRTH
      dateOfBirthController.text =
          data['dateOfBirth']?.toString() ?? '';

      // HEIGHT
      heightController.text =
          data['height']?.toString() ?? '';

      // WEIGHT
      weightController.text =
          data['weight']?.toString() ?? '';

      // ========================================
      // SAFE GENDER
      // ========================================
      final String? savedGender =
      data['gender']?.toString();

      if (savedGender != null &&
          savedGender.isNotEmpty &&
          genders.contains(savedGender)) {
        selectedGender = savedGender;
      } else {
        selectedGender = null;
      }

      // ========================================
      // SAFE BLOOD GROUP
      // ========================================
      final String? savedBloodGroup =
      data['bloodGroup']?.toString();

      if (savedBloodGroup != null &&
          savedBloodGroup.isNotEmpty &&
          bloodGroups.contains(savedBloodGroup)) {
        selectedBloodGroup =
            savedBloodGroup;
      } else {
        selectedBloodGroup = null;
      }

      // ========================================
      // SAFE RELATIONSHIP
      // ========================================
      if (widget.profileId != null) {
        final String? savedRelationship =
        data['relationship']?.toString();

        if (savedRelationship != null &&
            savedRelationship.isNotEmpty &&
            relationships.contains(
              savedRelationship,
            )) {
          selectedRelationship =
              savedRelationship;
        } else {
          selectedRelationship = null;
        }
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Unable to load profile: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // ==========================================
  // FORMAT DATE
  // ==========================================
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

  // ==========================================
  // SELECT DATE
  // ==========================================
  Future<void> _selectDate() async {
    final DateTime? selected =
    await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );

    if (selected != null) {
      setState(() {
        dateOfBirthController.text =
            _formatDate(selected);
      });
    }
  }

  // ==========================================
  // SAVE PROFILE
  // ==========================================
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final String fullName =
      fullNameController.text.trim();

      final Map<String, dynamic> updatedData = {
        'fullName': fullName,
        'dateOfBirth':
        dateOfBirthController.text.trim(),
        'gender':
        selectedGender ?? '',
        'bloodGroup':
        selectedBloodGroup ?? '',
        'height':
        heightController.text.trim(),
        'weight':
        weightController.text.trim(),
      };

      // Relationship is stored only
      // for created profiles.
      if (widget.profileId != null) {
        updatedData['relationship'] =
            selectedRelationship ?? '';
      }

      await _firestoreService.updateProfile(
        profileId: widget.profileId,
        data: updatedData,
      );

      // Change Firebase Auth display name
      // only for main logged-in account.
      if (widget.profileId == null) {
        await _authService.updateDisplayName(
          fullName,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Profile updated successfully.',
          ),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Unable to update profile: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  // ==========================================
  // INPUT DECORATION
  // ==========================================
  InputDecoration _decoration(
      String label,
      ) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,

      enabledBorder: OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(16),
        borderSide: BorderSide(
          color: AppColors.border,
        ),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(16),
        borderSide: BorderSide(
          color: AppColors.primary,
          width: 2,
        ),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Colors.red,
        ),
      ),

      focusedErrorBorder:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 2,
        ),
      ),
    );
  }

  @override
  void dispose() {
    fullNameController.dispose();
    dateOfBirthController.dispose();
    heightController.dispose();
    weightController.dispose();

    super.dispose();
  }

  // ==========================================
  // SCREEN
  // ==========================================
  @override
  Widget build(
      BuildContext context,
      ) {
    return ProfilePageScaffold(
      title: 'Edit Profile',

      body: isLoading
          ? Center(
        child:
        CircularProgressIndicator(
          color: AppColors.primary,
        ),
      )
          : SingleChildScrollView(
        padding:
        const EdgeInsets.all(18),

        child: Form(
          key: _formKey,

          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,

            children: [
              Text(
                'Personal Information',
                style: AppTextStyles
                    .titleLarge
                    .copyWith(
                  fontWeight:
                  FontWeight.w700,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                'Update personal and basic health details.',
                style: AppTextStyles
                    .bodySmall
                    .copyWith(
                  color:
                  AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 22),

              // ==================================
              // FULL NAME
              // ==================================
              TextFormField(
                controller:
                fullNameController,

                textCapitalization:
                TextCapitalization.words,

                decoration:
                _decoration(
                  'Full name',
                ).copyWith(
                  prefixIcon: Icon(
                    Icons.person_outline,
                    color:
                    AppColors.primary,
                  ),
                ),

                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'Please enter full name.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 15),

              // ==================================
              // EMAIL - MAIN USER ONLY
              // ==================================
              if (widget.profileId ==
                  null) ...[
                TextFormField(
                  initialValue:
                  FirebaseAuth
                      .instance
                      .currentUser
                      ?.email ??
                      '',
                  enabled: false,
                  decoration:
                  _decoration(
                    'Email',
                  ).copyWith(
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      color:
                      AppColors.primary,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 15,
                ),
              ],

              // ==================================
              // RELATIONSHIP
              // ==================================
              if (widget.profileId ==
                  null)
                TextFormField(
                  initialValue: 'Self',
                  enabled: false,
                  decoration:
                  _decoration(
                    'Relationship',
                  ).copyWith(
                    prefixIcon: Icon(
                      Icons
                          .family_restroom_rounded,
                      color:
                      AppColors.primary,
                    ),
                  ),
                )
              else
                DropdownButtonFormField<String>(
                  initialValue: selectedRelationship,

                  isExpanded: true,

                  decoration:
                  _decoration(
                    'Relationship',
                  ).copyWith(
                    prefixIcon: Icon(
                      Icons
                          .family_restroom_rounded,
                      color:
                      AppColors.primary,
                    ),
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

                  validator: (value) {
                    if (value == null ||
                        value.isEmpty) {
                      return 'Please select relationship.';
                    }

                    return null;
                  },
                ),

              const SizedBox(height: 15),

              // ==================================
              // DOB
              // ==================================
              TextFormField(
                controller:
                dateOfBirthController,

                readOnly: true,

                onTap: _selectDate,

                decoration:
                _decoration(
                  'Date of birth',
                ).copyWith(
                  prefixIcon: Icon(
                    Icons
                        .calendar_month_outlined,
                    color:
                    AppColors.primary,
                  ),
                  suffixIcon:
                  const Icon(
                    Icons
                        .keyboard_arrow_down_rounded,
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // ==================================
              // GENDER
              // ==================================
              DropdownButtonFormField<String>(
                initialValue: selectedGender,

                isExpanded: true,

                decoration:
                _decoration(
                  'Gender',
                ).copyWith(
                  prefixIcon: Icon(
                    Icons.people_outline,
                    color:
                    AppColors.primary,
                  ),
                ),

                items: genders
                    .map(
                      (gender) =>
                      DropdownMenuItem<
                          String>(
                        value: gender,
                        child: Text(
                          gender,
                        ),
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

              // ==================================
              // BLOOD GROUP
              // ==================================
              DropdownButtonFormField<String>(
                initialValue: selectedBloodGroup,

                isExpanded: true,

                decoration:
                _decoration(
                  'Blood group',
                ).copyWith(
                  prefixIcon:
                  const Icon(
                    Icons
                        .bloodtype_outlined,
                    color:
                    Colors.red,
                  ),
                ),

                items: bloodGroups
                    .map(
                      (group) =>
                      DropdownMenuItem<
                          String>(
                        value: group,
                        child:
                        Text(group),
                      ),
                )
                    .toList(),

                onChanged: (value) {
                  setState(() {
                    selectedBloodGroup =
                        value;
                  });
                },
              ),

              const SizedBox(height: 15),

              // ==================================
              // HEIGHT
              // ==================================
              TextFormField(
                controller:
                heightController,

                keyboardType:
                const TextInputType
                    .numberWithOptions(
                  decimal: true,
                ),

                decoration:
                _decoration(
                  'Height (e.g. 5.4 ft)',
                ).copyWith(
                  prefixIcon: Icon(
                    Icons
                        .straighten_outlined,
                    color:
                    AppColors.primary,
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // ==================================
              // WEIGHT
              // ==================================
              TextFormField(
                controller:
                weightController,

                keyboardType:
                const TextInputType
                    .numberWithOptions(
                  decimal: true,
                ),

                decoration:
                _decoration(
                  'Weight (e.g. 78 kg)',
                ).copyWith(
                  prefixIcon: Icon(
                    Icons
                        .monitor_weight_outlined,
                    color:
                    AppColors.primary,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ==================================
              // SAVE BUTTON
              // ==================================
              SizedBox(
                width: double.infinity,
                height: 54,

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

                  onPressed:
                  isSaving
                      ? null
                      : _saveProfile,

                  icon: isSaving
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child:
                    CircularProgressIndicator(
                      color:
                      Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Icon(
                    Icons.save_outlined,
                  ),

                  label: Text(
                    isSaving
                        ? 'Saving...'
                        : 'Save Changes',

                    style:
                    const TextStyle(
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
    );
  }
}