import Dependencies
import Foundation

struct NetworkService {
    var fetchData: (URL) async throws -> Data
    var downloadToCache: (URL, String) async throws -> URL
    var checkStreamHealth: (URL) async throws -> Bool
}

extension NetworkService: DependencyKey {
    static let liveValue = NetworkService(
        fetchData: { url in
            let (data, _) = try await URLSession.shared.data(from: url)
            return data
        },
        downloadToCache: { url, filename in
            let (tempURL, _) = try await URLSession.shared.download(from: url)
            @Dependency(\.fileCacheManager) var cache
            let destURL = try cache.cacheDirectory().appendingPathComponent(filename)
            if FileManager.default.fileExists(atPath: destURL.path) {
                try FileManager.default.removeItem(at: destURL)
            }
            try FileManager.default.moveItem(at: tempURL, to: destURL)
            try (destURL as NSURL).setResourceValue(true, forKey: .isExcludedFromBackupKey)
            return destURL
        },
        checkStreamHealth: { url in
            var request = URLRequest(url: url, timeoutInterval: 3)
            request.httpMethod = "HEAD"
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { return false }
            return (200...299).contains(http.statusCode)
        }
    )

    static let testValue = NetworkService(
        fetchData: { _ in unimplemented("NetworkService.fetchData", placeholder: Data()) },
        downloadToCache: { _, _ in unimplemented("NetworkService.downloadToCache", placeholder: URL(fileURLWithPath: "/")) },
        checkStreamHealth: { _ in unimplemented("NetworkService.checkStreamHealth", placeholder: false) }
    )
}

extension DependencyValues {
    var networkService: NetworkService {
        get { self[NetworkService.self] }
        set { self[NetworkService.self] = newValue }
    }
}
