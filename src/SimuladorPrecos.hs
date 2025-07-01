{-# LANGUAGE DeriveGeneric #-}

module SimuladorPrecos where

import Tipos
import Data.Time (UTCTime, diffUTCTime)
import System.Random (StdGen, randomR, mkStdGen)
import GHC.Generics (Generic)
import Data.Aeson (ToJSON, FromJSON)
import qualified Data.Map as Map
import Data.Map (Map)

-- Constantes de instabilidade
instabilidadePETR4, instabilidadeVALE3, instabilidadeMGLU3, instabilidadeITUB4 :: Double
instabilidadePETR4 = 100   -- Petrobras - instabilidade moderada (30%)
instabilidadeVALE3 = 20   -- Vale - instabilidade baixa (20%)
instabilidadeMGLU3 = 200   -- Magazine Luiza - instabilidade alta (80%)
instabilidadeITUB4 = 15  -- Itaú - instabilidade muito baixa (15%)

-- Função para obter instabilidade baseada no código do ativo
obterInstabilidade :: CodigoAtivo -> Double
obterInstabilidade codigo = case codigo of
    "PETR4" -> instabilidadePETR4
    "VALE3" -> instabilidadeVALE3
    "MGLU3" -> instabilidadeMGLU3
    "ITUB4" -> instabilidadeITUB4
    _ -> 0.25  -- Instabilidade padrão para ativos desconhecidos

-- Estado do simulador de preços (com gerador aleatório)
data EstadoSimulador = EstadoSimulador {
    ativosComPrecos :: Map CodigoAtivo AtivoComInstabilidade,
    geradorAleatorio :: StdGen
} deriving (Show)

-- Funções para conversão entre tipos serializável e não-serializável
paraSerializavel :: EstadoSimulador -> EstadoSimuladorSerializavel
paraSerializavel (EstadoSimulador ativos _) = EstadoSimuladorSerializavel ativos

deSerializavel :: EstadoSimuladorSerializavel -> EstadoSimulador
deSerializavel (EstadoSimuladorSerializavel ativos) = EstadoSimulador ativos (mkStdGen 42)

-- Inicializa o simulador com os ativos padrão (sem armazenar instabilidade)
inicializarSimulador :: UTCTime -> EstadoSimulador
inicializarSimulador tempoInicial = EstadoSimulador {
    ativosComPrecos = Map.fromList [
        ("PETR4", AtivoComInstabilidade (Ativo "PETR4" "Petrobras PN") 15.75 tempoInicial),
        ("VALE3", AtivoComInstabilidade (Ativo "VALE3" "Vale ON") 45.50 tempoInicial),
        ("MGLU3", AtivoComInstabilidade (Ativo "MGLU3" "Magazine Luiza ON") 2.50 tempoInicial),
        ("ITUB4", AtivoComInstabilidade (Ativo "ITUB4" "Itaú Unibanco PN") 30.10 tempoInicial)
    ],
    geradorAleatorio = mkStdGen 42
}

-- Atualiza os preços de todos os ativos baseado no tempo decorrido
atualizarPrecos :: UTCTime -> EstadoSimulador -> EstadoSimulador
atualizarPrecos tempoAtual estado = 
    let ativosAtualizados = Map.map (atualizarPrecoAtivo tempoAtual) (ativosComPrecos estado)
        novoGerador = gerarNovoSeed (geradorAleatorio estado) (length ativosAtualizados)
    in estado { ativosComPrecos = ativosAtualizados, geradorAleatorio = novoGerador }

-- Atualiza o preço de um ativo específico (usando instabilidade das constantes)
atualizarPrecoAtivo :: UTCTime -> AtivoComInstabilidade -> AtivoComInstabilidade
atualizarPrecoAtivo tempoAtual ativoInfo =
    let codigoAtivo = codigo $ ativoBase ativoInfo
        instabilidadeAtivo = obterInstabilidade codigoAtivo
        tempoDecorrido = realToFrac $ diffUTCTime tempoAtual (ultimaAtualizacao ativoInfo)
        -- Converte segundos para horas
        horasDecorridas = tempoDecorrido / 3600.0
        -- Fator de variação baseado no tempo e instabilidade
        fatorVariacao = min 0.5 (horasDecorridas * instabilidadeAtivo * 0.1)
        -- Gera variação aleatória (simplificada usando hash do código)
        semente = hashCodigo codigoAtivo (round tempoDecorrido)
        gerador = mkStdGen semente
        (variacaoAleatoria, _) = randomR (-fatorVariacao, fatorVariacao) gerador
        novoPreco = max 0.01 (precoAtual ativoInfo * (1.0 + variacaoAleatoria))
    in ativoInfo { 
        precoAtual = novoPreco, 
        ultimaAtualizacao = tempoAtual 
    }

-- Obtém o preço atual de um ativo do simulador
obterPrecoAtualizado :: CodigoAtivo -> EstadoSimulador -> Maybe Double
obterPrecoAtualizado codigo estado = 
    case Map.lookup codigo (ativosComPrecos estado) of
        Nothing -> Nothing
        Just ativoInfo -> Just (precoAtual ativoInfo)

-- Obtém todos os preços atuais como lista de tuplas
obterTodosPrecos :: EstadoSimulador -> [(CodigoAtivo, Double)]
obterTodosPrecos estado = 
    Map.toList $ Map.map precoAtual (ativosComPrecos estado)

-- Força uma atualização de preço para um ativo específico
forcarAtualizacaoAtivo :: CodigoAtivo -> UTCTime -> EstadoSimulador -> EstadoSimulador
forcarAtualizacaoAtivo codigo tempoAtual estado =
    case Map.lookup codigo (ativosComPrecos estado) of
        Nothing -> estado
        Just ativoInfo ->
            let ativoAtualizado = atualizarPrecoAtivo tempoAtual ativoInfo
                ativosAtualizados = Map.insert codigo ativoAtualizado (ativosComPrecos estado)
            in estado { ativosComPrecos = ativosAtualizados }

-- Adiciona um novo ativo ao simulador (sem especificar instabilidade)
adicionarAtivoAoSimulador :: Ativo -> Double -> UTCTime -> EstadoSimulador -> EstadoSimulador
adicionarAtivoAoSimulador ativo preco tempo estado =
    let novoAtivoInfo = AtivoComInstabilidade ativo preco tempo
        ativosAtualizados = Map.insert (codigo ativo) novoAtivoInfo (ativosComPrecos estado)
    in estado { ativosComPrecos = ativosAtualizados }

-- Retorna informações detalhadas de um ativo (com instabilidade calculada)
obterInfoAtivoCompleta :: CodigoAtivo -> EstadoSimulador -> Maybe (AtivoComInstabilidade, Double)
obterInfoAtivoCompleta codigo estado = 
    case Map.lookup codigo (ativosComPrecos estado) of
        Nothing -> Nothing
        Just ativoInfo -> Just (ativoInfo, obterInstabilidade codigo)

-- Função auxiliar para gerar hash simples baseado no código do ativo
hashCodigo :: String -> Int -> Int
hashCodigo str tempo = (sum (map fromEnum str) + tempo) `mod` 100000

-- Função auxiliar para gerar nova semente
gerarNovoSeed :: StdGen -> Int -> StdGen
gerarNovoSeed gen n = 
    let (novaSemente, _) = randomR (1, 1000000) gen
    in mkStdGen (novaSemente + n)

-- Simula volatilidade extrema (para eventos especiais)
aplicarChoqueMercado :: Double -> UTCTime -> EstadoSimulador -> EstadoSimulador
aplicarChoqueMercado intensidade tempoAtual estado =
    let ativosComChoque = Map.map (aplicarChoqueAtivo intensidade tempoAtual) (ativosComPrecos estado)
    in estado { ativosComPrecos = ativosComChoque }

-- Aplica choque de mercado a um ativo específico
aplicarChoqueAtivo :: Double -> UTCTime -> AtivoComInstabilidade -> AtivoComInstabilidade
aplicarChoqueAtivo intensidade tempoAtual ativoInfo =
    let codigoAtivo = codigo $ ativoBase ativoInfo
        semente = hashCodigo codigoAtivo (round intensidade * 1000)
        gerador = mkStdGen semente
        (variacaoChoque, _) = randomR (-intensidade, intensidade) gerador
        novoPreco = max 0.01 (precoAtual ativoInfo * (1.0 + variacaoChoque))
    in ativoInfo { 
        precoAtual = novoPreco,
        ultimaAtualizacao = tempoAtual 
    }