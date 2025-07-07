import Foundation

/// Errors that can occur during Keychain operations.
public enum KeychainError: Error {
    /// Authentication failed, e.g., due to biometric or passcode denial.
    case authenticationFailed
    /// No item found matching the query.
    case itemNotFound
    /// Unexpected or corrupted data found in Keychain item.
    case unexpectedData
    /// An unexpected OSStatus error code returned by Keychain API.
    case unexpectedCode(OSStatus)
    /// A generic unexpected error, with optional underlying error info.
    case unexpectedError(Error?)
}
