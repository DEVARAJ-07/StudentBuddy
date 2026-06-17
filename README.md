# 🎓 StudentBuddy

StudentBuddy is an AI-powered educational ecosystem that bridges the gap between productivity, mentorship, and assessment. Designed with a vibrant, intuitive UI, it acts as a central hub where students can track their learning, take assessments, and receive 24/7 personalized tutoring. Admins are provided with robust tools to manage student progress, assignments, and test creation.

## 🚀 Key Features
* **Role-Based Access Control:** Distinct zones for Students, Admins, and SuperAdmins.
* **AI Mentor Chat:** 24/7 personalized tutoring powered by Google Gemini API, featuring text, speech-to-text, and image-based (OCR) homework analysis.
* **Interactive Roadmap:** A highly immersive, database-synced roadmap to track student progress and experience levels.
* **Testing Arena & Analytics:** Secure environments for taking tests with built-in anti-cheat measures, followed by detailed graphical analytics (trends and subject strengths) using `fl_chart`.
* **Real-time Notifications:** Instant alerts for new assignments or tests.
* **Admin Dashboard:** Comprehensive tools for managing students, uploading CSV-based tests, and tracking platform usage.

## 🛠️ Tech Stack
* **Frontend:** Flutter (Mobile for Android/iOS + Web for Dashboards)
* **Backend as a Service:** Supabase (Auth, PostgreSQL Database, Storage, Real-time)
* **AI Engine:** Google Generative AI (Gemini API) + Local Python Backend (via ngrok) for advanced interactions
* **State Management & Routing:** `provider` and `go_router`
* **UI/UX & Graphics:** `flutter_animate`, `lottie`, `google_fonts`, `fl_chart`
* **Authentication:** Supabase Auth & Google Sign-In (`google_sign_in`)
* **Utilities:** `syncfusion_flutter_pdf` for report generation, `excel` for parsing, and `cached_network_image`.

## 🎨 UI/UX Philosophy
The application features a modern, colorful, and engaging user interface, drawing inspiration from high-engagement apps like Zomato and Instamart. It utilizes lively animations, shimmer effects for loading states, rich color gradients, and glassmorphism elements to deliver a premium, fluid user experience.

## 🏁 Getting Started
1. **Clone the repository:** `git clone https://github.com/your-repo/student_buddy.git`
2. **Install dependencies:** `flutter pub get`
3. **Setup Environments:** Create a `.env` file at the root containing necessary API keys (Supabase, Gemini, etc.).
4. **Run the app:** `flutter run`

## 📲 Download the App (APK)

For testing and installation on Android devices, you can download the built APK directly from this repository:
* 📥 **[Download Latest Release APK](file:///d:/Projects/student_buddy/build/app/outputs/flutter-apk/app-release.apk)**
* Alternatively, navigate to: `build/app/outputs/flutter-apk/app-release.apk`
