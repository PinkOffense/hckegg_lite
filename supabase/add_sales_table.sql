-- ============================================
-- HCKEgg Lite - Sales Feature Migration
-- ============================================
-- Execute este SQL no Supabase SQL Editor para adicionar
-- a funcionalidade de vendas e atualizar daily_egg_records
-- ============================================

-- ============================================
-- STEP 1: Atualizar daily_egg_records
-- ============================================

-- Remover colunas desnecessárias de daily_egg_records
ALTER TABLE public.daily_egg_records
    DROP COLUMN IF EXISTS eggs_sold,
    DROP COLUMN IF EXISTS price_per_egg,
    DROP COLUMN IF EXISTS feed_expense,
    DROP COLUMN IF EXISTS vet_expense,
    DROP COLUMN IF EXISTS other_expense;

-- ============================================
-- STEP 2: Criar tabela egg_sales
-- ============================================

CREATE TABLE IF NOT EXISTS public.egg_sales (
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

-- Índices para performance
CREATE INDEX idx_egg_sales_user_date ON public.egg_sales(user_id, date DESC);
CREATE INDEX idx_egg_sales_user_created ON public.egg_sales(user_id, created_at DESC);
CREATE INDEX idx_egg_sales_customer ON public.egg_sales(user_id, customer_name) WHERE customer_name IS NOT NULL;

-- ============================================
-- STEP 3: Trigger para updated_at
-- ============================================

CREATE TRIGGER update_egg_sales_updated_at
    BEFORE UPDATE ON public.egg_sales
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- STEP 4: Row Level Security (RLS)
-- ============================================

-- Habilitar RLS
ALTER TABLE public.egg_sales ENABLE ROW LEVEL SECURITY;

-- Políticas RLS
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
-- STEP 5: Atualizar VIEW (remover campos antigos)
-- ============================================

DROP VIEW IF EXISTS public.daily_egg_records_with_stats;

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
-- STEP 6: Atualizar função get_user_stats
-- ============================================

DROP FUNCTION IF EXISTS get_user_stats(UUID, DATE, DATE);

CREATE OR REPLACE FUNCTION get_user_stats(
    p_user_id UUID,
    p_start_date DATE,
    p_end_date DATE
)
RETURNS TABLE (
    total_eggs_collected BIGINT,
    total_eggs_consumed BIGINT,
    total_eggs_remaining BIGINT,
    total_revenue DECIMAL,
    total_sales_count BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        COALESCE(SUM(der.eggs_collected), 0)::BIGINT AS total_eggs_collected,
        COALESCE(SUM(der.eggs_consumed), 0)::BIGINT AS total_eggs_consumed,
        COALESCE(SUM(der.eggs_collected - der.eggs_consumed), 0)::BIGINT AS total_eggs_remaining,
        COALESCE(SUM(es.quantity_sold * es.price_per_egg), 0)::DECIMAL AS total_revenue,
        COALESCE(COUNT(es.id), 0)::BIGINT AS total_sales_count
    FROM public.daily_egg_records der
    LEFT JOIN public.egg_sales es
        ON es.user_id = der.user_id
        AND es.date BETWEEN p_start_date AND p_end_date
    WHERE der.user_id = p_user_id
      AND der.date BETWEEN p_start_date AND p_end_date
    GROUP BY der.user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- STEP 7: Atualizar permissões
-- ============================================

GRANT SELECT, INSERT, UPDATE, DELETE ON public.egg_sales TO authenticated;
GRANT SELECT ON public.egg_sales TO anon;

-- ============================================
-- COMPLETION MESSAGE
-- ============================================
-- Migração concluída com sucesso!
-- - daily_egg_records agora foca apenas na produção
-- - egg_sales é a nova tabela para registar vendas
-- - Vendas podem incluir informações do cliente para faturas
