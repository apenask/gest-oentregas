import React, { useState } from 'react';
import { Truck, FileText, Users, BarChart3, UserCheck, Settings } from 'lucide-react';
import { Dashboard } from './components/Dashboard';
import { NovaEntrega } from './components/NovaEntrega';
import { EditarEntrega } from './components/EditarEntrega';
import { Relatorios } from './components/Relatorios';
import { Entregadores } from './components/Entregadores';
import { Clientes } from './components/Clientes';
import { MeuPerfil } from './components/MeuPerfil';
import { Login } from './components/Login';
import { EntregadorDashboard } from './components/EntregadorDashboard';
import { AuthProvider, useAuth } from './contexts/AuthContext';
import { useSupabaseData } from './hooks/useSupabaseData';
import { TelaAtiva, Entrega } from './types';

function AppContent() {
  const { isAuthenticated, isGerente, isEntregador, logout, usuario } = useAuth();
  const [telaAtiva, setTelaAtiva] = useState<TelaAtiva>('dashboard');
  const [mostrarNovaEntrega, setMostrarNovaEntrega] = useState(false);
  const [mostrarMeuPerfil, setMostrarMeuPerfil] = useState(false);
  const [entregaParaEditar, setEntregaParaEditar] = useState<Entrega | null>(null);
  
  const {
    entregas,
    clientes,
    entregadores,
    loading,
    error,
    createEntrega,
    updateEntregaStatus,
    updateEntrega,
    deleteEntrega,
    createCliente,
    updateCliente,
    deleteCliente,
    createEntregador,
    updateEntregador,
    deleteEntregador
  } = useSupabaseData();

  // Se não estiver autenticado, mostrar tela de login
  if (!isAuthenticated) {
    return <Login />;
  }

  // Show loading state
  if (loading) {
    return (
      <div className="min-h-screen bg-gray-900 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-red-500 mx-auto mb-4"></div>
          <p className="text-white">Carregando dados...</p>
        </div>
      </div>
    );
  }

  // Show error state
  if (error) {
    return (
      <div className="min-h-screen bg-gray-900 flex items-center justify-center">
        <div className="text-center">
          <p className="text-red-400 mb-4">Erro ao carregar dados: {error}</p>
          <button 
            onClick={() => window.location.reload()} 
            className="bg-red-600 hover:bg-red-700 text-white px-4 py-2 rounded"
          >
            Tentar Novamente
          </button>
        </div>
      </div>
    );
  }

  // Se for entregador, mostrar dashboard específico
  if (isEntregador) {
    return (
      <EntregadorDashboard
        entregas={entregas}
        clientes={clientes}
        onAtualizarStatus={updateEntregaStatus}
      />
    );
  }

  const handleNovaEntrega = async (dadosEntrega: {
    numeroPedido: string;
    clienteId: number;
    clienteNovo?: {
      nome: string;
      ruaNumero: string;
      bairro: string;
      telefone?: string;
    };
    entregadorId: number;
    formaPagamento: 'Dinheiro' | 'Pix' | 'Cartão de Débito' | 'Cartão de Crédito';
    valorTotalPedido: number;
    valorCorrida: number;
  }) => {
    const result = await createEntrega(dadosEntrega);
    if (result.success) {
      setMostrarNovaEntrega(false);
    } else {
      alert('Erro ao criar entrega: ' + result.error);
    }
  };

  const handleAtualizarStatus = async (id: number, status: 'Em Rota' | 'Entregue' | 'Cancelado', dataHora?: Date) => {
    const result = await updateEntregaStatus(id, status, dataHora);
    if (!result.success) {
      alert('Erro ao atualizar status: ' + result.error);
    }
  };

  const handleEditarEntrega = (entrega: Entrega) => {
    setEntregaParaEditar(entrega);
  };

  const handleSalvarEdicaoEntrega = async (entregaEditada: Entrega) => {
    const result = await updateEntrega(entregaEditada);
    if (result.success) {
      setEntregaParaEditar(null);
    } else {
      alert('Erro ao editar entrega: ' + result.error);
    }
  };

  const handleExcluirEntrega = async (id: number) => {
    const result = await deleteEntrega(id);
    if (!result.success) {
      alert('Erro ao excluir entrega: ' + result.error);
    }
  };

  const handleAdicionarEntregador = async (nome: string, email: string) => {
    const result = await createEntregador(nome, email);
    if (!result.success) {
      alert('Erro ao adicionar entregador: ' + result.error);
    }
  };

  const handleEditarEntregador = async (id: number, nome: string, email: string) => {
    const result = await updateEntregador(id, nome, email);
    if (!result.success) {
      alert('Erro ao editar entregador: ' + result.error);
    }
  };

  const handleRemoverEntregador = async (id: number) => {
    const result = await deleteEntregador(id);
    if (!result.success) {
      alert(result.error || 'Erro ao remover entregador');
    }
  };

  const handleAtualizarPerfil = async (email: string, senha: string, nomeCompleto: string) => {
    // This would need to be implemented in the hook
    console.log('Update profile:', { email, senha, nomeCompleto });
  };

  const handleAdicionarCliente = async (dadosCliente: { nome: string; ruaNumero: string; bairro: string; telefone?: string }) => {
    const result = await createCliente(dadosCliente);
    if (!result.success) {
      alert('Erro ao adicionar cliente: ' + result.error);
    }
  };

  const handleEditarCliente = async (id: number, dadosCliente: { nome: string; ruaNumero: string; bairro: string; telefone?: string }) => {
    const result = await updateCliente(id, dadosCliente);
    if (!result.success) {
      alert('Erro ao editar cliente: ' + result.error);
    }
  };

  const handleRemoverCliente = async (id: number) => {
    const result = await deleteCliente(id);
    if (!result.success) {
      alert('Erro ao remover cliente: ' + result.error);
    }
  };

  // Se estiver na tela de perfil
  if (mostrarMeuPerfil) {
    return (
      <div className="min-h-screen bg-gray-900">
        <header className="bg-gray-800 border-b border-gray-700 shadow-lg">
          <div className="w-full px-4 sm:px-6 lg:px-8">
            <div className="flex items-center justify-between h-16">
              <div className="flex items-center gap-4">
                <img 
                  src="/borda de fogo - logo - nome preto e vermelho.png" 
                  alt="Pizzaria Borda de Fogo" 
                  className="h-12 w-auto"
                />
                <div className="hidden sm:block">
                  <h1 className="text-xl font-bold text-white">
                    Pizzaria Borda de Fogo
                  </h1>
                  <p className="text-sm text-gray-400">Configurações da Conta</p>
                </div>
              </div>
              
              <button
                onClick={logout}
                className="bg-red-600 hover:bg-red-700 text-white px-2 sm:px-3 py-2 rounded-md font-medium transition-colors duration-200 text-xs sm:text-sm"
              >
                Sair
              </button>
            </div>
          </div>
        </header>

        <main className="w-full px-4 sm:px-6 lg:px-8 py-4 sm:py-8">
          <MeuPerfil
            onVoltar={() => setMostrarMeuPerfil(false)}
            onAtualizarPerfil={handleAtualizarPerfil}
          />
        </main>
      </div>
    );
  }

  // Interface do gerente
  const menuItems = [
    { id: 'dashboard' as TelaAtiva, label: 'Dashboard', icon: BarChart3 },
    { id: 'relatorios' as TelaAtiva, label: 'Relatórios', icon: FileText },
    { id: 'entregadores' as TelaAtiva, label: 'Entregadores', icon: Users },
    { id: 'clientes' as TelaAtiva, label: 'Clientes', icon: UserCheck }
  ];

  return (
    <div className="min-h-screen bg-gray-900">
      {/* Header */}
      <header className="bg-gray-800 border-b border-gray-700 shadow-lg">
        <div className="w-full px-4 sm:px-6 lg:px-8">
          <div className="flex items-center justify-between h-16">
            <div className="flex items-center gap-4">
              <img 
                src="/borda de fogo - logo - nome preto e vermelho.png" 
                alt="Pizzaria Borda de Fogo" 
                className="h-12 w-auto"
              />
              <div className="hidden sm:block">
                <h1 className="text-xl font-bold text-white">
                  Pizzaria Borda de Fogo
                </h1>
                <p className="text-sm text-gray-400">Controle de Entregas</p>
              </div>
            </div>
            
            <div className="flex items-center gap-2 sm:gap-4">
              <nav className="flex space-x-1">
                {menuItems.map((item) => {
                  const Icon = item.icon;
                  return (
                    <button
                      key={item.id}
                      onClick={() => setTelaAtiva(item.id)}
                      className={`px-2 sm:px-3 py-2 rounded-md font-medium transition-colors duration-200 flex items-center gap-1 sm:gap-2 text-xs sm:text-sm lg:text-base ${
                        telaAtiva === item.id
                          ? 'bg-red-600 text-white'
                          : 'text-gray-300 hover:text-white hover:bg-gray-700'
                      }`}
                    >
                      <Icon size={16} />
                      <span className="hidden md:inline">{item.label}</span>
                    </button>
                  );
                })}
              </nav>
              
              {/* Botão Meu Perfil - Apenas para Gerente */}
              {isGerente && (
                <button
                  onClick={() => setMostrarMeuPerfil(true)}
                  className="text-gray-300 hover:text-white hover:bg-gray-700 p-2 rounded-md transition-colors duration-200"
                  title="Meu Perfil"
                >
                  <Settings size={18} />
                </button>
              )}
              
              <button
                onClick={logout}
                className="bg-red-600 hover:bg-red-700 text-white px-2 sm:px-3 py-2 rounded-md font-medium transition-colors duration-200 text-xs sm:text-sm"
              >
                Sair
              </button>
            </div>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="w-full px-4 sm:px-6 lg:px-8 py-4 sm:py-8">
        {telaAtiva === 'dashboard' && (
          <Dashboard
            entregas={entregas}
            entregadores={entregadores}
            clientes={clientes}
            onNovaEntrega={() => setMostrarNovaEntrega(true)}
            onAtualizarStatus={handleAtualizarStatus}
            onEditarEntrega={handleEditarEntrega}
            onExcluirEntrega={handleExcluirEntrega}
          />
        )}
        
        {telaAtiva === 'relatorios' && (
          <Relatorios
            entregas={entregas}
            entregadores={entregadores}
            clientes={clientes}
          />
        )}
        
        {telaAtiva === 'entregadores' && (
          <Entregadores
            entregadores={entregadores}
            onAdicionarEntregador={handleAdicionarEntregador}
            onEditarEntregador={handleEditarEntregador}
            onRemoverEntregador={handleRemoverEntregador}
          />
        )}

        {telaAtiva === 'clientes' && (
          <Clientes
            clientes={clientes}
            onAdicionarCliente={handleAdicionarCliente}
            onEditarCliente={handleEditarCliente}
            onRemoverCliente={handleRemoverCliente}
          />
        )}
      </main>

      {/* Modal Nova Entrega */}
      {mostrarNovaEntrega && (
        <NovaEntrega
          entregadores={entregadores}
          clientes={clientes}
          onSalvar={handleNovaEntrega}
          onFechar={() => setMostrarNovaEntrega(false)}
        />
      )}

      {/* Modal Editar Entrega */}
      {entregaParaEditar && (
        <EditarEntrega
          entrega={entregaParaEditar}
          entregadores={entregadores}
          clientes={clientes}
          onSalvar={handleSalvarEdicaoEntrega}
          onFechar={() => setEntregaParaEditar(null)}
        />
      )}
    </div>
  );
}

function App() {
  return (
    <AuthProvider>
      <AppContent />
    </AuthProvider>
  );
}

export default App;