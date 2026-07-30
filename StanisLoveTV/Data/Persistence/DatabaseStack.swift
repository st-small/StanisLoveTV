import Dependencies
import Foundation
import SQLiteData

struct DatabaseStack {
    let writer: any DatabaseWriter
}

extension DatabaseStack {
    static func live() throws -> DatabaseStack {
        let url = try FileManager.default
            .url(
                for: .cachesDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            .appendingPathComponent("stanislove.sqlite")
        var config = Configuration()
        config.foreignKeysEnabled = true
        let queue = try DatabaseQueue(path: url.path, configuration: config)
        var migrator = DatabaseMigrator()
        Migrations.register(in: &migrator)
        try migrator.migrate(queue)
        return DatabaseStack(writer: queue)
    }
}

extension DatabaseStack: DependencyKey {
    static let liveValue: DatabaseStack = {
        do { return try DatabaseStack.live() }
        catch { fatalError("Failed to open database: \(error)") }
    }()

    static let testValue: DatabaseStack = {
        do {
            let queue = try DatabaseQueue()
            var migrator = DatabaseMigrator()
            Migrations.register(in: &migrator)
            try migrator.migrate(queue)
            return DatabaseStack(writer: queue)
        } catch {
            fatalError("Failed to create test database: \(error)")
        }
    }()
}

extension DependencyValues {
    var database: DatabaseStack {
        get { self[DatabaseStack.self] }
        set { self[DatabaseStack.self] = newValue }
    }
}
