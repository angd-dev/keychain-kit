import Foundation

/// A type that provides access to data stored in the keychain.
///
/// Conforming types define how items are encoded, saved, and accessed securely, using account and
/// service descriptors to identify individual entries.
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
/// ### Retrieving Items
///
/// - ``get(by:)->Data?``
/// - ``get(by:)->String?``
/// - ``get(by:)->UUID?``
/// - ``get(by:decoder:)``
///
/// ### Inserting Items
///
/// - ``insert(_:by:)-(Data,_)``
/// - ``insert(_:by:)-(String,_)``
/// - ``insert(_:by:)-(UUID,_)``
/// - ``insert(_:by:encoder:)``
///
/// ### Deleting Items
///
/// - ``delete(by:)``
///
/// ### Checking Existence
///
/// - ``exists(by:)``
public protocol KeychainStorageProtocol: Sendable {
    // MARK: - Types
    
    /// A type that describes a keychain account used to identify stored items.
    associatedtype Account: KeychainAccountProtocol
    
    /// A type that describes a keychain service used to group stored items.
    associatedtype Service: KeychainServiceProtocol
    
    // MARK: - Properties
    
    /// The keychain service associated with this storage instance.
    var service: Service? { get }
    
    // MARK: - Methods
    
    /// Retrieves raw data for the given account.
    ///
    /// - Parameter account: The account descriptor identifying the stored item.
    /// - Returns: The stored data, or `nil` if no item exists.
    /// - Throws: ``KeychainError`` if the operation fails.
    func get(by account: Account) throws(KeychainError) -> Data?
    
    /// Inserts raw data for the given account.
    ///
    /// - Parameters:
    ///   - value: The data to store.
    ///   - account: The account descriptor identifying the target item.
    /// - Throws: ``KeychainError`` if the operation fails.
    func insert(_ value: Data, by account: Account) throws(KeychainError)
    
    /// Deletes the item for the given account.
    ///
    /// - Parameter account: The account descriptor identifying the item to remove.
    /// - Throws: ``KeychainError`` if the operation fails.
    func delete(by account: Account) throws(KeychainError)
    
    /// Checks whether an item exists for the given account.
    ///
    /// - Parameter account: The account descriptor identifying the stored item.
    /// - Returns: `true` if the item exists; otherwise, `false`.
    /// - Throws: ``KeychainError`` if the check fails.
    func exists(by account: Account) throws(KeychainError) -> Bool
}

// MARK: - Get Extension

public extension KeychainStorageProtocol {
    /// Retrieves a UTF-8 string for the given account.
    ///
    /// - Parameter account: The account descriptor identifying the stored item.
    /// - Returns: The decoded string, or `nil` if no item exists.
    /// - Throws: ``KeychainError`` if retrieval fails.
    /// - Throws: ``KeychainError/invalidData`` if the stored data cannot be decoded as UTF-8.
    func get(by account: Account) throws(KeychainError) -> String? {
        guard let data = try get(by: account) else { return nil }
        guard let string = String(data: data, encoding: .utf8) else {
            throw .invalidData
        }
        return string
    }
    
    /// Retrieves a UUID for the given account.
    ///
    /// - Parameter account: The account descriptor identifying the stored item.
    /// - Returns: The decoded UUID, or `nil` if no item exists.
    /// - Throws: ``KeychainError`` if retrieval fails.
    /// - Throws: ``KeychainError/invalidData`` if the stored value is not a valid UUID string.
    func get(by account: Account) throws(KeychainError) -> UUID? {
        guard let string: String = try get(by: account) else { return nil }
        guard let uuid = UUID(uuidString: string) else {
            throw .invalidData
        }
        return uuid
    }
    
    /// Retrieves and decodes a `Decodable` value for the given account.
    ///
    /// - Parameters:
    ///   - account: The account descriptor identifying the stored item.
    ///   - decoder: The JSON decoder used to decode the stored data.
    /// - Returns: The decoded value, or `nil` if no item exists.
    /// - Throws: ``KeychainError`` if retrieval fails.
    /// - Throws: ``KeychainError/underlying(_:)`` if JSON decoding fails.
    func get<T: Decodable>(
        by account: Account,
        decoder: JSONDecoder = .init()
    ) throws(KeychainError) -> T? {
        guard let data = try get(by: account) else { return nil }
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw .underlying(error as NSError)
        }
    }
}

// MARK: - Set Extension

public extension KeychainStorageProtocol {
    /// Inserts a UTF-8 string for the given account.
    ///
    /// - Parameters:
    ///   - value: The string to store.
    ///   - account: The account descriptor identifying the target item.
    /// - Throws: ``KeychainError`` if the operation fails.
    /// - Throws: ``KeychainError/invalidData`` if the string cannot be encoded as UTF-8.
    func insert(_ value: String, by account: Account) throws(KeychainError) {
        guard let data = value.data(using: .utf8) else {
            throw .invalidData
        }
        try insert(data, by: account)
    }
    
    /// Inserts a UUID for the given account.
    ///
    /// - Parameters:
    ///   - value: The UUID to store.
    ///   - account: The account descriptor identifying the target item.
    /// - Throws: ``KeychainError`` if the operation fails.
    func insert(_ value: UUID, by account: Account) throws(KeychainError) {
        try insert(value.uuidString, by: account)
    }
    
    /// Encodes and inserts an `Encodable` value for the given account.
    ///
    /// - Parameters:
    ///   - value: The value to encode and store.
    ///   - account: The account descriptor identifying the target item.
    ///   - encoder: The JSON encoder used to encode the value.
    /// - Throws: ``KeychainError`` if the operation fails.
    /// - Throws: ``KeychainError/underlying(_:)`` if JSON encoding fails.
    func insert<T: Encodable>(
        _ value: T,
        by account: Account,
        encoder: JSONEncoder = .init()
    ) throws(KeychainError) {
        let data: Data
        do {
            data = try encoder.encode(value)
        } catch {
            throw .underlying(error as NSError)
        }
        try insert(data, by: account)
    }
}
