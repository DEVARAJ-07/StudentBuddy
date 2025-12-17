🏗️ Project Title: StudentBuddy
Core Concept: An AI-powered educational ecosystem that bridges the gap between productivity, mentorship, and assessment. It uses AI to provide personalized tutoring and "Smart Scheduling" while offering Admins robust tools to manage student progress.

Technology Stack:

Frontend: Flutter (Mobile for Android/iOS + Web for Admin Dashboards).

Backend & Database: Supabase (PostgreSQL, Auth, Real-time).

AI Engine: Gemini API (Google Generative AI).

Key Packages: provider (State), flutter_animate, fl_chart, google_fonts.

🗺️ The Site Map & Flow Overview
The application uses Role-Based Routing. There is one entry point, but the destination changes based on the user's identity.

Public Zone: P0 (Welcome) → P1 (Auth)

Student Zone: P2 (Dashboard) ↔ P3 (Tests) ↔ P4 (Analytics) ↔ P5 (Mentor Chat)

Admin Zone: P6 (Admin Dashboard) ↔ P6-Users ↔ P6-Tests

SuperAdmin Zone: P7 (System Control)

📄 Detailed Page Specifications
1. P0: The Welcome Page (Landing)
Purpose: The visual "hook." It introduces the brand and directs users to sign in.

Flow: Entry → Click "Get Started" → Navigate to P1.

Why this page? To establish credibility and brand identity before asking for credentials.

Technology: Flutter Scaffold, Stack (for background images), Simple Animation controller.

UI Style: Full-screen gradient background (Deep Purple to Blue). Large, centered white typography. Glassmorphism effect on the bottom container.

Buttons & Actions:

"Get Started" (Primary): Large, pill-shaped button. Action: Navigator.pushNamed('/login').

"Learn More" (Secondary): Small text link. Action: Opens a bottom sheet with feature summary.

2. P1: Authentication Gateway
Purpose: Securely identify the user and determine their Role (Student vs. Admin).

Flow: User Enters Credentials/Social Login → Supabase Auth verifies → App checks public.profiles table for Role → Redirects to P2, P6, or P7.

Why this page? Security. It prevents unauthorized access and segments the user base.

Technology: Supabase Auth, Google Sign-In package.

UI Style: Clean white card on a colored background. Input fields with rounded corners.

Buttons & Actions:

"Sign In with Google" (Social): Triggers OAuth flow. Auto-creates a "Student" profile if new.

"Login" (Email): Validates form. Triggers supabase.auth.signInWithPassword.

"Forgot Password": Triggers supabase.auth.resetPasswordForEmail.

3. P2: Student Dashboard (The Hub)
Purpose: A "Heads-Up Display" for the student's academic life. Shows immediate tasks and progress.

Flow: P1 → P2. From here, navigate to P3, P4, or P5.

Why this page? Students need a central place to see "What do I need to do right now?" without searching.

Technology: StreamBuilder (listening to Supabase for live test alerts), fl_chart (for the graph).

UI Style: "iOS Style" Header. Cards with soft shadows. Horizontal scrolling lists.

Buttons & Actions:

"Notification Bell" (Icon): Opens the Alerts drawer (New tests/assignments).

"Resume Chat" (Card): Deep links directly to the last active P5 Mentor session.

"Take Test" (Action Button): Navigates to P3-Active.

4. P3: The Test Arena
Purpose: A secure environment for taking assessments.

Flow: P2 → Select Test → P3 (Full Screen) → Submit → Results Modal.

Why this page? To verify learning. Features "Anti-Cheat" UI (prevents copying text).

Technology: Timer.periodic (Countdown), Supabase Edge Functions (auto-grading).

UI Style: Minimalist. Distraction-free. White background with clear black text. Selected options turn Blue.

Buttons & Actions:

"Option A/B/C/D": Selects an answer.

"Flag": Marks question yellow for review.

"Submit Test" (Critical): Triggers grading logic. Cannot be undone.

5. P4: Analytics & Insights
Purpose: To show the student how they are learning, not just what they scored.

Flow: P2 or P3-Result → P4.

Why this page? Data visualization motivates improvement.

Technology: fl_chart (Line graphs for trends, Radar charts for subject strength). Aggregates data from test_results table.

UI Style: Data-heavy but clean. Uses color coding (Green = Good, Red = Needs Focus).

Buttons & Actions:

"Download Report": Generates a PDF summary.

"Focus on [Subject]": Auto-navigates to P5 (Mentor) with that subject context pre-loaded.

6. P5: AI Mentor Chat (The Core Feature)
Purpose: 24/7 personalized tutoring.

Flow: P2 → P5 (Select Mentor) → Chat Interface.

Why this page? This is the USP (Unique Selling Point). It replaces a human tutor.

Technology: Google Gemini API (via google_generative_ai package). Streaming text response. ImagePicker for OCR.

UI Style: Chat bubble interface. User = Blue (Right), AI = Grey (Left). Rich text support (Markdown for bolding/math).

Buttons & Actions:

"Microphone": Activates Speech-to-Text.

"Camera": Uploads homework photo for AI analysis.

"Explain Simply": A context action to rewrite the last answer for a 5-year-old.

7. P6: Admin Dashboard
Purpose: Management of the student population and content.

Flow: Login (As Admin) → P6.

Why this page? Admins need to create tests and monitor platform usage.

Technology: Flutter Web (Responsive). DataTable widgets.

UI Style: Desktop-first layout. Sidebar navigation. High-density data tables.

Buttons & Actions:

"Create Test" (FAB): Opens the CSV upload wizard.

"Disable User" (Table Action): Toggles is_active status in Supabase.

8. P7: SuperAdmin Panel
Purpose: "God Mode" for the platform owner.

Flow: Login (As SuperAdmin) → P7.

Why this page? To manage the Admins and global settings.

Technology: Same as P6, but with elevated RLS (Row Level Security) permissions.

Buttons & Actions:

"Add Admin": Promotes a user to Admin role.

"System Reset": (Dangerous) Clears test data for a new semester.

🎨 Global UI/UX Guidelines
Primary Color: Color(0xFF6A11CB) (Deep Purple) - Used for primary buttons and headers.

Secondary Color: Color(0xFF2575FC) (Bright Blue) - Used for gradients and accents.

Typography: "Poppins" for Headings (Friendly, Round), "Inter" or "Roboto" for Body text (Readable).

Feedback: Every button press has a "Splash" ripple effect. Every loading state uses a "Shimmer" skeleton loader, not a boring spinner.





Component,Technology,Role in StudentBuddy
Frontend,React Native (Expo),The Mobile App (Android/iOS).
Backend,Node.js + Express,The logic layer. It uses the supabase-js admin client to manage data safely and secure APIs with Arcjet.
Database,Supabase (PostgreSQL),(Replaces MongoDB) Structured SQL database. Perfect for relational data like Students belong to Classes and Tests have Questions.
Auth,Supabase Auth,"(Replaces Manual JWT) Handles Google/GitHub logins, Magic Links, and session management automatically."
Storage,Supabase Storage,"(Replaces Cloudinary) Stores Profile Pics, Syllabus PDFs, and OCR visuals in secure ""Buckets""."
Real-time,Supabase Realtime,"(Replaces Socket.io) Listens for database changes instantly (e.g., when a friend joins a ""Focus Circle"" or a new ""Test"" is assigned)."
Email,Resend,"Works with Supabase to send custom branded emails (Welcome, Exam Reminders, Mentor Invites)."
Security,Arcjet,Shield for your Node.js API routes (Rate limiting & Bot protection).













the ui is your wish , create the ui with more colorful and like instamart or zomato like logo and effect while go into the app and loding animations and all your wish as postively give the ui as best as you can for mobile and web too and then i need all the functalities in web and mobile too and then install with all 