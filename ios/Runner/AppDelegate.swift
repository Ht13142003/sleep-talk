import Flutter
import UIKit
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    configureAudioSession()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func configureAudioSession() {
    let session = AVAudioSession.sharedInstance()
    do {
      try session.setCategory(
        .playAndRecord,
        mode: .default,
        options: [.allowBluetooth, .defaultToSpeaker, .mixWithOthers]
      )
      try session.setActive(true)
    } catch {
      print("Failed to configure audio session: \(error)")
    }
  }

  override func applicationWillTerminate(_ application: UIApplication) {
    let session = AVAudioSession.sharedInstance()
    do {
      try session.setActive(false)
    } catch {
      print("Failed to deactivate audio session: \(error)")
    }
  }
}