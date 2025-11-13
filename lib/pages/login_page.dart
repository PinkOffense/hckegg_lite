// lib/pages/login_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/locale_provider.dart';
import '../l10n/translations.dart';
import '../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailCtl = TextEditingController();
  final _passCtl = TextEditingController();
  bool _loading = false;
  bool _isSignup = false;

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    final supabase = Supabase.instance.client;
    final auth = AuthService(supabase);
    final email = _emailCtl.text.trim();
    final pass = _passCtl.text;

    try {
      if (_isSignup) {
        final res = await auth.signUp(email, pass);
        if (res.session != null) {
          // logged in automatically
        } else {
          _showError(Translations.of(Provider.of<LocaleProvider>(context, listen: false).code, 'create_account'));
        }
      } else {
        final res = await auth.signIn(email, pass);
        if (res.session == null) {
          _showError(Translations.of(Provider.of<LocaleProvider>(context, listen: false).code, 'login_failed'));
        }
      }
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = Provider.of<LocaleProvider>(context).code;
    final t = (String k, {Map<String, String>? params}) => Translations.of(locale, k, params: params);

    return Scaffold(
      appBar: AppBar(title: Text(t('app_title'))),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isSignup ? t('create_account') : t('login'),
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _emailCtl,
                      decoration: InputDecoration(labelText: t('email')),
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.username, AutofillHints.email],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passCtl,
                      decoration: InputDecoration(labelText: t('password')),
                      obscureText: true,
                      autofillHints: const [AutofillHints.password],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _loading ? null : _submit,
                            child: _loading
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                : Text(_isSignup ? t('signup_button') : t('login_button')),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _loading ? null : () => setState(() => _isSignup = !_isSignup),
                      child: Text(_isSignup ? t('already_have_account') : t('create_account')),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
