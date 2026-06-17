-- =====================================================
-- LUCK CARD GAME SCHEMA
-- Daily scratch card game for user engagement
-- =====================================================

-- Table to store each play
CREATE TABLE IF NOT EXISTS public.luck_card_plays (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid (),
    user_id UUID REFERENCES public.profiles (id) ON DELETE CASCADE NOT NULL,
    result TEXT CHECK (
        result IN ('win', 'lose', 'joker')
    ) NOT NULL,
    points_earned INT NOT NULL DEFAULT 0,
    played_at TIMESTAMPTZ DEFAULT NOW(),
    play_date DATE DEFAULT CURRENT_DATE
);

-- Index for fast daily lookups
CREATE INDEX IF NOT EXISTS idx_luck_card_user_date ON public.luck_card_plays (user_id, play_date);

-- RLS Policies
ALTER TABLE public.luck_card_plays ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own plays" ON public.luck_card_plays;

CREATE POLICY "Users can view own plays" ON public.luck_card_plays FOR
SELECT USING (auth.uid () = user_id);

DROP POLICY IF EXISTS "Users can insert own plays" ON public.luck_card_plays;

CREATE POLICY "Users can insert own plays" ON public.luck_card_plays FOR
INSERT
WITH
    CHECK (auth.uid () = user_id);

-- Add luck_points column to user_progress if not exists
ALTER TABLE public.user_progress
ADD COLUMN IF NOT EXISTS luck_points INT DEFAULT 0;

-- Grant permissions
GRANT SELECT, INSERT ON public.luck_card_plays TO authenticated;

COMMENT ON
TABLE public.luck_card_plays IS 'Stores daily luck card game plays per user. Max 3 plays per day.';