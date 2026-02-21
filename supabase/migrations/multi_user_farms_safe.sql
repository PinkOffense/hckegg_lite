-- ============================================
-- HCKEgg Lite - Multi-User Farm Support (SAFE VERSION)
-- ============================================
-- This version uses IF NOT EXISTS and OR REPLACE everywhere
-- Safe to run multiple times
-- ============================================

-- ============================================
-- STEP 1: CREATE FARM TABLES
-- ============================================

CREATE TABLE IF NOT EXISTS public.farms (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    description TEXT,
    created_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_farms_created_by ON public.farms(created_by);

CREATE TABLE IF NOT EXISTS public.farm_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    farm_id UUID NOT NULL REFERENCES public.farms(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    role TEXT NOT NULL DEFAULT 'editor' CHECK (role IN ('owner', 'editor')),
    invited_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(farm_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_farm_members_farm ON public.farm_members(farm_id);
CREATE INDEX IF NOT EXISTS idx_farm_members_user ON public.farm_members(user_id);

CREATE TABLE IF NOT EXISTS public.farm_invitations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    farm_id UUID NOT NULL REFERENCES public.farms(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    role TEXT NOT NULL DEFAULT 'editor' CHECK (role IN ('owner', 'editor')),
    invited_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    token TEXT NOT NULL UNIQUE DEFAULT encode(extensions.gen_random_bytes(32), 'hex'),
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT (NOW() + INTERVAL '7 days'),
    accepted_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(farm_id, email)
);

CREATE INDEX IF NOT EXISTS idx_farm_invitations_email ON public.farm_invitations(email);
CREATE INDEX IF NOT EXISTS idx_farm_invitations_token ON public.farm_invitations(token);
CREATE INDEX IF NOT EXISTS idx_farm_invitations_farm ON public.farm_invitations(farm_id);

-- ============================================
-- STEP 2: ADD farm_id TO EXISTING TABLES
-- ============================================

ALTER TABLE public.daily_egg_records ADD COLUMN IF NOT EXISTS farm_id UUID REFERENCES public.farms(id) ON DELETE CASCADE;
ALTER TABLE public.egg_sales ADD COLUMN IF NOT EXISTS farm_id UUID REFERENCES public.farms(id) ON DELETE CASCADE;
ALTER TABLE public.egg_reservations ADD COLUMN IF NOT EXISTS farm_id UUID REFERENCES public.farms(id) ON DELETE CASCADE;
ALTER TABLE public.expenses ADD COLUMN IF NOT EXISTS farm_id UUID REFERENCES public.farms(id) ON DELETE CASCADE;
ALTER TABLE public.vet_records ADD COLUMN IF NOT EXISTS farm_id UUID REFERENCES public.farms(id) ON DELETE CASCADE;
ALTER TABLE public.feed_stocks ADD COLUMN IF NOT EXISTS farm_id UUID REFERENCES public.farms(id) ON DELETE CASCADE;
ALTER TABLE public.feed_movements ADD COLUMN IF NOT EXISTS farm_id UUID REFERENCES public.farms(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_daily_egg_records_farm ON public.daily_egg_records(farm_id);
CREATE INDEX IF NOT EXISTS idx_egg_sales_farm ON public.egg_sales(farm_id);
CREATE INDEX IF NOT EXISTS idx_egg_reservations_farm ON public.egg_reservations(farm_id);
CREATE INDEX IF NOT EXISTS idx_expenses_farm ON public.expenses(farm_id);
CREATE INDEX IF NOT EXISTS idx_vet_records_farm ON public.vet_records(farm_id);
CREATE INDEX IF NOT EXISTS idx_feed_stocks_farm ON public.feed_stocks(farm_id);
CREATE INDEX IF NOT EXISTS idx_feed_movements_farm ON public.feed_movements(farm_id);

-- ============================================
-- STEP 3: CREATE HELPER FUNCTIONS
-- ============================================

CREATE OR REPLACE FUNCTION public.is_farm_member(p_farm_id UUID, p_user_id UUID DEFAULT auth.uid())
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.farm_members
        WHERE farm_id = p_farm_id AND user_id = p_user_id
    );
END;
$$;

CREATE OR REPLACE FUNCTION public.is_farm_owner(p_farm_id UUID, p_user_id UUID DEFAULT auth.uid())
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.farm_members
        WHERE farm_id = p_farm_id AND user_id = p_user_id AND role = 'owner'
    );
END;
$$;

-- Drop first to allow changing return type
DROP FUNCTION IF EXISTS public.get_user_farms(UUID) CASCADE;

CREATE OR REPLACE FUNCTION public.get_user_farms(p_user_id UUID DEFAULT auth.uid())
RETURNS TABLE (
    farm_id UUID,
    farm_name TEXT,
    farm_description TEXT,
    user_role TEXT,
    member_count BIGINT,
    joined_at TIMESTAMP WITH TIME ZONE
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    SELECT
        f.id,
        f.name,
        f.description,
        fm.role,
        (SELECT COUNT(*) FROM public.farm_members WHERE farm_id = f.id),
        fm.joined_at
    FROM public.farms f
    JOIN public.farm_members fm ON f.id = fm.farm_id
    WHERE fm.user_id = p_user_id
    ORDER BY fm.joined_at DESC;
END;
$$;

CREATE OR REPLACE FUNCTION public.create_farm(
    p_name TEXT,
    p_description TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_farm_id UUID;
    v_user_id UUID;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    INSERT INTO public.farms (name, description, created_by)
    VALUES (p_name, p_description, v_user_id)
    RETURNING id INTO v_farm_id;

    INSERT INTO public.farm_members (farm_id, user_id, role, invited_by)
    VALUES (v_farm_id, v_user_id, 'owner', v_user_id);

    RETURN v_farm_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.invite_to_farm(
    p_farm_id UUID,
    p_email TEXT,
    p_role TEXT DEFAULT 'editor'
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_invitation_id UUID;
    v_user_id UUID;
    v_existing_user_id UUID;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    IF NOT public.is_farm_owner(p_farm_id, v_user_id) THEN
        RAISE EXCEPTION 'Only farm owners can invite members';
    END IF;

    SELECT u.id INTO v_existing_user_id
    FROM auth.users u
    JOIN public.farm_members fm ON u.id = fm.user_id
    WHERE LOWER(u.email) = LOWER(p_email) AND fm.farm_id = p_farm_id;

    IF v_existing_user_id IS NOT NULL THEN
        RAISE EXCEPTION 'User already has access to this farm';
    END IF;

    INSERT INTO public.farm_invitations (farm_id, email, role, invited_by)
    VALUES (p_farm_id, LOWER(p_email), p_role, v_user_id)
    ON CONFLICT (farm_id, email)
    DO UPDATE SET
        role = EXCLUDED.role,
        invited_by = EXCLUDED.invited_by,
        token = encode(extensions.gen_random_bytes(32), 'hex'),
        expires_at = NOW() + INTERVAL '7 days',
        accepted_at = NULL,
        created_at = NOW()
    RETURNING id INTO v_invitation_id;

    RETURN v_invitation_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.accept_farm_invitation(p_token TEXT)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_invitation RECORD;
    v_user_id UUID;
    v_user_email TEXT;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    SELECT email INTO v_user_email FROM auth.users WHERE id = v_user_id;

    SELECT * INTO v_invitation
    FROM public.farm_invitations
    WHERE token = p_token
      AND LOWER(email) = LOWER(v_user_email)
      AND accepted_at IS NULL
      AND expires_at > NOW();

    IF v_invitation IS NULL THEN
        RAISE EXCEPTION 'Invalid or expired invitation';
    END IF;

    INSERT INTO public.farm_members (farm_id, user_id, role, invited_by)
    VALUES (v_invitation.farm_id, v_user_id, v_invitation.role, v_invitation.invited_by)
    ON CONFLICT (farm_id, user_id) DO NOTHING;

    UPDATE public.farm_invitations
    SET accepted_at = NOW()
    WHERE id = v_invitation.id;

    RETURN v_invitation.farm_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.remove_farm_member(
    p_farm_id UUID,
    p_member_user_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_user_id UUID;
    v_owner_count INT;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    IF NOT public.is_farm_owner(p_farm_id, v_user_id) THEN
        RAISE EXCEPTION 'Only farm owners can remove members';
    END IF;

    SELECT COUNT(*) INTO v_owner_count
    FROM public.farm_members
    WHERE farm_id = p_farm_id AND role = 'owner';

    IF v_owner_count <= 1 AND EXISTS (
        SELECT 1 FROM public.farm_members
        WHERE farm_id = p_farm_id AND user_id = p_member_user_id AND role = 'owner'
    ) THEN
        RAISE EXCEPTION 'Cannot remove the last owner';
    END IF;

    DELETE FROM public.farm_members
    WHERE farm_id = p_farm_id AND user_id = p_member_user_id;

    RETURN TRUE;
END;
$$;

CREATE OR REPLACE FUNCTION public.leave_farm(p_farm_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_user_id UUID;
    v_owner_count INT;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    SELECT COUNT(*) INTO v_owner_count
    FROM public.farm_members
    WHERE farm_id = p_farm_id AND role = 'owner';

    IF v_owner_count <= 1 AND public.is_farm_owner(p_farm_id, v_user_id) THEN
        RAISE EXCEPTION 'Cannot leave as the last owner. Transfer ownership or delete the farm.';
    END IF;

    DELETE FROM public.farm_members
    WHERE farm_id = p_farm_id AND user_id = v_user_id;

    RETURN TRUE;
END;
$$;

CREATE OR REPLACE FUNCTION public.delete_farm(p_farm_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_user_id UUID;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    IF NOT public.is_farm_owner(p_farm_id, v_user_id) THEN
        RAISE EXCEPTION 'Only farm owners can delete the farm';
    END IF;

    DELETE FROM public.farms WHERE id = p_farm_id;

    RETURN TRUE;
END;
$$;

-- Drop first to allow changing return type
DROP FUNCTION IF EXISTS public.get_farm_members(UUID) CASCADE;

CREATE OR REPLACE FUNCTION public.get_farm_members(p_farm_id UUID)
RETURNS TABLE (
    member_id UUID,
    user_id UUID,
    email TEXT,
    display_name TEXT,
    avatar_url TEXT,
    role TEXT,
    joined_at TIMESTAMP WITH TIME ZONE
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF NOT public.is_farm_member(p_farm_id) THEN
        RAISE EXCEPTION 'Not a member of this farm';
    END IF;

    RETURN QUERY
    SELECT
        fm.id,
        fm.user_id,
        u.email,
        up.display_name,
        up.avatar_url,
        fm.role,
        fm.joined_at
    FROM public.farm_members fm
    JOIN auth.users u ON fm.user_id = u.id
    LEFT JOIN public.user_profiles up ON fm.user_id = up.user_id
    WHERE fm.farm_id = p_farm_id
    ORDER BY fm.role DESC, fm.joined_at ASC;
END;
$$;

-- Drop first to allow changing return type
DROP FUNCTION IF EXISTS public.get_farm_invitations(UUID) CASCADE;

CREATE OR REPLACE FUNCTION public.get_farm_invitations(p_farm_id UUID)
RETURNS TABLE (
    invitation_id UUID,
    email TEXT,
    role TEXT,
    invited_by_name TEXT,
    expires_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF NOT public.is_farm_owner(p_farm_id) THEN
        RAISE EXCEPTION 'Only farm owners can view invitations';
    END IF;

    RETURN QUERY
    SELECT
        fi.id,
        fi.email,
        fi.role,
        COALESCE(up.display_name, u.email),
        fi.expires_at,
        fi.created_at
    FROM public.farm_invitations fi
    JOIN auth.users u ON fi.invited_by = u.id
    LEFT JOIN public.user_profiles up ON fi.invited_by = up.user_id
    WHERE fi.farm_id = p_farm_id
      AND fi.accepted_at IS NULL
      AND fi.expires_at > NOW()
    ORDER BY fi.created_at DESC;
END;
$$;

CREATE OR REPLACE FUNCTION public.cancel_farm_invitation(p_invitation_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_user_id UUID;
    v_farm_id UUID;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    SELECT farm_id INTO v_farm_id
    FROM public.farm_invitations
    WHERE id = p_invitation_id;

    IF NOT public.is_farm_owner(v_farm_id, v_user_id) THEN
        RAISE EXCEPTION 'Only farm owners can cancel invitations';
    END IF;

    DELETE FROM public.farm_invitations WHERE id = p_invitation_id;

    RETURN TRUE;
END;
$$;

CREATE OR REPLACE FUNCTION public.migrate_user_to_farm()
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_user_id UUID;
    v_farm_id UUID;
    v_has_data BOOLEAN;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    SELECT farm_id INTO v_farm_id
    FROM public.farm_members
    WHERE user_id = v_user_id
    LIMIT 1;

    IF v_farm_id IS NOT NULL THEN
        RETURN v_farm_id;
    END IF;

    SELECT EXISTS (
        SELECT 1 FROM public.daily_egg_records WHERE user_id = v_user_id AND farm_id IS NULL
        UNION ALL
        SELECT 1 FROM public.egg_sales WHERE user_id = v_user_id AND farm_id IS NULL
        UNION ALL
        SELECT 1 FROM public.egg_reservations WHERE user_id = v_user_id AND farm_id IS NULL
        UNION ALL
        SELECT 1 FROM public.expenses WHERE user_id = v_user_id AND farm_id IS NULL
        UNION ALL
        SELECT 1 FROM public.vet_records WHERE user_id = v_user_id AND farm_id IS NULL
        UNION ALL
        SELECT 1 FROM public.feed_stocks WHERE user_id = v_user_id AND farm_id IS NULL
    ) INTO v_has_data;

    v_farm_id := public.create_farm('Meu Capoeiro', 'Capoeiro pessoal');

    IF v_has_data THEN
        UPDATE public.daily_egg_records SET farm_id = v_farm_id WHERE user_id = v_user_id AND farm_id IS NULL;
        UPDATE public.egg_sales SET farm_id = v_farm_id WHERE user_id = v_user_id AND farm_id IS NULL;
        UPDATE public.egg_reservations SET farm_id = v_farm_id WHERE user_id = v_user_id AND farm_id IS NULL;
        UPDATE public.expenses SET farm_id = v_farm_id WHERE user_id = v_user_id AND farm_id IS NULL;
        UPDATE public.vet_records SET farm_id = v_farm_id WHERE user_id = v_user_id AND farm_id IS NULL;
        UPDATE public.feed_stocks SET farm_id = v_farm_id WHERE user_id = v_user_id AND farm_id IS NULL;
        UPDATE public.feed_movements SET farm_id = v_farm_id WHERE user_id = v_user_id AND farm_id IS NULL;
    END IF;

    RETURN v_farm_id;
END;
$$;

-- ============================================
-- STEP 4: ENABLE RLS ON NEW TABLES
-- ============================================

ALTER TABLE public.farms ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.farm_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.farm_invitations ENABLE ROW LEVEL SECURITY;

-- ============================================
-- STEP 5: CREATE RLS POLICIES (DROP IF EXISTS FIRST)
-- ============================================

DROP POLICY IF EXISTS "Users can view farms they belong to" ON public.farms;
DROP POLICY IF EXISTS "Users can create farms" ON public.farms;
DROP POLICY IF EXISTS "Farm owners can update farm details" ON public.farms;
DROP POLICY IF EXISTS "Farm owners can delete farm" ON public.farms;
DROP POLICY IF EXISTS "Farm members can view other members" ON public.farm_members;
DROP POLICY IF EXISTS "System can manage farm members" ON public.farm_members;
DROP POLICY IF EXISTS "Farm owners can view invitations" ON public.farm_invitations;
DROP POLICY IF EXISTS "Users can view their own invitations" ON public.farm_invitations;

CREATE POLICY "Users can view farms they belong to" ON public.farms
    FOR SELECT USING (public.is_farm_member(id));

CREATE POLICY "Users can create farms" ON public.farms
    FOR INSERT WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Farm owners can update farm details" ON public.farms
    FOR UPDATE USING (public.is_farm_owner(id));

CREATE POLICY "Farm owners can delete farm" ON public.farms
    FOR DELETE USING (public.is_farm_owner(id));

CREATE POLICY "Farm members can view other members" ON public.farm_members
    FOR SELECT USING (public.is_farm_member(farm_id));

CREATE POLICY "System can manage farm members" ON public.farm_members
    FOR ALL USING (auth.uid() IS NOT NULL);

CREATE POLICY "Farm owners can view invitations" ON public.farm_invitations
    FOR SELECT USING (public.is_farm_owner(farm_id));

CREATE POLICY "Users can view their own invitations" ON public.farm_invitations
    FOR SELECT USING (
        email = (SELECT email FROM auth.users WHERE id = auth.uid())
    );

-- ============================================
-- STEP 6: UPDATE RLS POLICIES FOR DATA TABLES
-- ============================================

DROP POLICY IF EXISTS "Users can view their own daily egg records" ON public.daily_egg_records;
DROP POLICY IF EXISTS "Users can insert their own daily egg records" ON public.daily_egg_records;
DROP POLICY IF EXISTS "Users can update their own daily egg records" ON public.daily_egg_records;
DROP POLICY IF EXISTS "Users can delete their own daily egg records" ON public.daily_egg_records;
DROP POLICY IF EXISTS "Farm members can view daily egg records" ON public.daily_egg_records;
DROP POLICY IF EXISTS "Farm members can insert daily egg records" ON public.daily_egg_records;
DROP POLICY IF EXISTS "Farm members can update daily egg records" ON public.daily_egg_records;
DROP POLICY IF EXISTS "Farm members can delete daily egg records" ON public.daily_egg_records;

CREATE POLICY "Farm members can view daily egg records" ON public.daily_egg_records
    FOR SELECT USING (
        farm_id IS NULL AND auth.uid() = user_id
        OR public.is_farm_member(farm_id)
    );

CREATE POLICY "Farm members can insert daily egg records" ON public.daily_egg_records
    FOR INSERT WITH CHECK (
        auth.uid() = user_id
        AND (farm_id IS NULL OR public.is_farm_member(farm_id))
    );

CREATE POLICY "Farm members can update daily egg records" ON public.daily_egg_records
    FOR UPDATE USING (
        farm_id IS NULL AND auth.uid() = user_id
        OR public.is_farm_member(farm_id)
    );

CREATE POLICY "Farm members can delete daily egg records" ON public.daily_egg_records
    FOR DELETE USING (
        farm_id IS NULL AND auth.uid() = user_id
        OR public.is_farm_member(farm_id)
    );

-- egg_sales
DROP POLICY IF EXISTS "Users can view their own egg sales" ON public.egg_sales;
DROP POLICY IF EXISTS "Users can insert their own egg sales" ON public.egg_sales;
DROP POLICY IF EXISTS "Users can update their own egg sales" ON public.egg_sales;
DROP POLICY IF EXISTS "Users can delete their own egg sales" ON public.egg_sales;
DROP POLICY IF EXISTS "Farm members can view egg sales" ON public.egg_sales;
DROP POLICY IF EXISTS "Farm members can insert egg sales" ON public.egg_sales;
DROP POLICY IF EXISTS "Farm members can update egg sales" ON public.egg_sales;
DROP POLICY IF EXISTS "Farm members can delete egg sales" ON public.egg_sales;

CREATE POLICY "Farm members can view egg sales" ON public.egg_sales
    FOR SELECT USING (farm_id IS NULL AND auth.uid() = user_id OR public.is_farm_member(farm_id));

CREATE POLICY "Farm members can insert egg sales" ON public.egg_sales
    FOR INSERT WITH CHECK (auth.uid() = user_id AND (farm_id IS NULL OR public.is_farm_member(farm_id)));

CREATE POLICY "Farm members can update egg sales" ON public.egg_sales
    FOR UPDATE USING (farm_id IS NULL AND auth.uid() = user_id OR public.is_farm_member(farm_id));

CREATE POLICY "Farm members can delete egg sales" ON public.egg_sales
    FOR DELETE USING (farm_id IS NULL AND auth.uid() = user_id OR public.is_farm_member(farm_id));

-- egg_reservations
DROP POLICY IF EXISTS "Users can view their own reservations" ON public.egg_reservations;
DROP POLICY IF EXISTS "Users can insert their own reservations" ON public.egg_reservations;
DROP POLICY IF EXISTS "Users can update their own reservations" ON public.egg_reservations;
DROP POLICY IF EXISTS "Users can delete their own reservations" ON public.egg_reservations;
DROP POLICY IF EXISTS "Farm members can view reservations" ON public.egg_reservations;
DROP POLICY IF EXISTS "Farm members can insert reservations" ON public.egg_reservations;
DROP POLICY IF EXISTS "Farm members can update reservations" ON public.egg_reservations;
DROP POLICY IF EXISTS "Farm members can delete reservations" ON public.egg_reservations;

CREATE POLICY "Farm members can view reservations" ON public.egg_reservations
    FOR SELECT USING (farm_id IS NULL AND auth.uid() = user_id OR public.is_farm_member(farm_id));

CREATE POLICY "Farm members can insert reservations" ON public.egg_reservations
    FOR INSERT WITH CHECK (auth.uid() = user_id AND (farm_id IS NULL OR public.is_farm_member(farm_id)));

CREATE POLICY "Farm members can update reservations" ON public.egg_reservations
    FOR UPDATE USING (farm_id IS NULL AND auth.uid() = user_id OR public.is_farm_member(farm_id));

CREATE POLICY "Farm members can delete reservations" ON public.egg_reservations
    FOR DELETE USING (farm_id IS NULL AND auth.uid() = user_id OR public.is_farm_member(farm_id));

-- expenses
DROP POLICY IF EXISTS "Users can view their own expenses" ON public.expenses;
DROP POLICY IF EXISTS "Users can insert their own expenses" ON public.expenses;
DROP POLICY IF EXISTS "Users can update their own expenses" ON public.expenses;
DROP POLICY IF EXISTS "Users can delete their own expenses" ON public.expenses;
DROP POLICY IF EXISTS "Farm members can view expenses" ON public.expenses;
DROP POLICY IF EXISTS "Farm members can insert expenses" ON public.expenses;
DROP POLICY IF EXISTS "Farm members can update expenses" ON public.expenses;
DROP POLICY IF EXISTS "Farm members can delete expenses" ON public.expenses;

CREATE POLICY "Farm members can view expenses" ON public.expenses
    FOR SELECT USING (farm_id IS NULL AND auth.uid() = user_id OR public.is_farm_member(farm_id));

CREATE POLICY "Farm members can insert expenses" ON public.expenses
    FOR INSERT WITH CHECK (auth.uid() = user_id AND (farm_id IS NULL OR public.is_farm_member(farm_id)));

CREATE POLICY "Farm members can update expenses" ON public.expenses
    FOR UPDATE USING (farm_id IS NULL AND auth.uid() = user_id OR public.is_farm_member(farm_id));

CREATE POLICY "Farm members can delete expenses" ON public.expenses
    FOR DELETE USING (farm_id IS NULL AND auth.uid() = user_id OR public.is_farm_member(farm_id));

-- vet_records
DROP POLICY IF EXISTS "Users can view their own vet records" ON public.vet_records;
DROP POLICY IF EXISTS "Users can insert their own vet records" ON public.vet_records;
DROP POLICY IF EXISTS "Users can update their own vet records" ON public.vet_records;
DROP POLICY IF EXISTS "Users can delete their own vet records" ON public.vet_records;
DROP POLICY IF EXISTS "Farm members can view vet records" ON public.vet_records;
DROP POLICY IF EXISTS "Farm members can insert vet records" ON public.vet_records;
DROP POLICY IF EXISTS "Farm members can update vet records" ON public.vet_records;
DROP POLICY IF EXISTS "Farm members can delete vet records" ON public.vet_records;

CREATE POLICY "Farm members can view vet records" ON public.vet_records
    FOR SELECT USING (farm_id IS NULL AND auth.uid() = user_id OR public.is_farm_member(farm_id));

CREATE POLICY "Farm members can insert vet records" ON public.vet_records
    FOR INSERT WITH CHECK (auth.uid() = user_id AND (farm_id IS NULL OR public.is_farm_member(farm_id)));

CREATE POLICY "Farm members can update vet records" ON public.vet_records
    FOR UPDATE USING (farm_id IS NULL AND auth.uid() = user_id OR public.is_farm_member(farm_id));

CREATE POLICY "Farm members can delete vet records" ON public.vet_records
    FOR DELETE USING (farm_id IS NULL AND auth.uid() = user_id OR public.is_farm_member(farm_id));

-- feed_stocks
DROP POLICY IF EXISTS "Users can view their own feed stocks" ON public.feed_stocks;
DROP POLICY IF EXISTS "Users can insert their own feed stocks" ON public.feed_stocks;
DROP POLICY IF EXISTS "Users can update their own feed stocks" ON public.feed_stocks;
DROP POLICY IF EXISTS "Users can delete their own feed stocks" ON public.feed_stocks;
DROP POLICY IF EXISTS "Farm members can view feed stocks" ON public.feed_stocks;
DROP POLICY IF EXISTS "Farm members can insert feed stocks" ON public.feed_stocks;
DROP POLICY IF EXISTS "Farm members can update feed stocks" ON public.feed_stocks;
DROP POLICY IF EXISTS "Farm members can delete feed stocks" ON public.feed_stocks;

CREATE POLICY "Farm members can view feed stocks" ON public.feed_stocks
    FOR SELECT USING (farm_id IS NULL AND auth.uid() = user_id OR public.is_farm_member(farm_id));

CREATE POLICY "Farm members can insert feed stocks" ON public.feed_stocks
    FOR INSERT WITH CHECK (auth.uid() = user_id AND (farm_id IS NULL OR public.is_farm_member(farm_id)));

CREATE POLICY "Farm members can update feed stocks" ON public.feed_stocks
    FOR UPDATE USING (farm_id IS NULL AND auth.uid() = user_id OR public.is_farm_member(farm_id));

CREATE POLICY "Farm members can delete feed stocks" ON public.feed_stocks
    FOR DELETE USING (farm_id IS NULL AND auth.uid() = user_id OR public.is_farm_member(farm_id));

-- feed_movements
DROP POLICY IF EXISTS "Users can view their own feed movements" ON public.feed_movements;
DROP POLICY IF EXISTS "Users can insert their own feed movements" ON public.feed_movements;
DROP POLICY IF EXISTS "Users can update their own feed movements" ON public.feed_movements;
DROP POLICY IF EXISTS "Users can delete their own feed movements" ON public.feed_movements;
DROP POLICY IF EXISTS "Farm members can view feed movements" ON public.feed_movements;
DROP POLICY IF EXISTS "Farm members can insert feed movements" ON public.feed_movements;
DROP POLICY IF EXISTS "Farm members can update feed movements" ON public.feed_movements;
DROP POLICY IF EXISTS "Farm members can delete feed movements" ON public.feed_movements;

CREATE POLICY "Farm members can view feed movements" ON public.feed_movements
    FOR SELECT USING (farm_id IS NULL AND auth.uid() = user_id OR public.is_farm_member(farm_id));

CREATE POLICY "Farm members can insert feed movements" ON public.feed_movements
    FOR INSERT WITH CHECK (auth.uid() = user_id AND (farm_id IS NULL OR public.is_farm_member(farm_id)));

CREATE POLICY "Farm members can update feed movements" ON public.feed_movements
    FOR UPDATE USING (farm_id IS NULL AND auth.uid() = user_id OR public.is_farm_member(farm_id));

CREATE POLICY "Farm members can delete feed movements" ON public.feed_movements
    FOR DELETE USING (farm_id IS NULL AND auth.uid() = user_id OR public.is_farm_member(farm_id));

-- ============================================
-- STEP 7: CREATE TRIGGER
-- ============================================

DROP TRIGGER IF EXISTS update_farms_updated_at ON public.farms;
CREATE TRIGGER update_farms_updated_at
    BEFORE UPDATE ON public.farms
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- STEP 8: GRANT PERMISSIONS
-- ============================================

GRANT SELECT, INSERT, UPDATE, DELETE ON public.farms TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.farm_members TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.farm_invitations TO authenticated;

GRANT EXECUTE ON FUNCTION public.is_farm_member(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_farm_owner(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_farms(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_farm(TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.invite_to_farm(UUID, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.accept_farm_invitation(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.remove_farm_member(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.leave_farm(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.delete_farm(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_farm_members(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_farm_invitations(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.cancel_farm_invitation(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.migrate_user_to_farm() TO authenticated;

-- ============================================
-- DONE!
-- ============================================
SELECT 'Multi-User Farm Support installed successfully!' as status;
