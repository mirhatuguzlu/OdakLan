import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../focus/focus_controller.dart';
import '../game/game.dart';
import 'account.dart';

/// Nothing but sign-in until there is an account and its game has loaded:
/// all progress lives on the server.
class Gate extends ConsumerWidget {
  const Gate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(accountProvider);
    if (account.isLoading && !account.hasValue) return const _Splash();
    if (account.value == null) return const _SignIn();
    final game = ref.watch(gameProvider);
    if (game.hasError && !game.hasValue) {
      return _Problem(
        message: offlineMessage,
        onRetry: () => ref.invalidate(gameProvider),
      );
    }
    if (!game.hasValue) return const _Splash();
    // Keep the focus session (and its lifecycle listener) alive app-wide
    // without rebuilding the app on every tick.
    ref.listen(focusProvider, (_, _) {});
    return child;
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}

class _Problem extends StatelessWidget {
  const _Problem({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Tekrar dene')),
          ],
        ),
      ),
    ),
  );
}

class _SignIn extends ConsumerStatefulWidget {
  const _SignIn();

  @override
  ConsumerState<_SignIn> createState() => _SignInState();
}

class _SignInState extends ConsumerState<_SignIn> {
  var _busy = false;

  Future<void> _signIn(AuthService auth) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await auth.signInWithGoogle();
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Giriş yapılamadı. Tekrar dene.')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authServiceProvider);
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Icon(
                Icons.track_changes,
                size: 72,
                color: AppColors.accent,
              ),
              const SizedBox(height: 24),
              Text(
                'OdakLan',
                textAlign: TextAlign.center,
                style: text.displaySmall,
              ),
              const SizedBox(height: 12),
              const Text(
                'Odaklan, Enerji kazan, şehrini kur.\n'
                'İlerlemen hesabında güvenle saklanır.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted),
              ),
              const Spacer(),
              if (auth == null)
                const Text(
                  'Bu sürümde sunucu ayarları eksik; giriş yapılamıyor.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.danger),
                )
              else
                FilledButton.icon(
                  onPressed: _busy ? null : () => _signIn(auth),
                  icon: const Icon(Icons.login),
                  label: const Text('Google ile giriş yap'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                  ),
                ),
              const SizedBox(height: 12),
              const Text(
                'Diğer oyuncular yalnızca takma adını görür.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
