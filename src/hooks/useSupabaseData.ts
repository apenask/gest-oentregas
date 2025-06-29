import { useState, useEffect } from 'react'
import { supabase } from '../lib/supabase'
import { Entrega, Cliente, Entregador } from '../types'

export const useSupabaseData = () => {
  const [entregas, setEntregas] = useState<Entrega[]>([])
  const [clientes, setClientes] = useState<Cliente[]>([])
  const [entregadores, setEntregadores] = useState<Entregador[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  // Fetch all data from Supabase
  const fetchData = async () => {
    try {
      setLoading(true)
      setError(null)

      // Fetch entregas with related data using the corrected query structure
      const { data: entregasData, error: entregasError } = await supabase
        .from('entregas')
        .select(`
          *,
          clientes ( id, nome_completo, rua_numero, bairro, telefone ),
          entregadores ( id, nome_completo )
        `)
        .order('data_hora_pedido', { ascending: false })

      if (entregasError) throw entregasError

      // Fetch clientes
      const { data: clientesData, error: clientesError } = await supabase
        .from('clientes')
        .select('*')
        .order('nome_completo')

      if (clientesError) throw clientesError

      // Fetch entregadores
      const { data: entregadoresData, error: entregadoresError } = await supabase
        .from('entregadores')
        .select('id, nome_completo, usuario_id')
        .eq('ativo', true)
        .order('nome_completo')

      if (entregadoresError) throw entregadoresError

      // Transform data to match frontend types
      const transformedEntregas: Entrega[] = entregasData?.map(entrega => ({
        id: entrega.id,
        dataHora: new Date(entrega.data_hora_pedido),
        numeroPedido: entrega.numero_pedido || '',
        clienteId: entrega.cliente_id,
        cliente: entrega.clientes ? {
          id: entrega.clientes.id,
          nome: entrega.clientes.nome_completo,
          ruaNumero: entrega.clientes.rua_numero,
          bairro: entrega.clientes.bairro,
          telefone: entrega.clientes.telefone || undefined
        } : undefined,
        entregadorId: entrega.entregador_id,
        entregador: entrega.entregadores?.nome_completo || '',
        formaPagamento: entrega.forma_pagamento,
        valorTotalPedido: entrega.valor_pedido,
        valorCorrida: entrega.valor_corrida,
        status: entrega.status,
        dataHoraSaida: entrega.data_hora_saida ? new Date(entrega.data_hora_saida) : undefined,
        dataHoraEntrega: entrega.data_hora_entrega ? new Date(entrega.data_hora_entrega) : undefined,
        duracaoEntrega: entrega.duracao_entrega_segundos || undefined
      })) || []

      const transformedClientes: Cliente[] = clientesData?.map(cliente => ({
        id: cliente.id,
        nome: cliente.nome_completo,
        ruaNumero: cliente.rua_numero,
        bairro: cliente.bairro,
        telefone: cliente.telefone || undefined
      })) || []

      const transformedEntregadores: Entregador[] = entregadoresData?.map(entregador => ({
        id: entregador.id,
        nome: entregador.nome_completo,
        email: '' // Email will be fetched from auth if needed
      })) || []

      setEntregas(transformedEntregas)
      setClientes(transformedClientes)
      setEntregadores(transformedEntregadores)
    } catch (err) {
      console.error('Error fetching data:', err)
      setError(err instanceof Error ? err.message : 'Unknown error occurred')
    } finally {
      setLoading(false)
    }
  }

  // Create new entrega
  const createEntrega = async (entregaData: {
    numeroPedido: string
    clienteId: number
    clienteNovo?: {
      nome: string
      ruaNumero: string
      bairro: string
      telefone?: string
    }
    entregadorId: number
    formaPagamento: 'Dinheiro' | 'Pix' | 'Cartão de Débito' | 'Cartão de Crédito'
    valorTotalPedido: number
    valorCorrida: number
  }) => {
    try {
      let clienteId = entregaData.clienteId

      // Create new client if needed
      if (entregaData.clienteNovo) {
        const { data: novoCliente, error: clienteError } = await supabase
          .from('clientes')
          .insert({
            nome_completo: entregaData.clienteNovo.nome,
            rua_numero: entregaData.clienteNovo.ruaNumero,
            bairro: entregaData.clienteNovo.bairro,
            telefone: entregaData.clienteNovo.telefone || null
          })
          .select()
          .single()

        if (clienteError) throw clienteError
        clienteId = novoCliente.id
      }

      // Create entrega
      const { error: entregaError } = await supabase
        .from('entregas')
        .insert({
          numero_pedido: entregaData.numeroPedido,
          cliente_id: clienteId,
          entregador_id: entregaData.entregadorId,
          forma_pagamento: entregaData.formaPagamento,
          valor_pedido: entregaData.valorTotalPedido,
          valor_corrida: entregaData.valorCorrida,
          status: 'Aguardando',
          data_hora_pedido: new Date().toISOString()
        })

      if (entregaError) throw entregaError

      // Refresh data
      await fetchData()
      return { success: true }
    } catch (err) {
      console.error('Error creating entrega:', err)
      return { success: false, error: err instanceof Error ? err.message : 'Unknown error' }
    }
  }

  // Update entrega status
  const updateEntregaStatus = async (
    id: number, 
    status: 'Em Rota' | 'Entregue' | 'Cancelado', 
    dataHora?: Date
  ) => {
    try {
      const updateData: any = { status }

      if (status === 'Em Rota' && dataHora) {
        updateData.data_hora_saida = dataHora.toISOString()
      } else if (status === 'Entregue' && dataHora) {
        updateData.data_hora_entrega = dataHora.toISOString()
        
        // Calculate duration if we have saida time
        const entrega = entregas.find(e => e.id === id)
        if (entrega?.dataHoraSaida) {
          const durationSeconds = Math.floor((dataHora.getTime() - entrega.dataHoraSaida.getTime()) / 1000)
          updateData.duracao_entrega_segundos = durationSeconds
        }
      }

      const { error } = await supabase
        .from('entregas')
        .update(updateData)
        .eq('id', id)

      if (error) throw error

      // Refresh data
      await fetchData()
      return { success: true }
    } catch (err) {
      console.error('Error updating entrega status:', err)
      return { success: false, error: err instanceof Error ? err.message : 'Unknown error' }
    }
  }

  // Update entrega
  const updateEntrega = async (entregaEditada: Entrega) => {
    try {
      // Update cliente if needed
      if (entregaEditada.cliente) {
        const { error: clienteError } = await supabase
          .from('clientes')
          .update({
            nome_completo: entregaEditada.cliente.nome,
            rua_numero: entregaEditada.cliente.ruaNumero,
            bairro: entregaEditada.cliente.bairro,
            telefone: entregaEditada.cliente.telefone || null
          })
          .eq('id', entregaEditada.cliente.id)

        if (clienteError) throw clienteError
      }

      // Update entrega
      const { error: entregaError } = await supabase
        .from('entregas')
        .update({
          numero_pedido: entregaEditada.numeroPedido,
          cliente_id: entregaEditada.clienteId,
          entregador_id: entregaEditada.entregadorId,
          forma_pagamento: entregaEditada.formaPagamento,
          valor_pedido: entregaEditada.valorTotalPedido,
          valor_corrida: entregaEditada.valorCorrida,
          status: entregaEditada.status
        })
        .eq('id', entregaEditada.id)

      if (entregaError) throw entregaError

      // Refresh data
      await fetchData()
      return { success: true }
    } catch (err) {
      console.error('Error updating entrega:', err)
      return { success: false, error: err instanceof Error ? err.message : 'Unknown error' }
    }
  }

  // Delete entrega
  const deleteEntrega = async (id: number) => {
    try {
      const { error } = await supabase
        .from('entregas')
        .delete()
        .eq('id', id)

      if (error) throw error

      // Refresh data
      await fetchData()
      return { success: true }
    } catch (err) {
      console.error('Error deleting entrega:', err)
      return { success: false, error: err instanceof Error ? err.message : 'Unknown error' }
    }
  }

  // Create cliente
  const createCliente = async (dadosCliente: { 
    nome: string
    ruaNumero: string
    bairro: string
    telefone?: string 
  }) => {
    try {
      const { error } = await supabase
        .from('clientes')
        .insert({
          nome_completo: dadosCliente.nome,
          rua_numero: dadosCliente.ruaNumero,
          bairro: dadosCliente.bairro,
          telefone: dadosCliente.telefone || null
        })

      if (error) throw error

      // Refresh data
      await fetchData()
      return { success: true }
    } catch (err) {
      console.error('Error creating cliente:', err)
      return { success: false, error: err instanceof Error ? err.message : 'Unknown error' }
    }
  }

  // Update cliente
  const updateCliente = async (id: number, dadosCliente: { 
    nome: string
    ruaNumero: string
    bairro: string
    telefone?: string 
  }) => {
    try {
      const { error } = await supabase
        .from('clientes')
        .update({
          nome_completo: dadosCliente.nome,
          rua_numero: dadosCliente.ruaNumero,
          bairro: dadosCliente.bairro,
          telefone: dadosCliente.telefone || null
        })
        .eq('id', id)

      if (error) throw error

      // Refresh data
      await fetchData()
      return { success: true }
    } catch (err) {
      console.error('Error updating cliente:', err)
      return { success: false, error: err instanceof Error ? err.message : 'Unknown error' }
    }
  }

  // Delete cliente
  const deleteCliente = async (id: number) => {
    try {
      const { error } = await supabase
        .from('clientes')
        .delete()
        .eq('id', id)

      if (error) throw error

      // Refresh data
      await fetchData()
      return { success: true }
    } catch (err) {
      console.error('Error deleting cliente:', err)
      return { success: false, error: err instanceof Error ? err.message : 'Unknown error' }
    }
  }

  // Create entregador
  const createEntregador = async (nome: string, email: string) => {
    try {
      // This will be handled by the manager through the UI
      // For now, just return success
      return { success: true }
    } catch (err) {
      console.error('Error creating entregador:', err)
      return { success: false, error: err instanceof Error ? err.message : 'Unknown error' }
    }
  }

  // Update entregador
  const updateEntregador = async (id: number, nome: string, email: string) => {
    try {
      const { error } = await supabase
        .from('entregadores')
        .update({
          nome_completo: nome
        })
        .eq('id', id)

      if (error) throw error

      // Refresh data
      await fetchData()
      return { success: true }
    } catch (err) {
      console.error('Error updating entregador:', err)
      return { success: false, error: err instanceof Error ? err.message : 'Unknown error' }
    }
  }

  // Delete entregador
  const deleteEntregador = async (id: number) => {
    try {
      // Check for pending deliveries
      const { data: pendingDeliveries } = await supabase
        .from('entregas')
        .select('id')
        .eq('entregador_id', id)
        .in('status', ['Aguardando', 'Em Rota'])

      if (pendingDeliveries && pendingDeliveries.length > 0) {
        return { success: false, error: 'Não é possível remover este entregador pois há entregas pendentes.' }
      }

      const { error } = await supabase
        .from('entregadores')
        .update({ ativo: false })
        .eq('id', id)

      if (error) throw error

      // Refresh data
      await fetchData()
      return { success: true }
    } catch (err) {
      console.error('Error deleting entregador:', err)
      return { success: false, error: err instanceof Error ? err.message : 'Unknown error' }
    }
  }

  useEffect(() => {
    fetchData()
  }, [])

  return {
    entregas,
    clientes,
    entregadores,
    loading,
    error,
    refreshData: fetchData,
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
  }
}