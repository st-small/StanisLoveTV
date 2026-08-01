import Dependencies
import Foundation

struct UserDefaultsClient: Sendable {
    var data: @Sendable (String) -> Data?
    var setData: @Sendable (Data?, String) -> Void
    var stringArray: @Sendable (String) -> [String]?
    var setStringArray: @Sendable ([String]?, String) -> Void
}

nonisolated extension UserDefaultsClient: DependencyKey {
    static var liveValue: Self {
        Self(
            data: { Foundation.UserDefaults.standard.data(forKey: $0) },
            setData: { value, key in Foundation.UserDefaults.standard.set(value, forKey: key) },
            stringArray: { Foundation.UserDefaults.standard.stringArray(forKey: $0) },
            setStringArray: { value, key in Foundation.UserDefaults.standard.set(value, forKey: key) }
        )
    }

    static let testValue = UserDefaultsClient(
        data: { _ in unimplemented("UserDefaultsClient.data", placeholder: nil) },
        setData: { _, _ in unimplemented("UserDefaultsClient.setData") },
        stringArray: { _ in unimplemented("UserDefaultsClient.stringArray", placeholder: nil) },
        setStringArray: { _, _ in unimplemented("UserDefaultsClient.setStringArray") }
    )
}

nonisolated extension DependencyValues {
    var userDefaultsClient: UserDefaultsClient {
        get { self[UserDefaultsClient.self] }
        set { self[UserDefaultsClient.self] = newValue }
    }
}
