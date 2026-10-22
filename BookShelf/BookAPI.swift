import Foundation

struct Book: Codable, Hashable, Identifiable {
    let id: String
    let title: String
    let author: String
    let coverURL: URL?
    let publishedYear: Int?
    let summary: String

    var displayYear: String {
        publishedYear.map(String.init) ?? "Год не указан"
    }
}

protocol BookAPIClientProtocol {
    func searchBooks(query: String, limit: Int) async throws -> [Book]
}

struct OpenLibraryAPIClient: BookAPIClientProtocol {
    private let session: URLSession
    private let decoder: JSONDecoder

    init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder()
    }

    func searchBooks(query: String, limit: Int = 20) async throws -> [Book] {
        var components = URLComponents(string: "https://openlibrary.org/search.json")!
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "fields", value: "key,title,author_name,first_publish_year,cover_i,first_sentence")
        ]
        let request = URLRequest(url: components.url!, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 15)
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        let payload = try decoder.decode(SearchResponse.self, from: data)
        return payload.docs.compactMap { $0.book }
    }

    private struct SearchResponse: Decodable {
        let docs: [Document]
    }

    private struct Document: Decodable {
        let key: String?
        let title: String?
        let authorName: [String]?
        let firstPublishYear: Int?
        let coverID: Int?
        let firstSentence: [String]?

        enum CodingKeys: String, CodingKey {
            case key, title
            case authorName = "author_name"
            case firstPublishYear = "first_publish_year"
            case coverID = "cover_i"
            case firstSentence = "first_sentence"
        }

        var book: Book? {
            guard let key, let title, !title.isEmpty else { return nil }
            let coverURL = coverID.flatMap { URL(string: "https://covers.openlibrary.org/b/id/\($0)-M.jpg") }
            let summary = firstSentence?.first ?? "Описание отсутствует"
            return Book(
                id: key,
                title: title,
                author: authorName?.first ?? "Автор неизвестен",
                coverURL: coverURL,
                publishedYear: firstPublishYear,
                summary: summary
            )
        }
    }
}

protocol BookImageLoaderProtocol {
    func imageData(from url: URL) async throws -> Data
}

struct BookImageLoader: BookImageLoaderProtocol {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func imageData(from url: URL) async throws -> Data {
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return data
    }
}
