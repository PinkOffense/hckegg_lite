-- ============================================================================
-- FEED STOCK TABLES FOR HCKEGG LITE
-- Run this SQL in your Supabase SQL Editor
-- ============================================================================

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- 1. FEED_STOCKS TABLE
-- Stores the different types of feed in stock
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.feed_stocks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    type TEXT NOT NULL,
    brand TEXT,
    current_quantity_kg DECIMAL(10,2) NOT NULL DEFAULT 0,
    minimum_quantity_kg DECIMAL(10,2) NOT NULL DEFAULT 10,
    price_per_kg DECIMAL(10,2),
    notes TEXT,
    last_updated TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Index for faster queries by user
CREATE INDEX IF NOT EXISTS idx_feed_stocks_user_id ON public.feed_stocks(user_id);

-- ============================================================================
-- 2. FEED_MOVEMENTS TABLE
-- Stores all stock movements (purchases, consumption, adjustments, losses)
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.feed_movements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    feed_stock_id UUID NOT NULL REFERENCES public.feed_stocks(id) ON DELETE CASCADE,
    movement_type TEXT NOT NULL,
    quantity_kg DECIMAL(10,2) NOT NULL,
    cost DECIMAL(10,2),
    date TEXT NOT NULL,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Indexes for faster queries
CREATE INDEX IF NOT EXISTS idx_feed_movements_user_id ON public.feed_movements(user_id);
CREATE INDEX IF NOT EXISTS idx_feed_movements_feed_stock_id ON public.feed_movements(feed_stock_id);
CREATE INDEX IF NOT EXISTS idx_feed_movements_date ON public.feed_movements(date);

-- ============================================================================
-- 3. ROW LEVEL SECURITY (RLS) POLICIES
-- Users can only access their own data
-- ============================================================================

-- Enable RLS on feed_stocks
ALTER TABLE public.feed_stocks ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view their own feed stocks
CREATE POLICY "Users can view own feed_stocks"
    ON public.feed_stocks
    FOR SELECT
    USING (auth.uid() = user_id);

-- Policy: Users can insert their own feed stocks
CREATE POLICY "Users can insert own feed_stocks"
    ON public.feed_stocks
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Policy: Users can update their own feed stocks
CREATE POLICY "Users can update own feed_stocks"
    ON public.feed_stocks
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Policy: Users can delete their own feed stocks
CREATE POLICY "Users can delete own feed_stocks"
    ON public.feed_stocks
    FOR DELETE
    USING (auth.uid() = user_id);

-- Enable RLS on feed_movements
ALTER TABLE public.feed_movements ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view their own feed movements
CREATE POLICY "Users can view own feed_movements"
    ON public.feed_movements
    FOR SELECT
    USING (auth.uid() = user_id);

-- Policy: Users can insert their own feed movements
CREATE POLICY "Users can insert own feed_movements"
    ON public.feed_movements
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Policy: Users can update their own feed movements
CREATE POLICY "Users can update own feed_movements"
    ON public.feed_movements
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Policy: Users can delete their own feed movements
CREATE POLICY "Users can delete own feed_movements"
    ON public.feed_movements
    FOR DELETE
    USING (auth.uid() = user_id);

-- ============================================================================
-- 4. TRIGGER TO AUTO-UPDATE last_updated
-- ============================================================================

CREATE OR REPLACE FUNCTION public.update_feed_stock_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.last_updated = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_feed_stock_timestamp ON public.feed_stocks;
CREATE TRIGGER trigger_update_feed_stock_timestamp
    BEFORE UPDATE ON public.feed_stocks
    FOR EACH ROW
    EXECUTE FUNCTION public.update_feed_stock_timestamp();

-- ============================================================================
-- DONE! Your feed stock tables are now ready.
-- ============================================================================
