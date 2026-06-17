# 🎓 StudentBuddy

**StudentBuddy** is an AI-powered educational ecosystem designed to bridge the gap between productivity, mentorship, and assessment. Drawing UI/UX inspiration from premium, high-engagement consumer platforms like Zomato and Instamart, the app features rich color gradients, glassmorphism elements, custom animations, and shimmer loaders.

---

## 🛠️ Core Technologies & Environment Setup

To run or build StudentBuddy locally, ensure your development environment is configured with the following toolchain:

### 1. Flutter & Dart SDK
* **Flutter Version:** Ensure you have Flutter SDK `3.10.4` or higher installed.
* **Dart Version:** Compatible with Dart SDK `^3.10.4`.
* **Path Variables:** Ensure the Flutter binary is accessible via your path command line tools.

### 2. Android Studio (IDE)
* **Plugins:** Install the **Flutter** and **Dart** plugins via `Settings > Plugins` inside Android Studio.
* **SDK Manager:** From Android Studio, open the SDK Manager and install:
  * Android SDK Build-Tools
  * Android Emulator & Platform Tools
  * Android SDK Command-line Tools (latest version)
* **Device Setup:** Configure an Android Emulator (AVD) with API level 21 or higher (Lollipop+) or connect a physical Android device with USB Debugging enabled.

### 3. Supabase BaaS (Backend)
StudentBuddy leverages **Supabase** as its database, authentication provider, storage engine, and real-time event system:
* **Authentication:** Handled via Supabase Auth with Google Sign-in OAuth flow integration.
* **Database:** Powered by PostgreSQL containing custom schemas for roles (`profiles`), test configurations, result tables, and streaks.
* **Real-time Engine:** Syncs active test announcements and alerts directly to student dashboards.

---

## 🚀 Dev Setup & Execution

### 1. Get Dependencies
Run the package resolver from the project root:
```bash
flutter pub get
```

### 2. Setup Environment Keys
Create a `.env` configuration file in the root directory to store your API keys. Make sure **not** to commit this file to public version control:
```env
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-supabase-anonymous-key
DEEPSEEK_API_KEY=your-deepseek-api-key
OPENROUTER_KEY=your-openrouter-api-key
```

### 3. Run and Debug
Launch the application on your configured Android Emulator, iOS Simulator, or Web browser:
```bash
flutter run
```

---

## 📲 APK Download & Local Builds

For quick installations on Android devices for testing purposes, you can download the pre-built release package:

* 📥 **[Download Latest Release APK](file:///d:/Projects/student_buddy/build/app/outputs/flutter-apk/app-release.apk)**
* Alternatively, locate the binary locally at: `build/app/outputs/flutter-apk/app-release.apk`

To compile a fresh APK manually:
```bash
flutter build apk --release
```
