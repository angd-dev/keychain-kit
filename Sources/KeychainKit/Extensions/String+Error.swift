import Foundation
import Localizable

extension String {
    @Localizable(bundle: .module)
    enum Error {
        private enum Strings {
            case authenticationFailed
            case duplicateItem
            case invalidData
            case osStatus(String)
            case underlying(String)
        }
    }
}
