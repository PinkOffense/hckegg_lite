-- ============================================
-- HCKEgg Lite - Feed Stock Tables
-- ============================================
-- Execute este SQL no Supabase SQL Editor
-- Adiciona tabelas para gestão de stock de ração
-- ============================================

-- ============================================
-- TABLE: feed_stocks
-- Purpose: Track feed inventory levels
-- ============================================
CREATE TABLE IF NOT EXISTS public.feed_stocks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL CHECK (type IN ('layer', 'grower', 'starter', 'scratch', 'supplement', 'other')),
    brand TEXT,
    current_quantity_kg DECIMAL(10, 2) NOT NULL DEFAULT 0 CHECK (current_quantity_kg >= 0),
    minimum_quantity_kg DECIMAL(10, 2) NOT NULL DEFAULT 10 CHECK (minimum_quantity_kg >= 0),
    price_per_kg DECIMAL(10, 2) CHECK (price_per_kg >= 0),
    notes TEXT,
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for faster queries
CREATE INDEX idx_feed_stocks_user ON public.feed_stocks(user_id);
CREATE INDEX idx_feed_stocks_user_type ON public.feed_stocks(user_id, type);
CREATE INDEX idx_feed_stocks_low_stock ON public.feed_stocks(user_id)
    WHERE current_quantity_kg <= minimum_quantity_kg;

COMMENT ON TABLE public.feed_stocks IS 'Feed inventory stock levels';
COMMENT ON COLUMN public.feed_stocks.type IS 'Feed type: layer, grower, starter, scratch, supplement, other';
COMMENT ON COLUMN public.feed_stocks.current_quantity_kg IS 'Current stock quantity in kilograms';
COMMENT ON COLUMN public.feed_stocks.minimum_quantity_kg IS 'Minimum quantity threshold for low stock alert';

-- ============================================
-- TABLE: feed_movements
-- Purpose: Track stock movements (purchases, consumption, etc)
-- ============================================
CREATE TABLE IF NOT EXISTS public.feed_movements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    feed_stock_id UUID NOT NULL REFERENCES public.feed_stocks(id) ON DELETE CASCADE,
    movement_type VARCHAR(50) NOT NULL CHECK (movement_type IN ('purchase', 'consumption', 'adjustment', 'loss')),
    quantity_kg DECIMAL(10, 2) NOT NULL CHECK (quantity_kg > 0),
    cost DECIMAL(10, 2) CHECK (cost >= 0),
    date DATE NOT NULL,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for faster queries
CREATE INDEX idx_feed_movements_user ON public.feed_movements(user_id);
CREATE INDEX idx_feed_movements_stock ON public.feed_movements(feed_stock_id);
CREATE INDEX idx_feed_movements_date ON public.feed_movements(user_id, date DESC);
CREATE INDEX idx_feed_movements_type ON public.feed_movements(user_id, movement_type);

COMMENT ON TABLE public.feed_movements IS 'Feed stock movement history (purchases, consumption, adjustments, losses)';
COMMENT ON COLUMN public.feed_movements.movement_type IS 'Movement type: purchase, consumption, adjustment, loss';
COMMENT ON COLUMN public.feed_movements.quantity_kg IS 'Quantity moved in kilograms';

-- ============================================
-- TRIGGERS FOR UPDATED_AT
-- ============================================

-- Trigger for feed_stocks (reuses existing function)
CREATE TRIGGER update_feed_stocks_updated_at
    BEFORE UPDATE ON public.feed_stocks
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================

-- Enable RLS on tables
ALTER TABLE public.feed_stocks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.feed_movements ENABLE ROW LEVEL SECURITY;

-- ============================================
-- RLS Policies for feed_stocks
-- ============================================
CREATE POLICY "Users can view their own feed stocks"
    ON public.feed_stocks FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own feed stocks"
    ON public.feed_stocks FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own feed stocks"
    ON public.feed_stocks FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own feed stocks"
    ON public.feed_stocks FOR DELETE
    USING (auth.uid() = user_id);

-- ============================================
-- RLS Policies for feed_movements
-- ============================================
CREATE POLICY "Users can view their own feed movements"
    ON public.feed_movements FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own feed movements"
    ON public.feed_movements FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own feed movements"
    ON public.feed_movements FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own feed movements"
    ON public.feed_movements FOR DELETE
    USING (auth.uid() = user_id);

-- ============================================
-- GRANT PERMISSIONS
-- ============================================

GRANT SELECT, INSERT, UPDATE, DELETE ON public.feed_stocks TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.feed_movements TO authenticated;
GRANT SELECT ON public.feed_stocks TO anon;
GRANT SELECT ON public.feed_movements TO anon;

-- ============================================
-- COMPLETION MESSAGE
-- ============================================

DO $$
BEGIN
    RAISE NOTICE '✅ Feed Stock tables created successfully!';
    RAISE NOTICE '';
    RAISE NOTICE 'Tables created:';
    RAISE NOTICE '  ✓ feed_stocks - Stock de ração';
    RAISE NOTICE '  ✓ feed_movements - Movimentos de stock';
    RAISE NOTICE '';
    RAISE NOTICE 'Feed types available:';
    RAISE NOTICE '  • layer - Ração Poedeiras';
    RAISE NOTICE '  • grower - Ração Crescimento';
    RAISE NOTICE '  • starter - Ração Inicial';
    RAISE NOTICE '  • scratch - Milho/Cereais';
    RAISE NOTICE '  • supplement - Suplementos';
    RAISE NOTICE '  • other - Outro';
END $$;
