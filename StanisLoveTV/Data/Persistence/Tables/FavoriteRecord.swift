import Foundation
import SQLiteData

@Table nonisolated struct FavoriteRecord: Identifiable {
    let id: UUID
    var addedAt: Date
}
