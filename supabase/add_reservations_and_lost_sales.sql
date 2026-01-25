-- Migration: Add Reservations Table and Lost Sales Field
-- Description: Separates egg reservations from actual sales and adds lost sales tracking
-- Date: 2026-01-25

-- ================================================
-- 1. ADD is_lost FIELD TO egg_sales TABLE
-- ================================================

-- Add is_lost field to track sales that will never be paid
ALTER TABLE public.egg_sales
ADD COLUMN IF NOT EXISTS is_lost BOOLEAN NOT NULL DEFAULT FALSE;

-- Create index for faster filtering of lost sales
CREATE INDEX IF NOT EXISTS idx_egg_sales_is_lost
ON public.egg_sales(user_id, is_lost)
WHERE is_lost = TRUE;

-- ================================================
-- 2. CREATE egg_reservations TABLE
-- ================================================

-- Create egg_reservations table
CREATE TABLE IF NOT EXISTS public.egg_reservations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

    -- Dates
    date DATE NOT NULL,
    pickup_date DATE, -- Expected pickup date (optional)
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,

    -- Quantity
    quantity INTEGER NOT NULL CHECK (quantity > 0),

    -- Prices (optional - locks in price at reservation time)
    price_per_egg DECIMAL(10,2) CHECK (price_per_egg IS NULL OR price_per_egg >= 0),
    price_per_dozen DECIMAL(10,2) CHECK (price_per_dozen IS NULL OR price_per_dozen >= 0),

    -- Customer Information
    customer_name TEXT,
    customer_email TEXT,
    customer_phone TEXT,

    -- Notes
    notes TEXT
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_egg_reservations_user_date
ON public.egg_reservations(user_id, date DESC);

CREATE INDEX IF NOT EXISTS idx_egg_reservations_pickup_date
ON public.egg_reservations(user_id, pickup_date)
WHERE pickup_date IS NOT NULL;

-- ================================================
-- 3. ROW LEVEL SECURITY (RLS) FOR egg_reservations
-- ================================================

-- Enable RLS
ALTER TABLE public.egg_reservations ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view their own reservations
CREATE POLICY "Users can view their own reservations"
ON public.egg_reservations
FOR SELECT
USING (auth.uid() = user_id);

-- Policy: Users can insert their own reservations
CREATE POLICY "Users can insert their own reservations"
ON public.egg_reservations
FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Policy: Users can update their own reservations
CREATE POLICY "Users can update their own reservations"
ON public.egg_reservations
FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Policy: Users can delete their own reservations
CREATE POLICY "Users can delete their own reservations"
ON public.egg_reservations
FOR DELETE
USING (auth.uid() = user_id);

-- ================================================
-- 4. COMMENTS FOR DOCUMENTATION
-- ================================================

COMMENT ON TABLE public.egg_reservations IS
'Stores egg reservations - eggs reserved for future pickup (not yet delivered to customer)';

COMMENT ON COLUMN public.egg_reservations.date IS
'Date when the reservation was made';

COMMENT ON COLUMN public.egg_reservations.pickup_date IS
'Expected date for customer to pick up the reserved eggs';

COMMENT ON COLUMN public.egg_reservations.price_per_egg IS
'Optional: Lock in the price per egg at reservation time';

COMMENT ON COLUMN public.egg_reservations.price_per_dozen IS
'Optional: Lock in the price per dozen at reservation time';

COMMENT ON COLUMN public.egg_sales.is_lost IS
'Marks a sale as lost - customer took eggs but will never pay';

-- ================================================
-- 5. VERIFICATION
-- ================================================

-- Verify new column exists
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'egg_sales'
        AND column_name = 'is_lost'
    ) THEN
        RAISE EXCEPTION 'Migration failed: is_lost column not added to egg_sales';
    END IF;

    RAISE NOTICE 'Migration completed successfully!';
    RAISE NOTICE '✓ Added is_lost field to egg_sales table';
    RAISE NOTICE '✓ Created egg_reservations table';
    RAISE NOTICE '✓ Created indexes for performance';
    RAISE NOTICE '✓ Enabled RLS policies';
END $$;
