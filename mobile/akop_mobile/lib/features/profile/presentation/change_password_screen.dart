import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/form_fields.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/data/auth_repository.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _again = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _again.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    String? error;
    try {
      final changed = await ref.read(authControllerProvider.notifier).changePassword(_current.text, _next.text);
      if (!changed) error = 'Mevcut parola hatalı.';
    } on UnsupportedError {
      // Backend'de uç nokta hazır olana kadar
      error = 'Parola değiştirme henüz sunucuya bağlı değil.';
    } on NetworkFailure {
      error = 'Sunucuya ulaşılamadı. Bağlantınızı kontrol edip tekrar deneyin.';
    }
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _busy = false;
        _error = error;
      });
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Parolanız değiştirildi.')));
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: const Text('Parola değiştir'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_error != null) ...[
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
                      Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600))),
                    ]),
                  ),
                  const SizedBox(height: 16),
                ],
                PasswordField(
                  label: 'Mevcut parola',
                  controller: _current,
                  enabled: !_busy,
                  validator: (v) => (v == null || v.isEmpty) ? 'Mevcut parola zorunludur.' : null,
                ),
                const SizedBox(height: 20),
                PasswordField(
                  label: 'Yeni parola',
                  controller: _next,
                  enabled: !_busy,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Yeni parola zorunludur.';
                    if (v == _current.text) return 'Yeni parola mevcut parolayla aynı olamaz.';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                PasswordField(
                  label: 'Yeni parola (tekrar)',
                  controller: _again,
                  enabled: !_busy,
                  validator: (v) => v != _next.text ? 'Parolalar eşleşmiyor.' : null,
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: _busy ? null : _submit,
                  child: _busy
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Parolayı değiştir'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
