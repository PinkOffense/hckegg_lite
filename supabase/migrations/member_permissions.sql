-- ============================================
-- HCKEgg Lite - Member Permissions System
-- ============================================
-- Migration: Add granular permissions per member
-- Allows farm owners to control what each member can see/edit
-- ============================================
-- Version: 1.0
-- Date: 2026-02-21
-- ============================================
--
-- PERMISSIONS STRUCTURE (JSONB):
-- {
--   "eggs": {"view": true, "edit": true},
--   "health": {"view": true, "edit": true},
--   "feed": {"view": true, "edit": true},
--   "sales": {"view": true, "edit": true},
--   "expenses": {"view": true, "edit": true},
--   "reservations": {"view": true, "edit": true},
--   "analytics": {"view": true}
-- }
--
-- NOTE: Owners always have full access regardless of permissions field
-- ============================================

-- ============================================
-- STEP 1: ADD PERMISSIONS COLUMN
-- ============================================

-- Add permissions JSONB column to farm_members
ALTER TABLE public.farm_members
ADD COLUMN IF NOT EXISTS permissions JSONB DEFAULT '{
  "eggs": {"view": true, "edit": true},
  "health": {"view": true, "edit": true},
  "feed": {"view": true, "edit": true},
  "sales": {"view": true, "edit": true},
  "expenses": {"view": true, "edit": true},
  "reservations": {"view": true, "edit": true},
  "analytics": {"view": true}
}'::jsonb;

COMMENT ON COLUMN public.farm_members.permissions IS 'Granular permissions for each feature (view/edit). Owners have full access regardless.';

-- ============================================
-- STEP 2: CREATE HELPER FUNCTIONS
-- ============================================

-- Function to get default permissions (all enabled)
CREATE OR REPLACE FUNCTION public.get_default_permissions()
RETURNS JSONB
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT '{
    "eggs": {"view": true, "edit": true},
    "health": {"view": true, "edit": true},
    "feed": {"view": true, "edit": true},
    "sales": {"view": true, "edit": true},
    "expenses": {"view": true, "edit": true},
    "reservations": {"view": true, "edit": true},
    "analytics": {"view": true}
  }'::jsonb;
$$;

-- Function to check if user has permission for a feature
CREATE OR REPLACE FUNCTION public.has_permission(
    p_farm_id UUID,
    p_feature TEXT,
    p_action TEXT DEFAULT 'view',
    p_user_id UUID DEFAULT auth.uid()
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_role TEXT;
    v_permissions JSONB;
BEGIN
    -- Get member role and permissions
    SELECT role, COALESCE(permissions, get_default_permissions())
    INTO v_role, v_permissions
    FROM public.farm_members
    WHERE farm_id = p_farm_id AND user_id = p_user_id;

    -- Not a member
    IF v_role IS NULL THEN
        RETURN FALSE;
    END IF;

    -- Owners always have full access
    IF v_role = 'owner' THEN
        RETURN TRUE;
    END IF;

    -- Check specific permission
    RETURN COALESCE(
        (v_permissions -> p_feature ->> p_action)::boolean,
        TRUE  -- Default to true if not specified
    );
END;
$$;

-- Function to update member permissions (owner only)
CREATE OR REPLACE FUNCTION public.update_member_permissions(
    p_farm_id UUID,
    p_member_user_id UUID,
    p_permissions JSONB
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_user_id UUID;
    v_member_role TEXT;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- Check if current user is owner
    IF NOT public.is_farm_owner(p_farm_id, v_user_id) THEN
        RAISE EXCEPTION 'Only farm owners can update member permissions';
    END IF;

    -- Check target member role - cannot change owner permissions
    SELECT role INTO v_member_role
    FROM public.farm_members
    WHERE farm_id = p_farm_id AND user_id = p_member_user_id;

    IF v_member_role IS NULL THEN
        RAISE EXCEPTION 'Member not found';
    END IF;

    IF v_member_role = 'owner' THEN
        RAISE EXCEPTION 'Cannot modify owner permissions';
    END IF;

    -- Update permissions
    UPDATE public.farm_members
    SET permissions = p_permissions
    WHERE farm_id = p_farm_id AND user_id = p_member_user_id;

    RETURN TRUE;
END;
$$;

-- Function to get member permissions
CREATE OR REPLACE FUNCTION public.get_member_permissions(
    p_farm_id UUID,
    p_member_user_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_user_id UUID;
    v_permissions JSONB;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- Check if current user is member of the farm
    IF NOT public.is_farm_member(p_farm_id, v_user_id) THEN
        RAISE EXCEPTION 'Not a member of this farm';
    END IF;

    -- Get permissions
    SELECT COALESCE(permissions, get_default_permissions())
    INTO v_permissions
    FROM public.farm_members
    WHERE farm_id = p_farm_id AND user_id = p_member_user_id;

    RETURN v_permissions;
END;
$$;

-- ============================================
-- STEP 3: UPDATE get_farm_members TO INCLUDE PERMISSIONS
-- ============================================

-- Drop and recreate get_farm_members with permissions
DROP FUNCTION IF EXISTS public.get_farm_members(UUID);

CREATE OR REPLACE FUNCTION public.get_farm_members(p_farm_id UUID)
RETURNS TABLE (
    member_id UUID,
    user_id UUID,
    email TEXT,
    display_name TEXT,
    avatar_url TEXT,
    role TEXT,
    joined_at TIMESTAMP WITH TIME ZONE,
    permissions JSONB
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
        fm.joined_at,
        COALESCE(fm.permissions, public.get_default_permissions())
    FROM public.farm_members fm
    JOIN auth.users u ON fm.user_id = u.id
    LEFT JOIN public.user_profiles up ON fm.user_id = up.user_id
    WHERE fm.farm_id = p_farm_id
    ORDER BY fm.role DESC, fm.joined_at ASC;
END;
$$;

-- ============================================
-- STEP 4: GRANT PERMISSIONS
-- ============================================

GRANT EXECUTE ON FUNCTION public.get_default_permissions() TO authenticated;
GRANT EXECUTE ON FUNCTION public.has_permission(UUID, TEXT, TEXT, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_member_permissions(UUID, UUID, JSONB) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_member_permissions(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_farm_members(UUID) TO authenticated;

-- ============================================
-- COMPLETION MESSAGE
-- ============================================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '================================================';
    RAISE NOTICE '  Member Permissions System - Migration Complete!';
    RAISE NOTICE '================================================';
    RAISE NOTICE '';
    RAISE NOTICE 'New column:';
    RAISE NOTICE '  * farm_members.permissions (JSONB)';
    RAISE NOTICE '';
    RAISE NOTICE 'New functions:';
    RAISE NOTICE '  * get_default_permissions()    - Default permission set';
    RAISE NOTICE '  * has_permission()             - Check user permission';
    RAISE NOTICE '  * update_member_permissions()  - Update member permissions';
    RAISE NOTICE '  * get_member_permissions()     - Get member permissions';
    RAISE NOTICE '';
    RAISE NOTICE 'Features controlled:';
    RAISE NOTICE '  * eggs         - Egg records';
    RAISE NOTICE '  * health       - Vet/health records';
    RAISE NOTICE '  * feed         - Feed stock & movements';
    RAISE NOTICE '  * sales        - Egg sales';
    RAISE NOTICE '  * expenses     - Expenses';
    RAISE NOTICE '  * reservations - Egg reservations';
    RAISE NOTICE '  * analytics    - Dashboard/analytics (view only)';
    RAISE NOTICE '================================================';
END $$;
