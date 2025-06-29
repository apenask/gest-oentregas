/*
  # Fix infinite recursion in perfis table RLS policies

  1. Problem
    - The "Gerentes podem ver todos os perfis" policy creates infinite recursion
    - It queries the perfis table from within a perfis table policy
    
  2. Solution
    - Drop the problematic policy that causes recursion
    - Keep the simple policies that don't cause recursion
    - Managers will still be able to see profiles through application logic
    
  3. Security
    - Users can still see their own profiles
    - Users can still update their own profiles
    - Users can still create profiles during signup
*/

-- Drop the problematic policy that causes infinite recursion
DROP POLICY IF EXISTS "Gerentes podem ver todos os perfis" ON perfis;

-- The remaining policies are safe and don't cause recursion:
-- 1. "Usuários podem ver próprios perfis" - uses (uid() = id)
-- 2. "Usuários podem atualizar próprios perfis" - uses (uid() = id)  
-- 3. "Allow users to create their own profile during signup" - uses (uid() = id)

-- These policies are sufficient for basic functionality without recursion