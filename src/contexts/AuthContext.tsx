import React, { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import { supabase } from '../lib/supabase';
import { Usuario, AuthContextType, LoginResult } from '../types';

const AuthContext = createContext<AuthContextType | undefined>(undefined);

interface AuthProviderProps {
  children: ReactNode;
}

// Código de acesso para gerentes (pode ser configurado via variável de ambiente)
const MANAGER_ACCESS_CODE = import.meta.env.VITE_MANAGER_ACCESS_CODE || 'BORDA777';

export const AuthProvider: React.FC<AuthProviderProps> = ({ children }) => {
  const [usuario, setUsuario] = useState<any>(null); // Para o usuário do Supabase Auth
  const [perfil, setPerfil] = useState<any>(null); // NOVO ESTADO para o perfil do DB
  const [loading, setLoading] = useState(true);

  // CENTRALIZED AUTH STATE MANAGEMENT
  useEffect(() => {
    setLoading(true);

    const { data: { subscription } } = supabase.auth.onAuthStateChange(
      async (event, session) => {
        console.log('Auth state change:', event, !!session?.user);
        
        const currentUser = session?.user ?? null;
        setUsuario(currentUser); // Define o usuário de autenticação

        if (currentUser) {
          // Se há um usuário, busca o perfil
          try {
            const { data: profileData, error } = await supabase
              .from('perfis')
              .select('*')
              .eq('id', currentUser.id)
              .maybeSingle();

            if (error && error.code !== 'PGRST116') {
              console.error('Erro ao buscar perfil:', error);
            }

            console.log('Profile data:', profileData);
            setPerfil(profileData ?? null); // Define o perfil (ou null se não encontrado)
          } catch (error) {
            console.error('Erro inesperado ao buscar perfil:', error);
            setPerfil(null);
          }
        } else {
          // Se não há usuário, não há perfil
          setPerfil(null);
        }
        
        setLoading(false); // Finaliza o carregamento
      }
    );

    return () => {
      subscription.unsubscribe();
    };
  }, []); // Roda apenas uma vez para configurar o listener

  const login = async (email: string, senha: string): Promise<LoginResult> => {
    try {
      console.log('Attempting login for:', email);
      
      // Use Supabase's native authentication
      const { data, error } = await supabase.auth.signInWithPassword({
        email: email.toLowerCase(),
        password: senha,
      });

      console.log('Login response:', { data: !!data.user, error: error?.message });

      if (error) {
        console.error('Erro de autenticação do Supabase:', error.message);
        
        // Handle specific error cases
        if (error.message.includes('Email not confirmed') || error.message.includes('email_not_confirmed')) {
          return {
            sucesso: false,
            mensagem: 'Seu email ainda não foi confirmado. Verifique sua caixa de entrada e clique no link de confirmação.',
            tipoErro: 'email_nao_confirmado'
          };
        }
        
        if (error.message.includes('Invalid login credentials') || error.message.includes('invalid_credentials')) {
          return {
            sucesso: false,
            mensagem: 'Email ou senha incorretos.',
            tipoErro: 'credenciais_invalidas'
          };
        }
        
        return {
          sucesso: false,
          mensagem: 'Erro ao fazer login. Tente novamente.',
          tipoErro: 'erro_generico'
        };
      }

      // CRITICAL FIX: Check if user exists and return success immediately
      if (data.user) {
        console.log('Login successful for user:', data.user.id);
        // The auth state change listener will handle loading the profile
        return { sucesso: true };
      }

      return {
        sucesso: false,
        mensagem: 'Erro inesperado ao fazer login.',
        tipoErro: 'erro_generico'
      };
    } catch (error) {
      console.error('Erro inesperado no login:', error);
      return {
        sucesso: false,
        mensagem: 'Erro inesperado ao fazer login.',
        tipoErro: 'erro_generico'
      };
    }
  };

  const criarConta = async (
    email: string, 
    senha: string, 
    nomeCompleto: string, 
    cargo: 'gerente' | 'entregador',
    codigoAcesso?: string
  ): Promise<{ sucesso: boolean; mensagem: string }> => {
    try {
      console.log('Iniciando criação de conta:', { email, cargo });
      
      // Validar código de acesso para gerentes
      if (cargo === 'gerente') {
        if (!codigoAcesso || codigoAcesso !== MANAGER_ACCESS_CODE) {
          return { sucesso: false, mensagem: 'Código de acesso inválido.' };
        }
      }

      // PASSO 1: Create Supabase auth account
      console.log('Criando conta de autenticação...');
      const { data: authData, error: authError } = await supabase.auth.signUp({
        email: email.toLowerCase(),
        password: senha,
      });

      if (authError) {
        console.error('Erro na criação da conta de auth:', authError);
        if (authError.message.includes('already registered')) {
          return { sucesso: false, mensagem: 'Este email já está cadastrado no sistema.' };
        }
        throw authError;
      }

      if (!authData.user) {
        return { sucesso: false, mensagem: 'Erro ao criar conta de autenticação.' };
      }

      console.log('Conta de auth criada com sucesso:', authData.user.id);

      // PASSO 2: Create profile in perfis table
      console.log('Criando perfil no banco...');
      const { error: perfilError } = await supabase
        .from('perfis')
        .insert({
          id: authData.user.id,
          nome_completo: nomeCompleto,
          cargo: cargo
        });

      if (perfilError) {
        console.error('Erro ao criar perfil:', perfilError);
        throw perfilError;
      }

      console.log('Perfil criado com sucesso');

      // PASSO 3: If entregador, also create entregador record
      if (cargo === 'entregador') {
        console.log('Criando registro de entregador...');
        const { error: entregadorError } = await supabase
          .from('entregadores')
          .insert({
            usuario_id: authData.user.id,
            nome_completo: nomeCompleto,
            ativo: true
          });

        if (entregadorError) {
          console.error('Erro ao criar entregador:', entregadorError);
          throw entregadorError;
        }

        console.log('Registro de entregador criado com sucesso');
      }

      return { sucesso: true, mensagem: `Conta de ${cargo} criada com sucesso! Verifique seu email para confirmar a conta.` };
    } catch (error) {
      console.error('Erro detalhado na criação da conta:', error);
      
      // Provide more detailed error messages
      if (error instanceof Error) {
        if (error.message.includes('permission denied') || error.message.includes('RLS')) {
          return { sucesso: false, mensagem: 'Erro de permissão no banco de dados. Verifique as políticas RLS.' };
        }
        return { sucesso: false, mensagem: `Erro ao criar conta: ${error.message}` };
      }
      
      return { sucesso: false, mensagem: 'Erro desconhecido ao criar conta.' };
    }
  };

  const recuperarSenha = async (email: string): Promise<{ sucesso: boolean; mensagem: string }> => {
    try {
      // Use Supabase's built-in password recovery
      const { error } = await supabase.auth.resetPasswordForEmail(email.toLowerCase(), {
        redirectTo: `${window.location.origin}/redefinir-senha`,
      });

      if (error) {
        if (error.message.includes('not found')) {
          return { sucesso: false, mensagem: 'Email não encontrado no sistema.' };
        }
        throw error;
      }

      return { 
        sucesso: true, 
        mensagem: 'Email de recuperação enviado! Verifique sua caixa de entrada.' 
      };
    } catch (error) {
      console.error('Password recovery error:', error);
      return { sucesso: false, mensagem: 'Erro ao enviar email de recuperação.' };
    }
  };

  const redefinirSenha = async (token: string, novaSenha: string): Promise<{ sucesso: boolean; mensagem: string }> => {
    try {
      // Use Supabase's built-in password update
      const { error } = await supabase.auth.updateUser({
        password: novaSenha
      });

      if (error) throw error;

      return { sucesso: true, mensagem: 'Senha redefinida com sucesso!' };
    } catch (error) {
      console.error('Password reset error:', error);
      return { sucesso: false, mensagem: 'Erro ao redefinir senha.' };
    }
  };

  const reenviarConfirmacao = async (email: string): Promise<{ sucesso: boolean; mensagem: string }> => {
    try {
      const { error } = await supabase.auth.resend({
        type: 'signup',
        email: email.toLowerCase(),
      });

      if (error) {
        throw error;
      }

      return { 
        sucesso: true, 
        mensagem: 'Email de confirmação reenviado! Verifique sua caixa de entrada.' 
      };
    } catch (error) {
      console.error('Resend confirmation error:', error);
      return { sucesso: false, mensagem: 'Erro ao reenviar email de confirmação.' };
    }
  };

  const logout = async () => {
    try {
      await supabase.auth.signOut();
      // The auth state change listener will handle setting usuario to null
    } catch (error) {
      console.error('Logout error:', error);
      // Force logout even if there's an error
      setUsuario(null);
      setPerfil(null);
    }
  };

  // Criar objeto Usuario compatível com o tipo existente
  const usuarioCompativel: Usuario | null = usuario && perfil ? {
    id: parseInt(usuario.id.replace(/-/g, '').substring(0, 10), 16),
    email: usuario.email || '',
    senha: '',
    nomeCompleto: perfil.nome_completo,
    cargo: perfil.cargo,
    entregadorId: undefined, // Será preenchido se necessário
    emailVerificado: true
  } : null;

  const value: AuthContextType = {
    usuario: usuarioCompativel,     // O objeto de usuário compatível
    login,
    logout,
    criarConta,
    recuperarSenha,
    redefinirSenha,
    reenviarConfirmacao,
    isAuthenticated: !!usuario && !!perfil && !loading, // Só considera autenticado se tem usuário E perfil
    isGerente: perfil?.cargo === 'gerente',
    isEntregador: perfil?.cargo === 'entregador'
  };

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = (): AuthContextType => {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth deve ser usado dentro de um AuthProvider');
  }
  return context;
};