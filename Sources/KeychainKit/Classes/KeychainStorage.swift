import Foundation
import LocalAuthentication
import Security

/// A type-safe storage abstraction over the Keychain service.
///
/// Supports storing, retrieving, and deleting generic data associated with
/// accounts and services, with optional local authentication context support.
///
/// ## Topics
///
/// ### Initializers
///
/// - ``init(service:context:)``
///
/// ### Instance Properties
///
/// - ``service``
/// - ``context``
///
/// ### Retrieving Values
///
/// - ``get(_:)``
///
/// ### Storing Values
///
/// - ``set(_:for:)``
///
/// ### Deleting Values
///
/// - ``delete(_:)``
public final class KeychainStorage<
    Account: KeychainAccountProtocol,
    Service: KeychainServiceProtocol
>: KeychainStorageProtocol {
    // MARK: - Properties
    
    /// The service metadata associated with this Keychain storage instance.
    public let service: Service?
    
    /// An optional local authentication context used for biometric or passcode protection.
    public let context: LAContext?
    
    // MARK: - Inits
    
    /// Creates a new `KeychainStorage` instance with the given service and authentication context.
    ///
    /// - Parameters:
    ///   - service: An optional `Service` instance representing the keychain service metadata.
    ///   - context: An optional `LAContext` instance for authentication protection.
    public init(service: Service?, context: LAContext?) {
        self.service = service
        self.context = context
    }
    
    // MARK: - Methods
    
    /// Retrieves raw `Data` stored in the keychain for the specified account.
    ///
    /// - Parameter account: The account identifier used to locate the stored value.
    /// - Returns: The raw data associated with the specified account.
    ///
    /// - Throws: ``KeychainError/itemNotFound`` if no matching item is found in the keychain.
    /// - Throws: ``KeychainError/authenticationFailed`` if biometric or device authentication fails.
    /// - Throws: ``KeychainError/unexpectedData`` if the retrieved data is missing or corrupted.
    /// - Throws: ``KeychainError/unexpectedCode(_:)`` for any other unexpected OSStatus error.
    public func get(_ account: Account) throws(KeychainError) -> Data {
        var query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: account.identifier,
            kSecAttrSynchronizable: account.synchronizable,
            kSecUseDataProtectionKeychain: true,
            kSecMatchLimit: kSecMatchLimitOne,
            kSecReturnAttributes: true,
            kSecReturnData: true
        ]
        
        query[kSecAttrService] = service?.identifier
        query[kSecAttrAccessGroup] = service?.accessGroup
        query[kSecUseAuthenticationContext] = context
        
        var queryResult: AnyObject?
        let status = withUnsafeMutablePointer(to: &queryResult) {
            SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
        }
        
        switch status {
        case errSecSuccess:
            guard
                let item = queryResult as? [CFString : AnyObject],
                let data = item[kSecValueData] as? Data
            else { throw KeychainError.unexpectedData }
            return data
        case errSecItemNotFound:
            throw KeychainError.itemNotFound
        case errSecAuthFailed:
            throw KeychainError.authenticationFailed
        default:
            throw KeychainError.unexpectedCode(status)
        }
    }
    
    /// Stores raw `Data` in the keychain for the specified account, replacing any existing value.
    ///
    /// This method first deletes any existing keychain item for the account, then creates a new
    /// item with the specified data and applies the access control settings from the account's
    /// protection and flags.
    ///
    /// - Parameters:
    ///   - value: The raw data to store.
    ///   - account: The account identifier conforming to `KeychainAccountProtocol`.
    ///
    /// - Throws: ``KeychainError/unexpectedError(_:)`` if access control creation fails.
    /// - Throws: ``KeychainError/unexpectedCode(_:)`` if adding the new item to the keychain fails.
    /// - Throws: Any error thrown by ``delete(_:)`` if the existing item cannot be removed.
    public func set(_ value: Data, for account: Account) throws(KeychainError) {
        try delete(account)
        
        var error: Unmanaged<CFError>?
        let access = SecAccessControlCreateWithFlags(
            nil, account.protection, account.accessFlags, &error
        )
        
        guard let access else {
            throw KeychainError.unexpectedError(error?.takeUnretainedValue())
        }
        
        var query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: account.identifier,
            kSecAttrSynchronizable: account.synchronizable,
            kSecUseDataProtectionKeychain: true,
            kSecAttrAccessControl: access,
            kSecValueData: value
        ]
        
        query[kSecAttrService] = service?.identifier
        query[kSecAttrAccessGroup] = service?.accessGroup
        query[kSecUseAuthenticationContext] = context
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == noErr else {
            throw KeychainError.unexpectedCode(status)
        }
    }
    
    /// Deletes the keychain item associated with the specified account.
    ///
    /// If no item exists for the given account, this method completes silently without error.
    ///
    /// - Parameter account: The account identifier conforming to `KeychainAccountProtocol`.
    /// - Throws: ``KeychainError/unexpectedCode(_:)`` if the deletion fails with an unexpected OSStatus.
    public func delete(_ account: Account) throws(KeychainError) {
        var query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: account.identifier,
            kSecAttrSynchronizable: account.synchronizable,
            kSecUseDataProtectionKeychain: true
        ]
        
        query[kSecAttrService] = service?.identifier
        query[kSecAttrAccessGroup] = service?.accessGroup
        query[kSecUseAuthenticationContext] = context
        
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedCode(status)
        }
    }
}
