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
  
  // Handle incoming VoIP push credentials
  func pushRegistry(_ registry: PKPushRegistry, didUpdate credentials: PKPushCredentials, for type: PKPushType) {
      let tokenString = credentials.token.map { String(format: "%02.2hhx", $0) }.joined()
      SwiftFlutterCallkitIncomingPlugin.sharedInstance?.setDevicePushTokenVoIP(tokenString)
      print("VoIP Token received: \(tokenString)")
  }
  
  // Handle incoming push payload (this triggers the CallKit UI when app is killed)
  func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
      if let data = payload.dictionaryPayload["data"] as? [String: Any],
         let id = data["id"] as? String {
          
          let callerName = data["caller_name"] as? String ?? "Unknown Caller"
          let callType = data["call_type"] as? String ?? "video"
          
          let args: [String: Any] = [
              "id": id,
              "nameCaller": callerName,
              "appName": "Moharek",
              "handle": callerName,
              "type": callType == "video" ? 1 : 0,
              "duration": 30000,
              "extra": data
          ]
          
          let callData = flutter_callkit_incoming.Data(args: args)
          SwiftFlutterCallkitIncomingPlugin.sharedInstance?.showCallkitIncoming(callData, fromPushKit: true)
      }
      
      // Delay completion slightly so CallKit has time to present the UI
      DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
          completion()
      }
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
