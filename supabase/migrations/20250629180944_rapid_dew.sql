/*
  # Fix perfis table INSERT policy for user signup

  1. Security Changes
    - Drop the existing restrictive INSERT policy on perfis table
    - Create a new INSERT policy that allows profile creation during signup
    - The policy allows inserts where the user ID matches the authenticated user ID
    - This enables the signup process to work properly while maintaining security

  2. Policy Details
    - Policy name: "Allow users to create their own profile during signup"
    - Allows INSERT operations for authenticated users
    - Uses auth.uid() = id to ensure users can only create their own profile
    - Removes the overly restrictive with_check condition from the previous policy
*/

-- Drop the existing INSERT policy that's too restrictive
DROP POLICY IF EXISTS "Allow users to insert their own profile" ON perfis;

-- Create a new INSERT policy that allows profile creation during signup
CREATE POLICY "Allow users to create their own profile during signup"
  ON perfis
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);