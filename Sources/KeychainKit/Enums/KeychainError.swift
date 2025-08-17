import Foundation

public enum KeychainError: Error, Equatable {
    case authenticationFailed
    case duplicateItem
    case invalidData
    case osStatus(OSStatus)
    case underlying(NSError?)
    
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
