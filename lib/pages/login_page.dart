// lib/pages/login_page.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
  final _confirmPassCtl = TextEditingController();
  final _emailFocus = FocusNode();
  final _passFocus = FocusNode();
  final _confirmPassFocus = FocusNode();

  bool _loading = false;
  bool _googleLoading = false;
  bool _resetLoading = false;
  bool _isSignup = false;
  bool _acceptedTerms = false;
  String? _emailError;
  String? _passError;
  String? _confirmPassError;

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

    // Listen to password changes for strength indicator
    _passCtl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailCtl.dispose();
    _passCtl.dispose();
    _confirmPassCtl.dispose();
    _emailFocus.dispose();
    _passFocus.dispose();
    _confirmPassFocus.dispose();
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

  // Password strength calculation
  _PasswordStrength _getPasswordStrength(String password) {
    if (password.isEmpty) return _PasswordStrength.none;

    int score = 0;

    // Length checks
    if (password.length >= 6) score++;
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;

    // Character type checks
    if (password.contains(RegExp(r'[a-z]'))) score++;
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score++;

    if (score <= 2) return _PasswordStrength.weak;
    if (score <= 4) return _PasswordStrength.medium;
    if (score <= 5) return _PasswordStrength.strong;
    return _PasswordStrength.veryStrong;
  }

  // Password requirement checks
  bool _hasMinLength(String password) => password.length >= 8;
  bool _hasUppercase(String password) => password.contains(RegExp(r'[A-Z]'));
  bool _hasLowercase(String password) => password.contains(RegExp(r'[a-z]'));
  bool _hasNumber(String password) => password.contains(RegExp(r'[0-9]'));
  bool _hasSpecialChar(String password) =>
      password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

  bool _validateForm() {
    setState(() {
      _emailError = null;
      _passError = null;
      _confirmPassError = null;
    });

    bool isValid = true;
    final email = _emailCtl.text.trim();
    final pass = _passCtl.text;
    final confirmPass = _confirmPassCtl.text;

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
    } else if (_isSignup) {
      if (pass.length < 8) {
        setState(() => _passError = 'Password must be at least 8 characters');
        isValid = false;
      } else if (!_hasUppercase(pass) || !_hasLowercase(pass)) {
        setState(() => _passError = 'Password must contain upper and lowercase letters');
        isValid = false;
      } else if (!_hasNumber(pass)) {
        setState(() => _passError = 'Password must contain at least one number');
        isValid = false;
      }
    }

    // Confirm password validation (signup only)
    if (_isSignup) {
      if (confirmPass.isEmpty) {
        setState(() => _confirmPassError = 'Please confirm your password');
        isValid = false;
      } else if (confirmPass != pass) {
        setState(() => _confirmPassError = 'Passwords do not match');
        isValid = false;
      }

      // Terms validation
      if (!_acceptedTerms) {
        _showMessage('Please accept the Terms of Service', isError: true);
        isValid = false;
      }
    }

    return isValid;
  }

  Future<void> _submit() async {
    // Validate form
    if (!_validateForm()) {
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

  Future<void> _signInWithGoogle() async {
    setState(() => _googleLoading = true);

    final supabase = Supabase.instance.client;
    final auth = AuthService(supabase);

    try {
      await auth.signInWithGoogle();
      // Para mobile, o login é imediato
      // Para web, será redirecionado automaticamente
      if (!kIsWeb) {
        _showMessage('Welcome!');
      }
    } on AuthException catch (e) {
      // Ignorar mensagem de redirect no web
      if (!e.message.contains('Redirecting')) {
        _showMessage(e.message, isError: true);
      }
    } catch (e) {
      _showMessage('Google sign-in failed. Please try again.', isError: true);
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  void _toggleMode() {
    setState(() {
      _isSignup = !_isSignup;
      _emailError = null;
      _passError = null;
      _confirmPassError = null;
      _acceptedTerms = false;
      _confirmPassCtl.clear();
    });

    // Replay animation when switching modes
    _animationController.reset();
    _animationController.forward();
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms of Service'),
        content: const SingleChildScrollView(
          child: Text(
            'By creating an account, you agree to:\n\n'
            '1. Use this application responsibly\n'
            '2. Keep your login credentials secure\n'
            '3. Not share your account with others\n'
            '4. Respect the privacy of other users\n'
            '5. Report any security issues immediately\n\n'
            'Your data will be stored securely and used only for the purpose of managing your poultry records.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'Your privacy is important to us.\n\n'
            'We collect:\n'
            '• Email address (for authentication)\n'
            '• Poultry management data you enter\n\n'
            'We do NOT:\n'
            '• Sell your data to third parties\n'
            '• Share your data without consent\n'
            '• Use your data for advertising\n\n'
            'Your data is stored securely using Supabase infrastructure with encryption at rest and in transit.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _showForgotPasswordDialog(String locale) async {
    final emailController = TextEditingController(text: _emailCtl.text);
    final t = (String k, {Map<String, String>? params}) =>
        Translations.of(locale, k, params: params);

    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        icon: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.lock_reset,
            size: 40,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(
          t('reset_password'),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              t('enter_email_to_reset'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: t('email'),
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(t('cancel')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    if (emailController.text.trim().isNotEmpty) {
                      Navigator.pop(context, true);
                    }
                  },
                  child: Text(t('send_reset_link')),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (shouldReset != true || !mounted) return;

    setState(() => _resetLoading = true);

    try {
      final supabase = Supabase.instance.client;
      final auth = AuthService(supabase);
      await auth.resetPassword(emailController.text.trim());

      if (mounted) {
        setState(() => _resetLoading = false);
        _showMessage(t('reset_password_email_sent'));
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() => _resetLoading = false);
        _showMessage(e.message, isError: true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _resetLoading = false);
        _showMessage('An error occurred. Please try again.', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = Provider.of<LocaleProvider>(context).code;
    final t = (String k, {Map<String, String>? params}) =>
        Translations.of(locale, k, params: params);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final password = _passCtl.text;
    final strength = _getPasswordStrength(password);

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
                            height: 100,
                            width: 100,
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  colorScheme.primary,
                                  colorScheme.primaryContainer,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: colorScheme.primary.withValues(alpha: 0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.egg_outlined,
                              size: 50,
                              color: Colors.white,
                            ),
                          ),
                        ),

                        // App name
                        Text(
                          t('app_title'),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                            letterSpacing: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),

                        // Title
                        Text(
                          _isSignup ? t('join_us') : t('welcome_back'),
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),

                        // Subtitle
                        Text(
                          _isSignup
                              ? t('create_account_to_start')
                              : t('sign_in_to_continue'),
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 40),

                        // Email field
                        EmailField(
                          controller: _emailCtl,
                          label: t('email'),
                          errorText: _emailError,
                          autofocus: false,
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
                          errorText: _passError,
                          textInputAction: _isSignup
                              ? TextInputAction.next
                              : TextInputAction.done,
                          focusNode: _passFocus,
                          onChanged: (_) {
                            if (_passError != null) {
                              setState(() => _passError = null);
                            }
                          },
                        ),

                        // Forgot password link (login only)
                        if (!_isSignup) ...[
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _loading || _googleLoading || _resetLoading
                                  ? null
                                  : () => _showForgotPasswordDialog(locale),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: _resetLoading
                                  ? SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: colorScheme.primary,
                                      ),
                                    )
                                  : Text(
                                      t('forgot_password'),
                                      style: TextStyle(
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                            ),
                          ),
                        ],

                        // Password strength indicator (signup only)
                        if (_isSignup && password.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _PasswordStrengthIndicator(strength: strength),
                          const SizedBox(height: 16),
                          _PasswordRequirements(password: password),
                        ],

                        // Confirm password field (signup only)
                        if (_isSignup) ...[
                          const SizedBox(height: 16),
                          PasswordField(
                            controller: _confirmPassCtl,
                            label: t('confirm_password'),
                            errorText: _confirmPassError,
                            textInputAction: TextInputAction.done,
                            focusNode: _confirmPassFocus,
                            onChanged: (_) {
                              if (_confirmPassError != null) {
                                setState(() => _confirmPassError = null);
                              }
                            },
                          ),
                        ],

                        // Terms and conditions checkbox (signup only)
                        if (_isSignup) ...[
                          const SizedBox(height: 20),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: Checkbox(
                                  value: _acceptedTerms,
                                  onChanged: (value) {
                                    setState(() => _acceptedTerms = value ?? false);
                                  },
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text.rich(
                                  TextSpan(
                                    text: t('accept_terms_prefix'),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurface.withValues(alpha: 0.8),
                                    ),
                                    children: [
                                      TextSpan(
                                        text: t('terms_of_service'),
                                        style: TextStyle(
                                          color: colorScheme.primary,
                                          fontWeight: FontWeight.w600,
                                          decoration: TextDecoration.underline,
                                        ),
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = _showTermsDialog,
                                      ),
                                      TextSpan(text: t('and')),
                                      TextSpan(
                                        text: t('privacy_policy'),
                                        style: TextStyle(
                                          color: colorScheme.primary,
                                          fontWeight: FontWeight.w600,
                                          decoration: TextDecoration.underline,
                                        ),
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = _showPrivacyDialog,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],

                        const SizedBox(height: 32),

                        // Submit button
                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _loading || _googleLoading
                                ? null
                                : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                              elevation: 2,
                              shadowColor: colorScheme.primary.withValues(alpha: 0.3),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
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
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Divider with text
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: colorScheme.outline.withValues(alpha: 0.5),
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                t('or_continue_with'),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: colorScheme.outline.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Google Sign-In Button
                        _GoogleSignInButton(
                          onPressed: _googleLoading || _loading
                              ? null
                              : _signInWithGoogle,
                          isLoading: _googleLoading,
                          label: t('continue_with_google'),
                        ),
                        const SizedBox(height: 24),

                        // Toggle mode link
                        TextButton(
                          onPressed: _loading || _googleLoading || _resetLoading
                              ? null
                              : _toggleMode,
                          child: Text.rich(
                            TextSpan(
                              text: _isSignup
                                  ? t('already_have_account')
                                  : t('dont_have_account'),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                              children: [
                                TextSpan(
                                  text: _isSignup
                                      ? t('login')
                                      : t('create_account'),
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

// Password strength enum
enum _PasswordStrength { none, weak, medium, strong, veryStrong }

// Password strength indicator widget
class _PasswordStrengthIndicator extends StatelessWidget {
  final _PasswordStrength strength;

  const _PasswordStrengthIndicator({required this.strength});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Color getColor() {
      switch (strength) {
        case _PasswordStrength.none:
          return colorScheme.outline;
        case _PasswordStrength.weak:
          return Colors.red;
        case _PasswordStrength.medium:
          return Colors.orange;
        case _PasswordStrength.strong:
          return Colors.lightGreen;
        case _PasswordStrength.veryStrong:
          return Colors.green;
      }
    }

    String getLabel() {
      switch (strength) {
        case _PasswordStrength.none:
          return '';
        case _PasswordStrength.weak:
          return 'Weak';
        case _PasswordStrength.medium:
          return 'Medium';
        case _PasswordStrength.strong:
          return 'Strong';
        case _PasswordStrength.veryStrong:
          return 'Very Strong';
      }
    }

    int getFilledBars() {
      switch (strength) {
        case _PasswordStrength.none:
          return 0;
        case _PasswordStrength.weak:
          return 1;
        case _PasswordStrength.medium:
          return 2;
        case _PasswordStrength.strong:
          return 3;
        case _PasswordStrength.veryStrong:
          return 4;
      }
    }

    final filledBars = getFilledBars();
    final color = getColor();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(4, (index) {
            return Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(right: index < 3 ? 4 : 0),
                decoration: BoxDecoration(
                  color: index < filledBars ? color : colorScheme.outline.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        if (strength != _PasswordStrength.none) ...[
          const SizedBox(height: 4),
          Text(
            getLabel(),
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

// Password requirements checklist widget
class _PasswordRequirements extends StatelessWidget {
  final String password;

  const _PasswordRequirements({required this.password});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Widget buildRequirement(String text, bool isMet) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Icon(
              isMet ? Icons.check_circle : Icons.circle_outlined,
              size: 16,
              color: isMet ? Colors.green : colorScheme.outline,
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: isMet
                    ? colorScheme.onSurface
                    : colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Password requirements:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 8),
          buildRequirement('At least 8 characters', password.length >= 8),
          buildRequirement('One uppercase letter (A-Z)', password.contains(RegExp(r'[A-Z]'))),
          buildRequirement('One lowercase letter (a-z)', password.contains(RegExp(r'[a-z]'))),
          buildRequirement('One number (0-9)', password.contains(RegExp(r'[0-9]'))),
          buildRequirement('One special character (!@#\$%^&*)', password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))),
        ],
      ),
    );
  }
}

/// Custom Google Sign-In button following Google branding guidelines
class _GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String label;

  const _GoogleSignInButton({
    required this.onPressed,
    required this.isLoading,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: isDark ? const Color(0xFF131314) : Colors.white,
          side: BorderSide(
            color: isDark
                ? const Color(0xFF8E918F)
                : const Color(0xFFDADCE0),
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDark ? Colors.white : Colors.black87,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Google icon
                  const FaIcon(
                    FontAwesomeIcons.google,
                    size: 20,
                    color: Color(0xFF4285F4),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : const Color(0xFF1F1F1F),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
