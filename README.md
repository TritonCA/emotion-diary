# Mood Tracker (Flutter)

Минималистичный трекер эмоций. Интерфейс точно повторяет Stitch-макеты
(Record / History / Statistics / Settings), две темы (тёмная #121212 и светлая
#FDF7FF, акцент #8B8BF0), экспорт и импорт записей в CSV.

## Запуск

В проекте только `lib/` и `pubspec.yaml`. Платформенные папки генерирует Flutter:

```bash
cd mood_tracker
flutter create .          # создаёт android/ ios/ web/ ... (lib и pubspec не трогаются)
flutter pub get
flutter run               # или: flutter run -d chrome / -d macos / -d windows
```

Требуется Flutter 3.19+ / Dart 3.3+. Шрифт **Hanken Grotesk** подтягивается через
`google_fonts` в рантайме (кэшируется). Для офлайна положите ttf в `assets/fonts`
и пропишите его в `pubspec.yaml`.

## Архитектура (по ARCH.MD)

Feature-first + слои `presentation / application / domain / data`, поверх — `core`.
MVVM: `View = presentation`, `ViewModel = Cubit (application)`, `Model = domain + data`.

```
lib/
  core/            тема, токены цветов, DI, навигация, storage, утилиты, общие виджеты
  features/
    entries/       общий источник истины: MoodEntry, репозитории, use-cases,
                   app-scoped EntriesCubit (единый владелец списка записей)
    record/        экран записи + RecordCubit
    history/       лента истории + HistoryCubit (подписан на EntriesCubit)
    stats/         статистика + StatsCubit + ComputeStats (чистая агрегация)
    settings/      настройки/тема/CSV + SettingsCubit (app-scoped)
```

Ключевые правила, которые соблюдены:
- зависимости только сверху вниз; `domain` не знает Flutter, Dio, SharedPreferences;
- DTO ≠ Entity ≠ UiModel (есть `MoodEntryDto` + маппер);
- все side effects (storage, файлы, share, picker) — в `data` / `core`, не в UI;
- shared-состояние записей имеет единственного владельца (`EntriesCubit`),
  History и Stats читают его через stream, без проброса колбэков между фичами;
- CSV-эффекты спрятаны за доменным портом `EntriesCsvGateway`.

## Поток данных

```
View -> RecordCubit.save() -> SaveEntry (use case) -> EntriesRepository
     -> EntriesCubit.refresh() -> stream -> History/Stats пересобирают UiModel
```

## Формат CSV

Колонки: `id, timestamp, emotions, intensity, trigger`

- `timestamp` — ISO-8601;
- `emotions` — список через `;`, каждый как `name|categoryId|valence`
  (valence ∈ positive/neutral/negative);
- импорт сливает по `id` (дубликаты пропускаются).

Экспорт собирает файл во временной папке и открывает системный share-лист.
Импорт открывает файловый пикер (только `.csv`).

## Замечания по верстке

- Пунктирная рамка кнопки «Add emotion» в Flutter приближена сплошной 0.5px
  (нативного dashed-бордера в Material нет).
- «Daily prompt» сохраняет предпочтение; реальные локальные уведомления
  не подключены (точка расширения — пакет `flutter_local_notifications`).
- Settings открывается иконкой-шестерёнкой в верхнем баре (нижняя навигация
  оставлена ровно как в макетах: Record / History / Stats).
