import Dependencies
import Foundation

struct FileCacheManager {
    var cacheDirectory: () throws -> URL
    var writeData: (Data, String) throws -> URL
    var readData: (String) throws -> Data
    var fileExists: (String) -> Bool
    var deleteFile: (String) throws -> Void
}

extension FileCacheManager: DependencyKey {
    static let liveValue = FileCacheManager(
        cacheDirectory: {
            let base = try FileManager.default.url(
                for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true
            )
            let dir = base.appendingPathComponent("StanisLoveTV", isDirectory: true)
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            return dir
        },
        writeData: { data, filename in
            let base = try FileManager.default.url(
                for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true
            )
            let dir = base.appendingPathComponent("StanisLoveTV", isDirectory: true)
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            let url = dir.appendingPathComponent(filename)
            try data.write(to: url)
            try (url as NSURL).setResourceValue(true, forKey: .isExcludedFromBackupKey)
            return url
        },
        readData: { filename in
            let base = try FileManager.default.url(
                for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true
            )
            let url = base
                .appendingPathComponent("StanisLoveTV", isDirectory: true)
                .appendingPathComponent(filename)
            return try Data(contentsOf: url)
        },
        fileExists: { filename in
            guard let base = FileManager.default.urls(
                for: .cachesDirectory, in: .userDomainMask
            ).first else { return false }
            let url = base
                .appendingPathComponent("StanisLoveTV")
                .appendingPathComponent(filename)
            return FileManager.default.fileExists(atPath: url.path)
        },
        deleteFile: { filename in
            let base = try FileManager.default.url(
                for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true
            )
            let url = base
                .appendingPathComponent("StanisLoveTV", isDirectory: true)
                .appendingPathComponent(filename)
            try FileManager.default.removeItem(at: url)
        }
    )

    static let testValue = FileCacheManager(
        cacheDirectory: {
            let dir = FileManager.default.temporaryDirectory.appendingPathComponent("StanisLoveTVTests")
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            return dir
        },
        writeData: { data, filename in
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("StanisLoveTVTests")
                .appendingPathComponent(filename)
            try data.write(to: url)
            return url
        },
        readData: { _ in Data() },
        fileExists: { _ in false },
        deleteFile: { _ in }
    )
}

extension DependencyValues {
    var fileCacheManager: FileCacheManager {
        get { self[FileCacheManager.self] }
        set { self[FileCacheManager.self] = newValue }
    }
}
