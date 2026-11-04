import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odaklan_core/odaklan_core.dart';

import '../../app/services.dart';
import '../city/city_controller.dart';
import '../progress/progress_controller.dart';
import 'wallet.dart';

/// [credited] = what the last ended session paid, city bonuses included.
typedef FocusState = ({
  FocusSession? active,
  FocusSession? lastEnded,
  FocusReward? credited,
});

/// Runs the current focus session: ticks it, watches the app lifecycle,
/// persists it, and credits the wallet (reward + contract) and the history
/// exactly once when it ends.
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
        Future.microtask(() {
          final paid = _credit(ended);
          state = (active: null, lastEnded: ended, credited: paid);
        });
      }
      return (active: null, lastEnded: restored, credited: null);
    }
    _startTimer();
    return (active: restored, lastEnded: null, credited: null);
  }

  static Object? _decode(String raw) {
    try {
      return jsonDecode(raw);
    } on FormatException {
      return null;
    }
  }

  /// Returns false (nothing starts) when the stake can't be paid.
  bool start(Duration planned, {int stake = 0, String? tag}) {
    if (state.active != null) return false;
    final session = FocusSession.start(_now(), planned, stake: stake, tag: tag);
    if (stake > 0 && !ref.read(walletProvider.notifier).spend(stake)) {
      return false;
    }
    HapticFeedback.mediumImpact();
    ref.read(leaveAlertProvider).requestPermission();
    _set(session);
    _startTimer();
    return true;
  }

  void giveUp() => _update(state.active?.giveUp(_now()));

  void dismissResult() =>
      state = (active: state.active, lastEnded: null, credited: null);

  @visibleForTesting
  void onHidden() {
    final active = state.active;
    if (active == null) return;
    _update(active.backgrounded(_now()));
    // Ending inside the grace counts as completed, so nothing to warn about.
    if (active.plannedEnd.difference(_now()) > leaveGrace) {
      ref.read(leaveAlertProvider).started(leaveGrace);
    }
  }

  @visibleForTesting
  Future<void> onShown() async {
    ref.read(leaveAlertProvider).ended();
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
    state = (
      active: session,
      lastEnded: state.lastEnded,
      credited: state.credited,
    );
    ref.read(prefsProvider).setString(_activeKey, jsonEncode(session.toJson()));
  }

  void _finish(FocusSession ended) {
    _timer?.cancel();
    ref.read(prefsProvider).remove(_activeKey);
    final paid = _credit(ended);
    ended.phase == FocusPhase.completed
        ? HapticFeedback.heavyImpact()
        : HapticFeedback.vibrate();
    state = (active: null, lastEnded: ended, credited: paid);
  }

  /// Pays the reward boosted by the city as it was during the session,
  /// then lets the city take the repair or damage.
  FocusReward _credit(FocusSession ended) {
    final completed = ended.phase == FocusPhase.completed;
    final paid = ref
        .read(cityProvider)
        .boosted(ended.reward, completed: completed);
    ref
        .read(walletProvider.notifier)
        .add(FocusReward(energy: paid.energy + ended.stakeReturn, xp: paid.xp));
    ref.read(progressProvider.notifier).record(ended);
    ref.read(cityProvider.notifier).afterSession(ended);
    return paid;
  }
}

final focusProvider = NotifierProvider<FocusController, FocusState>(
  FocusController.new,
);
