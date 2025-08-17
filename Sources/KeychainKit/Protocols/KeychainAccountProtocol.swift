import Foundation

/// A type that describes a keychain account configuration for secure item storage and access.
///
/// Conforming types define metadata that determines how the keychain protects, authenticates, and
/// optionally synchronizes specific items.
///
/// ## Topics
///
/// ### Properties
///
/// - ``identifier``
/// - ``protection``
/// - ``accessFlags``
/// - ``synchronizable``
public protocol KeychainAccountProtocol: Sendable {
    /// A unique string that identifies the keychain account.
    var identifier: String { get }
    
    /// The keychain data protection level assigned to the account.
    ///
    /// Defaults to `kSecAttrAccessibleAfterFirstUnlock`. You can override this to use another
    /// accessibility option, such as `kSecAttrAccessibleWhenUnlocked` or
    /// `kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly`.
    var protection: CFString { get }
    
    /// The access control flags defining additional authentication requirements.
    ///
    /// Defaults to an empty set (`[]`). Override this to enforce constraints like `.userPresence`,
    /// `.biometryAny`, or `.devicePasscode`.
    var accessFlags: SecAccessControlCreateFlags { get }
    
    /// Indicates whether the item is synchronized through iCloud Keychain.
    ///
    /// Defaults to `false`. Set this to `true` if the item should be available across all devices
    /// associated with the same iCloud account.
    var synchronizable: Bool { get }
}

public extension KeychainAccountProtocol {
    var protection: CFString { kSecAttrAccessibleAfterFirstUnlock }
    
    var accessFlags: SecAccessControlCreateFlags { [] }
    
    var synchronizable: Bool { false }
}

public extension KeychainAccountProtocol where Self: RawRepresentable, Self.RawValue == String {
    /// A unique string that identifies the keychain account.
    ///
    /// Derived from the instance’s raw string value.
    var identifier: String { rawValue }
}
