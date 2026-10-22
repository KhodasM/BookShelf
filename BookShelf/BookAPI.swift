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

enum SampleBookData {
    static let books: [Book] = [
        Book(id: "/works/OL45804W", title: "The Swift Programming Language", author: "Apple Inc.", coverURL: nil, publishedYear: 2024, summary: "Официальное руководство по языку Swift и разработке приложений для Apple-платформ."),
        Book(id: "/works/OL17924733W", title: "Swift Programming: The Big Nerd Ranch Guide", author: "Matthew Mathias", coverURL: nil, publishedYear: 2016, summary: "Практическое введение в Swift с примерами и небольшими проектами."),
        Book(id: "/works/OL27448W", title: "Clean Code", author: "Robert C. Martin", coverURL: nil, publishedYear: 2008, summary: "Принципы создания понятного и поддерживаемого программного кода."),
        Book(id: "/works/OL2433231W", title: "Design Patterns", author: "Erich Gamma", coverURL: nil, publishedYear: 1994, summary: "Классические шаблоны проектирования и способы их применения."),
        Book(id: "/works/OL7353617W", title: "The Pragmatic Programmer", author: "David Thomas", coverURL: nil, publishedYear: 2019, summary: "Практические подходы к профессиональной разработке программного обеспечения."),
        Book(id: "/works/OL1975769W", title: "iOS Programming: The Big Nerd Ranch Guide", author: "Christian Keur", coverURL: nil, publishedYear: 2020, summary: "Руководство по созданию приложений для iOS на Swift."),
    ]
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
        var request = URLRequest(url: components.url!, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 15)
        request.setValue("BookShelf/1.0 (educational iOS app)", forHTTPHeaderField: "User-Agent")
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
