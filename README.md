# BookShelf

BookShelf — iOS-приложение-каталог книг. Данные загружаются из Open Library, избранные книги сохраняются в Core Data. Если сеть Simulator временно недоступна, приложение переключается на локальный резервный набор, поэтому каталог и поиск остаются доступными.

## Экраны

- Каталог — UIKit + UICollectionView.
- Избранное — SwiftUI + Core Data.
- Поиск — SwiftUI + NavigationStack.
- Профиль — SwiftUI.
- Детали книги — SwiftUI, открываются через NavigationStack.

## Архитектура

`View`/`UIViewController` → `BookShelfViewModel` → протоколы `BookAPIClientProtocol` и `FavoritesStoreProtocol` → сетевой клиент и Core Data.

Интерфейс не обращается к URLSession или Core Data напрямую. Зависимости передаются в ViewModel через инициализатор.

## Запуск

Откройте `BookShelf.xcodeproj` в Xcode 16 или новее и запустите на iOS Simulator 17+.
