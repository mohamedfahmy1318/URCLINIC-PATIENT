import UIKit
import Flutter
import Firebase
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var privacyView: UIView?

  private func resolvedGoogleMapsApiKey() -> String? {
    if let mapsApiKey = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_MAPS_API_KEY") as? String {
      let trimmed = mapsApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
      if !trimmed.isEmpty && trimmed != "$(GOOGLE_MAPS_API_KEY)" {
        return trimmed
      }
    }

    let candidateEnvPaths: [String] = [
      Bundle.main.path(forResource: "flutter_assets", ofType: nil).map { ($0 as NSString).appendingPathComponent(".env") },
      Bundle.main.privateFrameworksPath.map { ($0 as NSString).appendingPathComponent("App.framework/flutter_assets/.env") },
    ].compactMap { $0 }

    for envPath in candidateEnvPaths {
      guard let envContents = try? String(contentsOfFile: envPath, encoding: .utf8) else {
        continue
      }

      for rawLine in envContents.split(whereSeparator: \.isNewline) {
        let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
        if !line.hasPrefix("GOOGLE_MAPS_API_KEY=") { continue }

        var value = String(line.dropFirst("GOOGLE_MAPS_API_KEY=".count)).trimmingCharacters(in: .whitespacesAndNewlines)
        if (value.hasPrefix("\"") && value.hasSuffix("\"")) || (value.hasPrefix("'") && value.hasSuffix("'")) {
          value = String(value.dropFirst().dropLast())
        }

        return value.isEmpty ? nil : value
      }
    }

    return nil
  }

  override func application(
    _ application: UIApplication,	
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let mapsApiKey = resolvedGoogleMapsApiKey() {
      GMSServices.provideAPIKey(mapsApiKey)
    }
    
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }
    FirebaseApp.configure()
    GeneratedPluginRegistrant.register(with: self)
    configurePrivacyProtection()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func configurePrivacyProtection() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(appWillResignActive),
      name: UIApplication.willResignActiveNotification,
      object: nil
    )

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(appDidBecomeActive),
      name: UIApplication.didBecomeActiveNotification,
      object: nil
    )
  }

  @objc private func appWillResignActive() {
    showPrivacyOverlay()
  }

  @objc private func appDidBecomeActive() {
    hidePrivacyOverlay()
  }

  private func showPrivacyOverlay() {
    guard privacyView == nil,
          let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow }) else {
      return
    }

    let overlay = UIView(frame: window.bounds)
    overlay.backgroundColor = UIColor.systemBackground
    overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    window.addSubview(overlay)
    privacyView = overlay
  }

  private func hidePrivacyOverlay() {
    privacyView?.removeFromSuperview()
    privacyView = nil
  }
}
