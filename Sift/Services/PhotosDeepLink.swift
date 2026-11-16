import UIKit

/// The one place an undocumented URL scheme is allowed to live.
///
/// `photos-redirect://` opens the Photos app. Apple does not document it, so if App Review
/// ever objects, delete this file: `ProofView` already shows the manual path, and nothing
/// else in the app depends on it.
enum PhotosDeepLink {
    static let photosURL = URL(string: "photos-redirect://")

    /// Returns false when the scheme is unavailable, so the caller can show the manual route.
    @discardableResult
    static func openPhotos() -> Bool {
        guard let photosURL, UIApplication.shared.canOpenURL(photosURL) else { return false }
        UIApplication.shared.open(photosURL)
        return true
    }
}
