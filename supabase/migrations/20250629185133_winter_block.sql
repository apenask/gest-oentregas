-- =============================================
-- CORREÇÃO FINAL: POLÍTICAS RLS PARA REGISTRO DE USUÁRIOS
-- =============================================

/*
  # Correção das Políticas de Segurança (RLS)

  1. Políticas para Perfis
    - Permite que qualquer um crie um perfil (essencial para signUp)
    - Permite que usuários logados leiam e atualizem seus próprios perfis

  2. Políticas para Entregadores
    - Gerentes têm acesso total
    - Entregadores têm acesso restrito às suas próprias entregas

  3. Políticas para outras tabelas
    - Implementa controle baseado em cargo (gerente vs entregador)
*/

-- =============================================
-- PARTE 1: REMOVER POLÍTICAS PROBLEMÁTICAS
-- =============================================

-- Remove todas as políticas existentes para recriar corretamente
DROP POLICY IF EXISTS "Usuários podem ver próprios perfis" ON perfis;
DROP POLICY IF EXISTS "Usuários podem atualizar próprios perfis" ON perfis;
DROP POLICY IF EXISTS "Allow users to create their own profile during signup" ON perfis;
DROP POLICY IF EXISTS "Gerentes podem ver todos os perfis" ON perfis;

-- =============================================
-- PARTE 2: POLÍTICAS CORRETAS PARA PERFIS
-- =============================================

-- CRÍTICO: Permite que qualquer pessoa crie um perfil (resolve o problema do signUp)
CREATE POLICY "Permitir registro público de perfis"
  ON perfis
  FOR INSERT
  WITH CHECK (true);

-- Permite que usuários logados gerenciem seus próprios perfis
CREATE POLICY "Usuários podem gerenciar seus próprios perfis"
  ON perfis
  FOR ALL
  TO authenticated
  USING (auth.uid() = id);

-- =============================================
-- PARTE 3: POLÍTICAS PARA ENTREGADORES
-- =============================================

-- Remove políticas existentes
DROP POLICY IF EXISTS "Todos autenticados podem ver entregadores" ON entregadores;
DROP POLICY IF EXISTS "Gerentes podem gerenciar entregadores" ON entregadores;

-- Todos autenticados podem ver entregadores
CREATE POLICY "Todos autenticados podem ver entregadores"
  ON entregadores
  FOR SELECT
  TO authenticated
  USING (true);

-- Gerentes podem gerenciar entregadores
CREATE POLICY "Gerentes podem gerenciar entregadores"
  ON entregadores
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM perfis 
      WHERE perfis.id = auth.uid() AND perfis.cargo = 'gerente'
    )
  );

-- =============================================
-- PARTE 4: POLÍTICAS PARA CLIENTES
-- =============================================

-- Remove políticas existentes
DROP POLICY IF EXISTS "Todos autenticados podem ver clientes" ON clientes;
DROP POLICY IF EXISTS "Gerentes podem gerenciar clientes" ON clientes;

-- Todos autenticados podem ver clientes
CREATE POLICY "Todos autenticados podem ver clientes"
  ON clientes
  FOR SELECT
  TO authenticated
  USING (true);

-- Gerentes podem gerenciar clientes
CREATE POLICY "Gerentes podem gerenciar clientes"
  ON clientes
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM perfis 
      WHERE perfis.id = auth.uid() AND perfis.cargo = 'gerente'
    )
  );

-- =============================================
-- PARTE 5: POLÍTICAS PARA ENTREGAS
-- =============================================

-- Remove políticas existentes
DROP POLICY IF EXISTS "Gerentes podem ver todas as entregas" ON entregas;
DROP POLICY IF EXISTS "Entregadores podem ver suas próprias entregas" ON entregas;
DROP POLICY IF EXISTS "Gerentes podem gerenciar todas as entregas" ON entregas;
DROP POLICY IF EXISTS "Entregadores podem atualizar suas próprias entregas" ON entregas;

-- Gerentes podem ver todas as entregas
CREATE POLICY "Gerentes podem ver todas as entregas"
  ON entregas
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM perfis 
      WHERE perfis.id = auth.uid() AND perfis.cargo = 'gerente'
    )
  );

-- Entregadores podem ver suas próprias entregas
CREATE POLICY "Entregadores podem ver suas próprias entregas"
  ON entregas
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM entregadores e
      JOIN perfis p ON e.usuario_id = p.id
      WHERE p.id = auth.uid() AND e.id = entregas.entregador_id
    )
  );

-- Gerentes podem gerenciar todas as entregas
CREATE POLICY "Gerentes podem gerenciar todas as entregas"
  ON entregas
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM perfis 
      WHERE perfis.id = auth.uid() AND perfis.cargo = 'gerente'
    )
  );

-- Entregadores podem atualizar suas próprias entregas
CREATE POLICY "Entregadores podem atualizar suas próprias entregas"
  ON entregas
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM entregadores e
      JOIN perfis p ON e.usuario_id = p.id
      WHERE p.id = auth.uid() AND e.id = entregas.entregador_id
    )
  );

-- =============================================
-- PARTE 6: POLÍTICAS PARA CONFIGURAÇÕES
-- =============================================

-- Remove políticas existentes
DROP POLICY IF EXISTS "Todos autenticados podem ver configurações" ON configuracoes;
DROP POLICY IF EXISTS "Gerentes podem gerenciar configurações" ON configuracoes;

-- Todos autenticados podem ver configurações
CREATE POLICY "Todos autenticados podem ver configurações"
  ON configuracoes
  FOR SELECT
  TO authenticated
  USING (true);

-- Gerentes podem gerenciar configurações
CREATE POLICY "Gerentes podem gerenciar configurações"
  ON configuracoes
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM perfis 
      WHERE perfis.id = auth.uid() AND perfis.cargo = 'gerente'
    )
  );