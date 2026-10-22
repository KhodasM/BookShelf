import CoreData

struct StoredBook: Identifiable, Hashable {
    let id: String
    let title: String
    let author: String
    let coverURL: URL?
    let publishedYear: Int?
    let summary: String
}

protocol FavoritesStoreProtocol {
    func fetchFavorites() throws -> [StoredBook]
    func saveFavorite(_ book: Book) throws
    func deleteFavorite(id: String) throws
    func containsFavorite(id: String) throws -> Bool
}

final class PersistenceController: FavoritesStoreProtocol {
    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "BookShelfModel")
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { _, error in
            if let error { fatalError("Core Data error: \(error)") }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    func fetchFavorites() throws -> [StoredBook] {
        let request = FavoriteBookEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: #keyPath(FavoriteBookEntity.savedAt), ascending: false)]
        return try container.viewContext.fetch(request).map(StoredBook.init)
    }

    func saveFavorite(_ book: Book) throws {
        let request = FavoriteBookEntity.fetchRequest()
        request.predicate = NSPredicate(format: "remoteID == %@", book.id)
        let entity = try container.viewContext.fetch(request).first ?? FavoriteBookEntity(context: container.viewContext)
        entity.remoteID = book.id
        entity.title = book.title
        entity.author = book.author
        entity.coverURL = book.coverURL?.absoluteString ?? ""
        entity.publishedYear = Int32(book.publishedYear ?? 0)
        entity.summary = book.summary
        entity.savedAt = .now
        try container.viewContext.save()
    }

    func deleteFavorite(id: String) throws {
        let request = FavoriteBookEntity.fetchRequest()
        request.predicate = NSPredicate(format: "remoteID == %@", id)
        for entity in try container.viewContext.fetch(request) {
            container.viewContext.delete(entity)
        }
        try container.viewContext.save()
    }

    func containsFavorite(id: String) throws -> Bool {
        let request = FavoriteBookEntity.fetchRequest()
        request.predicate = NSPredicate(format: "remoteID == %@", id)
        request.fetchLimit = 1
        return try container.viewContext.count(for: request) > 0
    }
}

@objc(FavoriteBookEntity)
final class FavoriteBookEntity: NSManagedObject {
    @NSManaged var remoteID: String
    @NSManaged var title: String
    @NSManaged var author: String
    @NSManaged var coverURL: String
    @NSManaged var publishedYear: Int32
    @NSManaged var summary: String
    @NSManaged var savedAt: Date
}

extension FavoriteBookEntity {
    @nonobjc class func fetchRequest() -> NSFetchRequest<FavoriteBookEntity> {
        NSFetchRequest<FavoriteBookEntity>(entityName: "FavoriteBookEntity")
    }

    convenience init(context: NSManagedObjectContext) {
        self.init(entity: NSEntityDescription.entity(forEntityName: "FavoriteBookEntity", in: context)!, insertInto: context)
    }
}

extension StoredBook {
    init(entity: FavoriteBookEntity) {
        id = entity.remoteID
        title = entity.title
        author = entity.author
        coverURL = URL(string: entity.coverURL)
        publishedYear = entity.publishedYear == 0 ? nil : Int(entity.publishedYear)
        summary = entity.summary
    }
}
