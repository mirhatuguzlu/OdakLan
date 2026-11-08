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
      if (restored.backgroundedAt != null) {
        // The system killed the app while away (e.g. MIUI LockScreenClean).
        // Lock times are kept natively on disk, so judge the gap with them
        // once this build has returned (onShown reads the state).
        // shortcut: if the process also missed the unlock, the time since
        // locking counts as locked; step 9 UsageStats can close that gap.
        Future.microtask(onShown);
      } else {
        restored = restored.tick(_now());
      }
    }
    if (restored == null || !restored.isRunning) {
      if (restored != null) {
        ref.read(sessionKeeperProvider).ended();
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
    _keepAlive(restored);
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
    _keepAlive(session);
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
    // Always take: the log keeps the FIRST lock since the last take, so
    // events from outside a session must not linger into the next one.
    final lock = await ref.read(screenLockProvider).take();
    if (state.active?.backgroundedAt == null) return;
    _update(
      state.active?.resumed(
        _now(),
        lockedAt: lock.lockedAt,
        unlockedAt: lock.unlockedAt,
      ),
    );
  }

  /// Screen awake + the "Odaklanıyorsun" notification with what finishing pays.
  void _keepAlive(FocusSession s) {
    final best = ref
        .read(cityProvider)
        .boosted(rewardFor(s.planned, completed: true), completed: true);
    final energy = best.energy + stakePayout(s.stake, completed: true);
    ref
        .read(sessionKeeperProvider)
        .started(
          s.startedAt,
          s.plannedEnd,
          subtitle: [
            if (s.tag != null) tagLabel(s.tag),
            '${s.planned.inMinutes} dk seans',
            if (s.stake > 0) '${s.stake} Enerji sözleşme',
          ].join(' · '),
          goal: 'Bitirirsen +$energy Enerji · +${best.xp} XP',
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
    ref.read(sessionKeeperProvider).ended();
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
