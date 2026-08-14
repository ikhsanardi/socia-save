# Socia Save 📥

[![Flutter](https://img.shields.io/badge/Flutter-3.44+-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.12+-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Firestore%20%26%20Auth-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com)
[![Isar Database](https://img.shields.io/badge/Isar%20DB-3.1+-5856D6?style=for-the-badge)](https://isar.dev)

**Socia Save** is an offline-first, cross-platform mobile application built with **Flutter** designed to receive, organize, and manage content shared directly from social media platforms (Instagram, Facebook, Threads, TikTok, YouTube, X/Twitter, and more) via native system share sheets.

---

## ✨ Features

- **📥 Native Share Sheet Receiver**: Share links directly from any social media app into Socia Save without copying and pasting manually.
- **🌐 OpenGraph Metadata Extraction**: Automatically parses link titles, thumbnails (`og:image`), and platform sources in the background.
- **⚡ Offline-First Architecture**: Powered by **Isar Database** for native, high-performance local storage, indexing, and full-text search.
- **🗂️ Master Category System**: Organize your saved items with 100% custom categories and color-coded tags.
- **🔍 Filter & Search**: Instant full-text search with category filter modal sheets, dismissible active filter chips, and intuitive tap-out / back-gesture dismissal.
- **☁️ Cloud Backup & Synchronization**:
  - **Zero-Friction Authentication**: Uses Firebase Anonymous Authentication by default (no login form required).
  - **Batch Firestore Sync**: Backs up categories and content to Cloud Firestore with bidirectional sync and cloud deletion propagation.
  - **Unsynced Change Tracking**: AppBar badge showing the exact count of pending local changes.
  - **Seamless Data Migration**: Automatically migrates offline `'local_user'` data to the authenticated Firebase UID upon first sync.
- **✏️ Edit & Manage Content**: Kebab (`⋮`) menu on saved items with options to edit titles, reassign categories, copy links, or delete content with confirmation.
- **🚀 Instant External Launch**: Open saved links directly in their native social media apps or browser via `url_launcher`.
- **🎨 Material 3 Theming**: Responsive design supporting system-default Light and Dark modes.

---

## 🛠️ Tech Stack

- **Framework**: [Flutter](https://flutter.dev) (Dart SDK `^3.12`)
- **State Management**: [Riverpod](https://riverpod.dev) (`flutter_riverpod`)
- **Local Database**: [Isar Database](https://isar.dev) (`isar`, `isar_flutter_libs`)
- **Cloud & Auth**: [Firebase Core](https://firebase.google.com), `firebase_auth`, `cloud_firestore`
- **Share Intent**: `receive_sharing_intent`
- **Link Metadata**: `http`, `html` (OpenGraph HTML parser)
- **External Launch**: `url_launcher`

---

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK**: `3.44.x` or later ([Install Flutter](https://docs.flutter.dev/get-started/install))
- **Java**: OpenJDK 17
- **Android SDK**: Android API 34+ (`compileSdk = 36`)

---

### Installation & Setup

1. **Clone the Repository**:

   ```bash
   git clone https://github.com/ikhsanardi/socia_saver.git
   cd socia_saver
   ```

2. **Install Dependencies**:

   ```bash
   flutter pub get
   ```

3. **Generate Isar Models & Schema**:
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

---

### 🔥 Firebase Setup

1. Create a project in the [Firebase Console](https://console.firebase.google.com).
2. Add an **Android App** with package name:
   ```
   com.sharesaver.socmed_share_saver
   ```
3. Download `google-services.json` and place it at:
   ```
   android/app/google-services.json
   ```
4. **Enable Anonymous Authentication**:
   - Go to **Build** → **Authentication** → **Sign-in method** → Enable **Anonymous**.
5. **Create Cloud Firestore Database**:
   - Go to **Build** → **Firestore Database** → **Create Database** (Select _Standard Edition_).
   - In the **Rules** tab, publish the following security rules:
     ```javascript
     rules_version = '2';
     service cloud.firestore {
       match /databases/{database}/documents {
         match /users/{userId}/{document=**} {
           allow read, write: if request.auth != null && request.auth.uid == userId;
         }
       }
     }
     ```

---

### 📱 Running the App

```bash
# Run on connected device with Hot Reload enabled
flutter run
```

---

## 📂 Project Structure

```
lib/
├── core/
│   ├── services/
│   │   ├── isar_service.dart          # Local Isar DB CRUD, migration & sync markers
│   │   └── opengraph_service.dart     # Web scraping & OpenGraph metadata parser
│   └── theme/
│       └── app_theme.dart             # Material 3 Light/Dark theme configuration
├── models/
│   ├── category.dart                  # Category Isar collection schema
│   └── shared_content.dart            # Shared item Isar collection schema
├── providers/
│   ├── category_provider.dart         # Category state notifier & active filter
│   ├── database_provider.dart         # Isar service & dynamic user ID provider
│   ├── shared_content_provider.dart   # Content list notifier & unsynced badge provider
│   └── sync_provider.dart             # Firestore bidirectional synchronization engine
├── screens/
│   ├── categories_screen.dart         # Master categories management & color picker
│   ├── category_filter_modal.dart     # Category filter bottom sheet
│   ├── edit_content_bottom_sheet.dart # Content title & category edit modal
│   ├── home_screen.dart               # Main index view, search bar & action buttons
│   └── share_receiver_bottom_sheet.dart # Native system share intent receiver sheet
└── widgets/
    ├── content_card.dart              # Saved content card with preview & action buttons
    └── socmed_icon.dart               # Social platform icon badge
```

---

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.
