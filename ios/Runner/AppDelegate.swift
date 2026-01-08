import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller = window?.rootViewController as! FlutterViewController
    let iCloudChannel = FlutterMethodChannel(
      name: "com.smartcompany.longterminvestment/icloud",
      binaryMessenger: controller.binaryMessenger
    )
    
    iCloudChannel.setMethodCallHandler { (call, result) in
      let keyValueStore = NSUbiquitousKeyValueStore.default
      
      if call.method == "setICloudValue" {
        // iCloud Key-Value Storage에 값 저장 (자동 동기화)
        if let args = call.arguments as? [String: Any],
           let key = args["key"] as? String,
           let value = args["value"] as? String {
          keyValueStore.set(value, forKey: key)
          keyValueStore.synchronize()
          result(true)
        } else {
          result(FlutterError(code: "INVALID_ARGUMENT", message: "key and value are required", details: nil))
        }
      } else if call.method == "getICloudValue" {
        // iCloud Key-Value Storage에서 값 읽기
        if let args = call.arguments as? [String: Any],
           let key = args["key"] as? String {
          let value = keyValueStore.string(forKey: key)
          result(value)
        } else {
          result(FlutterError(code: "INVALID_ARGUMENT", message: "key is required", details: nil))
        }
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
