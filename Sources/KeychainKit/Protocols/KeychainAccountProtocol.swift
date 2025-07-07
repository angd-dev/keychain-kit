import Foundation

/// A protocol that defines the required properties for a keychain account descriptor.
///
/// Types conforming to this protocol provide metadata for configuring secure storage
/// and access behavior for keychain items.
public protocol KeychainAccountProtocol {
    /// A unique string used to identify the keychain account.
    var identifier: String { get }
    
    /// The keychain data protection level for the account.
    ///
    /// Defaults to `kSecAttrAccessibleAfterFirstUnlock`. You may override it to use other
    /// accessibility levels, such as `kSecAttrAccessibleWhenUnlocked`
    /// or `kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly`.
    var protection: CFString { get }
    
    /// The access control flags used to define authentication requirements.
    ///
    /// Defaults to `[]` (no additional access control). Can be overridden to specify
    /// constraints such as `.userPresence`, `.biometryAny`, or `.devicePasscode`.
    var accessFlags: SecAccessControlCreateFlags { get }
    
    /// Whether the item should be marked as synchronizable via iCloud Keychain.
    ///
    /// Defaults to `false`. Set to `true` if the item should sync across devices.
    var synchronizable: Bool { get }
}

public extension KeychainAccountProtocol {
    /// Default value for `protection`: accessible after first unlock.
    var protection: CFString { kSecAttrAccessibleAfterFirstUnlock }
    
    /// Default value for `accessFlags`: no access control constraints.
    var accessFlags: SecAccessControlCreateFlags { [] }
    
    /// Default value for `synchronizable`: not synchronized across devices.
    var synchronizable: Bool { false }
}

public extension KeychainAccountProtocol where Self: RawRepresentable, Self.RawValue == String {
    /// Provides a default `identifier` implementation for `RawRepresentable` types
    /// whose `RawValue` is `String`.
    ///
    /// The `identifier` is derived from the raw string value.
    var identifier: String { rawValue }
}
