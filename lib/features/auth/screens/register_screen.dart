import 'login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';



import 'package:sehatfile/core/theme/app_colors.dart';
import 'package:sehatfile/core/theme/app_text_styles.dart';
import 'package:sehatfile/core/widgets/custom_button.dart';
import 'package:sehatfile/core/widgets/custom_text_field.dart';
import 'package:sehatfile/services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;
  bool _isLoading = false;
  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();

    super.dispose();
  }

  Future<void> _createAccount() async {
    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please agree to the Terms of Service and Privacy Policy.',
          ),
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await AuthService().createAccount(
        fullName: fullNameController.text,
        email: emailController.text,
        password: passwordController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created successfully!'),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message = 'Unable to create account.';

      if (e.code == 'weak-password') {
        message = 'Your password is too weak.';
      } else if (e.code == 'email-already-in-use') {
        message = 'This email already has an account.';
      } else if (e.code == 'invalid-email') {
        message = 'Please enter a valid email.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 22,
            vertical: 24,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --------------------------------
                // CARE TRACK BRAND
                // --------------------------------
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.monitor_heart_outlined,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),

                    const SizedBox(width: 10),

                    Text(
                      'Care Track',
                      style: AppTextStyles.titleLarge.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 34),

                // --------------------------------
                // TITLE
                // --------------------------------
                Text(
                  'Create your account',
                  style: AppTextStyles.headingLarge.copyWith(
                    color: AppColors.primaryDark,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Set up your family\'s private health record\n'
                      'in a few steps.',
                  style: AppTextStyles.bodyMedium,
                ),

                const SizedBox(height: 28),

                // --------------------------------
                // FULL NAME
                // --------------------------------
                CustomTextField(
                  label: 'Full name',
                  hintText: 'Full name',
                  controller: fullNameController,
                  prefixIcon: Icons.person_outline,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your full name';
                    }

                    if (value.trim().length < 2) {
                      return 'Please enter a valid name';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 18),

                // --------------------------------
                // EMAIL
                // --------------------------------
                CustomTextField(
                  label: 'Email',
                  hintText: 'you@example.com',
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your email';
                    }

                    if (!value.contains('@') ||
                        !value.contains('.')) {
                      return 'Please enter a valid email';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 18),

                // --------------------------------
                // PASSWORD
                // --------------------------------
                CustomTextField(
                  label: 'Password',
                  hintText: 'Create a password',
                  controller: passwordController,
                  prefixIcon: Icons.lock_outline,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please create a password';
                    }

                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }

                    return null;
                  },
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // --------------------------------
                // CONFIRM PASSWORD
                // --------------------------------
                CustomTextField(
                  label: 'Confirm password',
                  hintText: 'Re-enter your password',
                  controller: confirmPasswordController,
                  prefixIcon: Icons.lock_outline,
                  obscureText: _obscureConfirmPassword,
                  textInputAction: TextInputAction.done,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }

                    if (value != passwordController.text) {
                      return 'Passwords do not match';
                    }

                    return null;
                  },
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword =
                        !_obscureConfirmPassword;
                      });
                    },
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // --------------------------------
                // TERMS
                // --------------------------------
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _agreeToTerms,
                        activeColor: AppColors.primary,
                        onChanged: (value) {
                          setState(() {
                            _agreeToTerms = value ?? false;
                          });
                        },
                      ),
                    ),

                    const SizedBox(width: 9),

                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          style: AppTextStyles.bodySmall,
                          children: [
                            const TextSpan(
                              text: 'I agree to the ',
                            ),

                            TextSpan(
                              text: 'Terms of Service',
                              style:
                              AppTextStyles.bodySmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            const TextSpan(
                              text: ' and ',
                            ),

                            TextSpan(
                              text: 'Privacy Policy',
                              style:
                              AppTextStyles.bodySmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // --------------------------------
                // CREATE ACCOUNT
                // --------------------------------
                CustomButton(
                  text: 'Create account',
                  onPressed: _createAccount,
                  isLoading: _isLoading,
                ),

                const SizedBox(height: 18),

                // --------------------------------
                // SIGN IN
                // --------------------------------
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account?',
                      style: AppTextStyles.bodyMedium,
                    ),

                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Login',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}