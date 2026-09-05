import Flutter
import UIKit
import UserNotifications
import alarm

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // flutter_local_notifications: ön planda bildirim ve aksiyon butonları için
    UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    // alarm: arka planda alarmı canlı tutan görevler
    SwiftAlarmPlugin.registerBackgroundTasks()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
