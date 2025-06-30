module Main where

import Tipos
import Logica
import System.IO
import qualified Data.ByteString.Lazy as B
import Data.Aeson
import Data.Maybe (fromMaybe)
import Control.Exception (catch, IOException)
import Data.Time (getCurrentTime)
import Data.Time.LocalTime (getCurrentTimeZone)

arquivoBanco :: FilePath
arquivoBanco = "banco_dados.json"

-- Salva o estado atual do banco no arquivo
salvarEstado :: EstadoBanco -> IO ()
salvarEstado estado = B.writeFile arquivoBanco (encode estado)

-- Carrega o estado do banco a partir do arquivo
carregarEstado :: IO EstadoBanco
carregarEstado = do
    conteudo <- B.readFile arquivoBanco `catch` tratarErroLeitura
    let estadoInicial = EstadoBanco {
                          clientes = [],
                          contas = [],
                          carteiras = [],
                          historico = [],
                          proximoIDCliente = 1,
                          ativosDoMercado = ativosDisponiveis
                        }
    return $ fromMaybe estadoInicial (decode conteudo)
  where
    tratarErroLeitura :: IOException -> IO B.ByteString
    tratarErroLeitura _ = do
      putStrLn "AVISO: Arquivo 'banco_dados.json' não encontrado. Um novo será criado com dados iniciais."
      return B.empty




-- Menu inicial, antes do login
inicio :: EstadoBanco -> IO ()
inicio estado = do
    putStrLn "\n--- Bem-vindo à Plataforma Bancária ---"
    putStrLn "1. Entrar na conta"
    putStrLn "2. Criar conta"
    putStrLn "3. Esqueci minha senha"
    putStrLn "4. Sair"
    putStr "Escolha uma opção: "
    hFlush stdout
    opcao <- getLine
    case opcao of
        "1" -> fazerLogin estado
        "2" -> cadastrarNovoCliente estado
        "3" -> recuperarSenha estado
        "4" -> putStrLn "Encerrando..."
        _   -> do
            putStrLn "Opção inválida."
            inicio estado

-- Processo de Login
fazerLogin :: EstadoBanco -> IO ()
fazerLogin estado = do
    putStr "Digite seu ID de Cliente: "
    hFlush stdout
    idStr <- getLine
    putStr "Digite sua senha: "
    hFlush stdout
    senha <- getLine
    let cid = read idStr :: IdCliente

    case loginCliente cid senha estado of
        Nothing -> do
            putStrLn "\n>> ID ou senha inválidos. Tente novamente."
            inicio estado
        Just clienteLogado -> do
            putStrLn $ "\n>> Bem-vindo(a), " ++ nomeCliente clienteLogado ++ "!"
            menuLogado clienteLogado estado

-- Processo de Recuperação de Senha
recuperarSenha :: EstadoBanco -> IO ()
recuperarSenha estado = do
    putStrLn "\n--- Recuperação de Senha ---"
    putStr "Digite seu ID de Cliente para começar: "
    hFlush stdout
    idStr <- getLine
    let cid = read idStr :: IdCliente

    case obterPerguntaSeguranca cid estado of
        Nothing -> do
            putStrLn ">> ID de Cliente não encontrado."
            inicio estado
        Just pergunta -> do
            putStrLn $ "Sua pergunta de segurança é: \"" ++ pergunta ++ "\""
            putStr "Digite a resposta: "
            hFlush stdout
            resposta <- getLine
            case verificarRespostaSeguranca cid resposta estado of
                Nothing -> do
                    putStrLn ">> Resposta incorreta."
                    inicio estado
                Just senhaRecuperada -> do
                    putStrLn $ ">> Recuperação bem-sucedida! Sua senha é: " ++ senhaRecuperada
                    inicio estado

-- Menu principal após o login bem-sucedido
menuLogado :: Cliente -> EstadoBanco -> IO ()
menuLogado clienteLogado estado = do
    let cid = clienteID clienteLogado
    putStrLn "\n=== Menu Principal da Conta ==="
    putStrLn "1. Consultar Ativos do Mercado"
    putStrLn "2. Comprar Ativo"
    putStrLn "3. Vender Ativo"
    putStrLn "4. Ver Posição da Carteira"
    putStrLn "5. Ver Extrato de Transações"
    putStrLn "6. Logout (Sair da conta)"
    putStr "Escolha uma opção: "
    hFlush stdout

    opcao <- getLine
    case opcao of
        "1" -> do
            putStrLn ""
            putStrLn $ consultarMercado estado
            menuLogado clienteLogado estado

        "2" -> do
            putStr "Digite o código do ativo (ex: PETR4): "
            hFlush stdout
            ticker <- getLine
            putStr "Digite a quantidade: "
            hFlush stdout
            qtdStr <- getLine
            let qtd = read qtdStr :: Int
            agora <- getCurrentTime
            let (novoEstado, msg) = executarOrdemDeCompra cid ticker qtd agora estado
            putStrLn msg
            salvarEstado novoEstado
            menuLogado clienteLogado novoEstado

        "3" -> do
            putStr "Digite o código do ativo (ex: VALE3): "
            hFlush stdout
            ticker <- getLine
            putStr "Digite a quantidade: "
            hFlush stdout
            qtdStr <- getLine
            let qtd = read qtdStr :: Int
            agora <- getCurrentTime
            let (novoEstado, msg) = executarOrdemDeVenda cid ticker qtd agora estado
            putStrLn msg
            salvarEstado novoEstado
            menuLogado clienteLogado novoEstado

        "4" -> do
            putStrLn ""
            putStrLn $ consultarPosicao cid estado
            menuLogado clienteLogado estado

        "5" -> do
            putStrLn ""
            tz <- getCurrentTimeZone
            putStrLn $ consultarExtrato tz cid estado
            menuLogado clienteLogado estado

        "6" -> do
            putStrLn "\n>> Fazendo logout..."
            inicio estado

        _ -> do
            putStrLn "Opção inválida."
            menuLogado clienteLogado estado

-- Processo de cadastro de um novo cliente
cadastrarNovoCliente :: EstadoBanco -> IO ()
cadastrarNovoCliente estado = do
    putStr "Nome completo: "
    hFlush stdout
    nome <- getLine
    putStr "Crie uma senha: "
    hFlush stdout
    senha <- getLine
    putStr "Crie uma pergunta de segurança: "
    hFlush stdout
    pergunta <- getLine
    putStr "Digite a resposta para a pergunta: "
    hFlush stdout
    resposta <- getLine
    putStr "Depósito inicial (R$): "
    hFlush stdout
    valorStr <- getLine
    let valor = read valorStr :: Double
    let novoEstado = abrirContaInvestimento nome senha pergunta resposta valor estado
    let novoID = proximoIDCliente estado
    putStrLn $ "\n>> Conta criada com sucesso! Seu ID de Cliente é: " ++ show novoID ++ ". Guarde este número!"
    salvarEstado novoEstado
    inicio novoEstado


main :: IO ()
main = do
    putStrLn "Iniciando sistema bancário..."
    estado <- carregarEstado
    inicio estado