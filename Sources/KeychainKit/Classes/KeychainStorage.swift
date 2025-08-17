import Foundation
import LocalAuthentication
import Security

public final class KeychainStorage<
    Account: KeychainAccountProtocol,
    Service: KeychainServiceProtocol
>: KeychainStorageProtocol, @unchecked Sendable {
    // MARK: - Properties
    
    public let service: Service?
    public let context: LAContext?
    
    // MARK: - Inits
    
    public init(service: Service?, context: LAContext?) {
        self.service = service
        self.context = context
    }
    
    // MARK: - Methods
    
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
