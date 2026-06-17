-- ========================================================
-- STUDENT DASHBOARD OPTIMIZATION v2
-- Unified view for all test-related data
-- ========================================================

DROP VIEW IF EXISTS public.student_test_dashboard CASCADE;

CREATE OR REPLACE VIEW public.student_test_dashboard AS
SELECT
    t.id AS test_id,
    t.title,
    t.subject,
    t.description,
    t.start_date,
    t.end_date,
    t.duration_minutes,
    t.total_questions as test_total_questions,
    ta.user_id,
    ta.id AS assignment_id,
    ta.status AS assignment_status,
    ta.attended_at,
    tr.id AS result_id,
    tr.score,
    tr.percentage,
    tr.completed_at,
    tr.wrong_count,
    tr.total_questions as result_total_questions,
    tr.answers
FROM public.tests t
    JOIN public.test_assignments ta ON t.id = ta.test_id
    LEFT JOIN public.test_results tr ON (
        t.id = tr.test_id
        AND ta.user_id = tr.user_id
    );

-- Grant access
GRANT SELECT ON public.student_test_dashboard TO authenticated;

GRANT SELECT ON public.student_test_dashboard TO service_role;

COMMENT ON VIEW public.student_test_dashboard IS 'Unified view for student tests with proper RLS mapping.';