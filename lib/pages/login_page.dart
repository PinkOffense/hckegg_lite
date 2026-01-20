// lib/pages/login_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/locale_provider.dart';
import '../l10n/translations.dart';
import '../services/auth_service.dart';
import '../widgets/accessible_text_field.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtl = TextEditingController();
  final _passCtl = TextEditingController();
  final _emailFocus = FocusNode();
  final _passFocus = FocusNode();

  bool _loading = false;
  bool _isSignup = false;
  String? _emailError;
  String? _passError;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailCtl.dispose();
    _passCtl.dispose();
    _emailFocus.dispose();
    _passFocus.dispose();
    super.dispose();
  }

  void _showMessage(String msg, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
  }

  bool _validateForm() {
    setState(() {
      _emailError = null;
      _passError = null;
    });

    bool isValid = true;
    final email = _emailCtl.text.trim();
    final pass = _passCtl.text;

    // Email validation
    if (email.isEmpty) {
      setState(() => _emailError = 'Please enter your email');
      isValid = false;
    } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      setState(() => _emailError = 'Please enter a valid email');
      isValid = false;
    }

    // Password validation
    if (pass.isEmpty) {
      setState(() => _passError = 'Please enter your password');
      isValid = false;
    } else if (_isSignup && pass.length < 6) {
      setState(() => _passError = 'Password must be at least 6 characters');
      isValid = false;
    }

    return isValid;
  }

  Future<void> _submit() async {
    // Validate form
    if (!_validateForm()) {
      // Announce error for screen readers
      _showMessage('Please correct the errors in the form', isError: true);
      return;
    }

    // Unfocus to hide keyboard
    FocusScope.of(context).unfocus();

    setState(() => _loading = true);

    final supabase = Supabase.instance.client;
    final auth = AuthService(supabase);
    final email = _emailCtl.text.trim();
    final pass = _passCtl.text;

    try {
      if (_isSignup) {
        final res = await auth.signUp(email, pass);
        if (res.session != null) {
          _showMessage('Account created successfully!');
        } else {
          _showMessage(
            'Account created! Please check your email to verify.',
          );
        }
      } else {
        final res = await auth.signIn(email, pass);
        if (res.session == null) {
          _showMessage('Login failed. Please try again.', isError: true);
        } else {
          _showMessage('Welcome back!');
        }
      }
    } on AuthException catch (e) {
      _showMessage(e.message, isError: true);
    } catch (e) {
      _showMessage('An error occurred. Please try again.', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toggleMode() {
    setState(() {
      _isSignup = !_isSignup;
      _emailError = null;
      _passError = null;
    });

    // Replay animation when switching modes
    _animationController.reset();
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final locale = Provider.of<LocaleProvider>(context).code;
    final t = (String k, {Map<String, String>? params}) =>
        Translations.of(locale, k, params: params);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // App logo/icon
                        Hero(
                          tag: 'app_logo',
                          child: Container(
                            height: 80,
                            width: 80,
                            margin: const EdgeInsets.only(bottom: 24),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.egg_outlined,
                              size: 48,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),

                        // Title
                        Text(
                          t('app_title'),
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),

                        // Subtitle
                        Text(
                          _isSignup ? t('create_account') : t('login'),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 40),

                        // Email field
                        EmailField(
                          controller: _emailCtl,
                          label: t('email'),
                          errorText: _emailError,
                          autofocus: true,
                          textInputAction: TextInputAction.next,
                          focusNode: _emailFocus,
                          onChanged: (_) {
                            if (_emailError != null) {
                              setState(() => _emailError = null);
                            }
                          },
                        ),
                        const SizedBox(height: 16),

                        // Password field
                        PasswordField(
                          controller: _passCtl,
                          label: t('password'),
                          hint: _isSignup ? 'At least 6 characters' : null,
                          errorText: _passError,
                          textInputAction: TextInputAction.done,
                          focusNode: _passFocus,
                          onChanged: (_) {
                            if (_passError != null) {
                              setState(() => _passError = null);
                            }
                          },
                        ),
                        const SizedBox(height: 32),

                        // Submit button
                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                            ),
                            child: _loading
                                ? SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        colorScheme.onPrimary,
                                      ),
                                    ),
                                  )
                                : Text(
                                    _isSignup
                                        ? t('signup_button')
                                        : t('login_button'),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Divider with text
                        Row(
                          children: [
                            Expanded(child: Divider(color: colorScheme.outline)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'OR',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurface.withOpacity(0.5),
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: colorScheme.outline)),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Toggle mode button
                        TextButton(
                          onPressed: _loading ? null : _toggleMode,
                          child: Text.rich(
                            TextSpan(
                              text: _isSignup
                                  ? 'Already have an account? '
                                  : 'Don\'t have an account? ',
                              style: theme.textTheme.bodyMedium,
                              children: [
                                TextSpan(
                                  text: _isSignup ? t('login') : t('create_account'),
                                  style: TextStyle(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
