# 🔍 FindMissingPerson (FMP)

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart" />
  <img src="https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" alt="Firebase" />
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web-brightgreen?style=for-the-badge" alt="Platform" />
  <img src="https://img.shields.io/badge/License-MIT-blue?style=for-the-badge" alt="License" />
</p>

> **FindMissingPerson** is a modern, crowdsourced community safety and missing person recovery platform built with Flutter and Cloud Firestore. It connects families, volunteers, and safety authorities to report, search, verify, and locate missing individuals quickly and securely.

---

## 🌟 Key Features

### 1. 🚨 Comprehensive Missing Person Reporting
* **Intake Details**: Report missing individuals with detailed profiles including full name, age, gender, last seen location, date of disappearance, emergency contact phone, and identifying physical traits.
* **Resilient Permanent Cloud Photos**: Image compression and permanent Base64 Cloud Firestore sync ensure photos never disappear across cache wipes, app updates, or device restarts.
* **Anti-Duplicate Multi-Tap Lock**: Rapid-tap debounce and a 12-second de-duplication guard prevent accidental duplicate submissions even on slow cellular networks.
* **Strict Author-Only Permissions**: Only the original creator of a post (`reportedBy == currentUserId`) or a verified administrator can edit, update status, or delete the report.

### 2. 👁️ Sighting Reports & AI Face Matching
* **Report Sightings / Found**: Citizens and finders can upload sighting details, current location, and photos when a missing person is spotted.
* **Local Face Embedding Engine**: Zero-API-cost on-device feature extraction computes cosine similarities between missing persons and found candidates to suggest potential matches.

### 3. 📱 Facebook-Style Social Community Feed
* **Interactive Timeline**: Real-time posts with visual status badges (`Missing`, `Possible Match`, `Sighted`, `Found`).
* **Uncropped Media Presentation**: Responsive, uncropped photo layouts ensure full portrait and landscape images remain clearly visible.
* **Full-Screen Lightbox Photo Viewer**: Tap any photo to open a Facebook-style full-screen viewer with:
  * Pure dark background
  * **Pinch-to-zoom** (up to 4.5x magnification) & double-tap to zoom
  * Smooth pan and repositioning
  * Quick-close (`X`) navigation
* **1-Click Printable Notice Poster**: Generate printable PDF-ready missing person posters with QR-ready layouts, contact cards, and case details.
* **Direct Reporter Contact**: One-tap phone dialing directly from the report card.

### 4. 👤 Facebook-Style Profiles & Privacy Architecture
* **Distinct Theming**: Modern Royal Violet (`#7C3AED`) & Deep Indigo (`#6366F1`) cover design for profile screens, keeping it visually distinct from the Navy/Crimson Home feed.
* **Unique Volunteer ID**: Every registered citizen receives an automatic unique ID (e.g. `#FMP-9B3C1A`).
* **Dedicated "My Reports" Feed**: Users can track and review all reports they have submitted in one place.
* **Public Volunteer Profiles**: Tap on any post author's name or avatar to view their public profile and see all cases they have reported.
* **Citizen Privacy Protection**:
  * **Email is strictly hidden by default** (`Email: Private · Hidden by user` 🔒).
  * Citizen toggles to show or hide their phone number and city.
* **Custom Profile Photo Persistence**: Custom profile pictures uploaded through Edit Profile are preserved permanently in Firestore and will never be overwritten on Google re-logins.

### 5. 🔐 Multi-Factor Authentication & Recovery
* **Email & Password**: Registration with client-side strong password validation.
* **Live 6-Digit Email OTP**: Direct SSL SMTP delivery via Gmail to verify user identity at signup.
* **One-Tap Google Sign-In**: Native Google Sign-In with OAuth token synchronization.
* **Smart Password Recovery**: Validates account registration in Firestore/Auth before sending recovery links; strictly refuses to send spam to unregistered emails and informs the user immediately.
* **Guest Browsing Mode**: Instant access for citizens to browse missing alerts without mandatory login.

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| **Framework** | [Flutter](https://flutter.dev/) (v3.x) & [Dart](https://dart.dev/) (v3.x) |
| **Database** | [Cloud Firestore](https://firebase.google.com/docs/firestore) |
| **Authentication** | [Firebase Auth](https://firebase.google.com/docs/auth) & [Google Sign-In](https://pub.dev/packages/google_sign_in) |
| **Email / SMTP** | [Mailer](https://pub.dev/packages/mailer) (Direct SSL Port 465) |
| **Media & Images** | [Image Picker](https://pub.dev/packages/image_picker) & Base64 Cloud Storage |
| **Formatting & Utilities** | [Intl](https://pub.dev/packages/intl), [URL Launcher](https://pub.dev/packages/url_launcher) |

---

## 📁 Project Architecture

```
findMissingPerson/
├── android/                         # Native Android configuration & Gradle build scripts
│   └── app/
│       ├── google-services.json.example   # Template for Firebase Android configuration
│       └── build.gradle
├── ios/                             # Native iOS project configuration
├── lib/
│   ├── config/                      # App secrets & configuration templates
│   │   ├── secrets.dart             # (Git-ignored) Local credentials
│   │   └── secrets.example.dart     # (Committed) Template for new clones
│   ├── models/                      # Data models (MissingPerson, FoundReport)
│   ├── screens/                     # Application screens
│   │   ├── admin/                   # Admin edit & case review screens
│   │   ├── edit_profile_screen.dart # Facebook-style profile editor with privacy switches
│   │   ├── home_screen.dart         # Home feed & Profile tabs
│   │   ├── login_screen.dart        # Authentication & Smart Password Reset
│   │   ├── person_detail_screen.dart# Report details, poster, & author actions
│   │   ├── public_profile_screen.dart# Facebook-style public user profile
│   │   ├── register_screen.dart     # Citizen signup & OTP verification
│   │   └── report_missing_screen.dart # Missing person intake form
│   ├── services/                    # Business logic & cloud integrations
│   │   ├── auth_service.dart        # User auth, roles, and profile persistence
│   │   ├── email_service.dart       # Live Gmail SMTP 6-digit OTP delivery
│   │   ├── face_embedding_engine.dart # On-device biometric feature matching
│   │   ├── missing_person_repository.dart # Firestore real-time CRUD & deduplication
│   │   └── storage_service.dart     # Resilient permanent image cloud sync
│   ├── utils/                       # Validators & formatters
│   ├── widgets/                     # Reusable UI components
│   │   ├── app_photo_view.dart      # Resilient base64 & network photo loader
│   │   ├── full_screen_image_viewer.dart # Zoomable Facebook-style photo viewer
│   │   ├── missing_poster_dialog.dart # Printable poster generation
│   │   └── social_post_card.dart    # Feed card with author permissions
│   ├── firebase_options.dart        # Firebase client platform options
│   └── main.dart                    # Application entrypoint
├── .gitignore                       # Production gitignore rules
├── pubspec.yaml                     # Project dependencies & metadata
└── README.md                        # Documentation
```

---

## 🚀 Getting Started

### 1. Prerequisites
* [Flutter SDK](https://docs.flutter.dev/get-started/install) (version 3.22+ recommended)
* [Android Studio](https://developer.android.com/studio) or VS Code with Flutter extension
* [Git](https://git-scm.com/) installed on your machine
* A [Firebase Project](https://console.firebase.google.com/) with **Authentication** and **Cloud Firestore** enabled

---

### 2. Installation & Setup

1. **Clone the repository**:
   ```bash
   git clone https://github.com/<your-username>/findMissingPerson.git
   cd findMissingPerson
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Configure Firebase Credentials**:
   * Download your `google-services.json` from the Firebase Console (Project Settings > General > Your Apps > Android).
   * Place it into `android/app/google-services.json`.
   * Refer to `android/app/google-services.json.example` for the expected schema.

4. **Configure Secrets & SMTP Credentials**:
   * Copy the template secrets file:
     ```bash
     cp lib/config/secrets.example.dart lib/config/secrets.dart
     ```
   * Open `lib/config/secrets.dart` and enter:
     * Your sender Gmail address.
     * Your 16-character [Google App Password](https://myaccount.google.com/apppasswords).
     * Your Firebase API key.

---

### 3. Running the Application

* **Start in Debug mode**:
  ```bash
  flutter run
  ```

* **Build Production Release APK**:
  ```bash
  flutter build apk --release
  ```
  The generated APK will be located at `build/app/outputs/flutter-apk/app-release.apk`.

---

## 🔒 Security & Privacy

* **Zero Leaked Secrets**: All sensitive API keys, service files, and email passwords are kept in `lib/config/secrets.dart` and `android/app/google-services.json`, which are strictly excluded from version control via `.gitignore`.
* **Author-Only Deletion & Mutation**: Reports can only be updated or deleted by their verified creator or authorized admins.
* **Citizen Privacy**: Public profiles mask user email addresses by default, allowing volunteers to collaborate without exposing their personal contact details.

---

## 🤝 Contributing

Contributions are welcomed! To contribute:
1. Fork this repository.
2. Create your feature branch (`git checkout -b feature/amazing-feature`).
3. Commit your changes (`git commit -m 'Add some amazing feature'`).
4. Push to the branch (`git push origin feature/amazing-feature`).
5. Open a Pull Request.

---

## 📄 License

This project is licensed under the **MIT License** - see the LICENSE file for details.

---

<p align="center">
  Built with ❤️ for community safety and helping reunite missing persons with their families.
</p>
