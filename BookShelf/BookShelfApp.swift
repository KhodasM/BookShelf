import SwiftUI

@main
struct BookShelfApp: App {
    private let persistence = PersistenceController()
    private let apiClient = OpenLibraryAPIClient()
    private let imageLoader = BookImageLoader()

    var body: some Scene {
        WindowGroup {
            let viewModel = BookShelfViewModel(apiClient: apiClient, store: persistence)
            RootView(viewModel: viewModel, imageLoader: imageLoader)
        }
    }
}
