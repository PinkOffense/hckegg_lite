-- ============================================================================
-- FEED STOCK TABLES - SUPABASE
-- Copy and paste this entire script into Supabase SQL Editor and run it
-- ============================================================================

-- Drop existing (if any)
DROP TABLE IF EXISTS public.feed_movements CASCADE;
DROP TABLE IF EXISTS public.feed_stocks CASCADE;

-- Create feed_stocks table
CREATE TABLE public.feed_stocks (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    type TEXT NOT NULL,
    brand TEXT,
    current_quantity_kg NUMERIC(10,2) NOT NULL DEFAULT 0,
    minimum_quantity_kg NUMERIC(10,2) NOT NULL DEFAULT 10,
    price_per_kg NUMERIC(10,2),
    notes TEXT,
    last_updated TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create feed_movements table
CREATE TABLE public.feed_movements (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    feed_stock_id UUID NOT NULL REFERENCES public.feed_stocks(id) ON DELETE CASCADE,
    movement_type TEXT NOT NULL,
    quantity_kg NUMERIC(10,2) NOT NULL,
    cost NUMERIC(10,2),
    date TEXT NOT NULL,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.feed_stocks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.feed_movements ENABLE ROW LEVEL SECURITY;

-- Policies for feed_stocks
CREATE POLICY "feed_stocks_all" ON public.feed_stocks
    FOR ALL USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Policies for feed_movements
CREATE POLICY "feed_movements_all" ON public.feed_movements
    FOR ALL USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Done!
