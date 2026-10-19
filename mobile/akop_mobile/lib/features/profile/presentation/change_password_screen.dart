import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/form_fields.dart';
import '../../auth/application/auth_controller.dart';

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
  String? _currentError;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _again.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _currentError = null);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    final ok = await ref.read(authControllerProvider.notifier).changePassword(_current.text, _next.text);
    if (!mounted) return;
    if (ok) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Parolanız güncellendi.')));
    } else {
      setState(() {
        _busy = false;
        _currentError = 'Mevcut parola hatalı.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String? required(String? v) => (v == null || v.isEmpty) ? 'Bu alan zorunludur.' : null;
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: const Text('Parolayı değiştir'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        PasswordField(label: 'Mevcut parola', controller: _current, validator: required, errorText: _currentError, enabled: !_busy),
                        const SizedBox(height: 20),
                        PasswordField(label: 'Yeni parola', controller: _next, validator: required, enabled: !_busy),
                        const SizedBox(height: 20),
                        PasswordField(
                          label: 'Yeni parola (tekrar)',
                          controller: _again,
                          enabled: !_busy,
                          validator: (v) => v != _next.text ? 'Parolalar eşleşmiyor.' : null,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              FilledButton(
                onPressed: _busy ? null : _submit,
                child: _busy
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Parolayı güncelle'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
