import Foundation
import LocalAuthentication
import Security

/// A service that provides access and management for keychain items.
///
/// This type provides direct access to the system keychain using `Security` and
/// `LocalAuthentication` frameworks. It supports querying, inserting, deleting, and checking item
/// existence, while handling authentication contexts and access controls automatically.
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
/// ### Instance Methods
///
/// - ``get(by:)->Data?``
/// - ``insert(_:by:)-(Data,_)``
/// - ``delete(by:)``
/// - ``exists(by:)``
public final class KeychainStorage<
    Account: KeychainAccountProtocol,
    Service: KeychainServiceProtocol
>: KeychainStorageProtocol, @unchecked Sendable {
    // MARK: - Properties
    
    /// The service descriptor associated with this keychain storage.
    public let service: Service?
    
    /// The authentication context used for keychain operations.
    public let context: LAContext?
    
    // MARK: - Initialization
    
    /// Creates a new keychain storage instance.
    ///
    /// - Parameters:
    ///   - service: The service descriptor that defines the keychain group and access settings.
    ///   - context: The authentication context used for secure access, or `nil` to use a default one.
    public init(service: Service?, context: LAContext?) {
        self.service = service
        self.context = context
    }
    
    // MARK: - Methods
    
    /// Retrieves raw data for the given account.
    ///
    /// - Parameter account: The account descriptor identifying the stored item.
    /// - Returns: The stored data, or `nil` if no item exists.
    /// - Throws: ``KeychainError/invalidData`` if the retrieved value cannot be cast to `Data`.
    /// - Throws: ``KeychainError/authenticationFailed`` if user authentication fails.
    /// - Throws: ``KeychainError/osStatus(_:)`` for unexpected system errors.
    public func get(by account: Account) throws(KeychainError) -> Data? {
        var query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: account.identifier,
            kSecAttrSynchronizable: account.synchronizable,
            kSecUseDataProtectionKeychain: true,
            kSecMatchLimit: kSecMatchLimitOne,
            kSecReturnData: true
        ]
        
        query[kSecAttrService] = service?.identifier
        query[kSecAttrAccessGroup] = service?.accessGroup
        query[kSecUseAuthenticationContext] = context
        
        var result: AnyObject?
        
        switch SecItemCopyMatching(query as CFDictionary, &result) {
        case errSecSuccess:
            if let data = result as? Data {
                return data
            } else {
                throw .invalidData
            }
        case errSecItemNotFound:
            return nil
        case errSecAuthFailed, errSecInteractionNotAllowed, errSecUserCanceled:
            throw .authenticationFailed
        case let status:
            throw .osStatus(status)
        }
    }
    
    /// Inserts raw data for the given account.
    ///
    /// - Parameters:
    ///   - value: The data to store.
    ///   - account: The account descriptor identifying the target item.
    /// - Throws: ``KeychainError/underlying(_:)`` if access control creation fails.
    /// - Throws: ``KeychainError/duplicateItem`` if an item with the same key already exists.
    /// - Throws: ``KeychainError/osStatus(_:)`` for unexpected system errors.
    public func insert(_ value: Data, by account: Account) throws(KeychainError) {
        var error: Unmanaged<CFError>?
        let access = SecAccessControlCreateWithFlags(
            nil, account.protection, account.accessFlags, &error
        )
        
        guard let access else {
            let error = error?.takeRetainedValue()
            throw .underlying(error as? NSError)
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
        
        switch SecItemAdd(query as CFDictionary, nil) {
        case errSecSuccess:
            return
        case errSecDuplicateItem:
            throw .duplicateItem
        case let status:
            throw .osStatus(status)
        }
    }
    
    /// Deletes the item for the given account.
    ///
    /// - Parameter account: The account descriptor identifying the item to remove.
    /// - Throws: ``KeychainError/authenticationFailed`` if user authentication fails.
    /// - Throws: ``KeychainError/osStatus(_:)`` for unexpected system errors.
    public func delete(by account: Account) throws(KeychainError) {
        var query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: account.identifier,
            kSecAttrSynchronizable: account.synchronizable,
            kSecUseDataProtectionKeychain: true
        ]
        
        query[kSecAttrService] = service?.identifier
        query[kSecAttrAccessGroup] = service?.accessGroup
        query[kSecUseAuthenticationContext] = context
        
        switch SecItemDelete(query as CFDictionary) {
        case errSecSuccess, errSecItemNotFound:
            return
        case errSecAuthFailed, errSecInteractionNotAllowed, errSecUserCanceled:
            throw .authenticationFailed
        case let status:
            throw .osStatus(status)
        }
    }
    
    /// Checks whether an item exists for the given account.
    ///
    /// - Parameter account: The account descriptor identifying the stored item.
    /// - Returns: `true` if the item exists; otherwise, `false`.
    /// - Throws: ``KeychainError/osStatus(_:)`` for unexpected system errors.
    public func exists(by account: Account) throws(KeychainError) -> Bool {
        var query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: account.identifier,
            kSecAttrSynchronizable: account.synchronizable,
            kSecUseDataProtectionKeychain: true,
            kSecMatchLimit: kSecMatchLimitOne,
            kSecReturnData: false
        ]
        
        let context = LAContext()
        context.interactionNotAllowed = true
        
        query[kSecAttrService] = service?.identifier
        query[kSecAttrAccessGroup] = service?.accessGroup
        query[kSecUseAuthenticationContext] = context
        
        switch SecItemCopyMatching(query as CFDictionary, nil) {
        case errSecSuccess, errSecAuthFailed, errSecInteractionNotAllowed:
            return true
        case errSecItemNotFound:
            return false
        case let status:
            throw .osStatus(status)
        }
    }
}
