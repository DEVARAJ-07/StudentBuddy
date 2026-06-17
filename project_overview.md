# 🎓 Overall Description of StudentBuddy

**StudentBuddy** is a comprehensive, AI-powered educational ecosystem designed to bridge productivity, mentorship, and assessment. It goes beyond a simple learning app by acting as a 24/7 personalized tutor and central hub for a student's academic life.

*   **Role-Based Experience**: The platform dynamically changes experiences based on identity (Student, Admin, SuperAdmin).
*   **AI Mentor Chat (The Core Feature)**: Replaces traditional tutoring by integrating Google Gemini AI and an external Python backend, supporting both text and Image-based OCR to analyze homework.
*   **Testing & Analytics**: Features a distraction-free "Test Arena" with anti-cheat measures, followed by deeply detailed radar and line-chart analytics to show learning trends and subjects that need focus.
*   **Immersive Roadmap**: A highly interactive, database-synced visual progression system that adapts to the student's chosen experience level.
*   **Vibrant UI/UX**: Drawing deep inspiration from premium apps like Zomato and Instamart, the app relies on responsive fluid animations, customized colored gradients, shimmer loading states, and a very modern aesthetic to keep students engaged. 

---

### 🛠️ Technology Stack

StudentBuddy utilizes a robust modern stack to run heavily data-driven insights combined with real-time AI generation:

**1. Frontend Application:**
*   **Framework**: Flutter (Deploys to Android, iOS, and Web Admin Dashboards).
*   **State Management & Routing**: `provider` for state handling and `go_router` for secure, role-based navigation.
*   **UI / Graphics**: `flutter_animate` and `lottie` for premium dynamic animations; `fl_chart` for complex analytic data visualization.

**2. Backend & Database (BaaS):**
*   **Primary Backend**: Supabase — This actively replaced earlier Appwrite/MongoDB instances.
*   **Database**: PostgreSQL (Handling the 17 table schema: users, tests, application configs, immersive roadmaps, etc.).
*   **Authentication**: Supabase Auth combined with `google_sign_in` for seamless social account creation.
*   **Storage & Real-time**: Supabase Storage buckets for PDFs/OCR visuals, and Supabase Realtime alerts for new tests without refreshing.

**3. Artificial Intelligence Engine:**
*   **API**: Google Generative AI (`Gemini API`) used for simple explanations, math solving, and adaptive responses.
*   **Custom Microservices**: A Python backend running via `ngrok` handling specialized, logic-heavy inference tasks.

**4. External Utilities & Tools:**
*   **Data Processing**: `excel` (for parsing CSV test uploads) and `syncfusion_flutter_pdf` (for generating download report cards).
*   **Device APIs**: `image_picker` / `permission_handler` to allow students to snap pictures of their work for their AI mentor.
