import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key, this.optional = false, this.required = false});

  final String text;
  final bool optional;
  final bool required;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text.rich(
          TextSpan(
            text: text,
            style: const TextStyle(color: AppColors.navy, fontSize: 14, fontWeight: FontWeight.w600),
            children: [
              if (required) const TextSpan(text: ' *', style: TextStyle(color: AppColors.danger)),
              if (optional)
                const TextSpan(
                  text: ' (isteğe bağlı)',
                  style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w400),
                ),
            ],
          ),
        ),
      );
}

/// Etiketli parola alanı, göster/gizle ikonlu.
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.label,
    required this.controller,
    this.validator,
    this.errorText,
    this.enabled = true,
    this.textInputAction,
  });

  final String label;
  final TextEditingController controller;
  final FormFieldValidator<String>? validator;
  final String? errorText;
  final bool enabled;
  final TextInputAction? textInputAction;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(widget.label),
        TextFormField(
          controller: widget.controller,
          enabled: widget.enabled,
          obscureText: _obscure,
          textInputAction: widget.textInputAction,
          validator: widget.validator,
          decoration: InputDecoration(
            hintText: '••••••••',
            errorText: widget.errorText,
            suffixIcon: IconButton(
              tooltip: 'Parolayı göster veya gizle',
              onPressed: () => setState(() => _obscure = !_obscure),
              icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: AppColors.textSecondary),
            ),
          ),
        ),
      ],
    );
  }
}
