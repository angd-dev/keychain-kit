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
/// - ``get(_:)-5u61a``
/// - ``get(_:)-502rt``
/// - ``get(_:)-63a3x``
/// - ``get(_:decoder:)``
///
/// ### Storing Values
///
/// - ``set(_:for:)-7053g``
/// - ``set(_:for:)-99s6o``
/// - ``set(_:for:)-2e1p6``
/// - ``set(_:for:encoder:)``
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
    
    /// Retrieves raw `Data` stored in Keychain for the specified account.
    ///
    /// - Parameter account: The account identifier conforming to `KeychainAccountProtocol`.
    /// - Returns: The raw data associated with the given account.
    /// - Throws: ``KeychainError/itemNotFound`` when no keychain item matches the query.
    /// - Throws: ``KeychainError/authenticationFailed`` if biometric or device authentication fails.
    /// - Throws: ``KeychainError/unexpectedData`` if the stored data is missing or corrupted.
    /// - Throws: ``KeychainError/unexpectedCode(_:)`` for any other OSStatus error returned by the Keychain API.
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
    
    /// Retrieves a UTF-8 encoded string stored in Keychain for the specified account.
    ///
    /// - Parameter account: The account identifier conforming to `KeychainAccountProtocol`.
    /// - Returns: The stored string value associated with the account.
    /// - Throws: ``KeychainError/itemNotFound`` when no keychain item matches the query.
    /// - Throws: ``KeychainError/authenticationFailed`` if biometric or device authentication fails.
    /// - Throws: ``KeychainError/unexpectedData`` if the stored data cannot be decoded as UTF-8.
    /// - Throws: ``KeychainError/unexpectedCode(_:)`` for any other OSStatus error returned by the Keychain API.
    public func get(_ account: Account) throws(KeychainError) -> String {
        guard let value = String(data: try get(account), encoding: .utf8) else {
            throw KeychainError.unexpectedData
        }
        return value
    }
    
    /// Retrieves a `UUID` stored in Keychain for the specified account.
    ///
    /// - Parameter account: The account identifier conforming to `KeychainAccountProtocol`.
    /// - Returns: The stored UUID value associated with the account.
    /// - Throws: ``KeychainError/itemNotFound`` when no keychain item matches the query.
    /// - Throws: ``KeychainError/authenticationFailed`` if biometric or device authentication fails.
    /// - Throws: ``KeychainError/unexpectedData`` if the stored string is missing or is not a valid UUID.
    /// - Throws: ``KeychainError/unexpectedCode(_:)`` for any other OSStatus error returned by the Keychain API.
    public func get(_ account: Account) throws(KeychainError) -> UUID {
        guard let value = UUID(uuidString: try get(account)) else {
            throw KeychainError.unexpectedData
        }
        return value
    }
    
    /// Retrieves a value of type `T` stored in Keychain, decoded from JSON using the provided decoder.
    ///
    /// - Parameters:
    ///   - account: The account identifier conforming to `KeychainAccountProtocol`.
    ///   - decoder: The `JSONDecoder` instance used to decode the data (default is a new instance).
    /// - Returns: The decoded value of type `T`.
    /// - Throws: ``KeychainError/itemNotFound`` when no keychain item matches the query.
    /// - Throws: ``KeychainError/authenticationFailed`` if biometric or device authentication fails.
    /// - Throws: ``KeychainError/unexpectedData`` if the stored data is missing or corrupted.
    /// - Throws: ``KeychainError/unexpectedCode(_:)`` for any OSStatus error returned by the Keychain API.
    /// - Throws: ``KeychainError/unexpectedError(_:)`` if decoding the data into `T` fails.
    public func get<T: Decodable>(
        _ account: Account,
        decoder: JSONDecoder = .init()
    ) throws(KeychainError) -> T {
        let value: Data = try get(account)
        do {
            return try decoder.decode(T.self, from: value)
        } catch {
            throw KeychainError.unexpectedError(error)
        }
    }
    
    /// Stores raw `Data` in the Keychain for the specified account, replacing any existing value.
    ///
    /// - Parameters:
    ///   - value: The raw data to store in the Keychain.
    ///   - account: The account identifier conforming to `KeychainAccountProtocol`.
    /// - Throws: ``KeychainError/unexpectedError(_:)`` if access control creation fails.
    /// - Throws: ``KeychainError/unexpectedCode(_:)`` if adding the item to the Keychain fails.
    /// - Throws: Any error thrown by ``delete(_:)`` if the previous value cannot be removed.
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
    
    /// Stores a UTF-8 encoded string in the Keychain for the specified account.
    ///
    /// - Parameters:
    ///   - value: The string value to store.
    ///   - account: The account identifier conforming to `KeychainAccountProtocol`.
    /// - Throws: ``KeychainError/unexpectedError(_:)`` if access control creation fails.
    /// - Throws: ``KeychainError/unexpectedCode(_:)`` if adding the item to the Keychain fails.
    /// - Throws: Any error thrown by ``set(_:for:)-7053g`` if encoding or insertion fails.
    public func set(_ value: String, for account: Account) throws(KeychainError) {
        try set(value.data(using: .utf8)!, for: account)
    }
    
    /// Stores a `UUID` value as a string in the Keychain for the specified account.
    ///
    /// - Parameters:
    ///   - value: The UUID value to store.
    ///   - account: The account identifier conforming to `KeychainAccountProtocol`.
    /// - Throws: ``KeychainError/unexpectedError(_:)`` if access control creation fails.
    /// - Throws: ``KeychainError/unexpectedCode(_:)`` if adding the item to the Keychain fails.
    /// - Throws: Any error thrown by ``set(_:for:)-7053g`` if encoding or insertion fails.
    public func set(_ value: UUID, for account: Account) throws(KeychainError) {
        try set(value.uuidString, for: account)
    }
    
    /// Stores an `Encodable` value in the Keychain as JSON-encoded data for the specified account.
    ///
    /// - Parameters:
    ///   - value: The value to encode and store.
    ///   - account: The account identifier conforming to `KeychainAccountProtocol`.
    ///   - encoder: The `JSONEncoder` to use for encoding the value (default is a new instance).
    /// - Throws: ``KeychainError/unexpectedError(_:)`` if encoding fails.
    /// - Throws: ``KeychainError/unexpectedError(_:)`` if access control creation fails.
    /// - Throws: ``KeychainError/unexpectedCode(_:)`` if adding the item to the Keychain fails.
    /// - Throws: Any error thrown by ``set(_:for:)-7053g`` if insertion fails.
    public func set<T: Encodable>(
        _ value: T,
        for account: Account,
        encoder: JSONEncoder = .init()
    ) throws(KeychainError) {
        do {
            let data = try encoder.encode(value)
            try set(data, for: account)
        } catch let error as KeychainError {
            throw error
        } catch {
            throw KeychainError.unexpectedError(error)
        }
    }
    
    /// Deletes the item associated with the specified account from the Keychain.
    ///
    /// If no item exists for the given account, the method does nothing and does not throw an error.
    ///
    /// - Parameter account: The account identifier conforming to `KeychainAccountProtocol`.
    /// - Throws: ``KeychainError/unexpectedCode(_:)`` if deletion fails with an unexpected OSStatus.
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
