import Foundation

/// An error that represents a keychain operation failure.
///
/// Each case corresponds to a specific system or data error encountered while performing keychain
/// operations.
public enum KeychainError: Error, Equatable {
    /// Authentication was required but failed or was canceled.
    case authenticationFailed
    
    /// An item with the same key already exists in the keychain.
    case duplicateItem
    
    /// The stored or retrieved data has an invalid format.
    case invalidData
    
    /// An unexpected system status code was returned.
    ///
    /// - Parameter status: The underlying `OSStatus` value.
    case osStatus(OSStatus)
    
    /// A lower-level error occurred during encoding, decoding, or other processing.
    ///
    /// - Parameter error: The underlying Foundation error, if available.
    case underlying(NSError?)
    
    /// A localized, human-readable description of the error.
    public var localizedDescription: String {
        switch self {
        case .authenticationFailed:
            return .Error.authenticationFailed
        case .duplicateItem:
            return .Error.duplicateItem
        case .invalidData:
            return .Error.invalidData
        case .osStatus(let status):
            let message = SecCopyErrorMessageString(status, nil)
            return .Error.osStatus(message as? String ?? "")
        case .underlying(let error):
            let message = error?.localizedDescription
            return .Error.underlying(message ?? "")
        }
    }
}
