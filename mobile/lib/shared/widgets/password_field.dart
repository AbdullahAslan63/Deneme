import 'package:flutter/material.dart';

/// Password input field with visibility toggle
/// Reusable widget for password fields in auth screens
class PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final bool obscureText;
  final VoidCallback onToggleVisibility;
  final String? labelText;
  final String? hintText;
  final bool enabled;
  final Function(String)? onChanged;
  final FocusNode? focusNode;
  final Widget? passwordCriteria;
  final String? helperText;
  final Color? borderColor;
  // Klavye davranışı için ek parametreler — mobil cihazda kullanıcı
  // klavye sağ alt köşesinden bir sonraki alana geçebilsin / submit
  // edebilsin.
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofillHints;

  const PasswordField({
    super.key,
    required this.controller,
    required this.obscureText,
    required this.onToggleVisibility,
    this.labelText,
    this.hintText,
    this.enabled = true,
    this.onChanged,
    this.focusNode,
    this.passwordCriteria,
    this.helperText,
    this.borderColor,
    this.textInputAction,
    this.onSubmitted,
    this.autofillHints,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          enabled: enabled,
          obscureText: obscureText,
          onChanged: onChanged,
          focusNode: focusNode,
          textInputAction: textInputAction,
          onSubmitted: onSubmitted,
          autofillHints: autofillHints,
          decoration: InputDecoration(
            labelText: labelText ?? 'Şifre',
            hintText: hintText ?? '••••••••',
            prefixIcon: const Icon(Icons.lock_outlined),
            suffixIcon: IconButton(
              icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility),
              onPressed: onToggleVisibility,
            ),
            helperText: helperText,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 17,
            ),
            border: borderColor != null
                ? OutlineInputBorder(
                    borderSide: BorderSide(color: borderColor!),
                  )
                : null,
            enabledBorder: borderColor != null
                ? OutlineInputBorder(
                    borderSide: BorderSide(color: borderColor!),
                  )
                : null,
            focusedBorder: borderColor != null
                ? OutlineInputBorder(
                    borderSide: BorderSide(color: borderColor!),
                  )
                : null,
          ),
        ),
        ...?passwordCriteria != null ? [passwordCriteria!] : null,
      ],
    );
  }
}
