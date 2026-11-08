import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  // First screen lock (and the first unlock after it) since Dart last asked, kept in
  // UserDefaults so they survive iOS killing the app while locked.
  // Protected-data notifications fire only when the device has a passcode;
  // without one, locking is indistinguishable from leaving the app.
  private let defaults = UserDefaults.standard

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let center = NotificationCenter.default
    center.addObserver(
      forName: UIApplication.protectedDataWillBecomeUnavailableNotification,
      object: nil, queue: .main
    ) { [weak self] _ in
      // First lock only: a later glance at the lock screen must not overwrite it.
      guard let self, self.defaults.object(forKey: "lockedAt") == nil else { return }
      self.defaults.set(Self.nowMs(), forKey: "lockedAt")
    }
    center.addObserver(
      forName: UIApplication.protectedDataDidBecomeAvailableNotification,
      object: nil, queue: .main
    ) { [weak self] _ in
      // First unlock after that lock: when time away from the app started.
      guard let self, self.defaults.object(forKey: "lockedAt") != nil,
        self.defaults.object(forKey: "unlockedAt") == nil else { return }
      self.defaults.set(Self.nowMs(), forKey: "unlockedAt")
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let channel = FlutterMethodChannel(
      name: "odaklan/screen_lock",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else { return result(FlutterMethodNotImplemented) }
      switch call.method {
      case "takeLockEvents":
        result([
          "lockedAt": self.defaults.object(forKey: "lockedAt") as Any,
          "unlockedAt": self.defaults.object(forKey: "unlockedAt") as Any,
        ])
        self.defaults.removeObject(forKey: "lockedAt")
        self.defaults.removeObject(forKey: "unlockedAt")
      case "sessionStarted":
        // Keep the screen awake during a session; the user may still lock it.
        UIApplication.shared.isIdleTimerDisabled = true
        result(nil)
      case "sessionEnded":
        UIApplication.shared.isIdleTimerDisabled = false
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private static func nowMs() -> Int64 { Int64(Date().timeIntervalSince1970 * 1000) }
}
