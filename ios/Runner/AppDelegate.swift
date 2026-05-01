import Flutter
import UIKit
import AVFAudio

@main
@objc class AppDelegate: FlutterAppDelegate {
  private func configureAmbientMixAudioSession() {
    let session = AVAudioSession.sharedInstance()
    do {
      // Keep external audio (Spotify/Apple Music) playing while Arena is foreground.
      try session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
      try session.setActive(true, options: [])
    } catch {
      NSLog("Audio session ambient mix config failed: \(error)")
    }
  }

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    configureAmbientMixAudioSession()
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func applicationDidBecomeActive(_ application: UIApplication) {
    super.applicationDidBecomeActive(application)
    // Re-apply in case any plugin reconfigured the session while inactive.
    configureAmbientMixAudioSession()
  }
}
