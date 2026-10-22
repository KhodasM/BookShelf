import Foundation
import Combine

@MainActor
final class BookShelfViewModel: ObservableObject {
    @Published private(set) var books: [Book] = []
    @Published private(set) var favorites: [StoredBook] = []
    @Published private(set) var favoriteIDs: Set<String> = []
    @Published private(set) var isLoading = false
    @Published private(set) var isUsingDemoData = false
    @Published var errorMessage: String?
    @Published var selectedBook: Book?

    private let apiClient: BookAPIClientProtocol
    private let store: FavoritesStoreProtocol
    private let defaultQuery = "swift programming"

    init(apiClient: BookAPIClientProtocol, store: FavoritesStoreProtocol) {
        self.apiClient = apiClient
        self.store = store
    }

    func loadInitial() async {
        guard books.isEmpty else { return }
        await search(query: defaultQuery)
    }

    func search(query: String) async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        isLoading = true
        errorMessage = nil
        do {
            books = try await apiClient.searchBooks(query: trimmed, limit: 20)
            isUsingDemoData = false
        } catch {
            let normalizedQuery = trimmed.lowercased()
            let filtered = SampleBookData.books.filter {
                $0.title.lowercased().contains(normalizedQuery) ||
                $0.author.lowercased().contains(normalizedQuery)
            }
            books = filtered.isEmpty ? SampleBookData.books : filtered
            isUsingDemoData = true
            errorMessage = "Сервер недоступен. Показаны демонстрационные данные."
        }
        isLoading = false
    }

    func loadFavorites() {
        do {
            favorites = try store.fetchFavorites()
            favoriteIDs = Set(favorites.map(\.id))
        } catch {
            errorMessage = "Не удалось прочитать избранное."
        }
    }

    func toggleFavorite(_ book: Book) {
        do {
            if favoriteIDs.contains(book.id) {
                try store.deleteFavorite(id: book.id)
            } else {
                try store.saveFavorite(book)
            }
            loadFavorites()
        } catch {
            errorMessage = "Не удалось сохранить книгу."
        }
    }

    func isFavorite(_ book: Book) -> Bool {
        favoriteIDs.contains(book.id)
    }

    func book(from stored: StoredBook) -> Book {
        Book(id: stored.id, title: stored.title, author: stored.author, coverURL: stored.coverURL, publishedYear: stored.publishedYear, summary: stored.summary)
    }
}
