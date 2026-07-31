import Dependencies
import Foundation

struct UserDefaultsClient: Sendable {
    var data: @Sendable (String) -> Data?
    var setData: @Sendable (Data?, String) -> Void
    var stringArray: @Sendable (String) -> [String]?
    var setStringArray: @Sendable ([String]?, String) -> Void
}

extension UserDefaultsClient: DependencyKey {
    static var liveValue: Self {
        let defaults = Foundation.UserDefaults.standard
        return Self(
            data: { defaults.data(forKey: $0) },
            setData: { value, key in defaults.set(value, forKey: key) },
            stringArray: { defaults.stringArray(forKey: $0) },
            setStringArray: { value, key in defaults.set(value, forKey: key) }
        )
    }

    static let testValue = UserDefaultsClient(
        data: { _ in unimplemented("UserDefaultsClient.data", placeholder: nil) },
        setData: { _, _ in unimplemented("UserDefaultsClient.setData") },
        stringArray: { _ in unimplemented("UserDefaultsClient.stringArray", placeholder: nil) },
        setStringArray: { _, _ in unimplemented("UserDefaultsClient.setStringArray") }
    )
}

extension DependencyValues {
    var userDefaultsClient: UserDefaultsClient {
        get { self[UserDefaultsClient.self] }
        set { self[UserDefaultsClient.self] = newValue }
    }
}
