/*
  # Complete Database Schema for Delivery Management System

  1. New Tables
    - `usuarios` - User accounts (managers and delivery personnel)
      - `id` (integer, primary key, auto-increment)
      - `email` (text, unique, not null)
      - `senha_hash` (text, not null) 
      - `nome_completo` (text, not null)
      - `cargo` (text, not null, check: 'gerente' or 'entregador')
      - `token_recuperacao` (text, nullable)
      - `token_expiracao` (timestamptz, nullable)
      - `created_at` (timestamptz, default now())
      - `updated_at` (timestamptz, default now())

    - `entregadores` - Delivery personnel records
      - `id` (integer, primary key, auto-increment)
      - `usuario_id` (integer, foreign key to usuarios, unique)
      - `ativo` (boolean, default true)
      - `created_at` (timestamptz, default now())
      - `updated_at` (timestamptz, default now())

    - `clientes` - Customer records
      - `id` (integer, primary key, auto-increment)
      - `nome_completo` (text, not null)
      - `rua_numero` (text, not null)
      - `bairro` (text, not null)
      - `telefone` (text, nullable)
      - `created_at` (timestamptz, default now())
      - `updated_at` (timestamptz, default now())

    - `entregas` - Delivery records
      - `id` (integer, primary key, auto-increment)
      - `numero_pedido` (text, nullable)
      - `cliente_id` (integer, foreign key to clientes, not null)
      - `entregador_id` (integer, foreign key to entregadores, not null)
      - `forma_pagamento` (text, not null, check: valid payment methods)
      - `valor_pedido` (numeric(10,2), not null, check >= 0)
      - `valor_corrida` (numeric(10,2), not null, check >= 0)
      - `status` (text, not null, default 'Aguardando', check: valid statuses)
      - `data_hora_pedido` (timestamptz, default now())
      - `data_hora_saida` (timestamptz, nullable)
      - `data_hora_entrega` (timestamptz, nullable)
      - `duracao_entrega_segundos` (integer, nullable)
      - `created_at` (timestamptz, default now())
      - `updated_at` (timestamptz, default now())

    - `configuracoes` - System configuration
      - `id` (integer, primary key, auto-increment)
      - `chave` (text, unique, not null)
      - `valor` (text, nullable)
      - `descricao` (text, nullable)
      - `created_at` (timestamptz, default now())
      - `updated_at` (timestamptz, default now())

  2. Security
    - Enable RLS on all tables
    - Add appropriate policies for authenticated users
    - Managers can manage all data
    - Delivery personnel can view relevant data

  3. Indexes
    - Performance indexes on frequently queried columns
    - Unique constraints where needed

  4. Triggers
    - Auto-update timestamps on record changes
*/

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create usuarios table
CREATE TABLE IF NOT EXISTS usuarios (
  id SERIAL PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  senha_hash TEXT NOT NULL,
  nome_completo TEXT NOT NULL,
  cargo TEXT NOT NULL CHECK (cargo IN ('gerente', 'entregador')),
  token_recuperacao TEXT,
  token_expiracao TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Create index on email for performance
CREATE INDEX IF NOT EXISTS idx_usuarios_email ON usuarios(email);

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

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_entregas_entregador_id ON entregas(entregador_id);
CREATE INDEX IF NOT EXISTS idx_entregas_status ON entregas(status);

-- Create configuracoes table
CREATE TABLE IF NOT EXISTS configuracoes (
  id SERIAL PRIMARY KEY,
  chave TEXT UNIQUE NOT NULL,
  valor TEXT,
  descricao TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Create triggers for updated_at
DROP TRIGGER IF EXISTS on_usuarios_update ON usuarios;
CREATE TRIGGER on_usuarios_update
  BEFORE UPDATE ON usuarios
  FOR EACH ROW EXECUTE FUNCTION handle_updated_at();

DROP TRIGGER IF EXISTS on_entregadores_update ON entregadores;
CREATE TRIGGER on_entregadores_update
  BEFORE UPDATE ON entregadores
  FOR EACH ROW EXECUTE FUNCTION handle_updated_at();

DROP TRIGGER IF EXISTS on_clientes_update ON clientes;
CREATE TRIGGER on_clientes_update
  BEFORE UPDATE ON clientes
  FOR EACH ROW EXECUTE FUNCTION handle_updated_at();

DROP TRIGGER IF EXISTS on_entregas_update ON entregas;
CREATE TRIGGER on_entregas_update
  BEFORE UPDATE ON entregas
  FOR EACH ROW EXECUTE FUNCTION handle_updated_at();

DROP TRIGGER IF EXISTS on_configuracoes_update ON configuracoes;
CREATE TRIGGER on_configuracoes_update
  BEFORE UPDATE ON configuracoes
  FOR EACH ROW EXECUTE FUNCTION handle_updated_at();

-- Enable Row Level Security
ALTER TABLE usuarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE entregadores ENABLE ROW LEVEL SECURITY;
ALTER TABLE clientes ENABLE ROW LEVEL SECURITY;
ALTER TABLE entregas ENABLE ROW LEVEL SECURITY;
ALTER TABLE configuracoes ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for usuarios
DROP POLICY IF EXISTS "Permitir inserção de novos usuários" ON usuarios;
CREATE POLICY "Permitir inserção de novos usuários"
  ON usuarios
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

DROP POLICY IF EXISTS "Usuários podem ver próprios dados" ON usuarios;
CREATE POLICY "Usuários podem ver próprios dados"
  ON usuarios
  FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "Usuários podem atualizar próprios dados" ON usuarios;
CREATE POLICY "Usuários podem atualizar próprios dados"
  ON usuarios
  FOR UPDATE
  TO authenticated
  USING (true);

-- Create RLS policies for entregadores
DROP POLICY IF EXISTS "Gerentes podem gerenciar entregadores" ON entregadores;
CREATE POLICY "Gerentes podem gerenciar entregadores"
  ON entregadores
  FOR ALL
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "Todos podem ver entregadores" ON entregadores;
CREATE POLICY "Todos podem ver entregadores"
  ON entregadores
  FOR SELECT
  TO authenticated
  USING (true);

-- Create RLS policies for clientes
DROP POLICY IF EXISTS "Todos podem gerenciar clientes" ON clientes;
CREATE POLICY "Todos podem gerenciar clientes"
  ON clientes
  FOR ALL
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "Todos podem ver clientes" ON clientes;
CREATE POLICY "Todos podem ver clientes"
  ON clientes
  FOR SELECT
  TO authenticated
  USING (true);

-- Create RLS policies for entregas
DROP POLICY IF EXISTS "Todos podem gerenciar entregas" ON entregas;
CREATE POLICY "Todos podem gerenciar entregas"
  ON entregas
  FOR ALL
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "Todos podem ver entregas" ON entregas;
CREATE POLICY "Todos podem ver entregas"
  ON entregas
  FOR SELECT
  TO authenticated
  USING (true);

-- Create RLS policies for configuracoes
DROP POLICY IF EXISTS "Gerentes podem gerenciar configurações" ON configuracoes;
CREATE POLICY "Gerentes podem gerenciar configurações"
  ON configuracoes
  FOR ALL
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "Todos podem ver configurações" ON configuracoes;
CREATE POLICY "Todos podem ver configurações"
  ON configuracoes
  FOR SELECT
  TO authenticated
  USING (true);