-- ============================================
-- HCKEgg Lite - Complete Database Schema
-- ============================================
-- Execute this SQL in Supabase SQL Editor
-- This is a FRESH INSTALL script - run once for new projects
-- ============================================
-- Version: 2.1
-- Last Updated: 2026-02-04
-- ============================================
--
-- Tables included:
--   1. user_profiles      - User profile with avatar
--   2. daily_egg_records  - Daily egg production tracking
--   3. egg_sales          - Sales with pricing and customer info
--   4. egg_reservations   - Future egg reservations
--   5. expenses           - Farm operational expenses
--   6. vet_records        - Veterinary and health records
--   7. feed_stocks        - Feed inventory levels
--   8. feed_movements     - Feed stock movement history
--
-- ============================================

-- ============================================
-- STEP 1: ENABLE EXTENSIONS
-- ============================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- STEP 2: CREATE HELPER FUNCTIONS
-- ============================================

-- Function to auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to allow users to delete their own account
CREATE OR REPLACE FUNCTION public.delete_user_account()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  current_user_id uuid;
BEGIN
  current_user_id := auth.uid();
  IF current_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;
  DELETE FROM auth.users WHERE id = current_user_id;
END;
$$;

COMMENT ON FUNCTION public.delete_user_account() IS
'Allows authenticated users to permanently delete their own account.';

-- ============================================
-- STEP 3: CREATE TABLES
-- ============================================

-- ============================================
-- TABLE: user_profiles
-- Purpose: Store user profile information
-- ============================================
CREATE TABLE IF NOT EXISTS public.user_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    display_name TEXT,
    avatar_url TEXT,
    bio TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id)
);

CREATE INDEX IF NOT EXISTS idx_user_profiles_user_id ON public.user_profiles(user_id);

COMMENT ON TABLE public.user_profiles IS 'User profile information including display name and avatar';

-- ============================================
-- TABLE: daily_egg_records
-- Purpose: Track daily egg production
-- ============================================
CREATE TABLE IF NOT EXISTS public.daily_egg_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    eggs_collected INTEGER NOT NULL DEFAULT 0 CHECK (eggs_collected >= 0),
    eggs_consumed INTEGER NOT NULL DEFAULT 0 CHECK (eggs_consumed >= 0),
    notes TEXT,
    hen_count INTEGER CHECK (hen_count > 0),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT unique_user_date UNIQUE(user_id, date)
);

CREATE INDEX idx_daily_egg_records_user_date ON public.daily_egg_records(user_id, date DESC);
CREATE INDEX idx_daily_egg_records_user_created ON public.daily_egg_records(user_id, created_at DESC);

COMMENT ON TABLE public.daily_egg_records IS 'Daily egg production records - tracks collection and consumption';
COMMENT ON COLUMN public.daily_egg_records.eggs_collected IS 'Number of eggs collected this day';
COMMENT ON COLUMN public.daily_egg_records.eggs_consumed IS 'Number of eggs consumed/used this day';
COMMENT ON COLUMN public.daily_egg_records.hen_count IS 'Number of hens on this day';

-- ============================================
-- TABLE: egg_sales
-- Purpose: Track egg sales with pricing
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
    payment_status VARCHAR(50) NOT NULL DEFAULT 'pending' CHECK (payment_status IN ('paid', 'pending', 'overdue', 'advance')),
    payment_date DATE,
    is_reservation BOOLEAN NOT NULL DEFAULT FALSE,
    reservation_notes TEXT,
    is_lost BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_egg_sales_user_date ON public.egg_sales(user_id, date DESC);
CREATE INDEX idx_egg_sales_user_created ON public.egg_sales(user_id, created_at DESC);
CREATE INDEX idx_egg_sales_customer ON public.egg_sales(user_id, customer_name) WHERE customer_name IS NOT NULL;
CREATE INDEX idx_egg_sales_is_lost ON public.egg_sales(user_id, is_lost) WHERE is_lost = TRUE;
CREATE INDEX idx_egg_sales_payment ON public.egg_sales(user_id, payment_status);

COMMENT ON TABLE public.egg_sales IS 'Egg sales records with pricing and customer information';
COMMENT ON COLUMN public.egg_sales.payment_status IS 'Payment status: paid, pending, overdue, advance';
COMMENT ON COLUMN public.egg_sales.is_reservation IS 'Whether this sale originated from a reservation';
COMMENT ON COLUMN public.egg_sales.is_lost IS 'Marks a sale as lost - customer took eggs but will never pay';

-- ============================================
-- TABLE: egg_reservations
-- Purpose: Track egg reservations for future pickup
-- ============================================
CREATE TABLE IF NOT EXISTS public.egg_reservations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    pickup_date DATE,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    price_per_egg DECIMAL(10, 2) CHECK (price_per_egg IS NULL OR price_per_egg >= 0),
    price_per_dozen DECIMAL(10, 2) CHECK (price_per_dozen IS NULL OR price_per_dozen >= 0),
    customer_name TEXT,
    customer_email TEXT,
    customer_phone TEXT,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_egg_reservations_user_date ON public.egg_reservations(user_id, date DESC);
CREATE INDEX idx_egg_reservations_pickup_date ON public.egg_reservations(user_id, pickup_date) WHERE pickup_date IS NOT NULL;

COMMENT ON TABLE public.egg_reservations IS 'Egg reservations - eggs reserved for future pickup';
COMMENT ON COLUMN public.egg_reservations.pickup_date IS 'Expected date for customer to pick up eggs';

-- ============================================
-- TABLE: expenses
-- Purpose: Track farm operational expenses
-- ============================================
CREATE TABLE IF NOT EXISTS public.expenses (
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

CREATE INDEX idx_expenses_user_date ON public.expenses(user_id, date DESC);
CREATE INDEX idx_expenses_user_category ON public.expenses(user_id, category);
CREATE INDEX idx_expenses_user_created ON public.expenses(user_id, created_at DESC);

COMMENT ON TABLE public.expenses IS 'Farm operational expenses (excludes veterinary costs)';
COMMENT ON COLUMN public.expenses.category IS 'Category: feed, maintenance, equipment, utilities, other';

-- ============================================
-- TABLE: vet_records
-- Purpose: Track veterinary and health records
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

CREATE INDEX idx_vet_records_user_date ON public.vet_records(user_id, date DESC);
CREATE INDEX idx_vet_records_user_type ON public.vet_records(user_id, type);
CREATE INDEX idx_vet_records_user_severity ON public.vet_records(user_id, severity);
CREATE INDEX idx_vet_records_next_action ON public.vet_records(user_id, next_action_date) WHERE next_action_date IS NOT NULL;
CREATE INDEX idx_vet_records_user_created ON public.vet_records(user_id, created_at DESC);

COMMENT ON TABLE public.vet_records IS 'Veterinary and health records for hens';
COMMENT ON COLUMN public.vet_records.type IS 'Record type: vaccine, disease, treatment, death, checkup';
COMMENT ON COLUMN public.vet_records.severity IS 'Severity: low, medium, high, critical';
COMMENT ON COLUMN public.vet_records.next_action_date IS 'Date for next follow-up action';

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

CREATE INDEX idx_feed_stocks_user ON public.feed_stocks(user_id);
CREATE INDEX idx_feed_stocks_user_type ON public.feed_stocks(user_id, type);
CREATE INDEX idx_feed_stocks_low_stock ON public.feed_stocks(user_id) WHERE current_quantity_kg <= minimum_quantity_kg;

COMMENT ON TABLE public.feed_stocks IS 'Feed inventory stock levels';
COMMENT ON COLUMN public.feed_stocks.type IS 'Feed type: layer, grower, starter, scratch, supplement, other';
COMMENT ON COLUMN public.feed_stocks.minimum_quantity_kg IS 'Threshold for low stock alert';

-- ============================================
-- TABLE: feed_movements
-- Purpose: Track feed stock movements
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

CREATE INDEX idx_feed_movements_user ON public.feed_movements(user_id);
CREATE INDEX idx_feed_movements_stock ON public.feed_movements(feed_stock_id);
CREATE INDEX idx_feed_movements_date ON public.feed_movements(user_id, date DESC);
CREATE INDEX idx_feed_movements_type ON public.feed_movements(user_id, movement_type);

COMMENT ON TABLE public.feed_movements IS 'Feed stock movement history';
COMMENT ON COLUMN public.feed_movements.movement_type IS 'Type: purchase, consumption, adjustment, loss';

-- ============================================
-- STEP 4: CREATE TRIGGERS
-- ============================================

CREATE TRIGGER update_user_profiles_updated_at
    BEFORE UPDATE ON public.user_profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_daily_egg_records_updated_at
    BEFORE UPDATE ON public.daily_egg_records
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_egg_sales_updated_at
    BEFORE UPDATE ON public.egg_sales
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_expenses_updated_at
    BEFORE UPDATE ON public.expenses
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_vet_records_updated_at
    BEFORE UPDATE ON public.vet_records
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_feed_stocks_updated_at
    BEFORE UPDATE ON public.feed_stocks
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- STEP 5: ENABLE ROW LEVEL SECURITY (RLS)
-- ============================================

ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_egg_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.egg_sales ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.egg_reservations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vet_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.feed_stocks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.feed_movements ENABLE ROW LEVEL SECURITY;

-- ============================================
-- STEP 6: CREATE RLS POLICIES
-- ============================================

-- user_profiles policies
CREATE POLICY "Users can view their own profile" ON public.user_profiles
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own profile" ON public.user_profiles
    FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own profile" ON public.user_profiles
    FOR UPDATE USING (auth.uid() = user_id);

-- daily_egg_records policies
CREATE POLICY "Users can view their own daily egg records" ON public.daily_egg_records
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own daily egg records" ON public.daily_egg_records
    FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own daily egg records" ON public.daily_egg_records
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete their own daily egg records" ON public.daily_egg_records
    FOR DELETE USING (auth.uid() = user_id);

-- egg_sales policies
CREATE POLICY "Users can view their own egg sales" ON public.egg_sales
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own egg sales" ON public.egg_sales
    FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own egg sales" ON public.egg_sales
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete their own egg sales" ON public.egg_sales
    FOR DELETE USING (auth.uid() = user_id);

-- egg_reservations policies
CREATE POLICY "Users can view their own reservations" ON public.egg_reservations
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own reservations" ON public.egg_reservations
    FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own reservations" ON public.egg_reservations
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete their own reservations" ON public.egg_reservations
    FOR DELETE USING (auth.uid() = user_id);

-- expenses policies
CREATE POLICY "Users can view their own expenses" ON public.expenses
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own expenses" ON public.expenses
    FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own expenses" ON public.expenses
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete their own expenses" ON public.expenses
    FOR DELETE USING (auth.uid() = user_id);

-- vet_records policies
CREATE POLICY "Users can view their own vet records" ON public.vet_records
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own vet records" ON public.vet_records
    FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own vet records" ON public.vet_records
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete their own vet records" ON public.vet_records
    FOR DELETE USING (auth.uid() = user_id);

-- feed_stocks policies
CREATE POLICY "Users can view their own feed stocks" ON public.feed_stocks
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own feed stocks" ON public.feed_stocks
    FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own feed stocks" ON public.feed_stocks
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete their own feed stocks" ON public.feed_stocks
    FOR DELETE USING (auth.uid() = user_id);

-- feed_movements policies
CREATE POLICY "Users can view their own feed movements" ON public.feed_movements
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own feed movements" ON public.feed_movements
    FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own feed movements" ON public.feed_movements
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete their own feed movements" ON public.feed_movements
    FOR DELETE USING (auth.uid() = user_id);

-- ============================================
-- STEP 7: GRANT PERMISSIONS
-- ============================================

GRANT USAGE ON SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO postgres, service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon;
GRANT EXECUTE ON FUNCTION public.delete_user_account() TO authenticated;

-- ============================================
-- STEP 8: CREATE STORAGE BUCKET FOR AVATARS
-- ============================================

INSERT INTO storage.buckets (id, name, public)
VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO NOTHING;

-- Storage policies for avatars bucket
CREATE POLICY "Avatar images are publicly accessible" ON storage.objects
    FOR SELECT USING (bucket_id = 'avatars');

CREATE POLICY "Users can upload their own avatar" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'avatars'
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

CREATE POLICY "Users can update their own avatar" ON storage.objects
    FOR UPDATE USING (
        bucket_id = 'avatars'
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

CREATE POLICY "Users can delete their own avatar" ON storage.objects
    FOR DELETE USING (
        bucket_id = 'avatars'
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

-- ============================================
-- STEP 9: OPTIONAL VIEWS FOR ANALYTICS
-- ============================================

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
-- COMPLETION MESSAGE
-- ============================================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '================================================';
    RAISE NOTICE '  HCKEgg Lite - Schema Created Successfully!';
    RAISE NOTICE '================================================';
    RAISE NOTICE '';
    RAISE NOTICE 'Tables created:';
    RAISE NOTICE '  * user_profiles      - User profile with avatar';
    RAISE NOTICE '  * daily_egg_records  - Daily egg production';
    RAISE NOTICE '  * egg_sales          - Sales with pricing';
    RAISE NOTICE '  * egg_reservations   - Future reservations';
    RAISE NOTICE '  * expenses           - Operational expenses';
    RAISE NOTICE '  * vet_records        - Veterinary records';
    RAISE NOTICE '  * feed_stocks        - Feed inventory';
    RAISE NOTICE '  * feed_movements     - Stock movements';
    RAISE NOTICE '';
    RAISE NOTICE 'Storage:';
    RAISE NOTICE '  * avatars bucket - User profile images';
    RAISE NOTICE '';
    RAISE NOTICE 'Functions:';
    RAISE NOTICE '  * delete_user_account() - Account deletion';
    RAISE NOTICE '  * update_updated_at_column() - Auto timestamps';
    RAISE NOTICE '';
    RAISE NOTICE 'Next steps:';
    RAISE NOTICE '  1. Verify tables in Supabase Table Editor';
    RAISE NOTICE '  2. Test RLS policies';
    RAISE NOTICE '  3. Run the Flutter app';
    RAISE NOTICE '================================================';
END $$;
