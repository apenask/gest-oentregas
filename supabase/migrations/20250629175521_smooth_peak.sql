/*
  # Reset Completo do Banco de Dados - Fonte da Verdade
  
  Este script é a única fonte da verdade para a estrutura do banco de dados.
  Ele deve ser executado no Supabase após apagar as tabelas antigas.
  
  1. Estrutura das Tabelas
    - perfis: Ligada a auth.users com informações do usuário
    - entregadores: Dados específicos dos entregadores
    - clientes: Informações dos clientes
    - entregas: Registros de entregas com duração em segundos
    - configuracoes: Configurações do sistema
  
  2. Segurança (RLS)
    - Gerentes: Acesso total a todas as tabelas
    - Entregadores: Acesso limitado às suas próprias entregas e dados relacionados
  
  3. Relações e Integridade
    - Todas as chaves estrangeiras definidas corretamente
    - Constraints para garantir integridade dos dados
*/

-- =============================================
-- PARTE 1: LIMPEZA COMPLETA (DROP TABLES)
-- =============================================

-- Drop existing tables in correct order (respecting foreign keys)
DROP TABLE IF EXISTS entregas CASCADE;
DROP TABLE IF EXISTS configuracoes CASCADE;
DROP TABLE IF EXISTS entregadores CASCADE;
DROP TABLE IF EXISTS clientes CASCADE;
DROP TABLE IF EXISTS perfis CASCADE;

-- Drop existing functions and triggers
DROP FUNCTION IF EXISTS handle_updated_at() CASCADE;

-- =============================================
-- PARTE 2: CRIAÇÃO DE FUNÇÕES AUXILIARES
-- =============================================

-- Function for automatic updated_at timestamps
CREATE OR REPLACE FUNCTION handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- PARTE 3: CRIAÇÃO DAS TABELAS
-- =============================================

-- Tabela perfis (ligada a auth.users)
CREATE TABLE perfis (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  nome_completo TEXT NOT NULL,
  cargo TEXT NOT NULL CHECK (cargo IN ('gerente', 'entregador')),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Tabela entregadores (dados específicos dos entregadores)
CREATE TABLE entregadores (
  id SERIAL PRIMARY KEY,
  usuario_id UUID NOT NULL REFERENCES perfis(id) ON DELETE CASCADE,
  nome_completo TEXT NOT NULL,
  ativo BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(usuario_id)
);

-- Tabela clientes
CREATE TABLE clientes (
  id SERIAL PRIMARY KEY,
  nome_completo TEXT NOT NULL,
  rua_numero TEXT NOT NULL,
  bairro TEXT NOT NULL,
  telefone TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Tabela entregas
CREATE TABLE entregas (
  id SERIAL PRIMARY KEY,
  numero_pedido TEXT,
  cliente_id INTEGER NOT NULL REFERENCES clientes(id),
  entregador_id INTEGER NOT NULL REFERENCES entregadores(id),
  forma_pagamento TEXT NOT NULL CHECK (forma_pagamento IN ('Dinheiro', 'Pix', 'Cartão de Débito', 'Cartão de Crédito')),
  valor_pedido NUMERIC(10,2) NOT NULL CHECK (valor_pedido >= 0),
  valor_corrida NUMERIC(10,2) NOT NULL CHECK (valor_corrida >= 0),
  status TEXT NOT NULL DEFAULT 'Aguardando' CHECK (status IN ('Aguardando', 'Em Rota', 'Entregue', 'Cancelado')),
  data_hora_pedido TIMESTAMPTZ DEFAULT now(),
  data_hora_saida TIMESTAMPTZ,
  data_hora_entrega TIMESTAMPTZ,
  duracao_entrega_segundos INTEGER,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Tabela configuracoes
CREATE TABLE configuracoes (
  id SERIAL PRIMARY KEY,
  chave TEXT UNIQUE NOT NULL,
  valor TEXT,
  descricao TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- =============================================
-- PARTE 4: ÍNDICES PARA PERFORMANCE
-- =============================================

CREATE INDEX idx_entregadores_usuario_id ON entregadores(usuario_id);
CREATE INDEX idx_entregas_entregador_id ON entregas(entregador_id);
CREATE INDEX idx_entregas_status ON entregas(status);
CREATE INDEX idx_entregas_data_pedido ON entregas(data_hora_pedido);

-- =============================================
-- PARTE 5: TRIGGERS PARA UPDATED_AT
-- =============================================

CREATE TRIGGER on_perfis_update
  BEFORE UPDATE ON perfis
  FOR EACH ROW EXECUTE FUNCTION handle_updated_at();

CREATE TRIGGER on_entregadores_update
  BEFORE UPDATE ON entregadores
  FOR EACH ROW EXECUTE FUNCTION handle_updated_at();

CREATE TRIGGER on_clientes_update
  BEFORE UPDATE ON clientes
  FOR EACH ROW EXECUTE FUNCTION handle_updated_at();

CREATE TRIGGER on_entregas_update
  BEFORE UPDATE ON entregas
  FOR EACH ROW EXECUTE FUNCTION handle_updated_at();

CREATE TRIGGER on_configuracoes_update
  BEFORE UPDATE ON configuracoes
  FOR EACH ROW EXECUTE FUNCTION handle_updated_at();

-- =============================================
-- PARTE 6: HABILITAÇÃO DO RLS
-- =============================================

ALTER TABLE perfis ENABLE ROW LEVEL SECURITY;
ALTER TABLE entregadores ENABLE ROW LEVEL SECURITY;
ALTER TABLE clientes ENABLE ROW LEVEL SECURITY;
ALTER TABLE entregas ENABLE ROW LEVEL SECURITY;
ALTER TABLE configuracoes ENABLE ROW LEVEL SECURITY;

-- =============================================
-- PARTE 7: POLÍTICAS DE SEGURANÇA (RLS)
-- =============================================

-- Políticas para PERFIS
CREATE POLICY "Usuários podem ver próprios perfis"
  ON perfis FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

CREATE POLICY "Usuários podem atualizar próprios perfis"
  ON perfis FOR UPDATE
  TO authenticated
  USING (auth.uid() = id);

CREATE POLICY "Permitir inserção de perfis"
  ON perfis FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Gerentes podem ver todos os perfis"
  ON perfis FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM perfis 
      WHERE id = auth.uid() AND cargo = 'gerente'
    )
  );

-- Políticas para ENTREGADORES
CREATE POLICY "Todos autenticados podem ver entregadores"
  ON entregadores FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Gerentes podem gerenciar entregadores"
  ON entregadores FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM perfis 
      WHERE id = auth.uid() AND cargo = 'gerente'
    )
  );

-- Políticas para CLIENTES
CREATE POLICY "Todos autenticados podem ver clientes"
  ON clientes FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Gerentes podem gerenciar clientes"
  ON clientes FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM perfis 
      WHERE id = auth.uid() AND cargo = 'gerente'
    )
  );

-- Políticas para ENTREGAS
CREATE POLICY "Gerentes podem ver todas as entregas"
  ON entregas FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM perfis 
      WHERE id = auth.uid() AND cargo = 'gerente'
    )
  );

CREATE POLICY "Entregadores podem ver suas próprias entregas"
  ON entregas FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM entregadores e
      JOIN perfis p ON e.usuario_id = p.id
      WHERE p.id = auth.uid() AND e.id = entregas.entregador_id
    )
  );

CREATE POLICY "Gerentes podem gerenciar todas as entregas"
  ON entregas FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM perfis 
      WHERE id = auth.uid() AND cargo = 'gerente'
    )
  );

CREATE POLICY "Entregadores podem atualizar suas próprias entregas"
  ON entregas FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM entregadores e
      JOIN perfis p ON e.usuario_id = p.id
      WHERE p.id = auth.uid() AND e.id = entregas.entregador_id
    )
  );

-- Políticas para CONFIGURAÇÕES
CREATE POLICY "Todos autenticados podem ver configurações"
  ON configuracoes FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Gerentes podem gerenciar configurações"
  ON configuracoes FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM perfis 
      WHERE id = auth.uid() AND cargo = 'gerente'
    )
  );

-- =============================================
-- PARTE 8: DADOS INICIAIS
-- =============================================

-- Inserir configurações padrão do sistema
INSERT INTO configuracoes (chave, valor, descricao) VALUES
  ('valor_corrida_padrao', '6.00', 'Valor padrão da corrida de entrega'),
  ('tempo_maximo_entrega', '45', 'Tempo máximo para entrega em minutos'),
  ('sistema_ativo', 'true', 'Indica se o sistema está ativo'),
  ('codigo_acesso_gerente', 'BORDA777', 'Código de acesso para criação de contas de gerente');

-- Inserir clientes de exemplo
INSERT INTO clientes (nome_completo, rua_numero, bairro, telefone) VALUES
  ('Ana Paula Silva', 'Rua das Flores, 123', 'Centro', '(11) 99999-1111'),
  ('Ricardo Mendes', 'Av. Principal, 456', 'Jardim América', '(11) 99999-2222'),
  ('Fernanda Lima', 'Rua do Comércio, 789', 'Vila Nova', '(11) 99999-3333'),
  ('Lucas Souza', 'Rua da Paz, 321', 'Bela Vista', '(11) 99999-4444'),
  ('Mariana Costa', 'Rua das Palmeiras, 654', 'Parque das Árvores', '(11) 99999-5555'),
  ('José Alves', 'Av. dos Trabalhadores, 987', 'Industrial', '(11) 99999-6666');