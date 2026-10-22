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

## Live demo

1. Открыть каталог и показать загрузку книг из Open Library.
2. Открыть карточку книги через NavigationStack.
3. Добавить книгу в избранное.
4. Перейти во вкладку «Избранное» и перезапустить приложение.
5. Показать, что книга осталась в Core Data.
6. Выполнить новый поиск на вкладке «Поиск».
