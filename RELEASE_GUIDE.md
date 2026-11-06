# DayTask: установка и публикация релиза

Пошаговая инструкция для разработчика: как установить приложение на устройство
и опубликовать **релиз** в Google Play и App Store. Соответствует этапу 5 ТЗ
(`ТЗ_ТрекерЗадач.md`, разделы 7 и 9).

> Слово «рендер» в запросе читаем как «релиз» — публикация готовой сборки.

---

## Часть 0. Что понадобится

| Компонент | Зачем | Где взять |
|---|---|---|
| Flutter SDK 3.27+ | сборка | https://docs.flutter.dev/get-started/install |
| Git | зависимости Flutter | https://git-scm.com/download/win |
| Android Studio (или cmdline-tools) + JDK 17 | Android-сборка, эмулятор, `keytool` | https://developer.android.com/studio |
| Android SDK Platform 35+ и Build-Tools | сборка AAB/APK | ставится через SDK Manager Android Studio |
| macOS + Xcode 15+ | iOS-сборка (только Mac) | App Store / developer.apple.com |
| Аккаунт Google Play Console | публикация в Play | $25 разово, https://play.google.com/console |
| Аккаунт Apple Developer Program | публикация в App Store | $99/год, https://developer.apple.com/programs/ |

Проверка окружения:

```bash
flutter doctor -v
```

Все пункты для вашей платформы должны быть зелёными (Android toolchain —
для Android, Xcode — для iOS).

> ⚠️ Проект должен лежать в пути **без кириллицы и пробелов**
> (например, `C:\dev\day_task`). Gradle и часть инструментов Flutter
> иначе работают некорректно.

---

## Часть 1. Подготовка проекта к релизу

### 1.1. Уникальный идентификатор приложения

Сейчас в проекте стоит временный ID `com.daytask.day_task`. Для публикации
нужен ваш собственный, уникальный в сторе (менять **до первой** публикации —
позже его изменить нельзя):

- **Android** — `android/app/build.gradle.kts`, строки `namespace` и
  `applicationId` (например, `com.ivanov.daytask`).
- **iOS** — Xcode → `ios/Runner.xcworkspace` → Runner → General →
  Bundle Identifier.

> Если меняете ID уже после генерации, переименуйте также пакет
> `android/app/src/main/kotlin/com/daytask/day_task/MainActivity.kt`
> и путь каталога под него (или выполните
> `flutter create . --org com.ivanov --project-name day_task` заново для
> платформенных папок, сохранив `lib/` и `test/`).

### 1.2. Название, иконка, заставка

- Название Android: `android/app/src/main/AndroidManifest.xml` → `android:label`.
- Название iOS: `ios/Runner/Info.plist` → `CFBundleDisplayName`.
- Иконка: удобно пакетом `flutter_launcher_icons` (добавьте в dev_dependencies,
  положите `assets/icon/icon.png` 1024×1024 и выполните `dart run flutter_launcher_icons`).
- Заставка: `android/app/src/main/res/drawable/launch_background.xml`,
  `ios/Runner/Base.lproj/LaunchScreen.storyboard`.

### 1.3. Версия

В `pubspec.yaml`: `version: 1.0.0+1`
- `1.0.0` — то, что видит пользователь (versionName / CFBundleShortVersionString);
- `+1` — внутренний номер сборки (versionCode / CFBundleVersion), **строго
  возрастает** с каждым релизом.

При каждом обновлении в сторе: поднимите `+N` (обязательно) и, при заметных
изменениях, `x.y.z`.

### 1.4. Политика конфиденциальности

Нужна и для Play, и для App Store (у приложения нет сети и сбора данных —
это стоит прямо указать). Разместите текст на любом публичном URL
(например, страница на GitHub Pages) и добавьте ссылку:
- Android — можно вынести в экран «О приложении» (раздел 11 ТЗ — бэклог) или в описание стора;
- iOS — ссылка в App Store Connect + в приложении.

---

## Часть 2. Установка на устройство (без сторов)

### 2.1. Android, вариант A — с компьютера (отладка)

1. На телефоне: «Настройки → Для разработчиков» (7 нажатий по номеру сборки) →
   «Отладка по USB».
2. Подключите телефон кабелем, разрешите отладку.
3. Проверьте: `flutter devices` — телефон должен быть в списке.
4. Запуск:

```bash
flutter run --release
```

### 2.2. Android, вариант B — APK-файл (можно переслать на любой телефон)

```bash
flutter build apk --release --split-per-abi
```

Готовый файл:
`build\app\outputs\flutter-apk\app-arm64-v8a-release.apk` (для большинства
современных телефонов). Без `--split-per-abi` получите один fat-APK
`app-release.apk` (~вдвое больше).

Установка: скопируйте файл на телефон (USB, облако, мессенджер), откройте,
разрешите «Установка из неизвестных источников» для файлового менеджера.

> До настройки релизного ключа (часть 3) APK подписывается отладочным ключом —
> для себя и друзей этого достаточно, для стора — нет.

### 2.3. iOS

**Бесплатный способ** (Apple ID без подписки, живёт 7 дней, потом перевыпуск):
Xcode → Runner → General → Signing & Capabilities → Team = ваш личный аккаунт →
`flutter run`. Подходит только для своего iPhone.

**Через TestFlight** (нужен платный аккаунт, часть 5): сборка живёт 90 дней,
удобно раздавать тестировщикам.

---

## Часть 3. Android: ключ подписи и релиз-сборка

### 3.1. Создать upload-ключ (один раз, **сделайте резервную копию!**)

```bash
keytool -genkeypair -v -keystore C:\dev\day_task-upload.jks -keyalg RSA ^
  -keysize 2048 -validity 10000 -alias upload
```

(`keytool` идёт в составе JDK; на macOS/Linux вместо `^` — `\`.)
Запомните пароли keystore и key. **Потеря ключа = потеря возможности
обновлять приложение в Google Play** (восстановление — только через поддержку
Google, и то не всегда).

### 3.2. Файл `android/key.properties` (не коммитить!)

```properties
storePassword=ПАРОЛЬ_KEYSTORE
keyPassword=ПАРОЛЬ_KEY
keyAlias=upload
storeFile=../day_task-upload.jks
```

Положите `day_task-upload.jks` в каталог `android/`. Убедитесь, что
`android/.gitignore` содержит `key.properties` и `*.jks` (в проекте уже есть).

### 3.3. Подключить подпись в `android/app/build.gradle.kts`

В начало файла (перед `plugins {`) — импорты и чтение свойств:

```kotlin
import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) load(FileInputStream(file))
}
```

В блоке `android { ... }` добавьте `signingConfigs` и укажите его в `release`
(сейчас там стоит отладочная подпись — замените):

```kotlin
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
```

### 3.4. Собрать

```bash
flutter build appbundle --release   # .aab — для Google Play (обязательно)
flutter build apk --release         # .apk — для установки вручную/прямых ссылок
```

Результат: `build\app\outputs\bundle\release\app-release.aab`.

---

## Часть 4. Публикация в Google Play

### 4.1. Регистрация разработчика
1. https://play.google.com/console → «Зарегистрироваться» → $25 разово.
2. Пройдите верификацию личности и привяжите карту (требование Google с 2023).
3. В профиле разработчика заполните имя, email поддержки, сайт (ссылка на
   политику конфиденциальности).

### 4.2. Создание приложения
Кнопка «Создать приложение» → название (до 30 символов), язык, «Приложение»,
бесплатное.

### 4.3. Настройка страницы магазина (все пункты обязательны)
- **Описание**: краткое (до 80 символов) и полное — по ТЗ это «простой трекер
  задач на день: добавляйте, отмечайте, удаляйте; всё хранится на устройстве».
- **Иконка** 512×512 PNG.
- **Feature graphic** 1024×500.
- **Скриншоты**: минимум 2 для телефона (рекомендую 4–6: список задач,
  отметка выполнения, удаление свайпом, тёмная тема). Размер 16:9 или 9:16,
  минимум 1080 px по короткой стороне.
- **Категория**: «Продуктивность», теги по желанию.
- **Контакты**: email обязателен, сайт/телефон — по желанию.
- **Политика конфиденциальности**: URL обязателен.

### 4.4. Анкеты («Политика» → «Содержание приложения»)
- **Data safety**: «Приложение не собирает и не передаёт данные» — это
  соответствует ТЗ (offline, без аналитики).
- **Возрастной рейтинг** (IARC): анкета — насилия/рекламы/покупок нет →
  «Для всех».
- **Реклама**: нет.
- **Объявление о целевой аудитории**: не для детей (или по вашему решению).
- **Разрешения и политики**: приложение не запрашивает опасных разрешений.

### 4.5. Загрузка сборки
1. «Тестирование → Внутреннее тестирование» → «Создать новое издание».
2. Загрузите `app-release.aab`.
3. Заполните «Что нового в этой версии» (можно текст из `CHANGELOG.md`).
4. Добавьте тестировщиков по email (список в разделе «Тестировщики»).
5. Сохраните → «Проверить и опубликовать».

> ⚠️ Для **новых личных аккаунтов** (созданы после ноября 2023) действует
> правило закрытого тестирования: **минимум 12 тестировщиков, не менее
> 14 дней подряд**, после чего открывается доступ к продакшну. Позовите
> коллег/друзей заранее.

### 4.6. Выход в продакшн
1. После тестирования: «Продакшн → Создать издание» → выберите проверенное.
2. Страны распространения (обычно все или выбранные).
3. Ценообразование: бесплатно.
4. «Отправить на рассмотрение». Модерация обычно занимает от нескольких часов
   до 7 дней. Статус виден в консоли; возможен запрос изменений — отвечайте
   в разделе «Решения центра приложений».

### 4.7. Обновления
```bash
# 1. В pubspec.yaml: version: 1.0.1+2   (номер сборки +1 обязателен!)
# 2. Обновить CHANGELOG.md
flutter build appbundle --release
# 3. Play Console → Продакшн → создать издание → загрузить новый .aab
```
Сборка с уже использованным `versionCode` будет отклонена.

---

## Часть 5. Публикация в App Store (iOS)

### 5.1. Аккаунт и сертификаты
1. Купите Apple Developer Program ($99/год).
2. Xcode → Settings → Accounts → добавьте аккаунт → «Manage Certificates» →
   «Apple Development» + «Apple Distribution».
3. Откройте `ios/Runner.xcworkspace` → Runner → General:
   - Bundle Identifier = ваш (часть 1.1);
   - Team = ваша организация/аккаунт;
   - Deployment Target = 13.0+ (по ТЗ).
4. Добавьте App Icon в `Assets.xcassets` (1024×1024 без прозрачности).

### 5.2. Сборка архива
```bash
flutter build ipa --release
```
Сборка поднимется в Xcode Organizer (Window → Organizer) как архив.
Альтернатива: Xcode → Product → Scheme Runner → Any iOS Device →
Product → Archive.

### 5.3. TestFlight (до публикации)
1. Organizer → «Distribute App» → «TestFlight & App Store Connect» → Upload.
2. App Store Connect (https://appstoreconnect.apple.com) → TestFlight:
   - **Внутренние** тестировщики (до 100 человек, модерация не нужна);
   - **Внешние** — нужна бета-модерация Apple (обычно 1–2 дня).
3. Тестировщики ставят TestFlight на iPhone и получают сборку.

### 5.4. Карточка приложения (App Store Connect → приложение)
- Название, подзаголовок, категория («Продуктивность»).
- **Скриншоты**: iPhone 6.9" (минимум 2, рекомендуется 5–6 — те же, что в Play).
- Описание, ключевые слова, URL поддержки, URL политики конфиденциальности.
- **Возрастной рейтинг**: анкета, всё «нет» → 4+.
- **App Privacy** (важно!): «Data Not Collected» / «Не собираются данные» —
  соответствует ТЗ.
- Цена: бесплатно; доступность по странам.

### 5.5. Отправка на модерацию
«Добавить сборку» (TestFlight-билд) → «Добавить в релиз» → «Отправить на
рассмотрение». Обычно 1–3 дня.

**Частые причины отказа** (все предотвратимы):
- краши при запуске — прогнать чек-лист ТЗ (раздел 10) на реальном iPhone;
- пустой/сырой функционал — у нас MVP, но сценарий «список → добавить →
  отметить → удалить» должен быть полным и стабильным;
- отсутствие политики конфиденциальности;
- введение в заблуждение в описании («AI», «синхронизация» и т.п. — у нас нет).

### 5.6. Обновления
```bash
# 1. pubspec.yaml: version: 1.0.1+2  (build-номер +1)
flutter build ipa --release
# 2. Xcode Organizer → Distribute App → Upload
# 3. App Store Connect → новая сборка → отправить на рассмотрение
```

---

## Часть 6. Версионирование и сопровождение

- **Семантика**: `MAJOR.MINOR.PATCH+BUILD`.
  - PATCH — исправления (1.0.1);
  - MINOR — новые функции (1.1.0);
  - MAJOR — переработка (2.0.0);
  - BUILD — обязателен к росту для каждого аплоада в оба стора.
- Ведите `CHANGELOG.md` — его текст удобно копировать в «Что нового».
- После релиза: следите за «Android vitals» (краши/ANR) и отзывами;
  критичные краши — в ближайший PATCH.
- При смене ПК или уходе разработчика: передайте `day_task-upload.jks` и
  пароли, доступы к Play Console и App Store Connect (по ТЗ — у заказчика).

---

## Часть 7. Чек-лист перед публикацией

- [ ] Проект в пути без кириллицы/пробелов
- [ ] `flutter analyze` / `dart analyze` — 0 замечаний
- [ ] `flutter test` — все тесты зелёные (42/42)
- [ ] Сценарии чек-листа ТЗ (раздел 10) пройдены на реальном устройстве
- [ ] Замер плавности (≥55 fps) на среднем Android
- [ ] Проверены тёмная тема, RU/EN, TalkBack/VoiceOver
- [ ] applicationId / Bundle ID — ваши, уникальные
- [ ] Иконка, название, заставка — финальные
- [ ] Версия `x.y.z+build` поднята
- [ ] Политика конфиденциальности опубликована по URL
- [ ] `day_task-upload.jks` + пароли сохранены в надёжном месте
- [ ] Скриншоты и описания подготовлены (Play + App Store)
- [ ] `CHANGELOG.md` обновлён

---

## Часть 8. Типовые проблемы

| Проблема | Решение |
|---|---|
| Gradle падает с «не-ASCII» путями | Перенесите проект в `C:\dev\...`, удалите `android/.gradle`, `build/` |
| `flutter analyze` падает с ошибкой LSP | Используйте `dart analyze` (баг инструмента на не-ASCII путях) |
| Play отклоняет сборку «versionCode уже существует» | Поднимите `+N` в `pubspec.yaml` |
| «Неподписанный APK» / установка запрещена | Настройте `signingConfigs` (часть 3), для ручной установки включите «Неизвестные источники» |
| Требование target API level | Обновите Flutter (тянет актуальный `targetSdk`) и пересоберите |
| Apple просит скриншоты iPad | Укажите, что iPad не поддерживается (Supported Device Families → iPhone) |
| Забыт пароль keystore | Ключ не восстановить — для нового ключа потребуется новое приложение в Play (или снятие старого) |
