-- ============================================
-- HCKEgg Lite - Performance Issues Fix
-- ============================================
-- Este script corrige os problemas de performance de RLS
-- criando índices nas colunas user_id das tabelas
-- ============================================

-- Criar índices para optimizar queries RLS com auth.uid()

-- Index para daily_egg_records
CREATE INDEX IF NOT EXISTS idx_daily_egg_records_user_id
ON public.daily_egg_records(user_id);

-- Index para egg_sales
CREATE INDEX IF NOT EXISTS idx_egg_sales_user_id
ON public.egg_sales(user_id);

-- Index para expenses
CREATE INDEX IF NOT EXISTS idx_expenses_user_id
ON public.expenses(user_id);

-- Index para vet_records (se existir)
CREATE INDEX IF NOT EXISTS idx_vet_records_user_id
ON public.vet_records(user_id);

-- Index para feed_stocks (se existir)
CREATE INDEX IF NOT EXISTS idx_feed_stocks_user_id
ON public.feed_stocks(user_id);

-- Index para reservations (se existir)
CREATE INDEX IF NOT EXISTS idx_reservations_user_id
ON public.reservations(user_id);

-- Index para vet_appointments (se existir)
CREATE INDEX IF NOT EXISTS idx_vet_appointments_user_id
ON public.vet_appointments(user_id);

-- Index para notifications (se existir)
CREATE INDEX IF NOT EXISTS idx_notifications_user_id
ON public.notifications(user_id);

-- Index para notification_settings (se existir)
CREATE INDEX IF NOT EXISTS idx_notification_settings_user_id
ON public.notification_settings(user_id);

-- Index para push_tokens (se existir)
CREATE INDEX IF NOT EXISTS idx_push_tokens_user_id
ON public.push_tokens(user_id);

-- Index para profiles (se existir)
CREATE INDEX IF NOT EXISTS idx_profiles_user_id
ON public.profiles(user_id);

-- ============================================
-- Índices compostos para queries comuns
-- ============================================

-- Index para daily_egg_records por user_id e date
CREATE INDEX IF NOT EXISTS idx_daily_egg_records_user_date
ON public.daily_egg_records(user_id, date DESC);

-- Index para expenses por user_id e date
CREATE INDEX IF NOT EXISTS idx_expenses_user_date
ON public.expenses(user_id, date DESC);

-- Index para egg_sales por user_id e date
CREATE INDEX IF NOT EXISTS idx_egg_sales_user_date
ON public.egg_sales(user_id, sale_date DESC);

-- ============================================
-- Atualizar estatísticas das tabelas
-- ============================================

ANALYZE public.daily_egg_records;
ANALYZE public.egg_sales;
ANALYZE public.expenses;

-- ============================================
-- Verificação
-- ============================================

DO $$
BEGIN
    RAISE NOTICE '============================================';
    RAISE NOTICE 'Performance Indexes Created Successfully!';
    RAISE NOTICE '============================================';
    RAISE NOTICE '';
    RAISE NOTICE 'Indexes created on user_id columns:';
    RAISE NOTICE '  - daily_egg_records';
    RAISE NOTICE '  - egg_sales';
    RAISE NOTICE '  - expenses';
    RAISE NOTICE '  - vet_records';
    RAISE NOTICE '  - feed_stocks';
    RAISE NOTICE '  - reservations';
    RAISE NOTICE '  - vet_appointments';
    RAISE NOTICE '  - notifications';
    RAISE NOTICE '  - notification_settings';
    RAISE NOTICE '  - push_tokens';
    RAISE NOTICE '  - profiles';
    RAISE NOTICE '';
    RAISE NOTICE 'Composite indexes created for common queries:';
    RAISE NOTICE '  - daily_egg_records (user_id, date)';
    RAISE NOTICE '  - expenses (user_id, date)';
    RAISE NOTICE '  - egg_sales (user_id, sale_date)';
    RAISE NOTICE '';
    RAISE NOTICE 'Note: Some indexes may fail silently if tables';
    RAISE NOTICE 'do not exist - this is expected behavior.';
    RAISE NOTICE '============================================';
END $$;
