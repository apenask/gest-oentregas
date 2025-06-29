/*
  # Fix perfis table INSERT policy for user registration

  1. Policy Changes
    - Drop the existing restrictive INSERT policy on perfis table
    - Create a new INSERT policy that allows authenticated users to create their own profile
    - The policy uses auth.uid() = id to ensure users can only create their own profile

  2. Security
    - Maintains security by ensuring users can only insert their own profile data
    - Uses Supabase's built-in auth.uid() function for proper user identification
*/

-- Drop the existing INSERT policy that's causing issues
DROP POLICY IF EXISTS "Permitir inserção de perfis" ON perfis;

-- Create a new INSERT policy that properly allows user registration
CREATE POLICY "Allow users to insert their own profile"
  ON perfis
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);