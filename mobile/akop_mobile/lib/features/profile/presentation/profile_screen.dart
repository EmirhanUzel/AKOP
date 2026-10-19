import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/application/auth_controller.dart';

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return (parts.first[0] + parts.last[0]).toUpperCase();
}

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _editName(BuildContext context, WidgetRef ref, String current) async {
    final name = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _EditNameSheet(initial: current),
    );
    if (name != null) ref.read(authControllerProvider.notifier).updateName(name);
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Çıkış yapılsın mı?'),
        content: const Text('Tekrar giriş yapmanız gerekecek.'),
        actions: [
          TextButton(onPressed: () => ctx.pop(false), child: const Text('Vazgeç')),
          TextButton(onPressed: () => ctx.pop(true), child: const Text('Çıkış yap')),
        ],
      ),
    );
    if (ok == true) ref.read(authControllerProvider.notifier).signOut();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    if (user == null) return const SizedBox.shrink();
    return Scaffold(
      appBar: AppBar(centerTitle: true, title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          _Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppColors.navy,
                    child: Text(_initials(user.fullName), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 12),
                  Text(user.fullName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(user.email, style: const TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text('HESAP', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.8, color: AppColors.textSecondary)),
          ),
          _Card(
            child: Column(
              children: [
                _Row(icon: Icons.badge_outlined, label: 'Ad soyadı düzenle', onTap: () => _editName(context, ref, user.fullName)),
                const Divider(height: 1, indent: 64, color: AppColors.border),
                _Row(icon: Icons.lock_reset, label: 'Parolayı değiştir', onTap: () => context.push('/profil/parola')),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _Card(
            child: _Row(
              icon: Icons.logout,
              label: 'Çıkış yap',
              color: AppColors.danger,
              chevron: false,
              center: true,
              onTap: () => _confirmSignOut(context, ref),
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
        child: child,
      );
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.label, required this.onTap, this.color, this.chevron = true, this.center = false});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final bool chevron;
  final bool center;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.text;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: center ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            if (center)
              Icon(icon, color: c, size: 20)
            else
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: AppColors.surfaceTint, borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: AppColors.navy, size: 20),
              ),
            SizedBox(width: center ? 8 : 16),
            if (center)
              Text(label, style: TextStyle(color: c, fontWeight: FontWeight.w600, fontSize: 16))
            else
              Expanded(child: Text(label, style: TextStyle(color: c, fontSize: 16))),
            if (chevron) const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _EditNameSheet extends StatefulWidget {
  const _EditNameSheet({required this.initial});

  final String initial;

  @override
  State<_EditNameSheet> createState() => _EditNameSheetState();
}

class _EditNameSheetState extends State<_EditNameSheet> {
  late final _controller = TextEditingController(text: widget.initial);
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 20, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ad soyadı düzenle', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _controller,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Ad soyad'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Ad soyad zorunludur.' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: TextButton(onPressed: () => context.pop(), child: const Text('Vazgeç'))),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) context.pop(_controller.text);
                    },
                    child: const Text('Kaydet'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
