import UIKit
import Flutter
import AVFoundation

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {

    private var isSending = false

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
        let channel = FlutterMethodChannel(name: "morsecodec.com/led_control", binaryMessenger: controller.binaryMessenger)

        channel.setMethodCallHandler({
            [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in guard call.method == "sendMorseCode" else {
                result(FlutterMethodNotImplemented)
                return
            }

            guard let args = call.arguments as? [String: Any], let morseCode = args["morseCode"] as? String else {
                    result(FlutterError(code: "Invalid arguments", message: "Expected 'morseCode' argument of type 'String'", details: nil))
                    return
            }
//
//            let args = call.arguments as? Dictionary<String, Any>
//            let morseCode = args?["morseCode"] as? String
            self?.sendMorseCode(morseCode)
            result(nil)
        })


        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    private func sendMorseCode(_ morseCode: String) {
        guard !isSending else {
            return
        }

        isSending = true
        let device = AVCaptureDevice.default(for: .video)
        if device == nil {
            print("No camera available")
            isSending = false
            return
        }

        do{
            try device!.lockForConfiguration()
            for char in morseCode{
                switch char{
                case ".":
                    device!.torchMode = .on
                    usleep(100_000)
                    device!.torchMode = .off
                    usleep(100_000)
                case "-":
                    device!.torchMode = .on
                    usleep(300_000)
                    device!.torchMode = .off
                    usleep(100_000)
                case " ":
                    usleep(300_000)
                case "/":
                    usleep(500_000)
                default:
                    print("Invalid Morse code sequence")
                    device!.unlockForConfiguration()
                    isSending = false
                    return
                }
            }
            device!.unlockForConfiguration()
            isSending = false
        } catch{
            print("Error: \(error.localizedDescription)")
            isSending = false
        }

    }
}
