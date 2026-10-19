import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/form_fields.dart';
import '../application/auth_controller.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _passwordAgain = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(authControllerProvider.notifier).clearError());
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _passwordAgain.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(authControllerProvider.notifier).register(_name.text, _email.text, _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: const Text('Hesap oluştur'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hesabınızı oluşturun', style: theme.textTheme.headlineSmall?.copyWith(color: AppColors.navy, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        const Text('İhbar oluşturmak için hesap gerekir.', style: TextStyle(color: AppColors.textSecondary)),
                        const SizedBox(height: 24),
                        if (auth.error != null) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.dangerBg,
                              border: Border.all(color: AppColors.danger),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(children: [
                              const Icon(Icons.error_outline, color: AppColors.danger, size: 20),
                              const SizedBox(width: 8),
                              Expanded(child: Text(auth.error!, style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600))),
                            ]),
                          ),
                          const SizedBox(height: 16),
                        ],
                        const FieldLabel('Ad soyad'),
                        TextFormField(
                          controller: _name,
                          enabled: !auth.loading,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(hintText: 'Adınız ve soyadınız'),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Ad soyad zorunludur.' : null,
                        ),
                        const SizedBox(height: 20),
                        const FieldLabel('E-posta'),
                        TextFormField(
                          controller: _email,
                          enabled: !auth.loading,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(hintText: 'ornek@posta.gov.tr'),
                          validator: (v) {
                            final value = v?.trim() ?? '';
                            if (value.isEmpty) return 'E-posta zorunludur.';
                            if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) return 'Geçerli bir e-posta girin.';
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        PasswordField(
                          label: 'Parola',
                          controller: _password,
                          enabled: !auth.loading,
                          validator: (v) => (v == null || v.isEmpty) ? 'Parola zorunludur.' : null,
                        ),
                        const SizedBox(height: 20),
                        PasswordField(
                          label: 'Parola (tekrar)',
                          controller: _passwordAgain,
                          enabled: !auth.loading,
                          validator: (v) => v != _password.text ? 'Parolalar eşleşmiyor.' : null,
                        ),
                        const SizedBox(height: 32),
                        FilledButton(
                          onPressed: auth.loading ? null : _submit,
                          child: auth.loading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Hesap oluştur'),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Text('Zaten hesabınız var mı?', style: TextStyle(color: AppColors.textSecondary)),
                            TextButton(onPressed: () => context.pop(), child: const Text('Giriş yap')),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
