# AGGK Investimentos

## Descrição:

**AGGK Investimentos** é um projeto de banco de investimentos, que será desenvolvido na linguagem de programação Haskell.

## Membros da Equipe:
* Álvaro Ribeiro;
* Gabriel Felipe;
* Guilherme Oliveira;
* Kleber Barbosa.

## Descrição

Este projeto é uma simulação da plataforma de investimentos de um banco digital, desenvolvida em Haskell. O objetivo é criar um sistema que gerencia clientes, contas de investimento, negociação de ativos financeiros e histórico de transações. O programa oferece uma interface de linha de comando (CLI) para interação do usuário e persiste os dados em um arquivo local JSON para manter o estado do sistema entre as execuções.


## Funcionalidades e Regras de Negócio

O sistema implementa as seguintes funcionalidades, simulando as operações de uma plataforma de um banco de investimentos:

### Funcionalidades:

* **Abertura de Conta de Investimentos:**
    * **Regra:** Ao cadastrar um novo cliente, uma conta de investimentos associada a ele é criada automaticamente.
    * **Regra:** A conta é iniciada com um depósito inicial em dinheiro.
    * **Regra:** Cada cliente possui um ID único para identificação no banco.

* **Ordem de Compra de Ativo (Buy):**
    * **Regra:** O cliente deve possuir uma conta ativa no banco.
    * **Regra:** A conta do cliente deve ter saldo em dinheiro suficiente para cobrir o custo total da ordem de compra (quantidade * preço do ativo).
    * **Regra:** O ativo (ex: "PETR4") deve existir e estar disponível para negociação no mercado simulado.
    * **Regra:** Ao executar a ordem, o valor é debitado do saldo da conta e o ativo (com sua quantidade) é adicionado ou atualizado na carteira de investimentos do cliente.

* **Ordem de Venda de Ativo (Sell):**
    * **Regra:** O cliente deve possuir o ativo que deseja vender em sua carteira.
    * **Regra:** A quantidade a ser vendida não pode ser maior que a custódia atual do cliente para aquele ativo.
    * **Regra:** Ao executar a ordem, o ativo é removido ou atualizado na carteira e o valor correspondente (quantidade * preço do ativo) é creditado no saldo em dinheiro da conta de investimentos.

* **Consulta de Carteira e Posição:**
    * **Regra:** Permite a visualização do saldo atual em dinheiro e a lista de todos os ativos sob custódia, com suas respectivas quantidades, na carteira de um cliente.

* **Persistência de Dados:**
    * **Regra:** Ao iniciar o sistema, todos os dados dos clientes e de suas contas de investimento são recuperados de um arquivo local (`banco_dados.json`).
    * **Regra:** A cada operação que altera os dados (compra, venda, cadastro), o estado completo do sistema é salvo novamente no arquivo, garantindo a consistência e persistência das informações.

* **Extrato de Transações:**
    * **Regra:** Toda ordem de compra e venda gera um registro de transação (nota de corretagem simplificada) contendo: tipo (compra/venda), cliente, ativo, quantidade, preço no momento da transação e data/hora.
    * **Regra:** Há uma funcionalidade para consultar o extrato completo de transações de um cliente.

* **Cálculo de Performance da Carteira:**
    * **Regra:** O sistema pode calcular o valor total da carteira de um cliente (Patrimônio), que é a soma do saldo em dinheiro com o valor de mercado atual de todos os seus ativos em custódia.
    * **Regra:** O sistema pode calcular o lucro/prejuízo total da carteira.



## Instalação e Execução do Projeto

### Pré-requisitos
* GHC (Glasgow Haskell Compiler) e Cabal (ferramenta de build).
    * A versão usada no desenvolvimento foi a GHC 8.6.5 com Cabal 2.4.1.0 (via Haskell Platform).

### Dependências

Este projeto utiliza a biblioteca `aeson` para manipulação de dados em formato JSON (persistência de arquivos).

Para adicionar a dependência, inclua `aeson` na seção `build-depends` do seu arquivo `.cabal`. Exemplo:

cabal
build-depends:    base ^>=4.12.0.0
                , aeson


### Comandos de Execução

1.  **Clone o repositório** (ou crie os arquivos em um diretório local).

2.  **Navegue até a pasta do projeto** pelo terminal.

3.  **Construa o projeto** (isso irá baixar e instalar as dependências):
    bash
       cabal build
   


4.  **Execute o programa:**
    bash
       cabal run
      