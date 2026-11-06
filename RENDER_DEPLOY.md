# Размещение DayTask на хостинге Render (тестовый вариант)

Приложение — Flutter-проект, у него есть **веб-сборка**: те же экраны, анимации
и логика работают в браузере, данные хранятся в IndexedDB браузера
(на устройстве пользователя). Этого достаточно для тестового размещения —
без Google Play и App Store.

Локальная сборка уже создана: `build/web` (команда `flutter build web --release`).

---

## Вариант A (рекомендуемый): сайт из Git-репозитория, сборка на Render

### 1. Выложите проект на GitHub

```bash
git init
git add .
git commit -m "DayTask 1.0.0"
git branch -M main
git remote add origin https://github.com/ВАШ_АККАУНТ/day-task.git
git push -u origin main
```

(Репозиторий создайте на github.com — публичный или приватный.)

### 2. Создайте Static Site на Render

1. https://dashboard.render.com → **New +** → **Static Site**.
2. Подключите GitHub-репозиторий `day-task` (доступ выдаётся через GitHub App).
3. Заполните настройки сборки:

| Поле | Значение |
|---|---|
| Name | `day-task` (станет адресом `day-task.onrender.com`) |
| Build Command | см. ниже |
| Publish Directory | `build/web` |

**Build Command** (Flutter на Render не предустановлен — ставим прямо в сборке):

```bash
git clone https://github.com/flutter/flutter.git -b stable --depth 1 && export PATH="$PWD/flutter/bin:$PATH" && flutter pub get && flutter build web --release
```

4. **Create Static Site** → первая сборка 3–6 минут (скачивается Flutter SDK).
5. Готово: `https://day-task.onrender.com` — открывается с любого устройства,
   HTTPS включён автоматически.

Каждый `git push` в `main` пересобирает сайт автоматически.

> Если не хотите, чтобы Render собирал проект (например, нет сети до
> flutter.dev), используйте вариант B.

---

## Вариант B: загрузить готовую сборку (уже собрана локально)

В папке проекта уже лежит `build/web` — это готовый сайт, его можно хранить
в Git вместо сборки на сервере:

1. Временно добавьте `build/` в исключения `.gitignore` (закомментируйте строку
   `build/`) или добавьте `!build/web`.
2. Закоммитьте `build/web` и запушьте.
3. На Render: **New + → Static Site** → тот же репозиторий:
   - Build Command: `echo "prebuilt"` (или пусто)
   - Publish Directory: `build/web`
4. При изменении кода: `flutter build web --release` → коммит → push.

Минус: артефакты в Git. Плюс: Render ничего не собирает, деплой за секунды.

---

## Вариант C: ручной деплой без Git (если в консоли есть Manual Deploy)

В разделе созданного Static Site на вкладке **Manual Deploy** можно загрузить
архив с готовым сайтом:

```bash
cd build
tar -czf ../day_task_web.tar.gz web
```

Загрузите `day_task_web.tar.gz` через **Upload archive**. Подходит для разовой
демонстрации.

---

## Автоматизация через render.yaml (опционально)

Файл в корне репозитория описывает сервис — можно создать инфраструктуру
кнопкой «Blueprints → New Blueprint Instance»:

```yaml
services:
  - type: static_site
    name: day-task
    buildCommand: |
      git clone https://github.com/flutter/flutter.git -b stable --depth 1
      export PATH="$PWD/flutter/bin:$PATH"
      flutter pub get
      flutter build web --release
    staticPublishPath: build/web
    routes:
      - type: catchAll
        destination: /
```

---

## Что важно знать про тестовое веб-размещение

| Вопрос | Ответ |
|---|---|
| Где хранятся задачи? | В IndexedDB браузера конкретного устройства (как в мобильной версии — локально). Из другого браузера/телефона будет свой пустой список |
| Нужен ли сервер/база? | Нет — статический сайт, «бэкенда» нет |
| Стоимость | Static Site на Render — бесплатно (есть «спящий» режим у некоторых типов сервисов; у статики — нет) |
| Свой домен | Можно привязать в настройках сайта (Custom Domains), HTTPS — автоматически |
| Анимации и темы | Работают как в мобильной версии (собрано из того же кода) |
| Чем это НЕ заменяет | Установку на телефон и публикацию в сторы (см. `RELEASE_GUIDE.md`) |

---

## Локальный просмотр (уже работает)

```bash
flutter build web --release
python -m http.server 8080 --directory build\web
# открыть http://localhost:8080
```

Любая статика подойдёт: `npx serve build/web`, nginx и т.п.
