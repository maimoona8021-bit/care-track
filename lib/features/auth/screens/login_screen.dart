import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:sehatfile/services/auth_service.dart';
import 'package:sehatfile/core/theme/app_colors.dart';
import 'package:sehatfile/core/theme/app_text_styles.dart';
import 'package:sehatfile/core/widgets/custom_button.dart';
import 'package:sehatfile/core/widgets/custom_text_field.dart';
import 'package:sehatfile/core/routes/app_routes.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
  });

  @override
  State<LoginScreen> createState() =>
      _LoginScreenState();
}

class _LoginScreenState
    extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey =
  GlobalKey<FormState>();

  final TextEditingController
  emailController =
  TextEditingController();

  final TextEditingController
  passwordController =
  TextEditingController();

  final AuthService _authService =
  AuthService();

  bool _obscurePassword = true;

  bool _isLoading = false;

  bool _isGoogleLoading = false;

  // =====================================================
  // DISPOSE
  // =====================================================

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();

    super.dispose();
  }

  // =====================================================
  // EMAIL SIGN IN
  // =====================================================

  Future<void> _signIn() async {
    if (_isLoading ||
        _isGoogleLoading) {
      return;
    }

    if (!_formKey.currentState!
        .validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.signIn(
        email:
        emailController.text.trim(),
        password:
        passwordController.text,
      );

      if (!mounted) {
        return;
      }

      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.home,
            (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) {
        return;
      }

      String message =
          'Unable to sign in.';

      if (e.code ==
          'invalid-credential') {
        message =
        'Email or password is incorrect.';
      } else if (e.code ==
          'invalid-email') {
        message =
        'Please enter a valid email.';
      } else if (e.code ==
          'too-many-requests') {
        message =
        'Too many attempts. Please try again later.';
      } else if (e.code ==
          'network-request-failed') {
        message =
        'Please check your internet connection.';
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content:
          Text(message),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Something went wrong. Please try again.',
          ),
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

  // =====================================================
  // GOOGLE SIGN IN
  // =====================================================

  Future<void> _signInWithGoogle() async {
    if (_isGoogleLoading ||
        _isLoading) {
      return;
    }

    setState(() {
      _isGoogleLoading = true;
    });

    try {
      await _authService
          .signInWithGoogle();

      if (!mounted) {
        return;
      }

      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.home,
            (route) => false,
      );
    }

    // ===================================================
    // GOOGLE SIGN-IN ERRORS
    // ===================================================

    on GoogleSignInException catch (e) {
      if (!mounted) {
        return;
      }

      // User intentionally closed/cancelled
      // the Google account picker.
      if (e.code ==
          GoogleSignInExceptionCode
              .canceled) {
        return;
      }

      String message =
          'Unable to sign in with Google.';

      if (e.code ==
          GoogleSignInExceptionCode
              .clientConfigurationError) {
        message =
        'Google Sign-In is not configured correctly.';
      } else if (e.code ==
          GoogleSignInExceptionCode
              .providerConfigurationError) {
        message =
        'Google Sign-In is currently unavailable.';
      } else if (e.code ==
          GoogleSignInExceptionCode
              .uiUnavailable) {
        message =
        'Google Sign-In could not open. Please try again.';
      } else if (e.code ==
          GoogleSignInExceptionCode
              .interrupted) {
        message =
        'Google Sign-In was interrupted. Please try again.';
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content:
          Text(message),
        ),
      );
    }

    // ===================================================
    // FIREBASE ERRORS
    // ===================================================

    on FirebaseAuthException catch (e) {
      if (!mounted) {
        return;
      }

      String message =
          'Unable to sign in with Google.';

      if (e.code ==
          'account-exists-with-different-credential') {
        message =
        'An account with this email already exists using another sign-in method.';
      } else if (e.code ==
          'operation-not-allowed') {
        message =
        'Google Sign-In is not enabled in Firebase.';
      } else if (e.code ==
          'network-request-failed') {
        message =
        'Please check your internet connection.';
      } else if (e.code ==
          'too-many-requests') {
        message =
        'Too many attempts. Please try again later.';
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content:
          Text(message),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Something went wrong with Google Sign-In. Please try again.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGoogleLoading =
          false;
        });
      }
    }
  }

  // =====================================================
  // FORGOT PASSWORD
  // =====================================================

  Future<void> _forgotPassword() async {
    final String email =
    emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Enter your email address first.',
          ),
        ),
      );

      return;
    }

    if (!email.contains('@') ||
        !email.contains('.')) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter a valid email address.',
          ),
        ),
      );

      return;
    }

    try {
      await _authService.resetPassword(
        email:
        email,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Password reset email sent. Check your inbox.',
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) {
        return;
      }

      String message =
          'Unable to send password reset email.';

      if (e.code ==
          'invalid-email') {
        message =
        'Please enter a valid email.';
      } else if (e.code ==
          'too-many-requests') {
        message =
        'Too many attempts. Try again later.';
      } else if (e.code ==
          'network-request-failed') {
        message =
        'Please check your internet connection.';
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content:
          Text(message),
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

      body: SafeArea(
        child:
        SingleChildScrollView(
          padding:
          const EdgeInsets.symmetric(
            horizontal:
            22,
            vertical:
            24,
          ),

          child: Form(
            key:
            _formKey,

            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                // =====================================
                // CARE TRACK BRAND
                // =====================================

                Row(
                  children: [
                    Container(
                      width:
                      34,
                      height:
                      34,
                      decoration:
                      BoxDecoration(
                        color:
                        AppColors.primary,
                        borderRadius:
                        BorderRadius.circular(
                          6,
                        ),
                      ),
                      child:
                      const Icon(
                        Icons.monitor_heart_outlined,
                        color:
                        Colors.white,
                        size:
                        22,
                      ),
                    ),

                    const SizedBox(
                      width:
                      10,
                    ),

                    Text(
                      'Care Track',
                      style:
                      AppTextStyles.titleLarge
                          .copyWith(
                        color:
                        AppColors.primary,
                        fontWeight:
                        FontWeight.w700,
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height:
                  34,
                ),

                // =====================================
                // HEADING
                // =====================================

                Text(
                  'Welcome back',
                  style:
                  AppTextStyles.headingLarge
                      .copyWith(
                    color:
                    AppColors.primaryDark,
                  ),
                ),

                const SizedBox(
                  height:
                  8,
                ),

                Text(
                  'Sign in to keep your family\'s health records\n'
                      'secure and up to date.',
                  style:
                  AppTextStyles.bodyMedium,
                ),

                const SizedBox(
                  height:
                  30,
                ),

                // =====================================
                // EMAIL
                // =====================================

                CustomTextField(
                  label:
                  'Email',
                  hintText:
                  'you@example.com',
                  controller:
                  emailController,
                  keyboardType:
                  TextInputType.emailAddress,
                  prefixIcon:
                  Icons.email_outlined,
                  textInputAction:
                  TextInputAction.next,

                  validator:
                      (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Please enter your email';
                    }

                    if (!value.contains('@') ||
                        !value.contains('.')) {
                      return 'Please enter a valid email';
                    }

                    return null;
                  },
                ),

                const SizedBox(
                  height:
                  18,
                ),

                // =====================================
                // PASSWORD
                // =====================================

                CustomTextField(
                  label:
                  'Password',
                  hintText:
                  'Enter your password',
                  controller:
                  passwordController,
                  prefixIcon:
                  Icons.lock_outline,
                  obscureText:
                  _obscurePassword,
                  textInputAction:
                  TextInputAction.done,

                  validator:
                      (value) {
                    if (value == null ||
                        value.isEmpty) {
                      return 'Please enter your password';
                    }

                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }

                    return null;
                  },

                  suffixIcon:
                  IconButton(
                    onPressed:
                        () {
                      setState(() {
                        _obscurePassword =
                        !_obscurePassword;
                      });
                    },
                    icon:
                    Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color:
                      AppColors.textSecondary,
                    ),
                  ),
                ),

                const SizedBox(
                  height:
                  4,
                ),

                // =====================================
                // FORGOT PASSWORD
                // =====================================

                Align(
                  alignment:
                  Alignment.centerRight,
                  child:
                  TextButton(
                    onPressed:
                    _forgotPassword,
                    child:
                    Text(
                      'Forgot password?',
                      style:
                      AppTextStyles.bodySmall
                          .copyWith(
                        color:
                        AppColors.primary,
                        fontWeight:
                        FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(
                  height:
                  10,
                ),

                // =====================================
                // EMAIL SIGN IN
                // =====================================

                CustomButton(
                  text:
                  'Sign in',
                  onPressed:
                  _signIn,
                  isLoading:
                  _isLoading,
                ),

                const SizedBox(
                  height:
                  28,
                ),

                // =====================================
                // DIVIDER
                // =====================================

                Row(
                  children: [
                    const Expanded(
                      child:
                      Divider(
                        color:
                        AppColors.divider,
                      ),
                    ),

                    Padding(
                      padding:
                      const EdgeInsets.symmetric(
                        horizontal:
                        12,
                      ),
                      child:
                      Text(
                        'OR CONTINUE WITH',
                        style:
                        AppTextStyles.bodySmall
                            .copyWith(
                          color:
                          AppColors.textLight,
                          fontSize:
                          10,
                          fontWeight:
                          FontWeight.w600,
                        ),
                      ),
                    ),

                    const Expanded(
                      child:
                      Divider(
                        color:
                        AppColors.divider,
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height:
                  22,
                ),

                // =====================================
                // GOOGLE
                // =====================================

                SizedBox(
                  width:
                  double.infinity,
                  height:
                  52,

                  child:
                  OutlinedButton(
                    onPressed:
                    _isGoogleLoading ||
                        _isLoading
                        ? null
                        : _signInWithGoogle,

                    style:
                    OutlinedButton.styleFrom(
                      side:
                      const BorderSide(
                        color:
                        AppColors.border,
                      ),
                      shape:
                      RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(
                          12,
                        ),
                      ),
                    ),

                    child:
                    _isGoogleLoading
                        ? SizedBox(
                      width:
                      21,
                      height:
                      21,
                      child:
                      CircularProgressIndicator(
                        strokeWidth:
                        2,
                        color:
                        AppColors.primary,
                      ),
                    )
                        : Row(
                      mainAxisAlignment:
                      MainAxisAlignment.center,
                      children: [
                        Text(
                          'G',
                          style:
                          AppTextStyles.titleLarge
                              .copyWith(
                            color:
                            AppColors.textPrimary,
                            fontWeight:
                            FontWeight.w700,
                          ),
                        ),

                        const SizedBox(
                          width:
                          10,
                        ),

                        Text(
                          'Continue with Google',
                          style:
                          AppTextStyles.bodyMedium
                              .copyWith(
                            color:
                            AppColors.textPrimary,
                            fontWeight:
                            FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(
                  height:
                  55,
                ),

                // =====================================
                // SIGN UP
                // =====================================

                Row(
                  mainAxisAlignment:
                  MainAxisAlignment.center,
                  children: [
                    Text(
                      'Don\'t have an account?',
                      style:
                      AppTextStyles.bodyMedium,
                    ),

                    TextButton(
                      onPressed:
                          () {
                        Navigator.pushReplacementNamed(
                          context,
                          AppRoutes.register,
                        );
                      },
                      child:
                      Text(
                        'Sign up',
                        style:
                        AppTextStyles.bodyMedium
                            .copyWith(
                          color:
                          AppColors.primary,
                          fontWeight:
                          FontWeight.w700,
                        ),
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