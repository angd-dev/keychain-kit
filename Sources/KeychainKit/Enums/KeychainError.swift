import Foundation

/// Errors that can occur during Keychain operations.
public enum KeychainError: Error, Equatable {
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
    
    /// Compares two `KeychainError` values for equality.
    ///
    /// - Parameters:
    ///   - lhs: The first `KeychainError` to compare.
    ///   - rhs: The second `KeychainError` to compare.
    /// - Returns: `true` if both errors are of the same case and represent the same error details.
    ///
    /// For `.unexpectedError`, the comparison is based on the underlying `NSError` identity,
    /// which includes domain and error code.
    public static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.authenticationFailed, .authenticationFailed):
            true
        case (.itemNotFound, .itemNotFound):
            true
        case (.unexpectedData, .unexpectedData):
            true
        case (.unexpectedCode(let lCode), .unexpectedCode(let rCode)):
            lCode == rCode
        case (.unexpectedError(let lErr), .unexpectedError(let rErr)):
            lErr as NSError? == rErr as NSError?
        default:
            false
        }
    }
}
