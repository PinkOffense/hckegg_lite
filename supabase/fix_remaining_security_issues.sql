-- ============================================
-- HCKEgg Lite - Fix Remaining Security Issues
-- ============================================
-- Este script corrige apenas as 2 funções que ainda têm
-- mutable search_path:
--   1. public.get_user_stats
--   2. public.update_updated_at_column
-- ============================================

-- FIX 1: Function get_user_stats
CREATE OR REPLACE FUNCTION public.get_user_stats(p_user_id UUID DEFAULT NULL)
RETURNS TABLE (
    total_eggs BIGINT,
    total_sold BIGINT,
    total_revenue NUMERIC,
    total_expenses NUMERIC,
    net_profit NUMERIC,
    total_hens INTEGER,
    avg_eggs_per_day NUMERIC
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    v_user_id UUID;
BEGIN
    -- Use provided user_id or current user
    v_user_id := COALESCE(p_user_id, auth.uid());

    RETURN QUERY
    SELECT
        COALESCE(SUM(der.eggs_collected), 0)::BIGINT AS total_eggs,
        COALESCE(SUM(der.eggs_sold), 0)::BIGINT AS total_sold,
        COALESCE(SUM(der.eggs_sold * der.price_per_egg), 0)::NUMERIC AS total_revenue,
        COALESCE((SELECT SUM(e.amount) FROM public.expenses e WHERE e.user_id = v_user_id), 0)::NUMERIC AS total_expenses,
        (COALESCE(SUM(der.eggs_sold * der.price_per_egg), 0) -
         COALESCE((SELECT SUM(e.amount) FROM public.expenses e WHERE e.user_id = v_user_id), 0))::NUMERIC AS net_profit,
        COALESCE(MAX(der.hen_count), 0)::INTEGER AS total_hens,
        CASE
            WHEN COUNT(DISTINCT der.date) > 0
            THEN (SUM(der.eggs_collected)::NUMERIC / COUNT(DISTINCT der.date))
            ELSE 0
        END AS avg_eggs_per_day
    FROM public.daily_egg_records der
    WHERE der.user_id = v_user_id;
END;
$$;

-- FIX 2: Function update_updated_at_column
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

-- Verification
DO $$
BEGIN
    RAISE NOTICE '============================================';
    RAISE NOTICE 'Security Issues Fixed!';
    RAISE NOTICE '  - get_user_stats() - SET search_path = ''''';
    RAISE NOTICE '  - update_updated_at_column() - SET search_path = ''''';
    RAISE NOTICE '============================================';
END $$;
