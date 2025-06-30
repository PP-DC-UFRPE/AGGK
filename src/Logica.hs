module Logica where

import Tipos
import Data.Maybe (isJust, fromJust, fromMaybe)
import Data.List (find, sortOn)
import Data.Time (UTCTime)
import Data.Time.Format (formatTime, defaultTimeLocale)
import Data.Time.LocalTime (TimeZone, utcToZonedTime)
import Data.Ord (Down(..))

-- Lista de todos os ativos disponíveis para negociação em nosso banco
ativosDisponiveis :: [Ativo]
ativosDisponiveis = [
    Ativo "PETR4" "Petrobras PN",
    Ativo "VALE3" "Vale ON",
    Ativo "MGLU3" "Magazine Luiza ON",
    Ativo "ITUB4" "Itaú Unibanco PN"
    ]

-- Preços fixos para os ativos
precosDeMercado :: [(CodigoAtivo, Double)]
precosDeMercado = [("PETR4", 15.75), ("VALE3", 45.50), ("MGLU3", 2.50), ("ITUB4", 30.10)]

-- Função para buscar o preço atual de um ativo
obterPreco :: CodigoAtivo -> Maybe Double
obterPreco codigo = lookup codigo precosDeMercado

-- Função para buscar os dados completos de um ativo pelo seu código
buscarAtivoDoMercado :: CodigoAtivo -> [Ativo] -> Maybe Ativo
buscarAtivoDoMercado tickerParaBuscar = find (\ativo -> codigo ativo == tickerParaBuscar)

-- Função auxiliar para buscar um cliente pelo ID
buscarClientePorID :: IdCliente -> [Cliente] -> Maybe Cliente
buscarClientePorID cid = find (\cliente -> clienteID cliente == cid)

-- Função auxiliar para buscar uma conta pelo ID do cliente
buscarContaPorID :: IdCliente -> [Conta] -> Maybe Conta
buscarContaPorID cid = find (\conta -> idClienteConta conta == cid)

-- Função auxiliar para buscar uma carteira pelo ID do cliente
buscarCarteiraPorID :: IdCliente -> [Carteira] -> Maybe Carteira
buscarCarteiraPorID cid = find (\carteira -> idClienteCarteira carteira == cid)

-- Valida as credenciais do cliente para login
loginCliente :: IdCliente -> String -> EstadoBanco -> Maybe Cliente
loginCliente cid senhaLogin estado =
  case buscarClientePorID cid (clientes estado) of
    Nothing -> Nothing
    Just cliente -> if senha cliente == senhaLogin then Just cliente else Nothing

-- Obtém a pergunta de segurança de um cliente para recuperação de senha
obterPerguntaSeguranca :: IdCliente -> EstadoBanco -> Maybe String
obterPerguntaSeguranca cid estado = fmap perguntaPessoalSenha (buscarClientePorID cid (clientes estado))

-- Verifica a resposta de segurança e retorna a senha se estiver correta
verificarRespostaSeguranca :: IdCliente -> String -> EstadoBanco -> Maybe String
verificarRespostaSeguranca cid respostaUsuario estado =
  case buscarClientePorID cid (clientes estado) of
    Nothing -> Nothing
    Just cliente -> if respostaPerguntaPessoal cliente == respostaUsuario then Just (senha cliente) else Nothing

-- Cria um novo cliente com conta e carteira associadas
abrirContaInvestimento :: String -> String -> String -> String -> Double -> EstadoBanco -> EstadoBanco
abrirContaInvestimento nome senhaLogin pergunta resposta depositoInicial estadoAntigo = novoEstado
  where
    novoID = proximoIDCliente estadoAntigo
    novoCliente = Cliente { clienteID = novoID, nomeCliente = nome, senha = senhaLogin, perguntaPessoalSenha = pergunta, respostaPerguntaPessoal = resposta }
    novaConta = Conta { idClienteConta = novoID, saldo = depositoInicial }
    novaCarteira = Carteira { idClienteCarteira = novoID, itens = [] }

    novoEstado = estadoAntigo {
        clientes = novoCliente : clientes estadoAntigo,
        contas = novaConta : contas estadoAntigo,
        carteiras = novaCarteira : carteiras estadoAntigo,
        proximoIDCliente = novoID + 1
    }

-- Processa uma ordem de compra de ativo
executarOrdemDeCompra :: IdCliente -> CodigoAtivo -> Int -> UTCTime -> EstadoBanco -> (EstadoBanco, String)
executarOrdemDeCompra cid ticker qtd agora estado =
  case buscarAtivoDoMercado ticker (ativosDoMercado estado) of
    Nothing -> (estado, "ERRO: Ativo '" ++ ticker ++ "' não é negociado por nosso banco.")
    Just ativoParaComprar ->
      case obterPreco ticker of
        Nothing -> (estado, "ERRO: Preço para o ativo não encontrado (Erro interno).")
        Just preco ->
          case buscarContaPorID cid (contas estado) of
            Nothing -> (estado, "ERRO: Conta do cliente não encontrada.")
            Just conta ->
              let custoTotal = preco * fromIntegral qtd
              in if saldo conta < custoTotal
                 then (estado, "ERRO: Saldo insuficiente para realizar a compra.")
                 else
                   let
                       contasAtualizadas = map (\c -> if idClienteConta c == cid then c { saldo = saldo c - custoTotal } else c) (contas estado)
                       carteirasAtualizadas = map (\c -> if idClienteCarteira c == cid then adicionarAtivoNaCarteira ativoParaComprar qtd c else c) (carteiras estado)
                       novaTransacao = RegistroTransacao cid Compra ticker qtd preco agora
                       historicoAtualizado = novaTransacao : historico estado
                       novoEstado = estado { contas = contasAtualizadas, carteiras = carteirasAtualizadas, historico = historicoAtualizado }
                   in (novoEstado, ">> Compra de " ++ show qtd ++ " " ++ ticker ++ " realizada com sucesso!")

-- Processa uma ordem de venda de ativo
executarOrdemDeVenda :: IdCliente -> CodigoAtivo -> Int -> UTCTime -> EstadoBanco -> (EstadoBanco, String)
executarOrdemDeVenda cid ticker qtd agora estado =
  case obterPreco ticker of
    Nothing -> (estado, "ERRO: Ativo '" ++ ticker ++ "' não encontrado no mercado.")
    Just preco ->
      case buscarCarteiraPorID cid (carteiras estado) of
        Nothing -> (estado, "ERRO: Carteira do cliente não encontrada.")
        Just carteira ->
          case verificarPosseAtivo ticker qtd carteira of
            False -> (estado, "ERRO: Você não possui a quantidade suficiente de '" ++ ticker ++ "' para vender.")
            True ->
              let valorVenda = preco * fromIntegral qtd
                  contasAtualizadas = map (\c -> if idClienteConta c == cid then c { saldo = saldo c + valorVenda } else c) (contas estado)
                  carteirasAtualizadas = map (\c -> if idClienteCarteira c == cid then removerAtivoDaCarteira ticker qtd c else c) (carteiras estado)
                  novaTransacao = RegistroTransacao cid Venda ticker qtd preco agora
                  historicoAtualizado = novaTransacao : historico estado
                  novoEstado = estado { contas = contasAtualizadas, carteiras = carteirasAtualizadas, historico = historicoAtualizado }
              in (novoEstado, ">> Venda de " ++ show qtd ++ " " ++ ticker ++ " realizada com sucesso!")

-- Retorna uma string formatada com a posição da carteira do cliente
consultarPosicao :: IdCliente -> EstadoBanco -> String
consultarPosicao cid estado =
  case buscarContaPorID cid (contas estado) of
    Nothing -> "Conta não encontrada."
    Just conta ->
        case buscarCarteiraPorID cid (carteiras estado) of
            Nothing -> "Carteira não encontrada."
            Just carteira ->
                unlines [
                    "--- Posição do Cliente " ++ show cid ++ " ---",
                    "Saldo disponível: R$ " ++ show (saldo conta),
                    "Ativos em custódia:",
                    if null (itens carteira)
                    then "  Nenhum ativo em custódia."
                    else unlines [ "  - " ++ codigo atv ++ " (" ++ nomeAtivo atv ++ "): " ++ show qtd ++ " unidades" | item <- itens carteira, let atv = ativo item, let qtd = quantidade item ]
                ]

-- Retorna uma string formatada com os ativos disponíveis no mercado
consultarMercado :: EstadoBanco -> String
consultarMercado estado =
    unlines (["--- Ativos Disponíveis para Negociação ---"] ++ linhasAtivos)
    where
      linhasAtivos = [ formatarLinhaAtivo atv | atv <- ativosDoMercado estado ]
      formatarLinhaAtivo atv =
          let tickerAtivo = codigo atv
              nomeCompleto = nomeAtivo atv
              preco :: Double
              preco = fromMaybe 0.0 (obterPreco tickerAtivo)
          in tickerAtivo ++ " (" ++ nomeCompleto ++ "): R$ " ++ show preco

-- Retorna uma string formatada com o extrato de transações de um cliente
consultarExtrato :: TimeZone -> IdCliente -> EstadoBanco -> String
consultarExtrato tz cid estado =
    let
        transacoesDoCliente = filter (\t -> idClienteTransacao t == cid) (historico estado)
        transacoesOrdenadas = sortOn (Down . timestamp) transacoesDoCliente
        cabecalho = "--- Extrato de Transações do Cliente " ++ show cid ++ " ---"
        linhasExtrato = map (formatarTransacao tz) transacoesOrdenadas
    in
        if null transacoesDoCliente
        then "Nenhuma transação encontrada para este cliente."
        else unlines (cabecalho : linhasExtrato)

-- Função auxiliar para formatar uma única linha do extrato
formatarTransacao :: TimeZone -> RegistroTransacao -> String
formatarTransacao tz transacao =
    let
        horaLocal = utcToZonedTime tz (timestamp transacao)
        dataHoraFormatada = formatTime defaultTimeLocale "%d/%m/%Y %H:%M:%S" horaLocal
        tipoStr = show (tipoTransacao transacao)
        qtd = quantidadeTransacionada transacao
        ticker = codigoTransacao transacao
        preco = precoUnitario transacao
        valorTotal = fromIntegral qtd * preco
    in
        "[" ++ dataHoraFormatada ++ "] " ++ tipoStr ++ " - " ++ show qtd ++ " " ++ ticker ++ " @ R$" ++ show preco ++ " | Total: R$" ++ show valorTotal


-- Adiciona ou atualiza a quantidade de um ativo na carteira
adicionarAtivoNaCarteira :: Ativo -> Int -> Carteira -> Carteira
adicionarAtivoNaCarteira ativoComprado qtdComprada carteira = carteira { itens = novosItens }
  where
    tickerComprado = codigo ativoComprado
    itemExistente = find (\item -> codigo (ativo item) == tickerComprado) (itens carteira)
    novosItens =
      case itemExistente of
        Nothing -> ItemCarteira ativoComprado qtdComprada : itens carteira
        Just _ -> map (\item -> if codigo (ativo item) == tickerComprado
                                 then item { quantidade = quantidade item + qtdComprada }
                                 else item) (itens carteira)

-- Remove ou atualiza a quantidade de um ativo na carteira
removerAtivoDaCarteira :: CodigoAtivo -> Int -> Carteira -> Carteira
removerAtivoDaCarteira tickerVendido qtdVendida carteira = carteira { itens = novosItens }
  where
    novosItens = filter (\item -> quantidade item > 0) $
                 map (\item -> if codigo (ativo item) == tickerVendido
                                then item { quantidade = quantidade item - qtdVendida }
                                else item) (itens carteira)

-- Verifica se o cliente possui uma quantidade suficiente de um ativo para vender
verificarPosseAtivo :: CodigoAtivo -> Int -> Carteira -> Bool
verificarPosseAtivo tickerVendido qtdVendida carteira =
  case find (\item -> codigo (ativo item) == tickerVendido) (itens carteira) of
    Nothing -> False
    Just item -> quantidade item >= qtdVendida