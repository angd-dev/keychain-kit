import Foundation

/// A protocol that defines the required properties for a keychain service descriptor.
///
/// Types conforming to this protocol provide an identifier used to distinguish stored items
/// and may optionally specify an access group to enable keychain sharing between apps.
public protocol KeychainServiceProtocol {
    /// A unique string used to identify the keychain service.
    var identifier: String { get }

    /// An optional keychain access group identifier to support shared access between apps.
    ///
    /// The default implementation returns `nil`, indicating no access group is specified.
    var accessGroup: String? { get }
}

public extension KeychainServiceProtocol {
    /// The default implementation returns `nil`, indicating that no access group is specified.
    var accessGroup: String? { nil }
}

public extension KeychainServiceProtocol where Self: RawRepresentable, Self.RawValue == String {
    /// Provides a default `identifier` implementation for `RawRepresentable` types
    /// whose `RawValue` is `String`.
    ///
    /// The `identifier` is derived from the raw string value.
    var identifier: String { rawValue }
}
