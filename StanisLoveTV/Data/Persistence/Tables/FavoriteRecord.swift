import Foundation
import SQLiteData

@Table("favorites") nonisolated struct FavoriteRecord: Identifiable {
    let id: UUID
    var addedAt: Date
}
