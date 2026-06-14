import Flutter
import UIKit
import AVFoundation
import CallKit
import PushKit
import flutter_callkit_incoming

@main
@objc class AppDelegate: FlutterAppDelegate, PKPushRegistryDelegate {
  private var recorder: AVAudioRecorder?
  private var lastFilePath: URL?
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(name: "com.zbooma.app/voice_recorder",
                                      binaryMessenger: controller.binaryMessenger)
    
    channel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      switch call.method {
      case "startRecording":
        if let args = call.arguments as? [String: Any],
           let path = args["path"] as? String {
          self.startRecording(path: path, result: result)
        } else {
          result(FlutterError(code: "INVALID_PATH", message: "Path was null", details: nil))
        }
      case "stopRecording":
        self.stopRecording(result: result)
      case "cancelRecording":
        self.cancelRecording(result: result)
      case "getAmplitude":
        result(self.getAmplitude())
      default:
        result(FlutterMethodNotImplemented)
      }
    })
    
    GeneratedPluginRegistrant.register(with: self)
    
    // Setup VoIP Push Registry for CallKit background wake
    let mainQueue = DispatchQueue.main
    let voipRegistry: PKPushRegistry = PKPushRegistry(queue: mainQueue)
    voipRegistry.delegate = self
    voipRegistry.desiredPushTypes = [PKPushType.voIP]
    
    // Setup for Missed call notifications (iOS 10+)
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // Handle incoming VoIP push credentials (this feeds the token back to the Dart plugin)
  func pushRegistry(_ registry: PKPushRegistry, didUpdate credentials: PKPushCredentials, for type: PKPushType) {
      // The flutter_callkit_incoming plugin will automatically read this token
      // when we call getDevicePushTokenVoIP() in Dart.
      let token = credentials.token
      print("VoIP Token received: \(token)")
  }
  
  // Handle incoming push payload (this triggers the CallKit UI when app is killed)
  func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
      // Let the flutter_callkit_incoming plugin handle the payload and show the CallKit UI
      completion()
  }
  
  private func startRecording(path: String, result: @escaping FlutterResult) {
    let fileURL = URL(fileURLWithPath: path)
    self.lastFilePath = fileURL
    
    let settings: [String: Any] = [
      AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
      AVSampleRateKey: 44100.0,
      AVNumberOfChannelsKey: 1,
      AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
    ]
    
    do {
      let session = AVAudioSession.sharedInstance()
      try session.setCategory(.playAndRecord, mode: .default)
      try session.setActive(true)
      
      recorder = try AVAudioRecorder(url: fileURL, settings: settings)
      recorder?.isMeteringEnabled = true
      recorder?.record()
      result(true)
    } catch {
      result(FlutterError(code: "START_ERROR", message: error.localizedDescription, details: nil))
    }
  }
  
  private func stopRecording(result: @escaping FlutterResult) {
    recorder?.stop()
    recorder = nil
    result(lastFilePath?.path)
  }
  
  private func cancelRecording(result: @escaping FlutterResult) {
    recorder?.stop()
    if let path = lastFilePath {
      try? FileManager.default.removeItem(at: path)
    }
    recorder = nil
    result(true)
  }
  
  private func getAmplitude() -> Double {
    recorder?.updateMeters()
    let avg = recorder?.averagePower(forChannel: 0) ?? -160.0
    // Convert dB to 0..1
    let normalized = (Double(avg) + 50.0) / 50.0
    return max(0.0, min(1.0, normalized))
  }
}
