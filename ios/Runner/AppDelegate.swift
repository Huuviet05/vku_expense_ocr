import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller = window?.rootViewController as? FlutterViewController
    if let controller = controller {
      let channel = FlutterMethodChannel(
        name: "vn.edu.vku/device_info",
        binaryMessenger: controller.binaryMessenger
      )

      channel.setMethodCallHandler { (call, result) in
        if call.method == "getBatteryLevel" {
          UIDevice.current.isBatteryMonitoringEnabled = true
          let batteryLevel = UIDevice.current.batteryLevel
          if batteryLevel >= 0 {
            result(Int(batteryLevel * 100))
          } else {
            result(-1)
          }
        } else if call.method == "getDeviceInfo" {
          let name = UIDevice.current.name
          let system = UIDevice.current.systemName
          let version = UIDevice.current.systemVersion
          result("\(name) - \(system) \(version)")
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
