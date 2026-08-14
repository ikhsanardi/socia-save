# Socia Save 📥

**Socia Save** is an offline-first, cross-platform mobile application built with **Flutter** designed to receive, organize, and manage content shared directly from social media platforms (Instagram, Facebook, Threads, TikTok, YouTube, X/Twitter, and more) via native system share sheets.

---

## ✨ Features

- **📥 Native Share Sheet Receiver**: Share links directly from any social media app into Socia Save without copying and pasting manually.
- **🌐 OpenGraph Metadata Extraction**: Automatically parses link titles, thumbnails (`og:image`), and platform sources in the background.
- **⚡ Offline-First Architecture**: Powered by **Isar Database** for native, high-performance local storage, indexing, and full-text search.
- **🗂️ Master Category System**: Organize your saved items with 100% custom categories and color-coded tags.
- **🔍 Filter & Search**: Instant full-text search with category filter modal sheets and quick-clear filter chips.
- **☁️ Cloud Backup & Synchronization**: Optional **Firebase Authentication** and **Cloud Firestore** sync with un-synced change tracking badges.
- **✏️ Edit & Manage Content**: Kebab menu on saved items with options to edit titles, reassign categories, copy links, or delete content with confirmation.
- **🚀 Instant External Launch**: Open saved links directly in their native social media apps or browser via `url_launcher`.
- **🎨 Material 3 Theming**: Responsive design supporting system-default Light and Dark modes.

---

## 🛠️ Tech Stack

- **Framework**: [Flutter](https://flutter.dev) (Dart SDK `^3.12`)
- **State Management**: [Riverpod](https://riverpod.dev) (`flutter_riverpod`)
- **Local Database**: [Isar Database](https://isar.dev) (`isar`, `isar_flutter_libs`)
- **Cloud & Sync**: [Firebase Core](https://firebase.google.com), `firebase_auth`, `cloud_firestore`
- **Share Handling**: `receive_sharing_intent`
- **Link Metadata**: `http`, `html` (OpenGraph parser)
- **External Launch**: `url_launcher`

---

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK**: `3.44.x` or later ([Install Flutter](https://docs.flutter.dev/get-started/install))
- **Java**: OpenJDK 17
- **Android SDK**: Android API 34+ (compileSdk 36)

### Installation

1. **Clone the Repository**:

   ```bash
   git clone https://github.com/ikhsanardi/socia_saver.git
   cd socia_saver
   ```

2. **Install Dependencies**:

   ```bash
   flutter pub get
   ```

3. **Generate Isar Models Code**:

   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **Run on Connected Device**:
   ```bash
   flutter run
   ```

---

## 📂 Project Structure

```
lib/
├── core/
│   ├── services/
│   │   ├── isar_service.dart          # Local database operations
│   │   └── opengraph_service.dart     # Metadata extraction
│   └── theme/
│       └── app_theme.dart             # Material 3 Light/Dark themes
├── models/
│   ├── category.dart                  # Category Isar schema
│   └── shared_content.dart            # Shared item Isar schema
├── providers/
│   ├── category_provider.dart         # Category state notifier
│   ├── database_provider.dart         # Isar service & user ID providers
│   ├── shared_content_provider.dart   # Content list & filter state
│   └── sync_provider.dart             # Cloud sync notifier
├── screens/
│   ├── categories_screen.dart         # Master categories management
│   ├── category_filter_modal.dart     # Category filter bottom sheet
│   ├── edit_content_bottom_sheet.dart # Content edit bottom sheet
│   ├── home_screen.dart               # Main index view & search bar
│   └── share_receiver_bottom_sheet.dart # Native share intent handler
└── widgets/
    ├── content_card.dart              # Saved content item card
    └── socmed_icon.dart               # Social platform icon badge
```

---

## 📄 License

This project is private and licensed under the MIT License - see the LICENSE file for details.
