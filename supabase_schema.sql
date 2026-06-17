-- ========================================================
-- CLEANUP: RUN THIS FIRST TO DELETE OLD TABLES
-- ========================================================

DROP VIEW IF EXISTS public.user_test_summary CASCADE;

DROP VIEW IF EXISTS public.active_tests_for_user CASCADE;

DROP VIEW IF EXISTS public.missed_tests_for_user CASCADE;

DROP VIEW IF EXISTS public.last_7_days_study CASCADE;

DROP VIEW IF EXISTS public.mentor_weekly_stats CASCADE;

DROP TABLE IF EXISTS public.mentor_interactions CASCADE;

DROP TABLE IF EXISTS public.admin_messages CASCADE;

DROP TABLE IF EXISTS public.notifications CASCADE;

DROP TABLE IF EXISTS public.user_chats CASCADE;

DROP TABLE IF EXISTS public.chat_messages CASCADE;

DROP TABLE IF EXISTS public.mentor_creations CASCADE;

DROP TABLE IF EXISTS public.study_sessions CASCADE;

DROP TABLE IF EXISTS public.test_results CASCADE;

DROP TABLE IF EXISTS public.test_assignments CASCADE;

DROP TABLE IF EXISTS public.test_questions CASCADE;

DROP TABLE IF EXISTS public.tests CASCADE;

DROP TABLE IF EXISTS public.user_progress CASCADE;

DROP TABLE IF EXISTS public.profiles CASCADE;

DROP FUNCTION IF EXISTS public.update_user_streak CASCADE;

DROP FUNCTION IF EXISTS public.get_chat_users CASCADE;

DROP FUNCTION IF EXISTS public.handle_new_user CASCADE;

DROP FUNCTION IF EXISTS public.handle_new_profile CASCADE;

-- ========================================================
-- STUDENT BUDDY - FINAL AUDITED & SYNCED SCHEMA (V2)
-- This schema incorporates all user comments for
-- student IDs, marks tracking, and test status logic.
-- ========================================================

-- Enable extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- 1. PROFILES
-- ============================================
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users (id) ON DELETE CASCADE,
    student_id TEXT UNIQUE, -- Integration ID (e.g. SB-2024-001)
    email TEXT UNIQUE NOT NULL,
    full_name TEXT,
    role TEXT DEFAULT 'user' CHECK (
        role IN (
            'user',
            'admin',
            'super_admin'
        )
    ),
    avatar_url TEXT,
    gender TEXT DEFAULT 'male' CHECK (
        gender IN ('male', 'female', 'other')
    ),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public profiles are viewable by everyone" ON public.profiles FOR
SELECT USING (true);

CREATE POLICY "Users can update own profile" ON public.profiles FOR
UPDATE USING (auth.uid () = id);

-- SuperAdmins can insert new profiles (for creating admins)
CREATE POLICY "SuperAdmins can insert profiles" ON public.profiles FOR
INSERT
WITH
    CHECK (
        EXISTS (
            SELECT 1
            FROM public.profiles
            WHERE
                id = auth.uid ()
                AND role = 'super_admin'
        )
    );

-- SuperAdmins can update any profile (for managing users/admins)
CREATE POLICY "SuperAdmins can update all profiles" ON public.profiles FOR
UPDATE USING (
    EXISTS (
        SELECT 1
        FROM public.profiles
        WHERE
            id = auth.uid ()
            AND role = 'super_admin'
    )
);

-- ============================================
-- 2. USER PROGRESS
-- ============================================
CREATE TABLE IF NOT EXISTS public.user_progress (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (),
    user_id UUID UNIQUE NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
    -- DUAL NAMING: Supporting both 'streak_count' and 'current_streak'
    streak_count INT DEFAULT 0,
    current_streak INT DEFAULT 0,
    longest_streak INT DEFAULT 0,
    last_login_date DATE,
    last_login_time TIMESTAMPTZ, -- Exact login timestamp
    study_hours DECIMAL DEFAULT 0,
    total_marks INT DEFAULT 0, -- Cumulative marks obtained
    avg_percentage DECIMAL DEFAULT 0, -- Average percentage across all tests
    tests_completed INT DEFAULT 0,
    progress_percentage DECIMAL DEFAULT 0, -- Overall progress %
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.user_progress ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own progress" ON public.user_progress FOR ALL USING (auth.uid () = user_id);

CREATE POLICY "Admins can view all progress" ON public.user_progress FOR
SELECT USING (
        EXISTS (
            SELECT 1
            FROM public.profiles
            WHERE
                profiles.id = auth.uid ()
                AND profiles.role IN ('admin', 'super_admin')
        )
    );

-- ============================================
-- 3. TESTS
-- ============================================
CREATE TABLE IF NOT EXISTS public.tests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (),
    title TEXT NOT NULL,
    subject TEXT DEFAULT 'General',
    description TEXT,
    mentor_id UUID, -- Optional: link to a specific mentor creation
    total_questions INT DEFAULT 15,
    duration_minutes INT DEFAULT 30,
    pass_marks INT DEFAULT 50, -- Passing threshold
    start_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    end_date TIMESTAMPTZ NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_by UUID REFERENCES public.profiles (id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.tests ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Active tests viewable by everyone" ON public.tests FOR
SELECT USING (is_active = true);

CREATE POLICY "Admins can manage tests" ON public.tests FOR ALL USING (
    EXISTS (
        SELECT 1
        FROM public.profiles
        WHERE
            profiles.id = auth.uid ()
            AND profiles.role IN ('admin', 'super_admin')
    )
);

-- ============================================
-- 4. TEST QUESTIONS
-- ============================================
CREATE TABLE IF NOT EXISTS public.test_questions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (),
    test_id UUID NOT NULL REFERENCES public.tests (id) ON DELETE CASCADE,
    question_text TEXT NOT NULL,
    question_type TEXT DEFAULT 'single',
    options JSONB,
    correct_answers JSONB,
    explanation TEXT,
    question_order INT DEFAULT 0,
    order_index INT DEFAULT 0 -- For code compatibility
);

ALTER TABLE public.test_questions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Questions viewable by everyone" ON public.test_questions FOR
SELECT USING (true);

CREATE POLICY "Admins manage questions" ON public.test_questions FOR ALL USING (
    EXISTS (
        SELECT 1
        FROM public.profiles
        WHERE
            profiles.id = auth.uid ()
            AND profiles.role IN ('admin', 'super_admin')
    )
);

-- ============================================
-- 5. TEST ASSIGNMENTS
-- ============================================
CREATE TABLE IF NOT EXISTS public.test_assignments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (),
    test_id UUID NOT NULL REFERENCES public.tests (id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
    status TEXT DEFAULT 'pending' CHECK (
        status IN (
            'pending',
            'attended',
            'completed',
            'missed'
        )
    ),
    attended_at TIMESTAMPTZ, -- When the user first started the test
    notified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (test_id, user_id)
);

ALTER TABLE public.test_assignments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Assignments viewable by user" ON public.test_assignments FOR
SELECT USING (auth.uid () = user_id);

CREATE POLICY "Admins manage assignments" ON public.test_assignments FOR ALL USING (
    EXISTS (
        SELECT 1
        FROM public.profiles
        WHERE
            profiles.id = auth.uid ()
            AND profiles.role IN ('admin', 'super_admin')
    )
);

-- ============================================
-- 6. TEST RESULTS
-- ============================================
CREATE TABLE IF NOT EXISTS public.test_results (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (),
    user_id UUID NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
    test_id UUID NOT NULL REFERENCES public.tests (id) ON DELETE CASCADE,
    score INT NOT NULL, -- Number of correct answers
    wrong_count INT,
    total_questions INT NOT NULL,
    percentage DECIMAL,
    answers JSONB,
    completed_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.test_results ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own results" ON public.test_results FOR ALL USING (auth.uid () = user_id);

CREATE POLICY "Admins view all results" ON public.test_results FOR
SELECT USING (
        EXISTS (
            SELECT 1
            FROM public.profiles
            WHERE
                profiles.id = auth.uid ()
                AND profiles.role IN ('admin', 'super_admin')
        )
    );

-- ============================================
-- 7. STUDY SESSIONS
-- ============================================
CREATE TABLE IF NOT EXISTS public.study_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (),
    user_id UUID NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
    start_time TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    end_time TIMESTAMPTZ,
    duration_seconds INT
);

ALTER TABLE public.study_sessions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own sessions" ON public.study_sessions FOR ALL USING (auth.uid () = user_id);

-- ============================================
-- 8. MENTOR CREATIONS
-- ============================================
CREATE TABLE IF NOT EXISTS public.mentor_creations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (),
    mentor_handle TEXT UNIQUE, -- Unique handle e.g. @pro_java_bot
    user_id UUID NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    domain TEXT,
    personality TEXT,
    avatar_style TEXT,
    additional_context TEXT, -- Extra context for mentor behavior
    experience_level TEXT, -- Beginner, Intermediate, Advanced
    learning_focus TEXT, -- Core concepts, practical skills, exam prep, revision
    guidance_style TEXT, -- Step-by-step, practice-based, project-oriented, balanced
    learning_pace TEXT, -- Slow, moderate, fast, adaptive
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.mentor_creations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own mentors" ON public.mentor_creations FOR ALL USING (auth.uid () = user_id);

CREATE POLICY "Admins view all mentors" ON public.mentor_creations FOR
SELECT USING (
        EXISTS (
            SELECT 1
            FROM public.profiles
            WHERE
                profiles.id = auth.uid ()
                AND profiles.role IN ('admin', 'super_admin')
        )
    );

-- ============================================
-- 9. CHAT MESSAGES (Mentor)
-- ============================================
CREATE TABLE IF NOT EXISTS public.chat_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (),
    user_id UUID NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
    mentor_id TEXT NOT NULL,
    content TEXT NOT NULL,
    is_from_user BOOLEAN DEFAULT TRUE,
    role TEXT DEFAULT 'user', -- Code synchronization
    reply_to_id UUID REFERENCES public.chat_messages (id), -- Threading support
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users view own chat history" ON public.chat_messages FOR
SELECT USING (auth.uid () = user_id);

CREATE POLICY "Users insert chat messages" ON public.chat_messages FOR
INSERT
WITH
    CHECK (auth.uid () = user_id);

-- ============================================
-- 10. USER CHATS (Buddy)
-- ============================================
CREATE TABLE IF NOT EXISTS public.user_chats (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (),
    sender_id UUID NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
    receiver_id UUID NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.user_chats ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users view relevant messages" ON public.user_chats FOR
SELECT USING (
        auth.uid () = sender_id
        OR auth.uid () = receiver_id
    );

CREATE POLICY "Users send messages" ON public.user_chats FOR
INSERT
WITH
    CHECK (auth.uid () = sender_id);

-- Allow users to update messages where they are the receiver (to mark as read)
CREATE POLICY "Users can mark messages as read" ON public.user_chats FOR
UPDATE USING (auth.uid () = receiver_id)
WITH
    CHECK (auth.uid () = receiver_id);

-- ============================================
-- 11. NOTIFICATIONS
-- ============================================
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (),
    user_id UUID NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
    sender_id UUID REFERENCES public.profiles (id), -- Who sent the notification (e.g. Admin)
    type TEXT NOT NULL,
    title TEXT NOT NULL,
    message TEXT,
    reply_content TEXT, -- User's reply to notification
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own notifications" ON public.notifications FOR ALL USING (auth.uid () = user_id);

-- ============================================
-- 12. ADMIN MESSAGES
-- ============================================
CREATE TABLE IF NOT EXISTS public.admin_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (),
    user_id UUID NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    is_from_admin BOOLEAN NOT NULL DEFAULT TRUE,
    is_read BOOLEAN DEFAULT FALSE,
    parent_id UUID REFERENCES public.admin_messages (id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.admin_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own messages" ON public.admin_messages FOR ALL USING (auth.uid () = user_id);

CREATE POLICY "Admins manage all messages" ON public.admin_messages FOR ALL USING (
    EXISTS (
        SELECT 1
        FROM public.profiles
        WHERE
            profiles.id = auth.uid ()
            AND profiles.role IN ('admin', 'super_admin')
    )
);

-- ============================================
-- 13. MENTOR INTERACTIONS (SYSTEM ANALYTICS)
-- ============================================
CREATE TABLE IF NOT EXISTS public.mentor_interactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (),
    user_id UUID NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
    mentor_id TEXT NOT NULL,
    mentor_type TEXT,
    start_time TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    end_time TIMESTAMPTZ,
    duration_seconds INT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.mentor_interactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage interactions" ON public.mentor_interactions FOR ALL USING (auth.uid () = user_id);

-- ============================================
-- RPC FUNCTIONS
-- ============================================

-- update_user_streak(p_user_id UUID)
-- Logic:
-- 1. If yesterday login AND today login -> increment streak
-- 2. If today login BUT didn't login yesterday -> reset streak to 1
-- 3. If yesterday login BUT didn't login today -> no action (will reset on next login)
CREATE OR REPLACE FUNCTION public.update_user_streak(p_user_id UUID)
RETURNS void AS $$
DECLARE
    v_last_login DATE;
    v_today DATE := CURRENT_DATE;
BEGIN
    SELECT last_login_date INTO v_last_login FROM public.user_progress WHERE user_id = p_user_id;

    IF v_last_login IS NULL THEN
        UPDATE public.user_progress SET streak_count = 1, current_streak = 1, last_login_date = v_today, last_login_time = NOW(), longest_streak = GREATEST(longest_streak, 1) WHERE user_id = p_user_id;
    ELSIF v_last_login < v_today THEN
        IF v_last_login = v_today - INTERVAL '1 day' THEN
            UPDATE public.user_progress SET streak_count = streak_count + 1, current_streak = streak_count + 1, last_login_date = v_today, last_login_time = NOW(), longest_streak = GREATEST(longest_streak, streak_count + 1) WHERE user_id = p_user_id;
        ELSE
            UPDATE public.user_progress SET streak_count = 1, current_streak = 1, last_login_date = v_today, last_login_time = NOW() WHERE user_id = p_user_id;
        END IF;
    ELSE
        -- Already logged in today, just update time
        UPDATE public.user_progress SET last_login_time = NOW() WHERE user_id = p_user_id;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- get_chat_users(current_user_id UUID)
CREATE OR REPLACE FUNCTION public.get_chat_users(current_user_id UUID)
RETURNS TABLE (id UUID, full_name TEXT, role TEXT, avatar_url TEXT, last_message_at TIMESTAMPTZ) AS $$
BEGIN
    RETURN QUERY SELECT p.id, p.full_name, p.role, p.avatar_url, MAX(uc.created_at) as last_message_at FROM public.profiles p LEFT JOIN public.user_chats uc ON (p.id = uc.sender_id OR p.id = uc.receiver_id) WHERE p.id != current_user_id AND p.role = 'user' GROUP BY p.id ORDER BY last_message_at DESC NULLS LAST, p.full_name ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- TRIGGERS
-- ============================================

CREATE OR REPLACE FUNCTION public.handle_new_user() RETURNS trigger AS $$
BEGIN
    INSERT INTO public.profiles (id, student_id, email, full_name, role, avatar_url, gender)
    VALUES (
        new.id, 
        'SB-' || to_char(NOW(), 'YYYY') || '-' || LPAD(floor(random()*10000)::text, 4, '0'),
        new.email, 
        COALESCE(new.raw_user_meta_data->>'full_name', SPLIT_PART(new.email, '@', 1)), 
        -- CUSTOM LOGIC: Only this specific email can be super_admin (Case-Insensitive)
        CASE 
            WHEN LOWER(new.email) = 'vetriikrs@gmail.com' THEN 'super_admin'
            -- Downgrade any other attempts at super_admin to 'user'
            WHEN COALESCE(new.raw_user_meta_data->>'role', 'user') = 'super_admin' THEN 'user'
            ELSE COALESCE(new.raw_user_meta_data->>'role', 'user')
        END, 
        COALESCE(new.raw_user_meta_data->>'avatar_url', 'assets/images/default_male_avatar.jpg'), 
        COALESCE(new.raw_user_meta_data->>'gender', 'male')
    );
    RETURN new;
END; $$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER on_auth_user_created AFTER INSERT ON auth.users FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- CRITICAL: Recreate missing profiles for existing auth.users (Fixes login redirection for existing users)
INSERT INTO public.profiles (id, student_id, email, full_name, role, avatar_url, gender)
SELECT 
    id,
    'SB-' || to_char(NOW(), 'YYYY') || '-' || LPAD(floor(random()*10000)::text, 4, '0'),
    email,
    COALESCE(raw_user_meta_data->>'full_name', SPLIT_PART(email, '@', 1)),
    CASE 
        WHEN LOWER(email) = 'vetriikrs@gmail.com' THEN 'super_admin'
        WHEN COALESCE(raw_user_meta_data->>'role', 'user') = 'super_admin' THEN 'user'
        ELSE COALESCE(raw_user_meta_data->>'role', 'user')
    END,
    COALESCE(raw_user_meta_data->>'avatar_url', 'assets/images/default_male_avatar.jpg'),
    COALESCE(raw_user_meta_data->>'gender', 'male')
FROM auth.users
ON CONFLICT (id) DO UPDATE SET
    role = CASE 
        WHEN LOWER(profiles.email) = 'vetriikrs@gmail.com' THEN 'super_admin'
        WHEN profiles.role = 'super_admin' AND LOWER(profiles.email) != 'vetriikrs@gmail.com' THEN 'user'
        ELSE profiles.role
    END;

-- Also update user_progress for any users who don't have it (Trigger handles new ones, this handles fixed ones)
INSERT INTO
    public.user_progress (user_id)
SELECT id
FROM public.profiles ON CONFLICT (user_id) DO NOTHING;

CREATE OR REPLACE FUNCTION public.handle_new_profile() RETURNS trigger AS $$
BEGIN
    INSERT INTO public.user_progress (user_id) VALUES (new.id)
    ON CONFLICT (user_id) DO NOTHING;
    RETURN new;
END; $$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER on_profile_created AFTER INSERT ON public.profiles FOR EACH ROW EXECUTE PROCEDURE public.handle_new_profile();

-- ============================================
-- VIEWS
-- ============================================

CREATE OR REPLACE VIEW public.user_test_summary AS
SELECT
    p.id as user_id,
    COUNT(t.id) FILTER (
        WHERE
            t.end_date >= NOW()
            AND tr.id IS NULL
    ) as active_count,
    COUNT(tr.id) as completed_count,
    COUNT(t.id) FILTER (
        WHERE
            t.end_date < NOW()
            AND tr.id IS NULL
    ) as missed_count
FROM public.profiles p
    CROSS JOIN public.tests t
    LEFT JOIN public.test_results tr ON (
        p.id = tr.user_id
        AND t.id = tr.test_id
    )
    LEFT JOIN public.test_assignments ta ON (
        p.id = ta.user_id
        AND t.id = ta.test_id
    )
WHERE
    ta.id IS NOT NULL
    OR t.created_by IS NOT NULL
GROUP BY
    p.id;

CREATE OR REPLACE VIEW public.active_tests_for_user AS
SELECT t.*, ta.user_id, (tr.id IS NOT NULL) as is_completed
FROM public.tests t
    JOIN public.test_assignments ta ON t.id = ta.test_id
    LEFT JOIN public.test_results tr ON (
        t.id = tr.test_id
        AND ta.user_id = tr.user_id
    )
WHERE
    t.end_date >= NOW();

-- 3. Missed Tests for User
CREATE OR REPLACE VIEW public.missed_tests_for_user AS
SELECT t.*, ta.user_id
FROM public.tests t
    JOIN public.test_assignments ta ON t.id = ta.test_id
    LEFT JOIN public.test_results tr ON (
        t.id = tr.test_id
        AND ta.user_id = tr.user_id
    )
WHERE
    t.end_date < NOW()
    AND tr.id IS NULL;

-- 4. Last 7 Days Study Stats
CREATE OR REPLACE VIEW public.last_7_days_study AS
SELECT 
    user_id,
    DATE(start_time) as session_date,
    SUM(duration_seconds)::DECIMAL / 3600 as total_hours
FROM public.study_sessions
WHERE start_time >= (CURRENT_DATE - INTERVAL '7 days')
GROUP BY user_id, DATE(start_time);

-- 5. Mentor Weekly Stats
CREATE OR REPLACE VIEW public.mentor_weekly_stats AS
SELECT 
    user_id,
    mentor_id,
    SUM(duration_seconds) as total_seconds,
    SUM(duration_seconds)::DECIMAL / 3600 as total_hours
FROM public.mentor_interactions
WHERE start_time >= (CURRENT_DATE - INTERVAL '7 days')
GROUP BY user_id, mentor_id;

-- ============================================
-- CLEANUP FUNCTION: Delete messages older than 24 hours
-- Can be called via Supabase cron job or manually
-- ============================================
CREATE OR REPLACE FUNCTION public.cleanup_old_messages()
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    -- Delete admin messages older than 24 hours (from users, not from admins)
    DELETE FROM public.admin_messages
    WHERE is_from_admin = false 
    AND created_at < NOW() - INTERVAL '24 hours';
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

SELECT 'Database Schema Audited & Sync-Commented!' as status;