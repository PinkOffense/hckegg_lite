-- ============================================
-- HCKEgg Lite - Multi-User Farm Support
-- ============================================
-- Migration: Add farms, farm_members, farm_invitations
-- Enables multiple users to share access to the same farm
-- ============================================
-- Version: 1.0
-- Date: 2026-02-20
-- ============================================
--
-- CHANGES:
--   1. New tables: farms, farm_members, farm_invitations
--   2. Add farm_id to all data tables
--   3. New RLS policies based on farm membership
--   4. Functions for farm management and invitations
--
-- ROLES:
--   - owner: Full access, can delete farm, manage all members
--   - editor: Can create/edit/delete records (no member management)
--
-- ============================================

-- ============================================
-- STEP 0: ENABLE REQUIRED EXTENSIONS
-- ============================================

-- pgcrypto is needed for gen_random_bytes() used in invitation tokens
-- On Supabase, extensions may live in the 'extensions' schema
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ============================================
-- STEP 1: CREATE FARM TABLES
-- ============================================

-- Farms table (capoeiros)
CREATE TABLE IF NOT EXISTS public.farms (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    description TEXT,
    created_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_farms_created_by ON public.farms(created_by);

COMMENT ON TABLE public.farms IS 'Farms/chicken coops that can be shared between multiple users';

-- Farm members table (roles: owner, editor)
CREATE TABLE IF NOT EXISTS public.farm_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    farm_id UUID NOT NULL REFERENCES public.farms(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    role TEXT NOT NULL DEFAULT 'editor' CHECK (role IN ('owner', 'editor')),
    invited_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(farm_id, user_id)
);

CREATE INDEX idx_farm_members_farm ON public.farm_members(farm_id);
CREATE INDEX idx_farm_members_user ON public.farm_members(user_id);

COMMENT ON TABLE public.farm_members IS 'Farm membership with roles (owner/editor)';
COMMENT ON COLUMN public.farm_members.role IS 'Role: owner (full access) or editor (CRUD on records)';

-- Farm invitations table
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

CREATE INDEX idx_farm_invitations_email ON public.farm_invitations(email);
CREATE INDEX idx_farm_invitations_token ON public.farm_invitations(token);
CREATE INDEX idx_farm_invitations_farm ON public.farm_invitations(farm_id);

COMMENT ON TABLE public.farm_invitations IS 'Pending invitations to join a farm';
COMMENT ON COLUMN public.farm_invitations.token IS 'Unique token for accepting invitation via link';
COMMENT ON COLUMN public.farm_invitations.expires_at IS 'Invitation expires after 7 days';

-- ============================================
-- STEP 2: ADD farm_id TO EXISTING TABLES
-- ============================================

-- Add farm_id column to all data tables (nullable for backwards compatibility)
ALTER TABLE public.daily_egg_records
    ADD COLUMN IF NOT EXISTS farm_id UUID REFERENCES public.farms(id) ON DELETE CASCADE;

ALTER TABLE public.egg_sales
    ADD COLUMN IF NOT EXISTS farm_id UUID REFERENCES public.farms(id) ON DELETE CASCADE;

ALTER TABLE public.egg_reservations
    ADD COLUMN IF NOT EXISTS farm_id UUID REFERENCES public.farms(id) ON DELETE CASCADE;

ALTER TABLE public.expenses
    ADD COLUMN IF NOT EXISTS farm_id UUID REFERENCES public.farms(id) ON DELETE CASCADE;

ALTER TABLE public.vet_records
    ADD COLUMN IF NOT EXISTS farm_id UUID REFERENCES public.farms(id) ON DELETE CASCADE;

ALTER TABLE public.feed_stocks
    ADD COLUMN IF NOT EXISTS farm_id UUID REFERENCES public.farms(id) ON DELETE CASCADE;

ALTER TABLE public.feed_movements
    ADD COLUMN IF NOT EXISTS farm_id UUID REFERENCES public.farms(id) ON DELETE CASCADE;

-- Create indexes for farm_id
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

-- Function to check if user is member of a farm
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

-- Function to check if user is owner of a farm
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

-- Function to get user's farms
-- NOTE: Return column names must NOT conflict with table column names
-- to avoid "column reference is ambiguous" errors in subqueries.
CREATE OR REPLACE FUNCTION public.get_user_farms(p_user_id UUID DEFAULT auth.uid())
RETURNS TABLE (
    id UUID,
    name TEXT,
    description TEXT,
    created_by UUID,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE,
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
        f.created_by,
        f.created_at,
        f.updated_at,
        fm.role,
        (SELECT COUNT(*) FROM public.farm_members sub_fm WHERE sub_fm.farm_id = f.id),
        fm.joined_at
    FROM public.farms f
    JOIN public.farm_members fm ON f.id = fm.farm_id
    WHERE fm.user_id = p_user_id
    ORDER BY fm.joined_at DESC;
END;
$$;

-- Function to create a new farm (creator becomes owner)
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

    -- Create the farm
    INSERT INTO public.farms (name, description, created_by)
    VALUES (p_name, p_description, v_user_id)
    RETURNING id INTO v_farm_id;

    -- Add creator as owner
    INSERT INTO public.farm_members (farm_id, user_id, role, invited_by)
    VALUES (v_farm_id, v_user_id, 'owner', v_user_id);

    RETURN v_farm_id;
END;
$$;

-- Function to invite user to farm by email
CREATE OR REPLACE FUNCTION public.invite_to_farm(
    p_farm_id UUID,
    p_email TEXT,
    p_role TEXT DEFAULT 'editor'
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
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

    -- Check if user is owner of the farm
    IF NOT public.is_farm_owner(p_farm_id, v_user_id) THEN
        RAISE EXCEPTION 'Only farm owners can invite members';
    END IF;

    -- Check if email already has access
    SELECT u.id INTO v_existing_user_id
    FROM auth.users u
    JOIN public.farm_members fm ON u.id = fm.user_id
    WHERE u.email = p_email AND fm.farm_id = p_farm_id;

    IF v_existing_user_id IS NOT NULL THEN
        RAISE EXCEPTION 'User already has access to this farm';
    END IF;

    -- Create or update invitation
    INSERT INTO public.farm_invitations (farm_id, email, role, invited_by)
    VALUES (p_farm_id, p_email, p_role, v_user_id)
    ON CONFLICT (farm_id, email)
    DO UPDATE SET
        role = EXCLUDED.role,
        invited_by = EXCLUDED.invited_by,
        token = encode(gen_random_bytes(32), 'hex'),
        expires_at = NOW() + INTERVAL '7 days',
        accepted_at = NULL,
        created_at = NOW()
    RETURNING id INTO v_invitation_id;

    RETURN v_invitation_id;
END;
$$;

-- Function to accept invitation (called after user signs up/in)
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

    -- Get user's email
    SELECT email INTO v_user_email FROM auth.users WHERE id = v_user_id;

    -- Find valid invitation
    SELECT * INTO v_invitation
    FROM public.farm_invitations
    WHERE token = p_token
      AND email = v_user_email
      AND accepted_at IS NULL
      AND expires_at > NOW();

    IF v_invitation IS NULL THEN
        RAISE EXCEPTION 'Invalid or expired invitation';
    END IF;

    -- Add user as farm member
    INSERT INTO public.farm_members (farm_id, user_id, role, invited_by)
    VALUES (v_invitation.farm_id, v_user_id, v_invitation.role, v_invitation.invited_by)
    ON CONFLICT (farm_id, user_id) DO NOTHING;

    -- Mark invitation as accepted
    UPDATE public.farm_invitations
    SET accepted_at = NOW()
    WHERE id = v_invitation.id;

    RETURN v_invitation.farm_id;
END;
$$;

-- Function to remove member from farm
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

    -- Check if user is owner
    IF NOT public.is_farm_owner(p_farm_id, v_user_id) THEN
        RAISE EXCEPTION 'Only farm owners can remove members';
    END IF;

    -- Prevent removing the last owner
    SELECT COUNT(*) INTO v_owner_count
    FROM public.farm_members
    WHERE farm_id = p_farm_id AND role = 'owner';

    IF v_owner_count <= 1 AND EXISTS (
        SELECT 1 FROM public.farm_members
        WHERE farm_id = p_farm_id AND user_id = p_member_user_id AND role = 'owner'
    ) THEN
        RAISE EXCEPTION 'Cannot remove the last owner';
    END IF;

    -- Remove member
    DELETE FROM public.farm_members
    WHERE farm_id = p_farm_id AND user_id = p_member_user_id;

    RETURN TRUE;
END;
$$;

-- Function to leave a farm
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

    -- Prevent last owner from leaving
    SELECT COUNT(*) INTO v_owner_count
    FROM public.farm_members
    WHERE farm_id = p_farm_id AND role = 'owner';

    IF v_owner_count <= 1 AND public.is_farm_owner(p_farm_id, v_user_id) THEN
        RAISE EXCEPTION 'Cannot leave as the last owner. Transfer ownership or delete the farm.';
    END IF;

    -- Leave farm
    DELETE FROM public.farm_members
    WHERE farm_id = p_farm_id AND user_id = v_user_id;

    RETURN TRUE;
END;
$$;

-- Function to delete farm (owner only)
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

    -- Check if user is owner
    IF NOT public.is_farm_owner(p_farm_id, v_user_id) THEN
        RAISE EXCEPTION 'Only farm owners can delete the farm';
    END IF;

    -- Delete farm (cascades to members, invitations, and all data)
    DELETE FROM public.farms WHERE id = p_farm_id;

    RETURN TRUE;
END;
$$;

-- Function to get farm members
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
    -- Check if user is member of the farm
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

-- Function to get pending invitations for a farm
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
    -- Check if user is owner of the farm
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

-- Function to cancel invitation
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

    -- Get farm_id from invitation
    SELECT farm_id INTO v_farm_id
    FROM public.farm_invitations
    WHERE id = p_invitation_id;

    -- Check if user is owner
    IF NOT public.is_farm_owner(v_farm_id, v_user_id) THEN
        RAISE EXCEPTION 'Only farm owners can cancel invitations';
    END IF;

    -- Delete invitation
    DELETE FROM public.farm_invitations WHERE id = p_invitation_id;

    RETURN TRUE;
END;
$$;

-- ============================================
-- STEP 4: ENABLE RLS ON NEW TABLES
-- ============================================

ALTER TABLE public.farms ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.farm_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.farm_invitations ENABLE ROW LEVEL SECURITY;

-- ============================================
-- STEP 5: CREATE RLS POLICIES FOR NEW TABLES
-- ============================================

-- Farms policies (users can only see farms they're members of)
CREATE POLICY "Users can view farms they belong to" ON public.farms
    FOR SELECT USING (public.is_farm_member(id));

CREATE POLICY "Users can create farms" ON public.farms
    FOR INSERT WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Farm owners can update farm details" ON public.farms
    FOR UPDATE USING (public.is_farm_owner(id));

CREATE POLICY "Farm owners can delete farm" ON public.farms
    FOR DELETE USING (public.is_farm_owner(id));

-- Farm members policies
CREATE POLICY "Farm members can view other members" ON public.farm_members
    FOR SELECT USING (public.is_farm_member(farm_id));

-- Handled by functions, not direct insert
CREATE POLICY "System can manage farm members" ON public.farm_members
    FOR ALL USING (auth.uid() IS NOT NULL);

-- Farm invitations policies
CREATE POLICY "Farm owners can view invitations" ON public.farm_invitations
    FOR SELECT USING (public.is_farm_owner(farm_id));

CREATE POLICY "Users can view their own invitations" ON public.farm_invitations
    FOR SELECT USING (
        email = (SELECT email FROM auth.users WHERE id = auth.uid())
    );

-- ============================================
-- STEP 6: UPDATE RLS POLICIES FOR DATA TABLES
-- ============================================

-- Drop old user-based policies
DROP POLICY IF EXISTS "Users can view their own daily egg records" ON public.daily_egg_records;
DROP POLICY IF EXISTS "Users can insert their own daily egg records" ON public.daily_egg_records;
DROP POLICY IF EXISTS "Users can update their own daily egg records" ON public.daily_egg_records;
DROP POLICY IF EXISTS "Users can delete their own daily egg records" ON public.daily_egg_records;

DROP POLICY IF EXISTS "Users can view their own egg sales" ON public.egg_sales;
DROP POLICY IF EXISTS "Users can insert their own egg sales" ON public.egg_sales;
DROP POLICY IF EXISTS "Users can update their own egg sales" ON public.egg_sales;
DROP POLICY IF EXISTS "Users can delete their own egg sales" ON public.egg_sales;

DROP POLICY IF EXISTS "Users can view their own reservations" ON public.egg_reservations;
DROP POLICY IF EXISTS "Users can insert their own reservations" ON public.egg_reservations;
DROP POLICY IF EXISTS "Users can update their own reservations" ON public.egg_reservations;
DROP POLICY IF EXISTS "Users can delete their own reservations" ON public.egg_reservations;

DROP POLICY IF EXISTS "Users can view their own expenses" ON public.expenses;
DROP POLICY IF EXISTS "Users can insert their own expenses" ON public.expenses;
DROP POLICY IF EXISTS "Users can update their own expenses" ON public.expenses;
DROP POLICY IF EXISTS "Users can delete their own expenses" ON public.expenses;

DROP POLICY IF EXISTS "Users can view their own vet records" ON public.vet_records;
DROP POLICY IF EXISTS "Users can insert their own vet records" ON public.vet_records;
DROP POLICY IF EXISTS "Users can update their own vet records" ON public.vet_records;
DROP POLICY IF EXISTS "Users can delete their own vet records" ON public.vet_records;

DROP POLICY IF EXISTS "Users can view their own feed stocks" ON public.feed_stocks;
DROP POLICY IF EXISTS "Users can insert their own feed stocks" ON public.feed_stocks;
DROP POLICY IF EXISTS "Users can update their own feed stocks" ON public.feed_stocks;
DROP POLICY IF EXISTS "Users can delete their own feed stocks" ON public.feed_stocks;

DROP POLICY IF EXISTS "Users can view their own feed movements" ON public.feed_movements;
DROP POLICY IF EXISTS "Users can insert their own feed movements" ON public.feed_movements;
DROP POLICY IF EXISTS "Users can update their own feed movements" ON public.feed_movements;
DROP POLICY IF EXISTS "Users can delete their own feed movements" ON public.feed_movements;

-- Create new farm-based policies for daily_egg_records
CREATE POLICY "Farm members can view daily egg records" ON public.daily_egg_records
    FOR SELECT USING (
        farm_id IS NULL AND auth.uid() = user_id  -- Legacy data
        OR public.is_farm_member(farm_id)          -- Farm data
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

-- Create new farm-based policies for egg_sales
CREATE POLICY "Farm members can view egg sales" ON public.egg_sales
    FOR SELECT USING (
        farm_id IS NULL AND auth.uid() = user_id
        OR public.is_farm_member(farm_id)
    );

CREATE POLICY "Farm members can insert egg sales" ON public.egg_sales
    FOR INSERT WITH CHECK (
        auth.uid() = user_id
        AND (farm_id IS NULL OR public.is_farm_member(farm_id))
    );

CREATE POLICY "Farm members can update egg sales" ON public.egg_sales
    FOR UPDATE USING (
        farm_id IS NULL AND auth.uid() = user_id
        OR public.is_farm_member(farm_id)
    );

CREATE POLICY "Farm members can delete egg sales" ON public.egg_sales
    FOR DELETE USING (
        farm_id IS NULL AND auth.uid() = user_id
        OR public.is_farm_member(farm_id)
    );

-- Create new farm-based policies for egg_reservations
CREATE POLICY "Farm members can view reservations" ON public.egg_reservations
    FOR SELECT USING (
        farm_id IS NULL AND auth.uid() = user_id
        OR public.is_farm_member(farm_id)
    );

CREATE POLICY "Farm members can insert reservations" ON public.egg_reservations
    FOR INSERT WITH CHECK (
        auth.uid() = user_id
        AND (farm_id IS NULL OR public.is_farm_member(farm_id))
    );

CREATE POLICY "Farm members can update reservations" ON public.egg_reservations
    FOR UPDATE USING (
        farm_id IS NULL AND auth.uid() = user_id
        OR public.is_farm_member(farm_id)
    );

CREATE POLICY "Farm members can delete reservations" ON public.egg_reservations
    FOR DELETE USING (
        farm_id IS NULL AND auth.uid() = user_id
        OR public.is_farm_member(farm_id)
    );

-- Create new farm-based policies for expenses
CREATE POLICY "Farm members can view expenses" ON public.expenses
    FOR SELECT USING (
        farm_id IS NULL AND auth.uid() = user_id
        OR public.is_farm_member(farm_id)
    );

CREATE POLICY "Farm members can insert expenses" ON public.expenses
    FOR INSERT WITH CHECK (
        auth.uid() = user_id
        AND (farm_id IS NULL OR public.is_farm_member(farm_id))
    );

CREATE POLICY "Farm members can update expenses" ON public.expenses
    FOR UPDATE USING (
        farm_id IS NULL AND auth.uid() = user_id
        OR public.is_farm_member(farm_id)
    );

CREATE POLICY "Farm members can delete expenses" ON public.expenses
    FOR DELETE USING (
        farm_id IS NULL AND auth.uid() = user_id
        OR public.is_farm_member(farm_id)
    );

-- Create new farm-based policies for vet_records
CREATE POLICY "Farm members can view vet records" ON public.vet_records
    FOR SELECT USING (
        farm_id IS NULL AND auth.uid() = user_id
        OR public.is_farm_member(farm_id)
    );

CREATE POLICY "Farm members can insert vet records" ON public.vet_records
    FOR INSERT WITH CHECK (
        auth.uid() = user_id
        AND (farm_id IS NULL OR public.is_farm_member(farm_id))
    );

CREATE POLICY "Farm members can update vet records" ON public.vet_records
    FOR UPDATE USING (
        farm_id IS NULL AND auth.uid() = user_id
        OR public.is_farm_member(farm_id)
    );

CREATE POLICY "Farm members can delete vet records" ON public.vet_records
    FOR DELETE USING (
        farm_id IS NULL AND auth.uid() = user_id
        OR public.is_farm_member(farm_id)
    );

-- Create new farm-based policies for feed_stocks
CREATE POLICY "Farm members can view feed stocks" ON public.feed_stocks
    FOR SELECT USING (
        farm_id IS NULL AND auth.uid() = user_id
        OR public.is_farm_member(farm_id)
    );

CREATE POLICY "Farm members can insert feed stocks" ON public.feed_stocks
    FOR INSERT WITH CHECK (
        auth.uid() = user_id
        AND (farm_id IS NULL OR public.is_farm_member(farm_id))
    );

CREATE POLICY "Farm members can update feed stocks" ON public.feed_stocks
    FOR UPDATE USING (
        farm_id IS NULL AND auth.uid() = user_id
        OR public.is_farm_member(farm_id)
    );

CREATE POLICY "Farm members can delete feed stocks" ON public.feed_stocks
    FOR DELETE USING (
        farm_id IS NULL AND auth.uid() = user_id
        OR public.is_farm_member(farm_id)
    );

-- Create new farm-based policies for feed_movements
CREATE POLICY "Farm members can view feed movements" ON public.feed_movements
    FOR SELECT USING (
        farm_id IS NULL AND auth.uid() = user_id
        OR public.is_farm_member(farm_id)
    );

CREATE POLICY "Farm members can insert feed movements" ON public.feed_movements
    FOR INSERT WITH CHECK (
        auth.uid() = user_id
        AND (farm_id IS NULL OR public.is_farm_member(farm_id))
    );

CREATE POLICY "Farm members can update feed movements" ON public.feed_movements
    FOR UPDATE USING (
        farm_id IS NULL AND auth.uid() = user_id
        OR public.is_farm_member(farm_id)
    );

CREATE POLICY "Farm members can delete feed movements" ON public.feed_movements
    FOR DELETE USING (
        farm_id IS NULL AND auth.uid() = user_id
        OR public.is_farm_member(farm_id)
    );

-- ============================================
-- STEP 7: CREATE TRIGGERS
-- ============================================

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

-- ============================================
-- STEP 9: MIGRATION HELPER - Auto-create farm for existing users
-- ============================================

-- Function to migrate existing user data to a personal farm
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

    -- Check if user already has a farm
    SELECT farm_id INTO v_farm_id
    FROM public.farm_members
    WHERE user_id = v_user_id
    LIMIT 1;

    IF v_farm_id IS NOT NULL THEN
        RETURN v_farm_id;  -- Already has a farm
    END IF;

    -- Check if user has any existing data (without farm_id)
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

    -- Create a personal farm
    v_farm_id := public.create_farm('Meu Capoeiro', 'Capoeiro pessoal');

    -- Migrate existing data to the new farm
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

GRANT EXECUTE ON FUNCTION public.migrate_user_to_farm() TO authenticated;

-- ============================================
-- COMPLETION MESSAGE
-- ============================================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '================================================';
    RAISE NOTICE '  Multi-User Farm Support - Migration Complete!';
    RAISE NOTICE '================================================';
    RAISE NOTICE '';
    RAISE NOTICE 'New tables:';
    RAISE NOTICE '  * farms             - Chicken coops/farms';
    RAISE NOTICE '  * farm_members      - User memberships with roles';
    RAISE NOTICE '  * farm_invitations  - Pending email invitations';
    RAISE NOTICE '';
    RAISE NOTICE 'New functions:';
    RAISE NOTICE '  * create_farm()           - Create new farm';
    RAISE NOTICE '  * invite_to_farm()        - Invite user by email';
    RAISE NOTICE '  * accept_farm_invitation()- Accept invitation';
    RAISE NOTICE '  * get_user_farms()        - List user farms';
    RAISE NOTICE '  * get_farm_members()      - List farm members';
    RAISE NOTICE '  * remove_farm_member()    - Remove a member';
    RAISE NOTICE '  * leave_farm()            - Leave a farm';
    RAISE NOTICE '  * delete_farm()           - Delete farm (owner)';
    RAISE NOTICE '  * migrate_user_to_farm()  - Migrate existing data';
    RAISE NOTICE '';
    RAISE NOTICE 'Roles:';
    RAISE NOTICE '  * owner  - Full access + member management';
    RAISE NOTICE '  * editor - CRUD on all records';
    RAISE NOTICE '';
    RAISE NOTICE 'Next steps:';
    RAISE NOTICE '  1. Update Flutter app with farm support';
    RAISE NOTICE '  2. Call migrate_user_to_farm() on app startup';
    RAISE NOTICE '  3. Add farm switcher UI';
    RAISE NOTICE '================================================';
END $$;
