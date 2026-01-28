-- Migration: Add delete_user_account function
-- This function allows users to delete their own account from auth.users
-- Run this in your Supabase SQL Editor

-- Create a function that allows authenticated users to delete their own account
CREATE OR REPLACE FUNCTION public.delete_user_account()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  current_user_id uuid;
BEGIN
  -- Get the current user's ID
  current_user_id := auth.uid();

  IF current_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- Delete the user from auth.users
  -- This will cascade delete any related data if configured
  DELETE FROM auth.users WHERE id = current_user_id;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.delete_user_account() TO authenticated;

-- Add a comment explaining the function
COMMENT ON FUNCTION public.delete_user_account() IS
'Allows authenticated users to permanently delete their own account.
This deletes the user from auth.users. Make sure to delete user data
from other tables before calling this function.';
