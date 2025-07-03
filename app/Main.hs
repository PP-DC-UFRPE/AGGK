module Main where

import Tipos
import Logica
import SimuladorPrecos
import System.IO
import qualified Data.ByteString.Lazy as B
import Data.Aeson
import Control.Exception (catch, IOException)
import Data.Time (getCurrentTime)
import Data.Time.LocalTime (getCurrentTimeZone)
import Text.Read (readMaybe)

arquivoBanco :: FilePath
arquivoBanco = "banco_dados.json"

-- Salva o estado atual do banco no arquivo
salvarEstado :: EstadoBanco -> IO ()
salvarEstado estado = B.writeFile arquivoBanco (encode estado)

-- Carrega o estado do banco a partir do arquivo
carregarEstado :: IO EstadoBanco
carregarEstado = do
    conteudo <- B.readFile arquivoBanco `catch` tratarErroLeitura
    tempoAtual <- getCurrentTime
    let estadoInicial = EstadoBanco {
                          clientes = [],
                          contas = [],
                          carteiras = [],
                          historico = [],
                          proximoIDCliente = 1,
                          ativosDoMercado = ativosDisponiveis,
                          simuladorPrecos = Just (paraSerializavel $ inicializarSimulador tempoAtual)
                        }
    case decode conteudo of
        Nothing -> return estadoInicial
        Just estadoCarregado -> 
            -- Se o estado carregado não tem simulador, inicializa um
            case simuladorPrecos estadoCarregado of
                Nothing -> return $ estadoCarregado { simuladorPrecos = Just (paraSerializavel $ inicializarSimulador tempoAtual) }
                Just _ -> return estadoCarregado
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

    -- readMaybe é uma versão do read que retorna Nothing caso a conversão falhe.
    case readMaybe idStr :: Maybe IdCliente of 
        Nothing -> do
            putStrLn "\n Falha ao logar: o ID do Cliente tem que ser um número"
            inicio estado
        Just cid -> do
            putStr "Digite sua senha: "
            hFlush stdout
            senha <- getLine

            case loginCliente cid senha estado of
                Nothing -> do
                    putStr "\n ID ou senha incorreto."
                    inicio estado
                Just clienteLogado -> do
                    putStrLn  $ "Bem-vindo(a), " ++ nomeCliente clienteLogado ++ "!" -- $ subistitui os ()

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
    putStrLn "6. Ver Relatório de Rendimento"
    putStrLn "7. Atualizar Preços Manualmente"
    putStrLn "8. Simular Choque de Mercado"
    putStrLn "9. Logout (Sair da conta)"
    putStr "Escolha uma opção: "
    hFlush stdout

    opcao <- getLine
    case opcao of
        "1" -> do
            putStrLn ""
            agora <- getCurrentTime
            let estadoAtualizado = atualizarPrecosNoBanco agora estado
            putStrLn $ consultarMercado estadoAtualizado
            salvarEstado estadoAtualizado
            menuLogado clienteLogado estadoAtualizado

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
            putStrLn ""
            putStrLn $ calcularRendimento cid estado
            menuLogado clienteLogado estado

        "7" -> do
            putStrLn ">> Atualizando preços..."
            agora <- getCurrentTime
            let estadoAtualizado = atualizarPrecosNoBanco agora estado
            putStrLn ">> Preços atualizados!"
            putStrLn $ consultarMercado estadoAtualizado
            salvarEstado estadoAtualizado
            menuLogado clienteLogado estadoAtualizado

        "8" -> do
            putStr "Digite a intensidade do choque (0.1 = 10%, 0.5 = 50%): "
            hFlush stdout
            intensidadeStr <- getLine
            let intensidade = read intensidadeStr :: Double
            agora <- getCurrentTime
            case simuladorPrecos estado of
                Nothing -> do
                    putStrLn "Simulador não inicializado!"
                    menuLogado clienteLogado estado
                Just simSerial -> do
                    let sim = deSerializavel simSerial
                        simComChoque = aplicarChoqueMercado intensidade agora sim
                        estadoAtualizado = estado { simuladorPrecos = Just (paraSerializavel simComChoque) }
                    putStrLn ">> Choque de mercado aplicado!"
                    putStrLn $ consultarMercado estadoAtualizado
                    salvarEstado estadoAtualizado
                    menuLogado clienteLogado estadoAtualizado

        "9" -> do
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
    agora <- getCurrentTime
    let novoEstado = abrirContaInvestimento nome senha pergunta resposta valor agora estado
    let novoID = proximoIDCliente estado
    putStrLn $ "\n>> Conta criada com sucesso! Seu ID de Cliente é: " ++ show novoID ++ ". Guarde este número!"
    salvarEstado novoEstado
    inicio novoEstado


main :: IO ()
main = do
    putStrLn "Iniciando sistema bancário..."
    estado <- carregarEstado
    inicio estado