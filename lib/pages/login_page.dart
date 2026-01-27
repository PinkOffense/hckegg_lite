// lib/pages/login_page.dart
import 'package:flutter/foundation.dart' show kIsWeb;
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
  bool _googleLoading = false;
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
                            height: 100,
                            width: 100,
                            margin: const EdgeInsets.only(bottom: 32),
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
                                  color: colorScheme.primary.withOpacity(0.3),
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
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 40),

                        // Google Sign-In Button
                        _GoogleSignInButton(
                          onPressed: _googleLoading || _loading
                              ? null
                              : _signInWithGoogle,
                          isLoading: _googleLoading,
                          label: t('continue_with_google'),
                        ),
                        const SizedBox(height: 24),

                        // Divider with text
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: colorScheme.outline.withOpacity(0.5),
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                t('or_continue_with'),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurface.withOpacity(0.5),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: colorScheme.outline.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

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
                            onPressed: _loading || _googleLoading
                                ? null
                                : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                              elevation: 2,
                              shadowColor: colorScheme.primary.withOpacity(0.3),
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

                        // Toggle mode button
                        TextButton(
                          onPressed: _loading || _googleLoading
                              ? null
                              : _toggleMode,
                          child: Text.rich(
                            TextSpan(
                              text: _isSignup
                                  ? 'Already have an account? '
                                  : 'Don\'t have an account? ',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.7),
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
                  // Google "G" logo
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CustomPaint(
                      painter: _GoogleLogoPainter(),
                    ),
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

/// Custom painter for Google "G" logo
class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Blue
    final bluePaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;

    // Green
    final greenPaint = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.fill;

    // Yellow
    final yellowPaint = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.fill;

    // Red
    final redPaint = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.fill;

    // Draw simplified Google G logo
    final center = Offset(w / 2, h / 2);
    final radius = w / 2;

    // Blue arc (right side)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -0.4,
      1.2,
      true,
      bluePaint,
    );

    // Green arc (bottom right)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0.8,
      1.0,
      true,
      greenPaint,
    );

    // Yellow arc (bottom left)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      1.8,
      1.0,
      true,
      yellowPaint,
    );

    // Red arc (top)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      2.8,
      1.0,
      true,
      redPaint,
    );

    // White center circle
    canvas.drawCircle(
      center,
      radius * 0.55,
      Paint()..color = Colors.white,
    );

    // Blue horizontal bar
    canvas.drawRect(
      Rect.fromLTWH(w * 0.48, h * 0.38, w * 0.52, h * 0.24),
      bluePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
