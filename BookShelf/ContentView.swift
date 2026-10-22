import SwiftUI
import UIKit
import Combine

struct RootView: View {
    @StateObject private var viewModel: BookShelfViewModel
    private let imageLoader: BookImageLoader

    init(viewModel: BookShelfViewModel, imageLoader: BookImageLoader) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.imageLoader = imageLoader
    }

    var body: some View {
        TabView {
            CatalogTab(viewModel: viewModel, imageLoader: imageLoader)
                .tabItem { Label("Каталог", systemImage: "books.vertical") }
            FavoritesView(viewModel: viewModel, imageLoader: imageLoader)
                .tabItem { Label("Избранное", systemImage: "heart.fill") }
            SearchView(viewModel: viewModel, imageLoader: imageLoader)
                .tabItem { Label("Поиск", systemImage: "magnifyingglass") }
            ProfileView()
                .tabItem { Label("Профиль", systemImage: "person.crop.circle") }
        }
        .tint(.indigo)
    }
}

struct CatalogTab: View {
    @ObservedObject var viewModel: BookShelfViewModel
    let imageLoader: BookImageLoader

    var body: some View {
        NavigationStack {
            CatalogUIKitView(
                viewModel: viewModel,
                imageLoader: imageLoader,
                selectedBook: $viewModel.selectedBook
            )
            .navigationTitle("BookShelf")
            .navigationDestination(item: $viewModel.selectedBook) { book in
                BookDetailView(book: book, viewModel: viewModel, imageLoader: imageLoader)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await viewModel.search(query: "swift programming") }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(viewModel.isLoading)
                }
            }
            .safeAreaInset(edge: .bottom) {
                if viewModel.isUsingDemoData {
                    Text("Сервер недоступен — показаны демонстрационные книги")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(.thinMaterial)
                }
            }
            .task {
                await viewModel.loadInitial()
                viewModel.loadFavorites()
            }
        }
    }
}

struct FavoritesView: View {
    @ObservedObject var viewModel: BookShelfViewModel
    let imageLoader: BookImageLoader

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.favorites.isEmpty {
                    ContentUnavailableView("Нет избранных книг", systemImage: "heart", description: Text("Добавляйте книги из каталога или поиска"))
                } else {
                    List(viewModel.favorites) { stored in
                        let book = viewModel.book(from: stored)
                        NavigationLink(value: book) {
                            BookRow(book: book, imageLoader: imageLoader)
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Избранное")
            .navigationDestination(for: Book.self) { book in
                BookDetailView(book: book, viewModel: viewModel, imageLoader: imageLoader)
            }
            .task { viewModel.loadFavorites() }
        }
    }
}

struct SearchView: View {
    @ObservedObject var viewModel: BookShelfViewModel
    let imageLoader: BookImageLoader
    @State private var query = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                HStack {
                    TextField("Название книги или автора", text: $query)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit { Task { await viewModel.search(query: query) } }
                    Button("Найти") {
                        Task { await viewModel.search(query: query) }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.horizontal)

                if viewModel.isLoading {
                    ProgressView("Ищем книги…")
                        .frame(maxHeight: .infinity)
                } else {
                    List(viewModel.books) { book in
                        NavigationLink(value: book) {
                            BookRow(book: book, imageLoader: imageLoader)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .safeAreaInset(edge: .bottom) {
                if viewModel.isUsingDemoData {
                    Text("Сервер недоступен — поиск работает по демонстрационным данным")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(.thinMaterial)
                }
            }
            .navigationTitle("Поиск")
            .navigationDestination(for: Book.self) { book in
                BookDetailView(book: book, viewModel: viewModel, imageLoader: imageLoader)
            }
        }
    }
}

struct ProfileView: View {
    @AppStorage("profileName") private var profileName = "Студент"

    var body: some View {
        NavigationStack {
            Form {
                Section("Профиль") {
                    Label("BookShelf", systemImage: "books.vertical.fill")
                        .font(.headline)
                    TextField("Ваше имя", text: $profileName)
                }
                Section("О приложении") {
                    LabeledContent("Источник данных", value: "Open Library")
                    LabeledContent("Локальное хранилище", value: "Core Data")
                    LabeledContent("Версия", value: "1.0")
                }
            }
            .navigationTitle("Профиль")
        }
    }
}

struct BookDetailView: View {
    let book: Book
    @ObservedObject var viewModel: BookShelfViewModel
    let imageLoader: BookImageLoader

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                RemoteBookCover(url: book.coverURL, imageLoader: imageLoader)
                    .frame(maxWidth: .infinity)
                    .frame(height: 260)
                    .clipShape(RoundedRectangle(cornerRadius: 20))

                Text(book.title)
                    .font(.title2.bold())
                Text(book.author)
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Text(book.displayYear)
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                Text(book.summary)
                    .font(.body)

                Button {
                    viewModel.toggleFavorite(book)
                } label: {
                    Label(
                        viewModel.isFavorite(book) ? "Удалить из избранного" : "Добавить в избранное",
                        systemImage: viewModel.isFavorite(book) ? "heart.slash" : "heart"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .navigationTitle("Книга")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct BookRow: View {
    let book: Book
    let imageLoader: BookImageLoader

    var body: some View {
        HStack(spacing: 12) {
            RemoteBookCover(url: book.coverURL, imageLoader: imageLoader)
                .frame(width: 64, height: 82)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.headline)
                    .lineLimit(2)
                Text(book.author)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(book.displayYear)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}

@MainActor
final class RemoteImageViewModel: ObservableObject {
    @Published var image: UIImage?
    private let loader: BookImageLoader
    private var task: Task<Void, Never>?

    init(loader: BookImageLoader) {
        self.loader = loader
    }

    func load(url: URL?) {
        guard let url else { return }
        task?.cancel()
        task = Task {
            do {
                let data = try await loader.imageData(from: url)
                guard !Task.isCancelled else { return }
                image = UIImage(data: data)
            } catch { }
        }
    }

    deinit { task?.cancel() }
}

struct RemoteBookCover: View {
    let url: URL?
    let imageLoader: BookImageLoader
    @StateObject private var model: RemoteImageViewModel

    init(url: URL?, imageLoader: BookImageLoader) {
        self.url = url
        self.imageLoader = imageLoader
        _model = StateObject(wrappedValue: RemoteImageViewModel(loader: imageLoader))
    }

    var body: some View {
        ZStack {
            Color.secondary.opacity(0.12)
            if let image = model.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: url == nil ? "book.closed" : "book")
                    .font(.system(size: 42))
                    .foregroundStyle(.secondary)
            }
        }
        .task(id: url) { model.load(url: url) }
    }
}

struct CatalogUIKitView: UIViewControllerRepresentable {
    @ObservedObject var viewModel: BookShelfViewModel
    let imageLoader: BookImageLoader
    @Binding var selectedBook: Book?

    func makeUIViewController(context: Context) -> CatalogViewController {
        let controller = CatalogViewController(imageLoader: imageLoader)
        controller.onSelectBook = { book in selectedBook = book }
        controller.update(books: viewModel.books)
        return controller
    }

    func updateUIViewController(_ controller: CatalogViewController, context: Context) {
        controller.onSelectBook = { book in selectedBook = book }
        controller.update(books: viewModel.books)
    }
}

final class CatalogViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    private let imageLoader: BookImageLoader
    private var books: [Book] = []
    private var collectionView: UICollectionView!
    var onSelectBook: ((Book) -> Void)?

    init(imageLoader: BookImageLoader) {
        self.imageLoader = imageLoader
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 16
        layout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 28, right: 16)
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(BookCollectionCell.self, forCellWithReuseIdentifier: BookCollectionCell.reuseID)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else { return }
        let width = (collectionView.bounds.width - 44) / 2
        layout.itemSize = CGSize(width: max(width, 120), height: 286)
    }

    func update(books: [Book]) {
        self.books = books
        if isViewLoaded { collectionView.reloadData() }
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { books.count }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: BookCollectionCell.reuseID, for: indexPath) as! BookCollectionCell
        cell.configure(book: books[indexPath.item], imageLoader: imageLoader)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        onSelectBook?(books[indexPath.item])
    }
}

final class BookCollectionCell: UICollectionViewCell {
    static let reuseID = "BookCollectionCell"
    private let coverView = UIImageView()
    private let titleLabel = UILabel()
    private let authorLabel = UILabel()
    private let yearLabel = UILabel()
    private var task: Task<Void, Never>?

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .secondarySystemGroupedBackground
        contentView.layer.cornerRadius = 16
        contentView.clipsToBounds = true
        coverView.contentMode = .scaleAspectFit
        coverView.backgroundColor = .tertiarySystemFill
        coverView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.numberOfLines = 2
        authorLabel.font = .preferredFont(forTextStyle: .subheadline)
        authorLabel.textColor = .secondaryLabel
        authorLabel.numberOfLines = 1
        yearLabel.font = .preferredFont(forTextStyle: .caption1)
        yearLabel.textColor = .tertiaryLabel
        let stack = UIStackView(arrangedSubviews: [coverView, titleLabel, authorLabel, yearLabel])
        stack.axis = .vertical
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            coverView.heightAnchor.constraint(equalToConstant: 170),
            stack.topAnchor.constraint(equalTo: contentView.topAnchor),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -10)
        ])
        stack.setCustomSpacing(10, after: coverView)
        stack.layoutMargins = UIEdgeInsets(top: 0, left: 10, bottom: 10, right: 10)
        stack.isLayoutMarginsRelativeArrangement = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(book: Book, imageLoader: BookImageLoader) {
        task?.cancel()
        coverView.image = nil
        coverView.image = UIImage(systemName: "book.closed")
        coverView.tintColor = .secondaryLabel
        titleLabel.text = book.title
        authorLabel.text = book.author
        yearLabel.text = book.displayYear
        guard let url = book.coverURL else { return }
        task = Task { [weak self] in
            do {
                let data = try await imageLoader.imageData(from: url)
                guard !Task.isCancelled else { return }
                await MainActor.run { self?.coverView.image = UIImage(data: data) }
            } catch { }
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        task?.cancel()
        coverView.image = nil
    }
}
