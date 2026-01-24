-- ============================================
-- CLEANUP SCRIPT - Remove todas as tabelas e dependências
-- ============================================
-- Execute ESTE script PRIMEIRO para limpar tudo
-- ============================================

-- Drop policies primeiro (dependem das tabelas)
DROP POLICY IF EXISTS "Users can view their own daily egg records" ON public.daily_egg_records;
DROP POLICY IF EXISTS "Users can insert their own daily egg records" ON public.daily_egg_records;
DROP POLICY IF EXISTS "Users can update their own daily egg records" ON public.daily_egg_records;
DROP POLICY IF EXISTS "Users can delete their own daily egg records" ON public.daily_egg_records;

DROP POLICY IF EXISTS "Users can view their own expenses" ON public.expenses;
DROP POLICY IF EXISTS "Users can insert their own expenses" ON public.expenses;
DROP POLICY IF EXISTS "Users can update their own expenses" ON public.expenses;
DROP POLICY IF EXISTS "Users can delete their own expenses" ON public.expenses;

DROP POLICY IF EXISTS "Users can view their own vet records" ON public.vet_records;
DROP POLICY IF EXISTS "Users can insert their own vet records" ON public.vet_records;
DROP POLICY IF EXISTS "Users can update their own vet records" ON public.vet_records;
DROP POLICY IF EXISTS "Users can delete their own vet records" ON public.vet_records;

-- Drop triggers
DROP TRIGGER IF EXISTS update_daily_egg_records_updated_at ON public.daily_egg_records;
DROP TRIGGER IF EXISTS update_expenses_updated_at ON public.expenses;
DROP TRIGGER IF EXISTS update_vet_records_updated_at ON public.vet_records;

-- Drop views
DROP VIEW IF EXISTS public.daily_egg_records_with_stats;

-- Drop functions
DROP FUNCTION IF EXISTS update_updated_at_column();
DROP FUNCTION IF EXISTS get_user_stats(UUID, DATE, DATE);

-- Drop indexes (são removidos com as tabelas, mas podemos ser explícitos)
DROP INDEX IF EXISTS public.idx_daily_egg_records_user_date;
DROP INDEX IF EXISTS public.idx_daily_egg_records_user_created;
DROP INDEX IF EXISTS public.idx_expenses_user_date;
DROP INDEX IF EXISTS public.idx_expenses_user_category;
DROP INDEX IF EXISTS public.idx_vet_records_user_date;
DROP INDEX IF EXISTS public.idx_vet_records_user_type;
DROP INDEX IF EXISTS public.idx_vet_records_user_severity;
DROP INDEX IF EXISTS public.idx_vet_records_next_action;

-- Drop tables (CASCADE remove todas as dependências)
DROP TABLE IF EXISTS public.daily_egg_records CASCADE;
DROP TABLE IF EXISTS public.expenses CASCADE;
DROP TABLE IF EXISTS public.vet_records CASCADE;

-- Mensagem de sucesso
SELECT 'Cleanup completo! Agora execute o schema.sql principal.' AS status;
