-- ============================================
-- HCKEgg Lite - Fresh Database Schema
-- ============================================
-- Execute este SQL no Supabase SQL Editor
-- Este script cria todas as tabelas do ZERO
-- (Use quando a database está vazia)
-- ============================================

-- ============================================
-- STEP 1: ENABLE EXTENSIONS
-- ============================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- STEP 2: CREATE TABLES
-- ============================================

-- ============================================
-- TABLE: daily_egg_records
-- Purpose: Track daily egg production (collection and consumption)
-- ============================================
CREATE TABLE public.daily_egg_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    eggs_collected INTEGER NOT NULL DEFAULT 0 CHECK (eggs_collected >= 0),
    eggs_consumed INTEGER NOT NULL DEFAULT 0 CHECK (eggs_consumed >= 0),
    notes TEXT,
    hen_count INTEGER CHECK (hen_count > 0),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- Unique constraint: one record per user per date
    CONSTRAINT unique_user_date UNIQUE(user_id, date)
);

-- Indexes for faster queries
CREATE INDEX idx_daily_egg_records_user_date ON public.daily_egg_records(user_id, date DESC);
CREATE INDEX idx_daily_egg_records_user_created ON public.daily_egg_records(user_id, created_at DESC);

COMMENT ON TABLE public.daily_egg_records IS 'Daily egg production records - tracks collection and consumption only';
COMMENT ON COLUMN public.daily_egg_records.eggs_collected IS 'Number of eggs collected this day';
COMMENT ON COLUMN public.daily_egg_records.eggs_consumed IS 'Number of eggs consumed/used this day';
COMMENT ON COLUMN public.daily_egg_records.hen_count IS 'Number of hens on this day';

-- ============================================
-- TABLE: egg_sales
-- Purpose: Track egg sales with pricing and customer information
-- ============================================
CREATE TABLE public.egg_sales (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    quantity_sold INTEGER NOT NULL CHECK (quantity_sold > 0),
    price_per_egg DECIMAL(10, 2) NOT NULL CHECK (price_per_egg > 0),
    price_per_dozen DECIMAL(10, 2) NOT NULL CHECK (price_per_dozen > 0),
    customer_name TEXT,
    customer_email TEXT,
    customer_phone TEXT,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for faster queries
CREATE INDEX idx_egg_sales_user_date ON public.egg_sales(user_id, date DESC);
CREATE INDEX idx_egg_sales_user_created ON public.egg_sales(user_id, created_at DESC);
CREATE INDEX idx_egg_sales_customer ON public.egg_sales(user_id, customer_name) WHERE customer_name IS NOT NULL;

COMMENT ON TABLE public.egg_sales IS 'Egg sales records with pricing and customer information';
COMMENT ON COLUMN public.egg_sales.quantity_sold IS 'Number of eggs sold in this transaction';
COMMENT ON COLUMN public.egg_sales.price_per_egg IS 'Price per individual egg';
COMMENT ON COLUMN public.egg_sales.price_per_dozen IS 'Price per dozen eggs';
COMMENT ON COLUMN public.egg_sales.customer_name IS 'Optional customer name for invoice generation';

-- ============================================
-- TABLE: expenses
-- Purpose: Track standalone expenses (feed, maintenance, equipment, etc.)
-- ============================================
CREATE TABLE public.expenses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    category VARCHAR(50) NOT NULL CHECK (category IN ('feed', 'maintenance', 'equipment', 'utilities', 'other')),
    amount DECIMAL(10, 2) NOT NULL CHECK (amount > 0),
    description TEXT NOT NULL,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for faster queries
CREATE INDEX idx_expenses_user_date ON public.expenses(user_id, date DESC);
CREATE INDEX idx_expenses_user_category ON public.expenses(user_id, category);
CREATE INDEX idx_expenses_user_created ON public.expenses(user_id, created_at DESC);

COMMENT ON TABLE public.expenses IS 'Standalone expenses for farm operations (excludes veterinary - see vet_records)';
COMMENT ON COLUMN public.expenses.category IS 'Expense category: feed, maintenance, equipment, utilities, other';

-- ============================================
-- TABLE: vet_records
-- Purpose: Track veterinary and health records for hens
-- ============================================
CREATE TABLE public.vet_records (
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

-- Indexes for faster queries
CREATE INDEX idx_vet_records_user_date ON public.vet_records(user_id, date DESC);
CREATE INDEX idx_vet_records_user_type ON public.vet_records(user_id, type);
CREATE INDEX idx_vet_records_user_severity ON public.vet_records(user_id, severity);
CREATE INDEX idx_vet_records_next_action ON public.vet_records(user_id, next_action_date) WHERE next_action_date IS NOT NULL;
CREATE INDEX idx_vet_records_user_created ON public.vet_records(user_id, created_at DESC);

COMMENT ON TABLE public.vet_records IS 'Veterinary and health records for hens';
COMMENT ON COLUMN public.vet_records.type IS 'Record type: vaccine, disease, treatment, death, checkup';
COMMENT ON COLUMN public.vet_records.severity IS 'Severity level: low, medium, high, critical';
COMMENT ON COLUMN public.vet_records.next_action_date IS 'Date for next follow-up action';

-- ============================================
-- STEP 3: CREATE TRIGGERS FOR UPDATED_AT
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

CREATE TRIGGER update_egg_sales_updated_at
    BEFORE UPDATE ON public.egg_sales
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
-- STEP 4: ROW LEVEL SECURITY (RLS)
-- ============================================

-- Enable RLS on all tables
ALTER TABLE public.daily_egg_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.egg_sales ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vet_records ENABLE ROW LEVEL SECURITY;

-- ============================================
-- RLS Policies for daily_egg_records
-- ============================================
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

-- ============================================
-- RLS Policies for egg_sales
-- ============================================
CREATE POLICY "Users can view their own egg sales"
    ON public.egg_sales FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own egg sales"
    ON public.egg_sales FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own egg sales"
    ON public.egg_sales FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own egg sales"
    ON public.egg_sales FOR DELETE
    USING (auth.uid() = user_id);

-- ============================================
-- RLS Policies for expenses
-- ============================================
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

-- ============================================
-- RLS Policies for vet_records
-- ============================================
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
-- STEP 5: GRANT PERMISSIONS
-- ============================================

GRANT USAGE ON SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO postgres, service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon;

-- ============================================
-- STEP 6: VIEWS (OPTIONAL - FOR ANALYTICS)
-- ============================================

-- View: Daily egg records with calculated remaining eggs
CREATE OR REPLACE VIEW public.daily_egg_records_with_stats AS
SELECT
    id,
    user_id,
    date,
    eggs_collected,
    eggs_consumed,
    (eggs_collected - eggs_consumed) AS eggs_remaining,
    notes,
    hen_count,
    created_at,
    updated_at
FROM public.daily_egg_records;

-- ============================================
-- STEP 7: FUNCTIONS (OPTIONAL - FOR COMPLEX QUERIES)
-- ============================================

-- Function: Get user statistics for date range
CREATE OR REPLACE FUNCTION get_user_stats(
    p_user_id UUID,
    p_start_date DATE,
    p_end_date DATE
)
RETURNS TABLE (
    total_eggs_collected BIGINT,
    total_eggs_consumed BIGINT,
    total_eggs_remaining BIGINT,
    total_sales_quantity BIGINT,
    total_revenue DECIMAL,
    total_sales_count BIGINT,
    total_expenses DECIMAL,
    total_vet_costs DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        COALESCE(SUM(der.eggs_collected), 0)::BIGINT,
        COALESCE(SUM(der.eggs_consumed), 0)::BIGINT,
        COALESCE(SUM(der.eggs_collected - der.eggs_consumed), 0)::BIGINT,
        COALESCE(SUM(es.quantity_sold), 0)::BIGINT,
        COALESCE(SUM(es.quantity_sold * es.price_per_egg), 0)::DECIMAL,
        COALESCE(COUNT(DISTINCT es.id), 0)::BIGINT,
        COALESCE(SUM(e.amount), 0)::DECIMAL,
        COALESCE(SUM(vr.cost), 0)::DECIMAL
    FROM public.daily_egg_records der
    LEFT JOIN public.egg_sales es
        ON es.user_id = der.user_id
        AND es.date BETWEEN p_start_date AND p_end_date
    LEFT JOIN public.expenses e
        ON e.user_id = der.user_id
        AND e.date BETWEEN p_start_date AND p_end_date
    LEFT JOIN public.vet_records vr
        ON vr.user_id = der.user_id
        AND vr.date BETWEEN p_start_date AND p_end_date
    WHERE der.user_id = p_user_id
      AND der.date BETWEEN p_start_date AND p_end_date;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- COMPLETION MESSAGE
-- ============================================

DO $$
BEGIN
    RAISE NOTICE '✅✅✅ Schema criado com sucesso! ✅✅✅';
    RAISE NOTICE '';
    RAISE NOTICE 'Tabelas criadas:';
    RAISE NOTICE '  ✓ daily_egg_records - Registos diários de produção';
    RAISE NOTICE '  ✓ egg_sales - Vendas de ovos com preços e clientes';
    RAISE NOTICE '  ✓ expenses - Despesas operacionais';
    RAISE NOTICE '  ✓ vet_records - Registos veterinários';
    RAISE NOTICE '';
    RAISE NOTICE 'Recursos adicionais criados:';
    RAISE NOTICE '  ✓ Triggers para updated_at';
    RAISE NOTICE '  ✓ Row Level Security (RLS) ativado';
    RAISE NOTICE '  ✓ Políticas RLS configuradas';
    RAISE NOTICE '  ✓ Índices para performance';
    RAISE NOTICE '  ✓ View daily_egg_records_with_stats';
    RAISE NOTICE '  ✓ Função get_user_stats()';
    RAISE NOTICE '';
    RAISE NOTICE 'Próximos passos:';
    RAISE NOTICE '  1. Ir ao Table Editor - Deve ver 4 tabelas';
    RAISE NOTICE '  2. Executar flutter run';
    RAISE NOTICE '  3. A aplicação está pronta! 🚀';
    RAISE NOTICE '';
    RAISE NOTICE 'SUCESSO! Pode fechar esta janela.';
END $$;
