import Foundation

/// A protocol that defines a type-safe interface for storing and retrieving values
/// in the system keychain.
///
/// This protocol provides generic support for `Data`, `String`, `UUID`, and `Codable` types.
/// It allows configuring the associated account and service context for each operation.
///
/// Types conforming to this protocol must specify concrete types for `Account`
/// and `Service`, which describe keychain item identity and service grouping.
///
/// ## Topics
///
/// ### Associated Types
///
/// - ``Account``
/// - ``Service``
///
/// ### Instance Properties
///
/// - ``service``
///
/// ### Retrieving Values
///
/// - ``get(_:)-2gcee``
/// - ``get(_:)-23z7h``
/// - ``get(_:)-4xbe6``
/// - ``get(_:decoder:)``
///
/// ### Storing Values
///
/// - ``set(_:for:)-21dla``
/// - ``set(_:for:)-6nzkf``
/// - ``set(_:for:)-2smpc``
/// - ``set(_:for:encoder:)``
///
/// ### Deleting Values
///
/// - ``delete(_:)``
public protocol KeychainStorageProtocol {
    /// A type that describes a keychain account and its security configuration.
    associatedtype Account: KeychainAccountProtocol
    
    /// A type that identifies a keychain service context (e.g., app or subsystem).
    associatedtype Service: KeychainServiceProtocol
    
    /// The service associated with this keychain storage instance.
    ///
    /// This value is used as the `kSecAttrService` when interacting with the keychain.
    /// If `nil`, the default service behavior is used.
    var service: Service? { get }
    
    /// Retrieves the value stored in the keychain for the specified account as raw `Data`.
    ///
    /// - Parameter account: The keychain account whose value should be retrieved.
    /// - Returns: The data associated with the given account.
    /// - Throws: An error if the item is not found, access is denied, or another keychain error occurs.
    func get(_ account: Account) throws(KeychainError) -> Data
    
    /// Retrieves the value stored in the keychain for the specified account as a UTF-8 string.
    ///
    /// - Parameter account: The keychain account whose value should be retrieved.
    /// - Returns: A string decoded from the stored data using UTF-8 encoding.
    /// - Throws: An error if the item is not found, the data is not valid UTF-8,
    ///   or a keychain access error occurs.
    func get(_ account: Account) throws(KeychainError) -> String
    
    /// Retrieves the value stored in the keychain for the specified account as a `UUID`.
    ///
    /// - Parameter account: The keychain account whose value should be retrieved.
    /// - Returns: A UUID decoded from a 16-byte binary representation stored in the keychain.
    /// - Throws: An error if the item is not found, the data is not exactly 16 bytes,
    ///   or a keychain access error occurs.
    func get(_ account: Account) throws(KeychainError) -> UUID
    
    /// Retrieves and decodes a value of type `T` stored in the keychain for the specified account.
    ///
    /// - Parameters:
    ///   - account: The keychain account whose value should be retrieved.
    ///   - decoder: The `JSONDecoder` instance used to decode the stored data.
    /// - Returns: A decoded instance of type `T`.
    /// - Throws: An error if the item is not found, decoding fails, or a keychain access error occurs.
    func get<T: Decodable>(_ account: Account, decoder: JSONDecoder) throws(KeychainError) -> T
    
    /// Stores raw `Data` in the keychain for the specified account.
    ///
    /// - Parameters:
    ///   - value: The data to store in the keychain.
    ///   - account: The keychain account under which the data will be saved.
    /// - Throws: An error if storing the data fails.
    func set(_ value: Data, for account: Account) throws(KeychainError)
    
    /// Stores a UTF-8 encoded `String` in the keychain for the specified account.
    ///
    /// - Parameters:
    ///   - value: The string to store in the keychain.
    ///   - account: The keychain account under which the string will be saved.
    /// - Throws: An error if storing the string fails.
    func set(_ value: String, for account: Account) throws(KeychainError)
    
    /// Stores a `UUID` in the keychain for the specified account.
    ///
    /// - Parameters:
    ///   - value: The UUID to store in the keychain (stored in 16-byte binary format).
    ///   - account: The keychain account under which the UUID will be saved.
    /// - Throws: An error if storing the UUID fails.
    func set(_ value: UUID, for account: Account) throws(KeychainError)
    
    /// Encodes and stores a value of type `T` in the keychain for the specified account.
    ///
    /// - Parameters:
    ///   - value: The value to encode and store.
    ///   - account: The keychain account under which the encoded data will be saved.
    ///   - encoder: The `JSONEncoder` used to encode the value.
    /// - Throws: An error if encoding or storing the value fails.
    func set<T: Encodable>(_ value: T, for account: Account, encoder: JSONEncoder) throws(KeychainError)
    
    /// Deletes the keychain item associated with the specified account.
    ///
    /// - Parameter account: The keychain account whose stored value should be deleted.
    /// - Note: If the item does not exist, the method completes silently without error.
    /// - Throws: An error only if the item exists but removal fails.
    func delete(_ account: Account) throws(KeychainError)
}

public extension KeychainStorageProtocol {
    /// Retrieves a UTF-8 encoded string stored in the keychain for the specified account.
    ///
    /// - Parameter account: The account identifier used to locate the stored value.
    /// - Returns: A string decoded from the keychain data using UTF-8 encoding.
    /// - Throws: ``KeychainError/unexpectedData`` if the data cannot be decoded as UTF-8.
    /// - Throws: Any error thrown by ``KeychainStorageProtocol/get(_:)-2gcee``
    ///   if reading the raw data fails.
    func get(_ account: Account) throws(KeychainError) -> String {
        guard let value = String(data: try get(account), encoding: .utf8) else {
            throw KeychainError.unexpectedData
        }
        return value
    }
    
    /// Retrieves a `UUID` stored in the keychain for the specified account.
    ///
    /// - Parameter account: The account identifier used to locate the stored value.
    /// - Returns: A UUID decoded from the keychain string.
    /// - Throws: ``KeychainError/unexpectedData`` if the stored string is missing or invalid.
    /// - Throws: Any error thrown by ``KeychainStorageProtocol/get(_:)-23z7h``
    ///   if reading the string from the keychain fails.
    func get(_ account: Account) throws(KeychainError) -> UUID {
        guard let value = UUID(uuidString: try get(account)) else {
            throw KeychainError.unexpectedData
        }
        return value
    }
    
    /// Retrieves a value of type `T` stored in the keychain and decodes it from JSON using the given decoder.
    ///
    /// - Parameters:
    ///   - account: The account identifier used to locate the stored value.
    ///   - decoder: The `JSONDecoder` to use for decoding. Defaults to a new instance.
    /// - Returns: A decoded instance of type `T`.
    /// - Throws: ``KeychainError/unexpectedError(_:)`` if the data cannot be decoded into the specified type.
    /// - Throws: Any error thrown by ``KeychainStorageProtocol/get(_:)-2gcee`` if reading the raw data fails.
    func get<T: Decodable>(
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
    
    /// Stores a UTF-8 encoded string in the keychain for the specified account.
    ///
    /// - Parameters:
    ///   - value: The string to store.
    ///   - account: The account identifier used as the key for storing the value.
    /// - Throws: ``KeychainError/unexpectedData`` if the string cannot be encoded as UTF-8.
    /// - Throws: Any error thrown by ``KeychainStorageProtocol/set(_:for:)-21dla``
    ///   if saving the data fails.
    func set(_ value: String, for account: Account) throws(KeychainError) {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.unexpectedData
        }
        try set(data, for: account)
    }
    
    /// Stores a `UUID` value as a UTF-8 encoded string in the keychain for the specified account.
    ///
    /// - Parameters:
    ///   - value: The UUID to store.
    ///   - account: The account identifier used as the key for storing the value.
    /// - Throws: Any error thrown by ``KeychainStorageProtocol/set(_:for:)-6nzkf``
    ///   if saving the data fails.
    func set(_ value: UUID, for account: Account) throws(KeychainError) {
        try set(value.uuidString, for: account)
    }
    
    /// Stores an `Encodable` value in the keychain as JSON-encoded data for the specified account.
    ///
    /// - Parameters:
    ///   - value: The value to encode and store.
    ///   - account: The account identifier used as the key for storing the value.
    ///   - encoder: The JSON encoder to use (default is a new instance).
    /// - Throws: ``KeychainError/unexpectedError(_:)`` if encoding the value fails.
    /// - Throws: Any error thrown by ``KeychainStorageProtocol/set(_:for:)-21dla``
    ///   if saving the data fails.
    func set<T: Encodable>(
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
}
