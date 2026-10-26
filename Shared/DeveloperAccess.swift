import Foundation
import CryptoKit

/// The developer code in Settings, for trying every OMO without earning it first.
/// Only the code's SHA-256 is kept here, so the code itself can't be read out of the app.
enum DeveloperAccess {
    private static let codeHash = "30096ce1bfdd4ab8df85792c379f1fac7b493dadff285fbb96dfbb25fa5d3e9b"

    /// Case, spaces and dashes don't matter.
    static func isValid(_ code: String) -> Bool {
        let normalized = code.uppercased().filter { $0.isASCII && ($0.isLetter || $0.isNumber) }
        let digest = SHA256.hash(data: Data(normalized.utf8))
        return digest.map { String(format: "%02x", $0) }.joined() == codeHash
    }
}
