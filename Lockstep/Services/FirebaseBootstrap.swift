import Foundation
import FirebaseCore

/// Solo focus sessions work without Firebase. Friends and study sessions need
/// `GoogleService-Info.plist` in the app (see README), so we only turn them on
/// when that file is present instead of crashing at launch.
enum FirebaseBootstrap {
    private(set) static var isConfigured = false

    static func configureIfPossible() {
        guard !isConfigured,
              Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil else { return }
        FirebaseApp.configure()
        isConfigured = true
    }
}
