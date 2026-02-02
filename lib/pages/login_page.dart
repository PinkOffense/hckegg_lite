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
import '../widgets/animated_chickens.dart';

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
    final isDark = theme.brightness == Brightness.dark;

    // Custom colors for the warm, cute theme
    const softPink = Color(0xFFFFE4EC);
    const warmPink = Color(0xFFFFB6C1);
    const accentPink = Color(0xFFFF69B4);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    const Color(0xFF1A1A2E),
                    const Color(0xFF16213E),
                  ]
                : [
                    softPink.withValues(alpha: 0.6),
                    Colors.white,
                    const Color(0xFFFFF8E7),
                  ],
            stops: isDark ? null : const [0.0, 0.4, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Floating decorative eggs
            ..._buildFloatingEggs(isDark),

            // Main content
            SafeArea(
              child: Center(
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Cute chicken with egg animation (bigger hero)
                              const AnimatedChickens(height: 200),
                              const SizedBox(height: 8),

                              // App name with cute styling
                              ShaderMask(
                                shaderCallback: (bounds) => LinearGradient(
                                  colors: isDark
                                      ? [warmPink, accentPink]
                                      : [accentPink, const Color(0xFFFF1493)],
                                ).createShader(bounds),
                                child: Text(
                                  t('app_title'),
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 2,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 32),

                              // Form Card Container
                              Container(
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? colorScheme.surface.withValues(alpha: 0.8)
                                      : Colors.white.withValues(alpha: 0.95),
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (isDark ? Colors.black : warmPink).withValues(alpha: 0.15),
                                      blurRadius: 30,
                                      offset: const Offset(0, 10),
                                    ),
                                    if (!isDark)
                                      BoxShadow(
                                        color: warmPink.withValues(alpha: 0.1),
                                        blurRadius: 60,
                                        spreadRadius: 10,
                                      ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(28),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      // Title with icon
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            _isSignup ? Icons.egg_alt_rounded : Icons.waving_hand_rounded,
                                            color: accentPink,
                                            size: 28,
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            _isSignup ? t('join_us') : t('welcome_back'),
                                            style: theme.textTheme.headlineSmall?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: colorScheme.onSurface,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),

                                      // Subtitle
                                      Text(
                                        _isSignup
                                            ? t('create_account_to_start')
                                            : t('sign_in_to_continue'),
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 28),

                                      // Email field with enhanced styling
                                      _StyledTextField(
                                        controller: _emailCtl,
                                        label: t('email'),
                                        errorText: _emailError,
                                        prefixIcon: Icons.email_outlined,
                                        keyboardType: TextInputType.emailAddress,
                                        textInputAction: TextInputAction.next,
                                        focusNode: _emailFocus,
                                        fillColor: isDark ? null : softPink.withValues(alpha: 0.3),
                                        onChanged: (_) {
                                          if (_emailError != null) {
                                            setState(() => _emailError = null);
                                          }
                                        },
                                      ),
                                      const SizedBox(height: 16),

                                      // Password field with enhanced styling
                                      _StyledPasswordField(
                                        controller: _passCtl,
                                        label: t('password'),
                                        errorText: _passError,
                                        textInputAction: _isSignup
                                            ? TextInputAction.next
                                            : TextInputAction.done,
                                        focusNode: _passFocus,
                                        fillColor: isDark ? null : softPink.withValues(alpha: 0.3),
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
                                                      color: accentPink,
                                                    ),
                                                  )
                                                : Text(
                                                    t('forgot_password'),
                                                    style: TextStyle(
                                                      color: accentPink,
                                                      fontWeight: FontWeight.w600,
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
                                        _StyledPasswordField(
                                          controller: _confirmPassCtl,
                                          label: t('confirm_password'),
                                          errorText: _confirmPassError,
                                          textInputAction: TextInputAction.done,
                                          focusNode: _confirmPassFocus,
                                          fillColor: isDark ? null : softPink.withValues(alpha: 0.3),
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
                                                activeColor: accentPink,
                                                onChanged: (value) {
                                                  setState(() => _acceptedTerms = value ?? false);
                                                },
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(6),
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
                                                        color: accentPink,
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
                                                        color: accentPink,
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

                                      const SizedBox(height: 28),

                                      // Submit button with gradient
                                      _GradientButton(
                                        onPressed: _loading || _googleLoading ? null : _submit,
                                        isLoading: _loading,
                                        label: _isSignup ? t('signup_button') : t('login_button'),
                                        icon: _isSignup ? Icons.egg_alt_rounded : Icons.login_rounded,
                                      ),
                                      const SizedBox(height: 24),

                                      // Divider with text
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Divider(
                                              color: colorScheme.outline.withValues(alpha: 0.3),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 16),
                                            child: Text(
                                              t('or_continue_with'),
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                color: colorScheme.onSurface.withValues(alpha: 0.5),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Divider(
                                              color: colorScheme.outline.withValues(alpha: 0.3),
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
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

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
                                      color: isDark
                                          ? colorScheme.onSurface.withValues(alpha: 0.7)
                                          : Colors.black87,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: _isSignup
                                            ? t('login')
                                            : t('create_account'),
                                        style: TextStyle(
                                          color: accentPink,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFloatingEggs(bool isDark) {
    return [
      // Top left egg
      Positioned(
        top: 60,
        left: 20,
        child: _FloatingEgg(
          size: 24,
          color: isDark ? const Color(0xFF4A3F5C) : const Color(0xFFFFE4B5),
          delay: 0,
        ),
      ),
      // Top right egg
      Positioned(
        top: 100,
        right: 30,
        child: _FloatingEgg(
          size: 18,
          color: isDark ? const Color(0xFF5C4A5C) : const Color(0xFFFFB6C1),
          delay: 500,
        ),
      ),
      // Middle left feather
      Positioned(
        top: 200,
        left: 15,
        child: _FloatingFeather(
          color: isDark ? const Color(0xFF6B5B7A) : const Color(0xFFFFB6C1),
          delay: 300,
        ),
      ),
      // Bottom right egg
      Positioned(
        bottom: 150,
        right: 25,
        child: _FloatingEgg(
          size: 20,
          color: isDark ? const Color(0xFF4A4A5C) : const Color(0xFFFFF8DC),
          delay: 700,
        ),
      ),
      // Bottom left feather
      Positioned(
        bottom: 100,
        left: 30,
        child: _FloatingFeather(
          color: isDark ? const Color(0xFF5C5A6B) : const Color(0xFFFFE4EC),
          delay: 200,
        ),
      ),
    ];
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

/// Styled text field with enhanced visual design
class _StyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? errorText;
  final IconData prefixIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final Color? fillColor;
  final ValueChanged<String>? onChanged;

  const _StyledTextField({
    required this.controller,
    required this.label,
    this.errorText,
    required this.prefixIcon,
    this.keyboardType,
    this.textInputAction,
    this.focusNode,
    this.fillColor,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    const accentPink = Color(0xFFFF69B4);

    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      focusNode: focusNode,
      onChanged: onChanged,
      style: TextStyle(
        color: colorScheme.onSurface,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        labelText: label,
        errorText: errorText,
        prefixIcon: Icon(prefixIcon, color: accentPink.withValues(alpha: 0.8)),
        filled: fillColor != null,
        fillColor: fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: accentPink, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        labelStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
    );
  }
}

/// Styled password field with visibility toggle
class _StyledPasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? errorText;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final Color? fillColor;
  final ValueChanged<String>? onChanged;

  const _StyledPasswordField({
    required this.controller,
    required this.label,
    this.errorText,
    this.textInputAction,
    this.focusNode,
    this.fillColor,
    this.onChanged,
  });

  @override
  State<_StyledPasswordField> createState() => _StyledPasswordFieldState();
}

class _StyledPasswordFieldState extends State<_StyledPasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    const accentPink = Color(0xFFFF69B4);

    return TextField(
      controller: widget.controller,
      obscureText: _obscure,
      textInputAction: widget.textInputAction,
      focusNode: widget.focusNode,
      onChanged: widget.onChanged,
      style: TextStyle(
        color: colorScheme.onSurface,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        labelText: widget.label,
        errorText: widget.errorText,
        prefixIcon: Icon(Icons.lock_outline, color: accentPink.withValues(alpha: 0.8)),
        suffixIcon: IconButton(
          icon: Icon(
            _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
        filled: widget.fillColor != null,
        fillColor: widget.fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: accentPink, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        labelStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
    );
  }
}

/// Gradient button with icon
class _GradientButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String label;
  final IconData icon;

  const _GradientButton({
    required this.onPressed,
    required this.isLoading,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: onPressed != null
            ? LinearGradient(
                colors: isDark
                    ? [const Color(0xFFFF69B4), const Color(0xFFFF1493)]
                    : [const Color(0xFFFF69B4), const Color(0xFFFF85C1)],
              )
            : null,
        color: onPressed == null ? Colors.grey.shade400 : null,
        borderRadius: BorderRadius.circular(16),
        boxShadow: onPressed != null
            ? [
                BoxShadow(
                  color: const Color(0xFFFF69B4).withValues(alpha: 0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: Colors.white, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Floating egg decoration with animation
class _FloatingEgg extends StatefulWidget {
  final double size;
  final Color color;
  final int delay;

  const _FloatingEgg({
    required this.size,
    required this.color,
    required this.delay,
  });

  @override
  State<_FloatingEgg> createState() => _FloatingEggState();
}

class _FloatingEggState extends State<_FloatingEgg>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    _animation = Tween<double>(begin: 0, end: 12).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -_animation.value),
          child: Container(
            width: widget.size,
            height: widget.size * 1.3,
            decoration: BoxDecoration(
              color: widget.color.withValues(alpha: 0.6),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(widget.size * 0.5),
                topRight: Radius.circular(widget.size * 0.5),
                bottomLeft: Radius.circular(widget.size * 0.4),
                bottomRight: Radius.circular(widget.size * 0.4),
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Floating feather decoration with animation
class _FloatingFeather extends StatefulWidget {
  final Color color;
  final int delay;

  const _FloatingFeather({
    required this.color,
    required this.delay,
  });

  @override
  State<_FloatingFeather> createState() => _FloatingFeatherState();
}

class _FloatingFeatherState extends State<_FloatingFeather>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _floatAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );

    _floatAnimation = Tween<double>(begin: 0, end: 15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _rotateAnimation = Tween<double>(begin: -0.1, end: 0.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -_floatAnimation.value),
          child: Transform.rotate(
            angle: _rotateAnimation.value,
            child: CustomPaint(
              size: const Size(20, 30),
              painter: _FeatherPainter(color: widget.color),
            ),
          ),
        );
      },
    );
  }
}

class _FeatherPainter extends CustomPainter {
  final Color color;

  _FeatherPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width * 0.5, 0)
      ..quadraticBezierTo(size.width * 0.8, size.height * 0.3, size.width * 0.6, size.height)
      ..quadraticBezierTo(size.width * 0.5, size.height * 0.7, size.width * 0.4, size.height)
      ..quadraticBezierTo(size.width * 0.2, size.height * 0.3, size.width * 0.5, 0);

    canvas.drawPath(path, paint);

    // Feather spine
    final spinePaint = Paint()
      ..color = color.withValues(alpha: 0.9)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(size.width * 0.5, 0),
      Offset(size.width * 0.5, size.height * 0.9),
      spinePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
