import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    // Register custom method channel for opening WeCom/WeChat KF links
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(name: "app.wechat/launch", binaryMessenger: controller.binaryMessenger)
      channel.setMethodCallHandler { call, result in
        switch call.method {
        case "openWeComKf":
          if let args = call.arguments as? [String: Any], let kfidUrl = args["kfidUrl"] as? String, let url = URL(string: kfidUrl) {
            if UIApplication.shared.canOpenURL(url) {
              UIApplication.shared.open(url, options: [:]) { _ in
                result(nil)
              }
            } else {
              result(FlutterError(code: "CANNOT_OPEN", message: "Cannot open URL", details: nil))
            }
          } else {
            result(FlutterError(code: "INVALID_ARGS", message: "kfidUrl missing or invalid", details: nil))
          }
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
