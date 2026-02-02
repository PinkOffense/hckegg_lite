-- ============================================
-- HCKEgg Lite - Analytics Aggregate Functions
-- ============================================
-- Execute this SQL in Supabase SQL Editor
-- These functions perform server-side aggregation for better performance
-- ============================================
-- Version: 1.0
-- Created: 2026-02-02
-- ============================================

-- ============================================
-- FUNCTION: get_production_totals
-- Returns aggregated production metrics
-- ============================================
CREATE OR REPLACE FUNCTION public.get_production_totals(p_user_id UUID)
RETURNS TABLE (
    total_collected BIGINT,
    total_consumed BIGINT,
    today_collected INTEGER,
    today_consumed INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_today DATE := CURRENT_DATE;
BEGIN
    RETURN QUERY
    SELECT
        COALESCE(SUM(eggs_collected), 0)::BIGINT AS total_collected,
        COALESCE(SUM(eggs_consumed), 0)::BIGINT AS total_consumed,
        COALESCE(MAX(CASE WHEN date = v_today THEN eggs_collected END), 0)::INTEGER AS today_collected,
        COALESCE(MAX(CASE WHEN date = v_today THEN eggs_consumed END), 0)::INTEGER AS today_consumed
    FROM daily_egg_records
    WHERE user_id = p_user_id;
END;
$$;

-- ============================================
-- FUNCTION: get_production_week_data
-- Returns recent production data for predictions
-- ============================================
CREATE OR REPLACE FUNCTION public.get_production_week_data(p_user_id UUID, p_days INTEGER DEFAULT 7)
RETURNS TABLE (
    record_date DATE,
    eggs_collected INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    SELECT date, der.eggs_collected
    FROM daily_egg_records der
    WHERE der.user_id = p_user_id
      AND der.date >= CURRENT_DATE - p_days
    ORDER BY der.date DESC;
END;
$$;

-- ============================================
-- FUNCTION: get_sales_totals
-- Returns aggregated sales metrics
-- ============================================
CREATE OR REPLACE FUNCTION public.get_sales_totals(p_user_id UUID)
RETURNS TABLE (
    total_quantity BIGINT,
    total_revenue NUMERIC,
    paid_amount NUMERIC,
    pending_amount NUMERIC,
    advance_amount NUMERIC,
    lost_amount NUMERIC,
    week_revenue NUMERIC,
    month_revenue NUMERIC
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_week_ago DATE := CURRENT_DATE - 7;
    v_month_ago DATE := CURRENT_DATE - 30;
BEGIN
    RETURN QUERY
    SELECT
        COALESCE(SUM(quantity_sold), 0)::BIGINT AS total_quantity,
        COALESCE(SUM(total_amount), 0)::NUMERIC AS total_revenue,
        COALESCE(SUM(CASE WHEN NOT is_lost AND payment_status = 'paid' THEN total_amount ELSE 0 END), 0)::NUMERIC AS paid_amount,
        COALESCE(SUM(CASE WHEN NOT is_lost AND payment_status = 'pending' THEN total_amount ELSE 0 END), 0)::NUMERIC AS pending_amount,
        COALESCE(SUM(CASE WHEN NOT is_lost AND payment_status = 'advance' THEN total_amount ELSE 0 END), 0)::NUMERIC AS advance_amount,
        COALESCE(SUM(CASE WHEN is_lost THEN total_amount ELSE 0 END), 0)::NUMERIC AS lost_amount,
        COALESCE(SUM(CASE WHEN date >= v_week_ago THEN total_amount ELSE 0 END), 0)::NUMERIC AS week_revenue,
        COALESCE(SUM(CASE WHEN date >= v_month_ago THEN total_amount ELSE 0 END), 0)::NUMERIC AS month_revenue
    FROM egg_sales
    WHERE user_id = p_user_id;
END;
$$;

-- ============================================
-- FUNCTION: get_total_eggs_sold
-- Returns total eggs sold (for remaining calculation)
-- ============================================
CREATE OR REPLACE FUNCTION public.get_total_eggs_sold(p_user_id UUID)
RETURNS BIGINT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_total BIGINT;
BEGIN
    SELECT COALESCE(SUM(quantity_sold), 0) INTO v_total
    FROM egg_sales
    WHERE user_id = p_user_id;
    RETURN v_total;
END;
$$;

-- ============================================
-- FUNCTION: get_expenses_totals
-- Returns aggregated expense metrics
-- ============================================
CREATE OR REPLACE FUNCTION public.get_expenses_totals(p_user_id UUID)
RETURNS TABLE (
    total_expenses NUMERIC,
    week_expenses NUMERIC,
    month_expenses NUMERIC,
    feed_expenses NUMERIC,
    maintenance_expenses NUMERIC,
    equipment_expenses NUMERIC,
    utilities_expenses NUMERIC,
    other_expenses NUMERIC
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_week_ago DATE := CURRENT_DATE - 7;
    v_month_ago DATE := CURRENT_DATE - 30;
BEGIN
    RETURN QUERY
    SELECT
        COALESCE(SUM(amount), 0)::NUMERIC AS total_expenses,
        COALESCE(SUM(CASE WHEN date >= v_week_ago THEN amount ELSE 0 END), 0)::NUMERIC AS week_expenses,
        COALESCE(SUM(CASE WHEN date >= v_month_ago THEN amount ELSE 0 END), 0)::NUMERIC AS month_expenses,
        COALESCE(SUM(CASE WHEN category = 'feed' THEN amount ELSE 0 END), 0)::NUMERIC AS feed_expenses,
        COALESCE(SUM(CASE WHEN category = 'maintenance' THEN amount ELSE 0 END), 0)::NUMERIC AS maintenance_expenses,
        COALESCE(SUM(CASE WHEN category = 'equipment' THEN amount ELSE 0 END), 0)::NUMERIC AS equipment_expenses,
        COALESCE(SUM(CASE WHEN category = 'utilities' THEN amount ELSE 0 END), 0)::NUMERIC AS utilities_expenses,
        COALESCE(SUM(CASE WHEN category = 'other' THEN amount ELSE 0 END), 0)::NUMERIC AS other_expenses
    FROM expenses
    WHERE user_id = p_user_id;
END;
$$;

-- ============================================
-- FUNCTION: get_vet_costs_totals
-- Returns aggregated vet costs
-- ============================================
CREATE OR REPLACE FUNCTION public.get_vet_costs_totals(p_user_id UUID)
RETURNS TABLE (
    total_vet_costs NUMERIC,
    week_vet_costs NUMERIC,
    month_vet_costs NUMERIC
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_week_ago DATE := CURRENT_DATE - 7;
    v_month_ago DATE := CURRENT_DATE - 30;
BEGIN
    RETURN QUERY
    SELECT
        COALESCE(SUM(cost), 0)::NUMERIC AS total_vet_costs,
        COALESCE(SUM(CASE WHEN date >= v_week_ago THEN cost ELSE 0 END), 0)::NUMERIC AS week_vet_costs,
        COALESCE(SUM(CASE WHEN date >= v_month_ago THEN cost ELSE 0 END), 0)::NUMERIC AS month_vet_costs
    FROM vet_records
    WHERE user_id = p_user_id;
END;
$$;

-- ============================================
-- FUNCTION: get_feed_totals
-- Returns aggregated feed metrics
-- ============================================
CREATE OR REPLACE FUNCTION public.get_feed_totals(p_user_id UUID)
RETURNS TABLE (
    total_stock_kg NUMERIC,
    low_stock_count BIGINT,
    layer_stock NUMERIC,
    grower_stock NUMERIC,
    starter_stock NUMERIC,
    scratch_stock NUMERIC,
    supplement_stock NUMERIC,
    other_stock NUMERIC
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    SELECT
        COALESCE(SUM(current_quantity_kg), 0)::NUMERIC AS total_stock_kg,
        COUNT(CASE WHEN current_quantity_kg <= minimum_quantity_kg THEN 1 END)::BIGINT AS low_stock_count,
        COALESCE(SUM(CASE WHEN type = 'layer' THEN current_quantity_kg ELSE 0 END), 0)::NUMERIC AS layer_stock,
        COALESCE(SUM(CASE WHEN type = 'grower' THEN current_quantity_kg ELSE 0 END), 0)::NUMERIC AS grower_stock,
        COALESCE(SUM(CASE WHEN type = 'starter' THEN current_quantity_kg ELSE 0 END), 0)::NUMERIC AS starter_stock,
        COALESCE(SUM(CASE WHEN type = 'scratch' THEN current_quantity_kg ELSE 0 END), 0)::NUMERIC AS scratch_stock,
        COALESCE(SUM(CASE WHEN type = 'supplement' THEN current_quantity_kg ELSE 0 END), 0)::NUMERIC AS supplement_stock,
        COALESCE(SUM(CASE WHEN type = 'other' THEN current_quantity_kg ELSE 0 END), 0)::NUMERIC AS other_stock
    FROM feed_stocks
    WHERE user_id = p_user_id;
END;
$$;

-- ============================================
-- FUNCTION: get_feed_consumed_total
-- Returns total feed consumed from movements
-- ============================================
CREATE OR REPLACE FUNCTION public.get_feed_consumed_total(p_user_id UUID)
RETURNS NUMERIC
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_total NUMERIC;
BEGIN
    SELECT COALESCE(SUM(quantity_kg), 0) INTO v_total
    FROM feed_movements
    WHERE user_id = p_user_id
      AND movement_type IN ('consumption', 'loss');
    RETURN v_total;
END;
$$;

-- ============================================
-- FUNCTION: get_health_totals
-- Returns aggregated health metrics
-- ============================================
CREATE OR REPLACE FUNCTION public.get_health_totals(p_user_id UUID)
RETURNS TABLE (
    total_deaths INTEGER,
    total_affected BIGINT,
    total_vet_costs NUMERIC,
    upcoming_actions BIGINT,
    recent_records BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_today DATE := CURRENT_DATE;
    v_month_ago DATE := CURRENT_DATE - 30;
BEGIN
    RETURN QUERY
    SELECT
        COALESCE(SUM(CASE WHEN type = 'death' THEN hens_affected ELSE 0 END), 0)::INTEGER AS total_deaths,
        COALESCE(SUM(hens_affected), 0)::BIGINT AS total_affected,
        COALESCE(SUM(cost), 0)::NUMERIC AS total_vet_costs,
        COUNT(CASE WHEN next_action_date >= v_today THEN 1 END)::BIGINT AS upcoming_actions,
        COUNT(CASE WHEN date >= v_month_ago THEN 1 END)::BIGINT AS recent_records
    FROM vet_records
    WHERE user_id = p_user_id;
END;
$$;

-- ============================================
-- FUNCTION: get_week_stats
-- Returns all week statistics in a single call
-- ============================================
CREATE OR REPLACE FUNCTION public.get_week_stats(p_user_id UUID)
RETURNS TABLE (
    eggs_collected BIGINT,
    eggs_consumed BIGINT,
    eggs_sold BIGINT,
    revenue NUMERIC,
    expenses NUMERIC,
    vet_costs NUMERIC,
    start_date DATE,
    end_date DATE
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_start_date DATE := CURRENT_DATE - 7;
    v_end_date DATE := CURRENT_DATE;
    v_eggs_collected BIGINT;
    v_eggs_consumed BIGINT;
    v_eggs_sold BIGINT;
    v_revenue NUMERIC;
    v_expenses NUMERIC;
    v_vet_costs NUMERIC;
BEGIN
    -- Eggs collected/consumed
    SELECT
        COALESCE(SUM(der.eggs_collected), 0),
        COALESCE(SUM(der.eggs_consumed), 0)
    INTO v_eggs_collected, v_eggs_consumed
    FROM daily_egg_records der
    WHERE der.user_id = p_user_id
      AND der.date BETWEEN v_start_date AND v_end_date;

    -- Eggs sold and revenue
    SELECT
        COALESCE(SUM(quantity_sold), 0),
        COALESCE(SUM(total_amount), 0)
    INTO v_eggs_sold, v_revenue
    FROM egg_sales
    WHERE user_id = p_user_id
      AND date BETWEEN v_start_date AND v_end_date;

    -- Expenses
    SELECT COALESCE(SUM(amount), 0)
    INTO v_expenses
    FROM expenses
    WHERE user_id = p_user_id
      AND date BETWEEN v_start_date AND v_end_date;

    -- Vet costs
    SELECT COALESCE(SUM(cost), 0)
    INTO v_vet_costs
    FROM vet_records
    WHERE user_id = p_user_id
      AND date BETWEEN v_start_date AND v_end_date;

    RETURN QUERY SELECT
        v_eggs_collected,
        v_eggs_consumed,
        v_eggs_sold,
        v_revenue,
        v_expenses + v_vet_costs,
        v_vet_costs,
        v_start_date,
        v_end_date;
END;
$$;

-- ============================================
-- GRANT PERMISSIONS
-- ============================================
GRANT EXECUTE ON FUNCTION public.get_production_totals(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_production_week_data(UUID, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_sales_totals(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_total_eggs_sold(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_expenses_totals(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_vet_costs_totals(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_feed_totals(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_feed_consumed_total(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_health_totals(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_week_stats(UUID) TO authenticated;

-- ============================================
-- COMPLETION MESSAGE
-- ============================================
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '================================================';
    RAISE NOTICE '  Analytics Functions Created Successfully!';
    RAISE NOTICE '================================================';
    RAISE NOTICE '';
    RAISE NOTICE 'Functions created:';
    RAISE NOTICE '  * get_production_totals     - Production aggregates';
    RAISE NOTICE '  * get_production_week_data  - Recent production data';
    RAISE NOTICE '  * get_sales_totals          - Sales aggregates';
    RAISE NOTICE '  * get_total_eggs_sold       - Total eggs sold';
    RAISE NOTICE '  * get_expenses_totals       - Expense aggregates';
    RAISE NOTICE '  * get_vet_costs_totals      - Vet cost aggregates';
    RAISE NOTICE '  * get_feed_totals           - Feed stock aggregates';
    RAISE NOTICE '  * get_feed_consumed_total   - Feed consumption total';
    RAISE NOTICE '  * get_health_totals         - Health metrics';
    RAISE NOTICE '  * get_week_stats            - Week statistics';
    RAISE NOTICE '================================================';
END $$;
