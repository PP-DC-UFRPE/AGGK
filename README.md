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


* **Ordem de Compra de Ativo:**
    * **Regra:** O cliente deve possuir uma conta ativa no banco.
    * **Regra:** A conta do cliente deve ter saldo em dinheiro suficiente para cobrir o custo total da ordem de compra(quantidade * preço do ativo).
    * **Regra:** O ativo (ex: "PETR4") deve existir e estar disponível para negociação no mercado simulado.
    * **Regra:** Ao executar a ordem, o valor é debitado do saldo da conta e o ativo , com sua quantidade, é adicionado ou atualizado na carteira de investimentos do cliente.


* **Ordem de Venda de Ativo:**
    * **Regra:** O cliente deve possuir o ativo que deseja vender em sua carteira.
    * **Regra:** A quantidade a ser vendida não pode ser maior que a custódia atual do cliente para aquele ativo.
    * **Regra:** Ao executar a ordem, o ativo é removido ou atualizado na carteira e o valor correspondente (quantidade * preço do ativo) é creditado no saldo em dinheiro da conta de investimentos.


* **Consulta de Carteira e Posição:**
    * **Regra:** Permite a visualização do saldo atual em dinheiro e a lista de todos os ativos sob custódia, com suas respectivas quantidades, na carteira de um cliente.


* **Persistência de Dados:**
    * **Regra:** Ao iniciar o sistema, todos os dados dos clientes e de suas contas de investimento são recuperados de um arquivo local (banco_dados.json).
    * **Regra:** A cada operação que altera os dados (compra, venda, cadastro), o estado completo do sistema é salvo novamente no arquivo, garantindo a consistência e persistência das informações.


* **Extrato de Transações:**
    * **Regra:** Toda ordem de compra e venda gera um registro de transação (nota de corretagem simplificada) contendo: tipo (compra/venda), cliente, ativo, quantidade, preço no momento da transação e data/hora.
    * **Regra:** Há uma funcionalidade para consultar o extrato completo de transações de um cliente.


* **Cálculo de Performance da Carteira:**
    * **Regra:** O sistema pode calcular o valor total da carteira de um cliente (Posição), que é a soma do saldo em dinheiro com o valor de mercado atual de todos os seus ativos em custódia.
    * **Regra:** O sistema pode calcular o lucro/prejuízo total da carteira.


* **Simulação de Mercado e Dinâmica de Preços:**

    * **Regra**: No momento em que o sistema é iniciado, caso não haja um estado de simulação salvo, os ativos disponíveis para negociação ("PETR4", "VALE3", etc) devem ser inicializados com um preço padrão pré-definido.
    * **Regra**: O preço de cada ativo não é estático. Ele flutua ao longo do tempo para simular a volatilidade de um mercado real.
    * **Regra**: Cada ativo possui um fator de "instabilidade" (volatilidade) intrínseco. Ativos mais voláteis (ex: "MGLU3") têm potencial para variações de preço maiores em um mesmo intervalo de tempo em comparação com ativos mais estáveis (ex: "ITUB4").
    * **Regra**: A atualização dos preços dos ativos é acionada dinamicamente. Sempre que uma operação sensível ao preço é solicitada, como uma ordem de compra/venda ou a consulta do mercado, o sistema recalcula o preço do ativo com base no tempo decorrido desde a última atualização e em seu fator de instabilidade.
    * **Regra**: O estado da simulação, incluindo o último preço calculado de cada ativo e a hora da última atualização, é persistido junto com os dados dos clientes no arquivo banco_dados.json. Isso garante que a flutuação dos preços seja contínua entre as sessões de uso do sistema.


## Instalação e Execução do Projeto

### Pré-requisitos
* GHC (Glasgow Haskell Compiler) e Cabal (ferramenta de build).
    * A versão usada no desenvolvimento foi a GHC 4.18.3.0 com Cabal 3.4

### Dependências

Este projeto utiliza a biblioteca **aeson** para manipulação de dados em formato JSON (persistência de arquivos).

Para adicionar a dependência, inclua **aeson** na seção **build-depends** do seu arquivo **.cabal**. 

Exemplo:
cabal
build-depends:    base ^>=4.12.0.0
                , aeson


### Comandos de Execução

1.  **Clone o repositório** (ou crie os arquivos em um diretório local).

2.  **Navegue até a pasta do projeto** pelo terminal.

3.  **Construa o projeto**:
    bash
       cabal build

4.  **Execute o programa:**
    bash
       cabal run


### Uso de IA (consciente):

● Modelo: ChatGPT

● Percentual: 70%

● Prompts: 

" *Modelagem de Dados:

Cliente: ID único e nome.

Conta: Pertence a um cliente e tem saldo.

Ativo Financeiro: Ex: Ação → código (ticker) e nome.

Carteira: Saldo + ativos com quantidades.


 *Funcionalidades Básicas:

1. Cadastro de Cliente e Conta
→ Cria cliente + conta com depósito inicial.


2. Comprar Ativo 
→ Verifica saldo, debita valor e adiciona ativo.


3. Vender Ativo 
→ Verifica se possui ativo e quantidade, remove da carteira e credita o valor.


4. Consultar Carteira
→ Mostra saldo + ativos e quantidades.


*Persistência de Dados:

Salvar/carregar dados em arquivo 


*Histórico de Transações:

Tipo Transacao: quem, o quê, quanto, preço, data/hora.

Log de todas as operações.

Função para consultar extrato.


 *Interface CLI 

Menu interativo:
1-Comprar, 2-Vender, 3-Ver Carteira, 4-Extrato, etc


 *Cálculo de Performance:

Valor total da carteira = saldo + valor atual dos ativos.

Lucro/Prejuízo = valor atual − total investido.

Baseado nessas funcionalidades, dizer como posso aplicá-las e os requisitos básicos para implementá-las(bibliotecas e recursos externos)"


* "Gerar módulos Tipos e Logica, cabal e funções básicas para Tipos e Logica"


* "Explicar toda a estrutura dos módulos, do cabal e das funções básicas detalhadamente"


* "Gerar função de extrato e menu interativo no Main"


* "Explicar código das função extrato e menu interativo detalhadamente"


* "Corrigir erros na implementação"


* "Tirar dúvidas sobre implementação"  
