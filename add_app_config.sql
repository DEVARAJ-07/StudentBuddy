-- Add app_config table for dynamic settings (like AI URL)
CREATE TABLE IF NOT EXISTS public.app_config (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Seed with current Ngrok URL
INSERT INTO
    public.app_config (key, value)
VALUES (
        'ai_mentor_url',
        'https://latashia-ruttiest-chara.ngrok-free.dev'
    ) ON CONFLICT (key) DO
UPDATE
SET
    value = EXCLUDED.value;

-- Enable RLS
ALTER TABLE public.app_config ENABLE ROW LEVEL SECURITY;

-- Everyone can read (to fetch the URL)
CREATE POLICY "Allow public read-only access to config" ON public.app_config FOR
SELECT USING (true);

-- Only admins can change settings
CREATE POLICY "Allow admins to update config" ON public.app_config FOR ALL USING (
    EXISTS (
        SELECT 1
        FROM public.profiles
        WHERE
            id = auth.uid ()
            AND (
                role = 'admin'
                OR role = 'super_admin'
            )
    )
);