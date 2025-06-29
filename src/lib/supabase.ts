import { createClient } from '@supabase/supabase-js'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY

if (!supabaseUrl || !supabaseAnonKey) {
  throw new Error('Missing Supabase environment variables')
}

export const supabase = createClient(supabaseUrl, supabaseAnonKey)

// Database types based on the new schema
export interface Database {
  public: {
    Tables: {
      perfis: {
        Row: {
          id: string
          nome_completo: string
          cargo: 'gerente' | 'entregador'
          updated_at: string
        }
        Insert: {
          id: string
          nome_completo: string
          cargo: 'gerente' | 'entregador'
        }
        Update: {
          nome_completo?: string
          cargo?: 'gerente' | 'entregador'
        }
      }
      entregadores: {
        Row: {
          id: number
          usuario_id: string
          nome_completo: string
          ativo: boolean
          created_at: string
          updated_at: string
        }
        Insert: {
          usuario_id: string
          nome_completo: string
          ativo?: boolean
        }
        Update: {
          nome_completo?: string
          ativo?: boolean
        }
      }
      clientes: {
        Row: {
          id: number
          nome_completo: string
          rua_numero: string
          bairro: string
          telefone: string | null
          created_at: string
          updated_at: string
        }
        Insert: {
          nome_completo: string
          rua_numero: string
          bairro: string
          telefone?: string | null
        }
        Update: {
          nome_completo?: string
          rua_numero?: string
          bairro?: string
          telefone?: string | null
        }
      }
      entregas: {
        Row: {
          id: number
          numero_pedido: string | null
          cliente_id: number
          entregador_id: number
          forma_pagamento: 'Dinheiro' | 'Pix' | 'Cartão de Débito' | 'Cartão de Crédito'
          valor_pedido: number
          valor_corrida: number
          status: 'Aguardando' | 'Em Rota' | 'Entregue' | 'Cancelado'
          data_hora_pedido: string
          data_hora_saida: string | null
          data_hora_entrega: string | null
          duracao_entrega_segundos: number | null
          created_at: string
          updated_at: string
        }
        Insert: {
          numero_pedido?: string | null
          cliente_id: number
          entregador_id: number
          forma_pagamento: 'Dinheiro' | 'Pix' | 'Cartão de Débito' | 'Cartão de Crédito'
          valor_pedido: number
          valor_corrida: number
          status?: 'Aguardando' | 'Em Rota' | 'Entregue' | 'Cancelado'
          data_hora_pedido?: string
          data_hora_saida?: string | null
          data_hora_entrega?: string | null
          duracao_entrega_segundos?: number | null
        }
        Update: {
          numero_pedido?: string | null
          cliente_id?: number
          entregador_id?: number
          forma_pagamento?: 'Dinheiro' | 'Pix' | 'Cartão de Débito' | 'Cartão de Crédito'
          valor_pedido?: number
          valor_corrida?: number
          status?: 'Aguardando' | 'Em Rota' | 'Entregue' | 'Cancelado'
          data_hora_pedido?: string
          data_hora_saida?: string | null
          data_hora_entrega?: string | null
          duracao_entrega_segundos?: number | null
        }
      }
      configuracoes: {
        Row: {
          id: number
          chave: string
          valor: string | null
          descricao: string | null
          created_at: string
          updated_at: string
        }
        Insert: {
          chave: string
          valor?: string | null
          descricao?: string | null
        }
        Update: {
          chave?: string
          valor?: string | null
          descricao?: string | null
        }
      }
    }
  }
}