-- ============================================
-- FIX: Auth and Add Payment Tracking
-- ============================================

-- Add payment and reservation tracking to egg_sales
ALTER TABLE public.egg_sales
ADD COLUMN IF NOT EXISTS payment_status VARCHAR(50) NOT NULL DEFAULT 'pending'
    CHECK (payment_status IN ('paid', 'pending', 'overdue', 'advance'));

ALTER TABLE public.egg_sales
ADD COLUMN IF NOT EXISTS payment_date DATE;

ALTER TABLE public.egg_sales
ADD COLUMN IF NOT EXISTS is_reservation BOOLEAN NOT NULL DEFAULT FALSE;

ALTER TABLE public.egg_sales
ADD COLUMN IF NOT EXISTS reservation_notes TEXT;

-- Add index for payment queries
CREATE INDEX IF NOT EXISTS idx_egg_sales_payment_status ON public.egg_sales(user_id, payment_status);
CREATE INDEX IF NOT EXISTS idx_egg_sales_reservations ON public.egg_sales(user_id, is_reservation) WHERE is_reservation = TRUE;

-- Comments
COMMENT ON COLUMN public.egg_sales.payment_status IS 'Payment status: paid, pending, overdue, advance (paid in advance)';
COMMENT ON COLUMN public.egg_sales.payment_date IS 'Date when payment was received';
COMMENT ON COLUMN public.egg_sales.is_reservation IS 'Whether this is a reservation (eggs reserved for future pickup)';
COMMENT ON COLUMN public.egg_sales.reservation_notes IS 'Notes about the reservation';

-- ============================================
-- SUCCESS MESSAGE
-- ============================================

DO $$
BEGIN
    RAISE NOTICE '✅ Tabela egg_sales atualizada com sucesso!';
    RAISE NOTICE '✓ Campos de pagamento adicionados';
    RAISE NOTICE '✓ payment_status: paid, pending, overdue, advance';
    RAISE NOTICE '✓ payment_date: data do pagamento';
    RAISE NOTICE '✓ is_reservation: marca reservas';
    RAISE NOTICE '✓ reservation_notes: notas sobre reserva';
    RAISE NOTICE '';
    RAISE NOTICE 'Agora pode criar contas e gerir pagamentos! 🚀';
END $$;
