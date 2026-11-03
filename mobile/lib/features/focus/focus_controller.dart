import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odaklan_core/odaklan_core.dart';

import '../../app/services.dart';
import 'wallet.dart';

typedef FocusState = ({FocusSession? active, FocusSession? lastEnded});

/// Runs the current focus session: ticks it, watches the app lifecycle,
/// persists it, and credits the wallet exactly once when it ends.
class FocusController extends Notifier<FocusState> {
  static const _activeKey = 'focus.active';

  Timer? _timer;
  AppLifecycleListener? _lifecycle;

  DateTime _now() => ref.read(clockProvider)();

  @override
  FocusState build() {
    _lifecycle = AppLifecycleListener(onHide: onHidden, onShow: onShown);
    ref.onDispose(() {
      _timer?.cancel();
      _lifecycle?.dispose();
    });

    final raw = ref.read(prefsProvider).getString(_activeKey);
    var restored = raw == null ? null : FocusSession.tryFromJson(_decode(raw));
    if (restored != null && restored.isRunning) {
      // shortcut: if the process died in the background, the native lock
      // times died with it, so the gap counts as leaving the app. Upgrade by
      // persisting lock times natively if users report false breaks.
      restored = restored.backgroundedAt != null
          ? restored.resumed(_now())
          : restored.tick(_now());
    }
    if (restored == null || !restored.isRunning) {
      if (restored != null) {
        final ended = restored;
        ref.read(prefsProvider).remove(_activeKey);
        // Providers may not modify other providers while building.
        Future.microtask(
          () => ref.read(walletProvider.notifier).add(ended.reward),
        );
      }
      return (active: null, lastEnded: restored);
    }
    _startTimer();
    return (active: restored, lastEnded: null);
  }

  static Object? _decode(String raw) {
    try {
      return jsonDecode(raw);
    } on FormatException {
      return null;
    }
  }

  void start(Duration planned) {
    if (state.active != null) return;
    final session = FocusSession.start(_now(), planned);
    HapticFeedback.mediumImpact();
    _set(session);
    _startTimer();
  }

  void giveUp() => _update(state.active?.giveUp(_now()));

  void dismissResult() => state = (active: state.active, lastEnded: null);

  @visibleForTesting
  void onHidden() => _update(state.active?.backgrounded(_now()));

  @visibleForTesting
  Future<void> onShown() async {
    if (state.active?.backgroundedAt == null) return;
    final lock = await ref.read(screenLockProvider).take();
    _update(
      state.active?.resumed(
        _now(),
        lockedAt: lock.lockedAt,
        unlockedAt: lock.unlockedAt,
      ),
    );
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _update(state.active?.tick(_now())),
    );
  }

  void _update(FocusSession? next) {
    if (next == null || identical(next, state.active)) return;
    if (next.isRunning) {
      _set(next);
    } else {
      _finish(next);
    }
  }

  void _set(FocusSession session) {
    state = (active: session, lastEnded: state.lastEnded);
    ref.read(prefsProvider).setString(_activeKey, jsonEncode(session.toJson()));
  }

  void _finish(FocusSession ended) {
    _timer?.cancel();
    ref.read(prefsProvider).remove(_activeKey);
    ref.read(walletProvider.notifier).add(ended.reward);
    ended.phase == FocusPhase.completed
        ? HapticFeedback.heavyImpact()
        : HapticFeedback.vibrate();
    state = (active: null, lastEnded: ended);
  }
}

final focusProvider = NotifierProvider<FocusController, FocusState>(
  FocusController.new,
);
