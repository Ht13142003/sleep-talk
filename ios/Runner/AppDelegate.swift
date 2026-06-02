import Flutter
import UIKit
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var backgroundTask: UIBackgroundTaskIdentifier = .invalid

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    configureAudioSession()
    registerObservers()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // MARK: - Audio Session

  private func configureAudioSession() {
    let session = AVAudioSession.sharedInstance()
    do {
      // .playAndRecord + .defaultToSpeaker: 允许同时播放和录音
      // .allowBluetooth: 支持蓝牙耳机
      // .allowBluetoothA2DP: 支持高质量蓝牙音频
      try session.setCategory(
        .playAndRecord,
        mode: .default,
        options: [.allowBluetooth, .defaultToSpeaker, .allowBluetoothA2DP]
      )
      try session.setActive(true, options: .notifyOthersOnDeactivation)
    } catch {
      print("[SleepTalk] Failed to configure audio session: \(error)")
    }
  }

  // MARK: - Observers

  private func registerObservers() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleInterruption(_:)),
      name: AVAudioSession.interruptionNotification,
      object: nil
    )

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleRouteChange(_:)),
      name: AVAudioSession.routeChangeNotification,
      object: nil
    )

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleMediaServicesReset),
      name: AVAudioSession.mediaServicesWereResetNotification,
      object: nil
    )
  }

  @objc private func handleInterruption(_ notification: Notification) {
    guard let userInfo = notification.userInfo,
          let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
          let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
      return
    }

    if type == .ended {
      // 中断结束（如来电结束），重新激活音频会话
      let session = AVAudioSession.sharedInstance()
      do {
        try session.setActive(true, options: .notifyOthersOnDeactivation)
      } catch {
        print("[SleepTalk] Failed to reactivate audio: \(error)")
      }
    }
  }

  @objc private func handleRouteChange(_ notification: Notification) {
    // 音频路由变化（如插拔耳机），保持会话活跃
    let session = AVAudioSession.sharedInstance()
    do {
      try session.setActive(true, options: .notifyOthersOnDeactivation)
    } catch {
      print("[SleepTalk] Route change error: \(error)")
    }
  }

  @objc private func handleMediaServicesReset() {
    // 媒体服务重置（罕见情况），重新配置音频
    configureAudioSession()
  }

  // MARK: - Background Task

  override func applicationDidEnterBackground(_ application: UIApplication) {
    // 申请后台任务时间，确保 App 不会立即被挂起
    backgroundTask = application.beginBackgroundTask(withName: "SleepTalkMonitoring") { [weak self] in
      self?.endBackgroundTask()
    }

    // 确保音频会话在进入后台时保持活跃
    let session = AVAudioSession.sharedInstance()
    do {
      try session.setActive(true, options: .notifyOthersOnDeactivation)
    } catch {
      print("[SleepTalk] Background audio activate error: \(error)")
    }
  }

  override func applicationWillEnterForeground(_ application: UIApplication) {
    endBackgroundTask()

    let session = AVAudioSession.sharedInstance()
    do {
      try session.setActive(true, options: .notifyOthersOnDeactivation)
    } catch {
      print("[SleepTalk] Foreground audio activate error: \(error)")
    }
  }

  private func endBackgroundTask() {
    guard backgroundTask != .invalid else { return }
    UIApplication.shared.endBackgroundTask(backgroundTask)
    backgroundTask = .invalid
  }

  // MARK: - Termination

  override func applicationWillTerminate(_ application: UIApplication) {
    endBackgroundTask()
    let session = AVAudioSession.sharedInstance()
    do {
      try session.setActive(false, options: .notifyOthersOnDeactivation)
    } catch {
      print("[SleepTalk] Deactivate error: \(error)")
    }
  }
}