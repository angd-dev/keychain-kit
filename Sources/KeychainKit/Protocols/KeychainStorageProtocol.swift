import Foundation

public protocol KeychainStorageProtocol: Sendable {
    // MARK: - Types
    
    associatedtype Account: KeychainAccountProtocol
    associatedtype Service: KeychainServiceProtocol
    
    // MARK: - Properties
    
    var service: Service? { get }
    
    // MARK: - Methods
    
    func get(by account: Account) throws(KeychainError) -> Data?
    func insert(_ value: Data, by account: Account) throws(KeychainError)
    func delete(by account: Account) throws(KeychainError)
    func exists(by account: Account) throws(KeychainError) -> Bool
}

// MARK: - Get Extension

public extension KeychainStorageProtocol {
    func get(by account: Account) throws(KeychainError) -> String? {
        guard let data = try get(by: account) else { return nil }
        guard let string = String(data: data, encoding: .utf8) else {
            throw .invalidData
        }
        return string
    }
    
    func get(by account: Account) throws(KeychainError) -> UUID? {
        guard let string: String = try get(by: account) else { return nil }
        guard let uuid = UUID(uuidString: string) else {
            throw .invalidData
        }
        return uuid
    }
    
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
    func insert(_ value: String, by account: Account) throws(KeychainError) {
        guard let data = value.data(using: .utf8) else {
            throw .invalidData
        }
        try insert(data, by: account)
    }
    
    func insert(_ value: UUID, by account: Account) throws(KeychainError) {
        try insert(value.uuidString, by: account)
    }
    
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
