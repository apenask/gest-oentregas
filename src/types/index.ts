export interface Entregador {
  id: number;
  nome: string;
  email: string;
}

export interface Cliente {
  id: number;
  nome: string;
  ruaNumero: string;
  bairro: string;
  telefone?: string;
}

export interface Usuario {
  id: number;
  email: string;
  senha: string;
  nomeCompleto: string;
  cargo: 'gerente' | 'entregador';
  entregadorId?: number; // Para vincular usuário entregador ao entregador
  emailVerificado?: boolean;
  tokenRecuperacao?: string;
  tokenExpiracao?: Date;
}

export interface Entrega {
  id: number;
  dataHora: Date;
  numeroPedido: string;
  clienteId: number;
  cliente?: Cliente;
  entregadorId: number;
  entregador?: string;
  formaPagamento: 'Dinheiro' | 'Pix' | 'Cartão de Débito' | 'Cartão de Crédito';
  valorTotalPedido: number;
  valorCorrida: number;
  status: 'Aguardando' | 'Em Rota' | 'Entregue' | 'Cancelado';
  dataHoraSaida?: Date;
  dataHoraEntrega?: Date;
  duracaoEntrega?: number; // Duração em SEGUNDOS - SALVA PERMANENTEMENTE
}

export type TelaAtiva = 'dashboard' | 'relatorios' | 'entregadores' | 'clientes';

export interface LoginResult {
  sucesso: boolean;
  mensagem?: string;
  tipoErro?: 'email_nao_confirmado' | 'credenciais_invalidas' | 'erro_generico';
}

export interface AuthContextType {
  usuario: Usuario | null;
  login: (email: string, senha: string) => Promise<LoginResult>;
  logout: () => void;
  criarConta: (email: string, senha: string, nomeCompleto: string, cargo: 'gerente' | 'entregador', codigoAcesso?: string) => Promise<{ sucesso: boolean; mensagem: string }>;
  recuperarSenha: (email: string) => Promise<{ sucesso: boolean; mensagem: string }>;
  redefinirSenha: (token: string, novaSenha: string) => Promise<{ sucesso: boolean; mensagem: string }>;
  reenviarConfirmacao: (email: string) => Promise<{ sucesso: boolean; mensagem: string }>;
  isAuthenticated: boolean;
  isGerente: boolean;
  isEntregador: boolean;
}