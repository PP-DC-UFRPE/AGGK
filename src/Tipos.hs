{-# LANGUAGE DeriveGeneric #-}

module Tipos where

import GHC.Generics (Generic)
import Data.Aeson (ToJSON, FromJSON)
import Data.Time (UTCTime)

-- Tipos básicos
type IdCliente = Int
type CodigoAtivo = String

-- Cliente do banco
data Cliente = Cliente {
    clienteID :: IdCliente,
    nomeCliente :: String,
    senha :: String,
    perguntaPessoalSenha :: String,
    respostaPerguntaPessoal :: String
} deriving (Show, Generic)

-- Conta de investimentos
data Conta = Conta {
    idClienteConta :: IdCliente,
    saldo :: Double
} deriving (Show, Generic)

-- Ativo disponível no mercado
data Ativo = Ativo {
    codigo :: CodigoAtivo,
    nomeAtivo :: String
} deriving (Show, Generic, Eq)

-- Item da carteira do cliente
data ItemCarteira = ItemCarteira {
    ativo :: Ativo,
    quantidade :: Int
} deriving (Show, Generic)

-- Carteira de ativos do cliente
data Carteira = Carteira {
    idClienteCarteira :: IdCliente,
    itens :: [ItemCarteira]
} deriving (Show, Generic)

-- Tipo da transação realizada
data TipoTransacao = Compra | Venda deriving (Show, Generic)

-- Registro de uma operação feita
data RegistroTransacao = RegistroTransacao {
    idClienteTransacao :: IdCliente,
    tipoTransacao :: TipoTransacao,
    codigoTransacao :: CodigoAtivo,
    quantidadeTransacionada :: Int,
    precoUnitario :: Double,
    timestamp :: UTCTime
} deriving (Show, Generic)

-- Estado geral do sistema bancário
data EstadoBanco = EstadoBanco {
    clientes :: [Cliente],
    contas :: [Conta],
    carteiras :: [Carteira],
    historico :: [RegistroTransacao],
    proximoIDCliente :: IdCliente,
    ativosDoMercado :: [Ativo]
} deriving (Show, Generic)

-- Instâncias JSON para leitura/gravação em arquivo
instance ToJSON Cliente
instance FromJSON Cliente
instance ToJSON Conta
instance FromJSON Conta
instance ToJSON Ativo
instance FromJSON Ativo
instance ToJSON ItemCarteira
instance FromJSON ItemCarteira
instance ToJSON Carteira
instance FromJSON Carteira
instance ToJSON TipoTransacao
instance FromJSON TipoTransacao
instance ToJSON RegistroTransacao
instance FromJSON RegistroTransacao
instance ToJSON EstadoBanco
instance FromJSON EstadoBanco