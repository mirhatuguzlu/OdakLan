import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  // Latest screen lock/unlock times (epoch ms) since Dart last asked.
  // Protected-data notifications fire only when the device has a passcode;
  // without one, locking is indistinguishable from leaving the app.
  private var lockedAt: Int64?
  private var unlockedAt: Int64?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let center = NotificationCenter.default
    center.addObserver(
      forName: UIApplication.protectedDataWillBecomeUnavailableNotification,
      object: nil, queue: .main
    ) { [weak self] _ in self?.lockedAt = Self.nowMs() }
    center.addObserver(
      forName: UIApplication.protectedDataDidBecomeAvailableNotification,
      object: nil, queue: .main
    ) { [weak self] _ in self?.unlockedAt = Self.nowMs() }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let channel = FlutterMethodChannel(
      name: "odaklan/screen_lock",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self, call.method == "takeLockEvents" else {
        result(FlutterMethodNotImplemented)
        return
      }
      result(["lockedAt": self.lockedAt as Any, "unlockedAt": self.unlockedAt as Any])
      self.lockedAt = nil
      self.unlockedAt = nil
    }
  }

  private static func nowMs() -> Int64 { Int64(Date().timeIntervalSince1970 * 1000) }
}
