import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:sehatfile/core/theme/app_colors.dart';
import 'package:sehatfile/features/profile/widgets/profile_page_scaffold.dart';
import 'package:sehatfile/services/auth_service.dart';

class ChangePasswordScreen
    extends StatefulWidget {
  const ChangePasswordScreen({
    super.key,
  });

  @override
  State<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState
    extends State<ChangePasswordScreen> {
  final _formKey =
  GlobalKey<FormState>();

  final currentPasswordController =
  TextEditingController();

  final newPasswordController =
  TextEditingController();

  final confirmPasswordController =
  TextEditingController();

  final AuthService _authService =
  AuthService();

  bool isLoading = false;

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (newPasswordController.text !=
        confirmPasswordController.text) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Passwords do not match.',
          ),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await _authService.changePassword(
        currentPassword:
        currentPasswordController.text,
        newPassword:
        newPasswordController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Password changed successfully.',
          ),
        ),
      );

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message =
          'Unable to change password.';

      if (e.code ==
          'wrong-password' ||
          e.code ==
              'invalid-credential') {
        message =
        'Current password is incorrect.';
      } else if (e.code ==
          'weak-password') {
        message =
        'New password is too weak.';
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(message),
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

  @override
  void dispose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ProfilePageScaffold(
      title: 'Change Password',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller:
                currentPasswordController,
                obscureText: true,
                decoration:
                const InputDecoration(
                  labelText:
                  'Current password',
                  prefixIcon:
                  Icon(Icons.lock_outline),
                ),
                validator: (value) {
                  if (value == null ||
                      value.isEmpty) {
                    return 'Enter current password';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 18),

              TextFormField(
                controller:
                newPasswordController,
                obscureText: true,
                decoration:
                const InputDecoration(
                  labelText: 'New password',
                  prefixIcon:
                  Icon(Icons.password),
                ),
                validator: (value) {
                  if (value == null ||
                      value.length < 6) {
                    return 'Use at least 6 characters';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 18),

              TextFormField(
                controller:
                confirmPasswordController,
                obscureText: true,
                decoration:
                const InputDecoration(
                  labelText:
                  'Confirm password',
                  prefixIcon:
                  Icon(Icons.password),
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  style:
                  FilledButton.styleFrom(
                    backgroundColor:
                    AppColors.primary,
                  ),
                  onPressed: isLoading
                      ? null
                      : _changePassword,
                  child: const Text(
                    'Update Password',
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