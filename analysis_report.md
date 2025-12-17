# StudentBuddy Requirements Analysis

## 1. Executive Summary
The `requirementsupdations.md` file outlines an AI-powered educational platform called **StudentBuddy**. It features a role-based system (Student, Admin, SuperAdmin) with a focus on personalized AI tutoring (Gemini), testing, and analytics.

## 2. Technology Stack Conflict
**⚠️ CRITICAL DISCREPANCY DETECTED ⚠️**
The requirements file contains contradictory information regarding the frontend and backend technologies:

*   **Top Section (Lines 4-12) & Detailed Specs (Lines 26-167)**:
    *   **Frontend**: Flutter (Mobile + Web).
    *   **Backend**: Supabase (PostgreSQL, Auth, Real-time).
    *   **Evidence**: The detailed breakdown references Flutter-specific components like `Scaffold`, `Navigator.pushNamed`, `StreamBuilder`, and `fl_chart`.

*   **Bottom Section (Lines 181-189)**:
    *   **Frontend**: React Native (Expo).
    *   **Backend**: Node.js + Express.
    *   **Evidence**: Explicitly lists "React Native" and "Node.js + Express" in the summary table.

**Conclusion**: The detailed page specifications (P0-P7) strongly suggest that **Flutter** is the intended framework. The React Native/Node.js references at the bottom appear to be inconsistent or possibly from a different version of the specs.
**This analysis follows the Flutter specifications found in the detailed sections.**

---

## 3. Feature Breakdown

### A. Core Architecture
*   **Role-Based Routing**: Single entry point with redirection based on role (Student, Admin, SuperAdmin).
*   **Zones**:
    *   **Public**: Welcome & Auth.
    *   **Student**: Dashboard, Testing, Analytics, Mentor Chat.
    *   **Admin**: Dashboard, User & Test Management.
    *   **SuperAdmin**: System Control.

### B. User Features (Student Zone)
1.  **Authentication (P1)**:
    *   Social Login (Google) and Email/Password.
    *   Role verification loop (`public.profiles`).
2.  **Dashboard (P2)**:
    *   "Heads-Up Display" for tasks.
    *   Real-time test alerts via Supabase.
    *   Quick deep-link to resume Mentor Chat.
3.  **Test Arena (P3)**:
    *   **Security**: Anti-cheat UI (copy prevention), Full screen.
    *   **Functionality**: Periodic timer, Question flagging, Auto-grading (Edge Functions).
4.  **Analytics (P4)**:
    *   **Visuals**: Line graphs (Performance Trends), Radar charts (Subject Strength).
    *   **Actions**: Download PDF Report, "Focus on [Subject]" redirect to Mentor.
5.  **AI Mentor (P5)**:
    *   **Engine**: Gemini API (Streaming responses).
    *   **Inputs**: Text, Speech-to-Text (Mic), Image/Homework implementation (Camera/OCR).
    *   **Features**: Rich text (Markdown), "Explain Simply" context toggle.

### C. Admin & System Features
1.  **Admin Dashboard (P6)**:
    *   Desktop-first Flutter Web layout.
    *   **User Management**: DataTable widgets, Disable/Enable users.
    *   **Content**: CSV Upload wizard for creating tests.
2.  **SuperAdmin (P7)**:
    *   "God Mode" for platform ownership.
    *   Add Admins, System Reset.

---

## 4. Dependencies & Tech Stack Analysis

Based on the detailed Flutter specifications, here are the required dependencies and technologies:

### Core Framework & State
*   **Flutter SDK**: Mobile (Android/iOS) & Web.
*   **`provider`**: Global state management.
*   **`flutter_animate`**: UI animations (Welcome page, feedback).
*   **`google_fonts`**: Poppins & Inter typography.

### Backend & Data
*   **Supabase Project**:
    *   **Table `public.profiles`**: Storage of roles/users.
    *   **Table `test_results`**: Storage of scores for analytics.
    *   **Edge Functions**: For auto-grading logic.
*   **`supabase_flutter`**: Official client sdk.

### Features & Integrations
*   **AI**: `google_generative_ai` (Gemini API).
*   **Charts**: `fl_chart` (Line & Radar charts).
*   **Auth**: `google_sign_in` (OAuth).
*   **Input**:
    *   `image_picker` (Camera for homework).
    *   `speech_to_text` (Microphone).
*   **Utils**:
    *   `file_picker` (CSV upload for Admins).
    *   `pdf` (Report generation).

### UI/UX Design System
*   **Colors**: Deep Purple (`0xFF6A11CB`), Bright Blue (`0xFF2575FC`).
*   **Style**: Glassmorphism, "Shimmer" loading states, Splash ripple effects.
