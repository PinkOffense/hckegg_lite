// lib/widgets/accessible_text_field.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// An accessible text field with proper semantics and validation
class AccessibleTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool autofocus;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final FormFieldValidator<String>? validator;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLines;
  final int? maxLength;
  final bool enabled;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;

  const AccessibleTextField({
    super.key,
    this.controller,
    required this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.keyboardType,
    this.obscureText = false,
    this.autofocus = false,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.onTap,
    this.validator,
    this.inputFormatters,
    this.maxLines = 1,
    this.maxLength,
    this.enabled = true,
    this.textInputAction,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      hint: hint,
      enabled: enabled,
      textField: true,
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        autofocus: autofocus,
        onChanged: onChanged,
        onTap: onTap,
        validator: validator,
        inputFormatters: inputFormatters,
        maxLines: maxLines,
        maxLength: maxLength,
        enabled: enabled,
        textInputAction: textInputAction,
        focusNode: focusNode,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          helperText: helperText,
          errorText: errorText,
          prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
          suffixIcon: suffixIcon,
          // Ensure good contrast for error messages
          errorStyle: TextStyle(
            color: Theme.of(context).colorScheme.error,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// Password field with show/hide toggle
class PasswordField extends StatefulWidget {
  final TextEditingController? controller;
  final String label;
  final String? hint;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final bool autofocus;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;

  const PasswordField({
    super.key,
    this.controller,
    this.label = 'Password',
    this.hint,
    this.errorText,
    this.onChanged,
    this.validator,
    this.autofocus = false,
    this.textInputAction,
    this.focusNode,
  });

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return AccessibleTextField(
      controller: widget.controller,
      label: widget.label,
      hint: widget.hint,
      errorText: widget.errorText,
      obscureText: _obscureText,
      autofocus: widget.autofocus,
      onChanged: widget.onChanged,
      validator: widget.validator,
      textInputAction: widget.textInputAction,
      focusNode: widget.focusNode,
      keyboardType: TextInputType.visiblePassword,
      prefixIcon: Icons.lock_outline,
      suffixIcon: IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility : Icons.visibility_off,
        ),
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
        tooltip: _obscureText ? 'Show password' : 'Hide password',
      ),
    );
  }
}

/// Email field with validation
class EmailField extends StatelessWidget {
  final TextEditingController? controller;
  final String label;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final bool autofocus;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;

  const EmailField({
    super.key,
    this.controller,
    this.label = 'Email',
    this.errorText,
    this.onChanged,
    this.autofocus = false,
    this.textInputAction,
    this.focusNode,
  });

  static String? validator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AccessibleTextField(
      controller: controller,
      label: label,
      hint: 'your@email.com',
      errorText: errorText,
      keyboardType: TextInputType.emailAddress,
      autofocus: autofocus,
      onChanged: onChanged,
      validator: validator,
      textInputAction: textInputAction,
      focusNode: focusNode,
      prefixIcon: Icons.email_outlined,
      inputFormatters: [
        FilteringTextInputFormatter.deny(RegExp(r'\s')), // No spaces
      ],
    );
  }
}
