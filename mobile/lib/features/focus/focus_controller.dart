import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odaklan_core/odaklan_core.dart';

import '../../app/services.dart';
import '../game/game.dart';

/// [credited] = what the server paid for [lastEnded], city bonus included
/// (null until the server has accepted the report).
typedef FocusState = ({
  FocusSession? active,
  FocusSession? lastEnded,
  FocusReward? credited,
});

/// Runs the current focus session on the phone: ticks it, watches the app
/// lifecycle and screen lock, and reports how it ended to the server, which
/// alone decides what it pays. A report that can't be sent (offline, app
/// killed) is kept and re-sent until the server takes it.
class FocusController extends Notifier<FocusState> {
  /// The running session: server times plus phone-only leave tracking.
  static const _activeKey = 'focus.active';

  /// A finish report the server hasn't accepted yet.
  static const _pendingKey = 'focus.pending';

  Timer? _timer;
  Timer? _retry;
  AppLifecycleListener? _lifecycle;
  var _sending = false;

  DateTime _now() => ref.read(clockProvider)();

  @override
  FocusState build() {
    _lifecycle = AppLifecycleListener(onHide: onHidden, onShow: onShown);
    ref.onDispose(() {
      _timer?.cancel();
      _retry?.cancel();
      _lifecycle?.dispose();
    });
    ref.listen(gameProvider, (_, next) {
      if (next.value case final g?) Future.microtask(() => _reconcile(g));
    }, fireImmediately: true);

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
        final ended = restored;
        // Providers may not modify state while building.
        Future.microtask(() => _finish(ended));
      } else {
        Future.microtask(_flushPending);
      }
      return (active: null, lastEnded: null, credited: null);
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

  /// The server's session wins: adopt one started elsewhere, drop one the
  /// server already closed.
  void _reconcile(GameState g) {
    if (!ref.mounted || _sending) return;
    if (ref.read(prefsProvider).getString(_pendingKey) != null) {
      _flushPending();
      return;
    }
    final server = g.active;
    final local = state.active;
    if (server == null) {
      if (local != null) {
        _timer?.cancel();
        ref.read(prefsProvider).remove(_activeKey);
        ref.read(sessionKeeperProvider).ended();
        state = (active: null, lastEnded: null, credited: null);
      }
      return;
    }
    if (local != null && local.startedAt == server.startedAt) return;
    _set(server);
    _keepAlive(server);
    _startTimer();
  }

  /// Starts on the server (its clock). Returns the refusal, or null.
  /// Throws [GameOffline].
  Future<GameError?> start(
    Duration planned, {
    int stake = 0,
    String? tag,
  }) async {
    if (state.active != null || _sending) return GameError.alreadyRunning;
    _sending = true;
    final GameResult r;
    try {
      r = await ref
          .read(gameProvider.notifier)
          .act(StartSession(planned.inMinutes, stake: stake, tag: tag));
    } finally {
      _sending = false;
    }
    if (!r.ok) return r.error;
    final session = r.state.active!;
    HapticFeedback.mediumImpact();
    ref.read(leaveAlertProvider).requestPermission();
    _set(session);
    _keepAlive(session);
    _startTimer();
    return null;
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
    if (!ref.mounted) return;
    unawaited(_flushPending());
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

  /// Ended on the phone: show it now, report it to the server.
  void _finish(FocusSession ended) {
    _timer?.cancel();
    final prefs = ref.read(prefsProvider);
    prefs.remove(_activeKey);
    prefs.setString(
      _pendingKey,
      jsonEncode(FinishSession(ended.phase, ended.endedAt!).toJson()),
    );
    ref.read(sessionKeeperProvider).ended();
    ended.phase == FocusPhase.completed
        ? HapticFeedback.heavyImpact()
        : HapticFeedback.vibrate();
    state = (active: null, lastEnded: ended, credited: null);
    unawaited(_flushPending());
  }

  /// Sends the kept finish report, if any. Offline → kept for next time.
  Future<void> _flushPending() async {
    final prefs = ref.read(prefsProvider);
    final raw = prefs.getString(_pendingKey);
    if (raw == null || _sending) return;
    final action = GameAction.tryFromJson(_decode(raw));
    if (action is! FinishSession) {
      prefs.remove(_pendingKey);
      return;
    }
    _sending = true;
    try {
      final r = await ref.read(gameProvider.notifier).act(action);
      if (!ref.mounted) return;
      // Phone clock ahead of the server, or spamming: try again shortly.
      if (r.error == GameError.tooEarly || r.error == GameError.rateLimited) {
        _retry?.cancel();
        _retry = Timer(const Duration(seconds: 30), _flushPending);
        return;
      }
      prefs.remove(_pendingKey);
      if (r.ended case final ended?) {
        state = (active: state.active, lastEnded: ended, credited: r.credited);
      }
    } on GameOffline {
      // Kept; re-sent on the next app show or start.
    } finally {
      _sending = false;
    }
  }
}

final focusProvider = NotifierProvider<FocusController, FocusState>(
  FocusController.new,
);
