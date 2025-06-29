# Sistema de Gestão de Entregas - Pizzaria Borda de Fogo

Sistema completo para gerenciamento de entregas de pizzaria, desenvolvido com React, TypeScript, Tailwind CSS e Supabase.

## 🚀 Funcionalidades

### Para Gerentes
- **Dashboard Completo**: Visão geral de todas as entregas em tempo real
- **Gestão de Entregas**: Criar, editar, acompanhar e finalizar entregas
- **Gestão de Entregadores**: Cadastrar e gerenciar equipe de entregadores
- **Gestão de Clientes**: Cadastro completo de clientes com endereços
- **Relatórios Detalhados**: Relatórios financeiros em PDF por período e entregador
- **Controle de Status**: Acompanhamento em tempo real do status das entregas

### Para Entregadores
- **Dashboard Personalizado**: Visualização apenas das suas entregas
- **Controle de Rota**: Marcar saída e chegada das entregas
- **Cronômetro Automático**: Tempo de entrega calculado automaticamente
- **Informações do Cliente**: Acesso a endereço e telefone para contato

## 🛠️ Tecnologias Utilizadas

- **Frontend**: React 18, TypeScript, Tailwind CSS
- **Backend**: Supabase (PostgreSQL + Auth + RLS)
- **Autenticação**: Supabase Auth com Row Level Security
- **Relatórios**: jsPDF com autoTable
- **Ícones**: Lucide React
- **Build**: Vite

## 📋 Pré-requisitos

- Node.js 18+ 
- Conta no Supabase
- Git

## 🔧 Configuração do Projeto

### 1. Clone o repositório
```bash
git clone <url-do-repositorio>
cd sistema-entregas-pizzaria
```

### 2. Instale as dependências
```bash
npm install
```

### 3. Configure o Supabase

#### 3.1. Crie um projeto no Supabase
1. Acesse [supabase.com](https://supabase.com)
2. Crie uma nova conta ou faça login
3. Crie um novo projeto
4. Anote a URL e a chave anônima do projeto

#### 3.2. Configure as variáveis de ambiente
```bash
cp .env.example .env
```

Edite o arquivo `.env` com suas credenciais:
```env
VITE_SUPABASE_URL=sua_url_do_supabase
VITE_SUPABASE_ANON_KEY=sua_chave_anonima_do_supabase
VITE_MANAGER_ACCESS_CODE=BORDA777
```

#### 3.3. Execute as migrações do banco
1. Acesse o SQL Editor no painel do Supabase
2. Execute o conteúdo do arquivo `supabase/migrations/20250629182000_fix_rls_policies.sql`

### 4. Inicie o servidor de desenvolvimento
```bash
npm run dev
```

## 🔐 Sistema de Autenticação

### Tipos de Conta

#### Gerente
- **Código de Acesso**: `BORDA777` (configurável via `.env`)
- **Permissões**: Acesso total ao sistema
- **Funcionalidades**: Todas as funcionalidades administrativas

#### Entregador
- **Cadastro**: Livre (qualquer pessoa pode criar)
- **Permissões**: Acesso apenas às suas entregas
- **Funcionalidades**: Dashboard personalizado e controle de entregas

### Primeiro Acesso
1. Acesse a aplicação
2. Clique em "Criar Nova Conta"
3. Escolha o tipo de conta (Gerente ou Entregador)
4. Para gerente, use o código: `BORDA777`
5. Confirme o email (verifique a caixa de entrada)

## 📊 Estrutura do Banco de Dados

### Tabelas Principais
- **perfis**: Dados dos usuários (ligada ao Supabase Auth)
- **entregadores**: Informações específicas dos entregadores
- **clientes**: Cadastro de clientes com endereços
- **entregas**: Registro completo das entregas
- **configuracoes**: Configurações do sistema

### Segurança (RLS)
- Políticas de Row Level Security implementadas
- Gerentes têm acesso total
- Entregadores veem apenas suas entregas
- Clientes e configurações visíveis para todos autenticados

## 🚀 Deploy

### Netlify (Recomendado)
1. Conecte seu repositório ao Netlify
2. Configure as variáveis de ambiente no painel do Netlify
3. Deploy automático a cada push

### Outras Plataformas
- Vercel
- Railway
- Heroku

## 📱 Responsividade

O sistema é totalmente responsivo e funciona perfeitamente em:
- 📱 Dispositivos móveis
- 📱 Tablets
- 💻 Desktops
- 🖥️ Monitores grandes

## 🎨 Design

- **Tema**: Dark mode com acentos vermelhos
- **Tipografia**: Sistema de fontes nativo
- **Componentes**: Totalmente customizados com Tailwind CSS
- **Animações**: Micro-interações suaves
- **UX**: Interface intuitiva e profissional

## 📈 Funcionalidades Avançadas

### Relatórios em PDF
- Relatórios individuais por entregador
- Relatórios consolidados gerais
- Filtros por período
- Cálculos automáticos de valores
- Download direto

### Cronômetro de Entregas
- Início automático ao marcar "Em Rota"
- Cálculo preciso em segundos
- Exibição em tempo real
- Histórico de tempos de entrega

### Gestão de Status
- **Aguardando**: Pedido registrado
- **Em Rota**: Entregador saiu para entrega
- **Entregue**: Entrega finalizada com sucesso
- **Cancelado**: Entrega cancelada

## 🔧 Desenvolvimento

### Scripts Disponíveis
```bash
npm run dev          # Servidor de desenvolvimento
npm run build        # Build para produção
npm run preview      # Preview do build
npm run lint         # Verificação de código
```

### Estrutura de Pastas
```
src/
├── components/      # Componentes React
├── contexts/        # Contextos (Auth, etc.)
├── hooks/          # Custom hooks
├── lib/            # Configurações (Supabase)
├── types/          # Definições TypeScript
├── utils/          # Funções utilitárias
└── main.tsx        # Ponto de entrada
```

## 🐛 Solução de Problemas

### Erro de Login Infinito
- Verifique se as migrações foram executadas
- Confirme as variáveis de ambiente
- Verifique as políticas RLS no Supabase

### Erro de Permissão
- Execute a migração `fix_rls_policies.sql`
- Verifique se o RLS está habilitado
- Confirme as políticas de segurança

### Email não Confirmado
- Verifique a caixa de spam
- Use o botão "Reenviar Confirmação"
- Configure o template de email no Supabase

## 📞 Suporte

Para dúvidas ou problemas:
1. Verifique a documentação
2. Consulte os logs do navegador
3. Verifique as configurações do Supabase
4. Abra uma issue no repositório

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo `LICENSE` para mais detalhes.

---

**Desenvolvido com ❤️ para a Pizzaria Borda de Fogo**