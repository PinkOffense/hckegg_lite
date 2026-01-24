-- ============================================
-- HCKEgg Lite - Supabase Database Schema
-- ============================================
-- Execute este SQL no Supabase SQL Editor
-- ============================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- TABELA: daily_egg_records
-- ============================================
CREATE TABLE IF NOT EXISTS public.daily_egg_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    eggs_collected INTEGER NOT NULL DEFAULT 0,
    eggs_sold INTEGER NOT NULL DEFAULT 0,
    eggs_consumed INTEGER NOT NULL DEFAULT 0,
    price_per_egg DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    notes TEXT,
    hen_count INTEGER,
    feed_expense DECIMAL(10, 2) DEFAULT 0.00,
    vet_expense DECIMAL(10, 2) DEFAULT 0.00,
    other_expense DECIMAL(10, 2) DEFAULT 0.00,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- Unique constraint: one record per user per date
    CONSTRAINT unique_user_date UNIQUE(user_id, date)
);

-- Index for faster queries
CREATE INDEX idx_daily_egg_records_user_date ON public.daily_egg_records(user_id, date DESC);
CREATE INDEX idx_daily_egg_records_user_created ON public.daily_egg_records(user_id, created_at DESC);

-- ============================================
-- TABELA: expenses
-- ============================================
CREATE TABLE IF NOT EXISTS public.expenses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    category VARCHAR(50) NOT NULL CHECK (category IN ('feed', 'veterinary', 'maintenance', 'equipment', 'utilities', 'other')),
    amount DECIMAL(10, 2) NOT NULL CHECK (amount > 0),
    description TEXT NOT NULL,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index for faster queries
CREATE INDEX idx_expenses_user_date ON public.expenses(user_id, date DESC);
CREATE INDEX idx_expenses_user_category ON public.expenses(user_id, category);

-- ============================================
-- TABELA: vet_records
-- ============================================
CREATE TABLE IF NOT EXISTS public.vet_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    type VARCHAR(50) NOT NULL CHECK (type IN ('vaccine', 'disease', 'treatment', 'death', 'checkup')),
    hens_affected INTEGER NOT NULL DEFAULT 1 CHECK (hens_affected > 0),
    description TEXT NOT NULL,
    medication TEXT,
    cost DECIMAL(10, 2) CHECK (cost >= 0),
    next_action_date DATE,
    notes TEXT,
    severity VARCHAR(50) NOT NULL DEFAULT 'low' CHECK (severity IN ('low', 'medium', 'high', 'critical')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index for faster queries
CREATE INDEX idx_vet_records_user_date ON public.vet_records(user_id, date DESC);
CREATE INDEX idx_vet_records_user_type ON public.vet_records(user_id, type);
CREATE INDEX idx_vet_records_user_severity ON public.vet_records(user_id, severity);
CREATE INDEX idx_vet_records_next_action ON public.vet_records(user_id, next_action_date) WHERE next_action_date IS NOT NULL;

-- ============================================
-- TRIGGERS: updated_at auto-update
-- ============================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for each table
CREATE TRIGGER update_daily_egg_records_updated_at
    BEFORE UPDATE ON public.daily_egg_records
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_expenses_updated_at
    BEFORE UPDATE ON public.expenses
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_vet_records_updated_at
    BEFORE UPDATE ON public.vet_records
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================

-- Enable RLS on all tables
ALTER TABLE public.daily_egg_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vet_records ENABLE ROW LEVEL SECURITY;

-- Policies for daily_egg_records
CREATE POLICY "Users can view their own daily egg records"
    ON public.daily_egg_records FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own daily egg records"
    ON public.daily_egg_records FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own daily egg records"
    ON public.daily_egg_records FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own daily egg records"
    ON public.daily_egg_records FOR DELETE
    USING (auth.uid() = user_id);

-- Policies for expenses
CREATE POLICY "Users can view their own expenses"
    ON public.expenses FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own expenses"
    ON public.expenses FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own expenses"
    ON public.expenses FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own expenses"
    ON public.expenses FOR DELETE
    USING (auth.uid() = user_id);

-- Policies for vet_records
CREATE POLICY "Users can view their own vet records"
    ON public.vet_records FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own vet records"
    ON public.vet_records FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own vet records"
    ON public.vet_records FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own vet records"
    ON public.vet_records FOR DELETE
    USING (auth.uid() = user_id);

-- ============================================
-- VIEWS (optional - for analytics)
-- ============================================

-- View: Daily egg records with calculated fields
CREATE OR REPLACE VIEW public.daily_egg_records_with_stats AS
SELECT
    id,
    user_id,
    date,
    eggs_collected,
    eggs_sold,
    eggs_consumed,
    price_per_egg,
    (eggs_sold * price_per_egg) AS revenue,
    (COALESCE(feed_expense, 0) + COALESCE(vet_expense, 0) + COALESCE(other_expense, 0)) AS total_expenses,
    ((eggs_sold * price_per_egg) - (COALESCE(feed_expense, 0) + COALESCE(vet_expense, 0) + COALESCE(other_expense, 0))) AS net_profit,
    notes,
    hen_count,
    feed_expense,
    vet_expense,
    other_expense,
    created_at,
    updated_at
FROM public.daily_egg_records;

-- ============================================
-- FUNCTIONS (optional - for complex queries)
-- ============================================

-- Function: Get user statistics for date range
CREATE OR REPLACE FUNCTION get_user_stats(
    p_user_id UUID,
    p_start_date DATE,
    p_end_date DATE
)
RETURNS TABLE (
    total_eggs_collected BIGINT,
    total_eggs_sold BIGINT,
    total_eggs_consumed BIGINT,
    total_revenue DECIMAL,
    total_expenses DECIMAL,
    net_profit DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        SUM(eggs_collected)::BIGINT,
        SUM(eggs_sold)::BIGINT,
        SUM(eggs_consumed)::BIGINT,
        SUM(eggs_sold * price_per_egg)::DECIMAL,
        SUM(COALESCE(feed_expense, 0) + COALESCE(vet_expense, 0) + COALESCE(other_expense, 0))::DECIMAL,
        (SUM(eggs_sold * price_per_egg) - SUM(COALESCE(feed_expense, 0) + COALESCE(vet_expense, 0) + COALESCE(other_expense, 0)))::DECIMAL
    FROM public.daily_egg_records
    WHERE user_id = p_user_id
      AND date BETWEEN p_start_date AND p_end_date;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- SEED DATA (optional - for testing)
-- ============================================
-- Uncomment to insert sample data for testing
-- Replace 'YOUR_USER_ID' with actual user ID from auth.users

/*
INSERT INTO public.daily_egg_records (user_id, date, eggs_collected, eggs_sold, eggs_consumed, price_per_egg, hen_count, feed_expense)
VALUES
    ('YOUR_USER_ID', CURRENT_DATE - INTERVAL '1 day', 12, 10, 2, 0.50, 15, 5.00),
    ('YOUR_USER_ID', CURRENT_DATE - INTERVAL '2 days', 14, 12, 2, 0.50, 15, 5.00),
    ('YOUR_USER_ID', CURRENT_DATE - INTERVAL '3 days', 13, 11, 2, 0.50, 15, 5.00);
*/

-- ============================================
-- GRANT PERMISSIONS (if needed)
-- ============================================
-- These are typically handled by Supabase automatically
-- but included for completeness

GRANT USAGE ON SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO postgres, service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon;

-- ============================================
-- COMPLETION MESSAGE
-- ============================================
-- Schema criado com sucesso!
-- Próximos passos:
-- 1. Verificar as tabelas no Supabase Table Editor
-- 2. Testar as policies RLS
-- 3. Implementar os repositories no Flutter
