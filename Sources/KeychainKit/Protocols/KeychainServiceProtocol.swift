import Foundation

/// A type that describes a keychain service used to group and identify stored items.
///
/// Conforming types define a unique service identifier and may optionally specify an access group
/// for sharing keychain data between multiple apps or extensions.
///
/// ## Topics
///
/// ### Properties
///
/// - ``identifier``
/// - ``accessGroup``
public protocol KeychainServiceProtocol: Sendable {
    /// A unique string that identifies the keychain service.
    var identifier: String { get }
    
    /// An optional keychain access group identifier that enables shared access between apps.
    ///
    /// Defaults to `nil`, meaning no access group is specified.
    var accessGroup: String? { get }
}

public extension KeychainServiceProtocol {
    var accessGroup: String? { nil }
}

public extension KeychainServiceProtocol where Self: RawRepresentable, Self.RawValue == String {
    /// A unique string that identifies the keychain service.
    ///
    /// Derived from the instance’s raw string value.
    var identifier: String { rawValue }
}
