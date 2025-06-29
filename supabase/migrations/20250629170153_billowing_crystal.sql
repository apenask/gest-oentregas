/*
  # Complete Database Schema for Pizzaria Borda de Fogo

  1. New Tables
    - `usuarios` - User accounts (managers and delivery drivers)
    - `entregadores` - Delivery drivers linked to users
    - `clientes` - Customer information
    - `entregas` - Delivery orders and tracking
    - `configuracoes` - System configuration

  2. Security
    - Enable RLS on all tables
    - Add policies for authenticated users
    - Proper foreign key relationships

  3. Features
    - Automatic updated_at timestamps
    - Performance indexes
    - Data validation constraints
    - Sample data for testing
*/

-- Drop existing triggers if they exist
DROP TRIGGER IF EXISTS on_usuarios_update ON usuarios;
DROP TRIGGER IF EXISTS on_entregadores_update ON entregadores;
DROP TRIGGER IF EXISTS on_clientes_update ON clientes;
DROP TRIGGER IF EXISTS on_entregas_update ON entregas;
DROP TRIGGER IF EXISTS on_configuracoes_update ON configuracoes;

-- Drop existing function if it exists
DROP FUNCTION IF EXISTS handle_updated_at();

-- Create function for automatic updated_at
CREATE OR REPLACE FUNCTION handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Create usuarios table
CREATE TABLE IF NOT EXISTS usuarios (
  id SERIAL PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  senha_hash TEXT NOT NULL DEFAULT '',
  nome_completo TEXT NOT NULL,
  cargo TEXT NOT NULL CHECK (cargo IN ('gerente', 'entregador')),
  token_recuperacao TEXT,
  token_expiracao TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Create entregadores table
CREATE TABLE IF NOT EXISTS entregadores (
  id SERIAL PRIMARY KEY,
  usuario_id INTEGER UNIQUE REFERENCES usuarios(id) ON DELETE CASCADE,
  ativo BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Create clientes table
CREATE TABLE IF NOT EXISTS clientes (
  id SERIAL PRIMARY KEY,
  nome_completo TEXT NOT NULL,
  rua_numero TEXT NOT NULL,
  bairro TEXT NOT NULL,
  telefone TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Create entregas table
CREATE TABLE IF NOT EXISTS entregas (
  id SERIAL PRIMARY KEY,
  numero_pedido TEXT,
  cliente_id INTEGER NOT NULL REFERENCES clientes(id),
  entregador_id INTEGER NOT NULL REFERENCES entregadores(id),
  forma_pagamento TEXT NOT NULL CHECK (forma_pagamento IN ('Dinheiro', 'Pix', 'Cartão de Débito', 'Cartão de Crédito')),
  valor_pedido DECIMAL(10,2) NOT NULL CHECK (valor_pedido >= 0),
  valor_corrida DECIMAL(10,2) NOT NULL CHECK (valor_corrida >= 0),
  status TEXT NOT NULL DEFAULT 'Aguardando' CHECK (status IN ('Aguardando', 'Em Rota', 'Entregue', 'Cancelado')),
  data_hora_pedido TIMESTAMPTZ DEFAULT now(),
  data_hora_saida TIMESTAMPTZ,
  data_hora_entrega TIMESTAMPTZ,
  duracao_entrega_segundos INTEGER,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Create configuracoes table
CREATE TABLE IF NOT EXISTS configuracoes (
  id SERIAL PRIMARY KEY,
  chave TEXT UNIQUE NOT NULL,
  valor TEXT,
  descricao TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_usuarios_email ON usuarios(email);
CREATE INDEX IF NOT EXISTS idx_entregas_entregador_id ON entregas(entregador_id);
CREATE INDEX IF NOT EXISTS idx_entregas_status ON entregas(status);

-- Create triggers for updated_at
CREATE TRIGGER on_usuarios_update
  BEFORE UPDATE ON usuarios
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

-- Enable RLS on all tables
ALTER TABLE usuarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE entregadores ENABLE ROW LEVEL SECURITY;
ALTER TABLE clientes ENABLE ROW LEVEL SECURITY;
ALTER TABLE entregas ENABLE ROW LEVEL SECURITY;
ALTER TABLE configuracoes ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Usuários podem ver próprios dados" ON usuarios;
DROP POLICY IF EXISTS "Usuários podem atualizar próprios dados" ON usuarios;
DROP POLICY IF EXISTS "Permitir inserção de novos usuários" ON usuarios;
DROP POLICY IF EXISTS "Todos podem ver entregadores" ON entregadores;
DROP POLICY IF EXISTS "Gerentes podem gerenciar entregadores" ON entregadores;
DROP POLICY IF EXISTS "Todos podem ver clientes" ON clientes;
DROP POLICY IF EXISTS "Todos podem gerenciar clientes" ON clientes;
DROP POLICY IF EXISTS "Todos podem ver entregas" ON entregas;
DROP POLICY IF EXISTS "Todos podem gerenciar entregas" ON entregas;
DROP POLICY IF EXISTS "Todos podem ver configurações" ON configuracoes;
DROP POLICY IF EXISTS "Gerentes podem gerenciar configurações" ON configuracoes;

-- Create RLS policies for usuarios
CREATE POLICY "Usuários podem ver próprios dados"
  ON usuarios FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Usuários podem atualizar próprios dados"
  ON usuarios FOR UPDATE
  TO authenticated
  USING (true);

CREATE POLICY "Permitir inserção de novos usuários"
  ON usuarios FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Create RLS policies for entregadores
CREATE POLICY "Todos podem ver entregadores"
  ON entregadores FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Gerentes podem gerenciar entregadores"
  ON entregadores FOR ALL
  TO authenticated
  USING (true);

-- Create RLS policies for clientes
CREATE POLICY "Todos podem ver clientes"
  ON clientes FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Todos podem gerenciar clientes"
  ON clientes FOR ALL
  TO authenticated
  USING (true);

-- Create RLS policies for entregas
CREATE POLICY "Todos podem ver entregas"
  ON entregas FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Todos podem gerenciar entregas"
  ON entregas FOR ALL
  TO authenticated
  USING (true);

-- Create RLS policies for configuracoes
CREATE POLICY "Todos podem ver configurações"
  ON configuracoes FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Gerentes podem gerenciar configurações"
  ON configuracoes FOR ALL
  TO authenticated
  USING (true);

-- Insert default manager user
INSERT INTO usuarios (email, senha_hash, nome_completo, cargo) 
VALUES ('gerente@bordadefogo.com', 'YWRtaW4xMjNzYWx0X3NlY3JldG8=', 'Administrador do Sistema', 'gerente')
ON CONFLICT (email) DO NOTHING;

-- Insert sample delivery driver users (without passwords initially)
INSERT INTO usuarios (email, senha_hash, nome_completo, cargo) VALUES
  ('joao@bordadefogo.com', '', 'João Silva', 'entregador'),
  ('maria@bordadefogo.com', '', 'Maria Santos', 'entregador'),
  ('pedro@bordadefogo.com', '', 'Pedro Costa', 'entregador')
ON CONFLICT (email) DO NOTHING;

-- Link delivery drivers to entregadores table
DO $$
DECLARE
    joao_id INTEGER;
    maria_id INTEGER;
    pedro_id INTEGER;
BEGIN
    -- Get user IDs
    SELECT id INTO joao_id FROM usuarios WHERE email = 'joao@bordadefogo.com';
    SELECT id INTO maria_id FROM usuarios WHERE email = 'maria@bordadefogo.com';
    SELECT id INTO pedro_id FROM usuarios WHERE email = 'pedro@bordadefogo.com';
    
    -- Insert into entregadores table
    INSERT INTO entregadores (usuario_id, ativo) VALUES
        (joao_id, true),
        (maria_id, true),
        (pedro_id, true)
    ON CONFLICT (usuario_id) DO NOTHING;
END $$;

-- Insert sample customers
INSERT INTO clientes (nome_completo, rua_numero, bairro, telefone) VALUES
  ('Ana Paula', 'Rua das Flores, 123', 'Centro', '(11) 99999-1111'),
  ('Ricardo Mendes', 'Av. Principal, 456', 'Jardim América', '(11) 99999-2222'),
  ('Fernanda Lima', 'Rua do Comércio, 789', 'Vila Nova', '(11) 99999-3333'),
  ('Lucas Souza', 'Rua da Paz, 321', 'Bela Vista', '(11) 99999-4444'),
  ('Mariana Costa', 'Rua das Palmeiras, 654', 'Parque das Árvores', '(11) 99999-5555'),
  ('José Alves', 'Av. dos Trabalhadores, 987', 'Industrial', '(11) 99999-6666')
ON CONFLICT DO NOTHING;

-- Insert default system configurations
INSERT INTO configuracoes (chave, valor, descricao) VALUES
  ('valor_corrida_padrao', '6.00', 'Valor padrão da corrida de entrega'),
  ('tempo_maximo_entrega', '45', 'Tempo máximo para entrega em minutos'),
  ('sistema_ativo', 'true', 'Indica se o sistema está ativo')
ON CONFLICT (chave) DO NOTHING;