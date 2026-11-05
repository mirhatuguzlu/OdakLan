import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import 'account.dart';

/// Profil header: guest or signed-in account, Google sign-in / sign-out.
class AccountCard extends ConsumerStatefulWidget {
  const AccountCard({super.key});

  @override
  ConsumerState<AccountCard> createState() => _AccountCardState();
}

class _AccountCardState extends ConsumerState<AccountCard> {
  var _busy = false;

  Future<void> _run(Future<Object?> Function(AuthService auth) action) async {
    final auth = ref.read(authServiceProvider);
    if (auth == null || _busy) return;
    setState(() => _busy = true);
    try {
      await action(auth);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('İşlem yapılamadı. Bağlantını kontrol et.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final account = ref.watch(accountProvider).value;
    final configured = ref.watch(authServiceProvider) != null;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(
            account == null ? Icons.person_outline : Icons.verified_user,
            size: 32,
            color: account == null ? AppColors.textMuted : AppColors.accent,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account == null ? 'Misafir' : account.nickname ?? 'Hesabın',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  account?.email ??
                      (configured
                          ? 'İlerlemen bu cihazda. Klanlar için giriş yap.'
                          : 'Hesaplar bu sürümde kapalı.'),
                  style: const TextStyle(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          if (configured && account == null)
            FilledButton.icon(
              onPressed: _busy ? null : () => _run((a) => a.signInWithGoogle()),
              icon: const Icon(Icons.login, size: 18),
              label: const Text('Google ile giriş'),
            ),
          if (account != null)
            TextButton(
              onPressed: _busy ? null : () => _run((a) => a.signOut()),
              child: const Text('Çıkış'),
            ),
        ],
      ),
    );
  }
}
