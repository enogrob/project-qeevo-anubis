# Anubis

## Descrição

O Anubis é um microserviço responsável pela orquestração do envio de dados de alunos pagantes para APIs de instituições de ensino superior, como Kroton e Estácio. Ele gerencia o fluxo de inscrições vindas do Quero Bolsa e dos novos marketplaces (Ead.com, Guia da Carreira e Mundo Vestibular), organizando os payloads e registrando logs estruturados com o status das tentativas, além de implementar mecanismos automáticos de retry para falhas temporárias.

O escopo do serviço não inclui o envio de leads do Quero Captação, alunos pagantes de outros produtos da Qeevo, agendamento de envios ou interface para reenvio manual de falhas. O foco está na integração eficiente e segura dos dados de alunos pagantes entre os sistemas internos e as APIs das instituições parceiras.


## Modelo de Dados (ER Diagram)

<details>
<summary>📊 Visualizar Diagrama Entidade-Relacionamento</summary>

```mermaid
%%{init: {
  'theme':'base',
  'themeVariables': {
    'primaryColor':'#E8F4FD',
    'primaryBorderColor':'#4A90E2',
    'primaryTextColor':'#2C3E50',
    'secondaryColor':'#F0F8E8',
    'tertiaryColor':'#FDF2E8',
    'quaternaryColor':'#F8E8F8',
    'lineColor':'#5D6D7E',
    'fontFamily':'Inter,Segoe UI,Arial'
  }
}}%%
erDiagram
  SUBSCRIPTIONS }o--|| INTEGRATIONS : "belongs_to integration"
  INTEGRATIONS ||--o{ SUBSCRIPTIONS : "has_many subscriptions"
  
  SUBSCRIPTIONS }o--|| INTEGRATION_FILTERS : "belongs_to integration_filter"
  INTEGRATION_FILTERS ||--o{ SUBSCRIPTIONS : "has_many subscriptions"
  
  INTEGRATIONS ||--o{ INTEGRATION_FILTERS : "has_many integration_filters"
  INTEGRATION_FILTERS }o--|| INTEGRATIONS : "belongs_to integration"
  
  INTEGRATIONS ||--o{ INTEGRATION_TOKENS : "has_many integration_tokens"
  INTEGRATION_TOKENS }o--|| INTEGRATIONS : "belongs_to integration"
  
  SUBSCRIPTIONS ||--o{ SUBSCRIPTION_EVENTS : "has_many subscription_events"
  SUBSCRIPTION_EVENTS }o--|| SUBSCRIPTIONS : "belongs_to subscription"

  INTEGRATIONS {
    integer id PK
    string name "📋 Integration Name"
    string type "🔧 Integration Type"
    string key "🔑 API Key"
    integer interval "⏱️ Sync Interval (minutes)"
    timestamp created_at
    timestamp updated_at
  }
  
  INTEGRATION_FILTERS {
    integer id PK
    integer integration_id FK "🔗 Integration Reference"
    json filter "🎯 Filter Configuration"
    string type "📝 Filter Type"
    boolean enabled "✅ Is Active"
    timestamp created_at
    timestamp updated_at
  }
  
  SUBSCRIPTIONS {
    integer id PK
    integer integration_id FK "🔌 Integration Reference"
    integer integration_filter_id FK "🎯 Filter Reference"
    integer order_id "📦 Order ID"
    string origin "🌐 Data Source"
    string cpf "👤 Student CPF"
    json payload "📄 Student Data"
    string status "📊 Processing Status"
    timestamp sent_at "📤 Sent Timestamp"
    timestamp checked_at "👀 Last Check"
    timestamp scheduled_to "⏰ Scheduled For"
    timestamp created_at
    timestamp updated_at
  }
  
  INTEGRATION_TOKENS {
    integer id PK
    integer integration_id FK "🔗 Integration Reference"
    string key "🔐 Token Key"
    string value "🎫 Token Value"
    timestamp valid_until "⏳ Expiration Date"
    timestamp created_at
    timestamp updated_at
  }
  
  SUBSCRIPTION_EVENTS {
    integer id PK
    integer subscription_id FK "📦 Subscription Reference"
    string status "📈 Event Status"
    string operation_name "⚙️ Operation Type"
    string error_message "❌ Error Details"
    json request "📤 Request Payload"
    json response "📥 Response Data"
    string model "🏷️ Model Name"
    timestamp created_at
    timestamp updated_at
  }
```

</details>

### Comandos usados para Gerar os Models

```bash
rails g model Integration name:string type:string key:string interval:integer --no-test-framework
rails g model IntegrationFilter integration:references filter:json type:string enabled:boolean --no-test-framework
rails g model Subscription integration:references integration_filter:references order_id:integer origin:string cpf:string payload:json status:string sent_at:timestamp checked_at:timestamp scheduled_to:timestamp --no-test-framework
rails g model IntegrationToken integration:references key:string value:string valid_until:timestamp --no-test-framework
rails g model SubscriptionEvent subscription:references status:string operation_name:string error_message:string request:json response:json model:string --no-test-framework
```

## Fluxos do Projeto

### 🏗️ Visão Geral do Sistema (Overview)

<details>
<summary>🏗️ Visualizar Diagrama de Visão Geral do Sistema</summary>

```mermaid
%%{init: {
  'theme':'base',
  'themeVariables': {
    'primaryColor':'#E8F4FD',
    'primaryBorderColor':'#4A90E2',
    'primaryTextColor':'#2C3E50',
    'secondaryColor':'#F0F8E8',
    'tertiaryColor':'#FDF2E8',
    'quaternaryColor':'#F8E8F8',
    'lineColor':'#5D6D7E',
    'fontFamily':'Inter,Segoe UI,Arial'
  }
}}%%
flowchart TD
    subgraph "🌐 Marketplaces"
        QB["🎓 Quero Bolsa"]
        EAD["📚 EAD.com"]
        GC["🗞️ Guia da Carreira"]
        MV["🎯 Mundo Vestibular"]
    end
    
    subgraph "⚙️ Anubis Service"
        ANUBIS["🔄 Anubis<br/>Orchestrator"]
        QUEUE["📥 Message Queue"]
        PROC["⚡ Processor"]
        LOG["📝 Event Logger"]
    end
    
    subgraph "🏛️ Institution APIs"
        KROTON["🏢 Kroton API"]
        ESTACIO["🏫 Estácio API"]
        OTHER["🏤 Other APIs"]
    end
    
    subgraph "💾 Storage"
        DB["🗄️ PostgreSQL"]
        KAFKA["📨 Kafka"]
    end
    
    QB --> ANUBIS
    EAD --> ANUBIS
    GC --> ANUBIS
    MV --> ANUBIS
    
    ANUBIS --> QUEUE
    QUEUE --> PROC
    PROC --> LOG
    
    PROC --> KROTON
    PROC --> ESTACIO
    PROC --> OTHER
    
    LOG --> DB
    ANUBIS --> KAFKA
    
    classDef marketplace fill:#E8F4FD,stroke:#4A90E2,color:#2C3E50
    classDef anubis fill:#F0F8E8,stroke:#7CB342,color:#2C3E50
    classDef institution fill:#FDF2E8,stroke:#FF9800,color:#2C3E50
    classDef storage fill:#F8E8F8,stroke:#9C27B0,color:#2C3E50
    
    class QB,EAD,GC,MV marketplace
    class ANUBIS,QUEUE,PROC,LOG anubis
    class KROTON,ESTACIO,OTHER institution
    class DB,KAFKA storage
```

</details>

**📋 Explicação da Visão Geral:**

O Anubis atua como um **orquestrador central** que recebe dados de alunos pagantes de múltiplos marketplaces educacionais e os distribui para as APIs das instituições de ensino superior. O fluxo é unidirecional e assíncrono:

- **Entrada de Dados**: Quero Bolsa, EAD.com, Guia da Carreira e Mundo Vestibular enviam informações de inscrições
- **Processamento**: O Anubis valida, transforma e enfileira os dados para processamento
- **Distribuição**: Os dados são enviados para APIs de instituições como Kroton, Estácio e outras
- **Persistência**: PostgreSQL armazena os dados estruturados e logs, enquanto Kafka gerencia mensagens assíncronas
- **Monitoramento**: Cada operação é logada para auditoria e debugging

### 🔧 Arquitetura de Serviços

<details>
<summary>🔧 Visualizar Diagrama da Arquitetura de Serviços</summary>

```mermaid
%%{init: {
  'theme':'base',
  'themeVariables': {
    'primaryColor':'#E8F4FD',
    'primaryBorderColor':'#4A90E2',
    'primaryTextColor':'#2C3E50',
    'secondaryColor':'#F0F8E8',
    'tertiaryColor':'#FDF2E8',
    'quaternaryColor':'#F8E8F8',
    'lineColor':'#5D6D7E',
    'fontFamily':'Inter,Segoe UI,Arial'
  }
}}%%
flowchart LR
    subgraph "📊 Data Sources"
        ORDER["📦 Order Service"]
        STUDENT["👤 Student Data"]
    end
    
    subgraph "🔄 Anubis Core"
        REGISTER["📋 Register Sync"]
        SCHEDULER["⏰ Scheduler"]
        CHECKER["🔍 Checker"]
        RETRY["🔄 Retry Logic"]
    end
    
    subgraph "🎯 Integration Layer"
        FILTER["🧰 Filters"]
        TOKEN["🔐 Token Manager"]
        PAYLOAD["📄 Payload Builder"]
    end
    
    subgraph "📤 Output Services"
        API_CLIENT["🌐 API Client"]
        EVENT_LOG["📝 Event Logger"]
    end
    
    ORDER --> REGISTER
    STUDENT --> REGISTER
    
    REGISTER --> SCHEDULER
    SCHEDULER --> CHECKER
    CHECKER --> RETRY
    
    REGISTER --> FILTER
    FILTER --> TOKEN
    TOKEN --> PAYLOAD
    
    PAYLOAD --> API_CLIENT
    API_CLIENT --> EVENT_LOG
    CHECKER --> EVENT_LOG
    
    classDef source fill:#E8F4FD,stroke:#4A90E2,color:#2C3E50
    classDef core fill:#F0F8E8,stroke:#7CB342,color:#2C3E50
    classDef integration fill:#FDF2E8,stroke:#FF9800,color:#2C3E50
    classDef output fill:#F8E8F8,stroke:#9C27B0,color:#2C3E50
    
    class ORDER,STUDENT source
    class REGISTER,SCHEDULER,CHECKER,RETRY core
    class FILTER,TOKEN,PAYLOAD integration
    class API_CLIENT,EVENT_LOG output
```

</details>

**⚙️ Explicação da Arquitetura de Serviços:**

Esta arquitetura modular divide o Anubis em **componentes especializados** que trabalham em conjunto:

- **Fontes de Dados**: Order Service e Student Data fornecem as informações base dos alunos
- **Núcleo de Processamento**: 
  - **Register Sync**: Processa inscrições em tempo real
  - **Scheduler**: Agenda tarefas e verificações periódicas
  - **Checker**: Monitora status das integrações
  - **Retry Logic**: Gerencia reenvios automáticos em caso de falha
- **Camada de Integração**:
  - **Filters**: Aplicam regras de negócio específicas por instituição
  - **Token Manager**: Gerencia autenticação e tokens de acesso
  - **Payload Builder**: Constrói dados no formato esperado por cada API
- **Serviços de Saída**:
  - **API Client**: Comunica com APIs externas das instituições
  - **Event Logger**: Registra todos os eventos para auditoria

#### 📋 Fluxo Register Sync

<details>
<summary>📋 Visualizar Diagrama do Fluxo Register Sync</summary>

```mermaid
%%{init: {
  'theme':'base',
  'themeVariables': {
    'primaryColor':'#E8F4FD',
    'primaryBorderColor':'#4A90E2',
    'primaryTextColor':'#2C3E50',
    'secondaryColor':'#F0F8E8',
    'tertiaryColor':'#FDF2E8',
    'quaternaryColor':'#F8E8F8',
    'lineColor':'#5D6D7E',
    'fontFamily':'Inter,Segoe UI,Arial'
  }
}}%%
flowchart TD
    START["🚀 Start Process"]
    
    subgraph "📥 Data Collection"
        RECEIVE["📨 Receive Order Event"]
        VALIDATE["✅ Validate Data"]
        EXTRACT["🔍 Extract Student Info"]
    end
    
    subgraph "🎯 Integration Matching"
        FIND_INT["🔍 Find Integrations"]
        APPLY_FILTER["🧰 Apply Filters"]
        CHECK_RULES["📋 Check Rules"]
    end
    
    subgraph "📄 Payload Processing"
        BUILD_PAYLOAD["🔧 Build Payload"]
        ADD_TOKEN["🔐 Add Auth Token"]
        VALIDATE_PAYLOAD["✅ Validate Payload"]
    end
    
    subgraph "📤 Delivery"
        SEND_API["🌐 Send to Institution API"]
        LOG_EVENT["📝 Log Event"]
        SCHEDULE_CHECK["⏰ Schedule Check"]
    end
    
    SUCCESS["✅ Success"]
    ERROR["❌ Error"]
    RETRY["🔄 Schedule Retry"]
    
    START --> RECEIVE
    RECEIVE --> VALIDATE
    VALIDATE --> EXTRACT
    
    EXTRACT --> FIND_INT
    FIND_INT --> APPLY_FILTER
    APPLY_FILTER --> CHECK_RULES
    
    CHECK_RULES --> BUILD_PAYLOAD
    BUILD_PAYLOAD --> ADD_TOKEN
    ADD_TOKEN --> VALIDATE_PAYLOAD
    
    VALIDATE_PAYLOAD --> SEND_API
    SEND_API --> LOG_EVENT
    LOG_EVENT --> SCHEDULE_CHECK
    
    SCHEDULE_CHECK --> SUCCESS
    
    VALIDATE -->|❌ Invalid| ERROR
    CHECK_RULES -->|❌ No Match| ERROR
    SEND_API -->|❌ Failed| ERROR
    
    ERROR --> RETRY
    RETRY --> FIND_INT
    
    classDef start fill:#E8F4FD,stroke:#4A90E2,color:#2C3E50
    classDef process fill:#F0F8E8,stroke:#7CB342,color:#2C3E50
    classDef decision fill:#FDF2E8,stroke:#FF9800,color:#2C3E50
    classDef endNode fill:#F8E8F8,stroke:#9C27B0,color:#2C3E50
    
    class START start
    class RECEIVE,VALIDATE,EXTRACT,FIND_INT,APPLY_FILTER,CHECK_RULES,BUILD_PAYLOAD,ADD_TOKEN,VALIDATE_PAYLOAD,SEND_API,LOG_EVENT,SCHEDULE_CHECK process
    class SUCCESS,ERROR,RETRY endNode
```

</details>

**🔄 Explicação do Register Sync:**

O **Register Sync** é o processo principal de sincronização em tempo real que processa cada inscrição individualmente:

1. **Coleta de Dados**:
   - Recebe eventos de inscrição dos marketplaces
   - Valida integridade e formato dos dados
   - Extrai informações do aluno (CPF, dados pessoais, curso)

2. **Matching de Integração**:
   - Busca integrações ativas para a instituição
   - Aplica filtros específicos (curso, região, perfil do aluno)
   - Verifica regras de negócio antes do envio

3. **Preparação do Payload**:
   - Constrói payload no formato esperado pela API da instituição
   - Adiciona tokens de autenticação válidos
   - Valida estrutura final do payload

4. **Entrega e Logging**:
   - Envia dados para API da instituição
   - Registra evento com status de sucesso/falha
   - Agenda verificação posterior do status de processamento

5. **Tratamento de Erros**:
   - Em caso de falha, programa retry automático
   - Mantém contador de tentativas
   - Escalona para intervenção manual após limite de tentativas

#### ⏰ Fluxo Register Cron

<details>
<summary>⏰ Visualizar Diagrama do Fluxo Register Cron</summary>

```mermaid
%%{init: {
  'theme':'base',
  'themeVariables': {
    'primaryColor':'#E8F4FD',
    'primaryBorderColor':'#4A90E2',
    'primaryTextColor':'#2C3E50',
    'secondaryColor':'#F0F8E8',
    'tertiaryColor':'#FDF2E8',
    'quaternaryColor':'#F8E8F8',
    'lineColor':'#5D6D7E',
    'fontFamily':'Inter,Segoe UI,Arial'
  }
}}%%
flowchart TD
    CRON_START["⏰ Cron Job Started"]
    
    subgraph "🔍 Discovery Phase"
        FETCH_INTEGRATIONS["📋 Fetch Active Integrations"]
        CHECK_INTERVAL["⏱️ Check Sync Intervals"]
        FILTER_DUE["🎯 Filter Due Syncs"]
    end
    
    subgraph "📊 Data Processing"
        FETCH_ORDERS["📦 Fetch Pending Orders"]
        GROUP_BY_INT["🗂️ Group by Integration"]
        PREPARE_BATCH["📋 Prepare Batch"]
    end
    
    subgraph "⚡ Batch Execution"
        PROCESS_BATCH["⚡ Process Batch"]
        APPLY_FILTERS["🧰 Apply Integration Filters"]
        BUILD_PAYLOADS["📄 Build Payloads"]
    end
    
    subgraph "📤 Delivery & Logging"
        SEND_BATCH["🌐 Send Batch to APIs"]
        LOG_RESULTS["📝 Log Results"]
        UPDATE_STATUS["📊 Update Status"]
    end
    
    COMPLETE["✅ Cron Complete"]
    ERROR_HANDLER["❌ Error Handler"]
    SCHEDULE_RETRY["🔄 Schedule Retry"]
    
    CRON_START --> FETCH_INTEGRATIONS
    FETCH_INTEGRATIONS --> CHECK_INTERVAL
    CHECK_INTERVAL --> FILTER_DUE
    
    FILTER_DUE --> FETCH_ORDERS
    FETCH_ORDERS --> GROUP_BY_INT
    GROUP_BY_INT --> PREPARE_BATCH
    
    PREPARE_BATCH --> PROCESS_BATCH
    PROCESS_BATCH --> APPLY_FILTERS
    APPLY_FILTERS --> BUILD_PAYLOADS
    
    BUILD_PAYLOADS --> SEND_BATCH
    SEND_BATCH --> LOG_RESULTS
    LOG_RESULTS --> UPDATE_STATUS
    
    UPDATE_STATUS --> COMPLETE
    
    PROCESS_BATCH -->|❌ Error| ERROR_HANDLER
    SEND_BATCH -->|❌ Failed| ERROR_HANDLER
    ERROR_HANDLER --> SCHEDULE_RETRY
    SCHEDULE_RETRY --> PROCESS_BATCH
    
    classDef cron fill:#E8F4FD,stroke:#4A90E2,color:#2C3E50
    classDef discovery fill:#F0F8E8,stroke:#7CB342,color:#2C3E50
    classDef processing fill:#FDF2E8,stroke:#FF9800,color:#2C3E50
    classDef delivery fill:#F8E8F8,stroke:#9C27B0,color:#2C3E50
    classDef endNode fill:#FCE4EC,stroke:#E91E63,color:#2C3E50
    
    class CRON_START cron
    class FETCH_INTEGRATIONS,CHECK_INTERVAL,FILTER_DUE discovery
    class FETCH_ORDERS,GROUP_BY_INT,PREPARE_BATCH,PROCESS_BATCH,APPLY_FILTERS,BUILD_PAYLOADS processing
    class SEND_BATCH,LOG_RESULTS,UPDATE_STATUS delivery
    class COMPLETE,ERROR_HANDLER,SCHEDULE_RETRY endNode
```

</details>

**⏰ Explicação do Register Cron:**

O **Register Cron** é o processo batch que executa periodicamente para processar volumes maiores de dados:

1. **Fase de Descoberta**:
   - Executa em intervalos programados (ex: a cada hora)
   - Busca todas as integrações ativas no sistema
   - Filtra integrações que estão no tempo de sincronização
   - Identifica quais precisam de processamento batch

2. **Processamento de Dados**:
   - Busca pedidos pendentes no período
   - Agrupa por integração para otimizar processamento
   - Prepara lotes (batches) para envio em massa

3. **Execução em Lote**:
   - Processa múltiplas inscrições simultaneamente
   - Aplica filtros de integração em massa
   - Constrói payloads otimizados para envio batch

4. **Entrega e Monitoramento**:
   - Envia lotes para APIs das instituições
   - Registra resultados de cada lote processado
   - Atualiza status de todas as inscrições processadas

5. **Recuperação de Erros**:
   - Identifica lotes que falharam
   - Agenda reprocessamento automático
   - Mantém métricas de performance e taxa de sucesso

**💡 Diferença entre Sync e Cron:**
- **Sync**: Processa inscrições individuais em tempo real
- **Cron**: Processa lotes de inscrições em intervalos programados

#### 🔍 Fluxo Checker

<details>
<summary>🔍 Visualizar Diagrama do Fluxo Checker</summary>

```mermaid
%%{init: {
  'theme':'base',
  'themeVariables': {
    'primaryColor':'#E8F4FD',
    'primaryBorderColor':'#4A90E2',
    'primaryTextColor':'#2C3E50',
    'secondaryColor':'#F0F8E8',
    'tertiaryColor':'#FDF2E8',
    'quaternaryColor':'#F8E8F8',
    'lineColor':'#5D6D7E',
    'fontFamily':'Inter,Segoe UI,Arial'
  }
}}%%
flowchart TD
    CHECKER_START["🔍 Checker Started"]
    
    subgraph "📊 Status Monitoring"
        FETCH_PENDING["📋 Fetch Pending Subscriptions"]
        CHECK_SCHEDULE["⏰ Check Scheduled Time"]
        FILTER_READY["🎯 Filter Ready to Check"]
    end
    
    subgraph "🌐 API Verification"
        CALL_STATUS_API["📞 Call Institution Status API"]
        PARSE_RESPONSE["📄 Parse Response"]
        EXTRACT_STATUS["🔍 Extract Status"]
    end
    
    subgraph "🔄 Status Processing"
        COMPARE_STATUS["⚖️ Compare with Current"]
        UPDATE_SUBSCRIPTION["📊 Update Subscription"]
        DETERMINE_ACTION["🤔 Determine Next Action"]
    end
    
    subgraph "📝 Event Logging"
        LOG_CHECK["📝 Log Check Event"]
        UPDATE_TIMESTAMP["⏰ Update Check Timestamp"]
        STORE_RESPONSE["💾 Store API Response"]
    end
    
    subgraph "🎯 Action Decision"
        SUCCESS["✅ Processing Complete"]
        PENDING["⏳ Still Pending"]
        FAILED["❌ Processing Failed"]
        RETRY_NEEDED["🔄 Retry Required"]
    end
    
    SCHEDULE_NEXT["⏰ Schedule Next Check"]
    TRIGGER_RETRY["🔄 Trigger Retry Process"]
    COMPLETE["✅ Check Complete"]
    
    CHECKER_START --> FETCH_PENDING
    FETCH_PENDING --> CHECK_SCHEDULE
    CHECK_SCHEDULE --> FILTER_READY
    
    FILTER_READY --> CALL_STATUS_API
    CALL_STATUS_API --> PARSE_RESPONSE
    PARSE_RESPONSE --> EXTRACT_STATUS
    
    EXTRACT_STATUS --> COMPARE_STATUS
    COMPARE_STATUS --> UPDATE_SUBSCRIPTION
    UPDATE_SUBSCRIPTION --> DETERMINE_ACTION
    
    DETERMINE_ACTION --> LOG_CHECK
    LOG_CHECK --> UPDATE_TIMESTAMP
    UPDATE_TIMESTAMP --> STORE_RESPONSE
    
    STORE_RESPONSE --> SUCCESS
    STORE_RESPONSE --> PENDING
    STORE_RESPONSE --> FAILED
    STORE_RESPONSE --> RETRY_NEEDED
    
    SUCCESS --> COMPLETE
    PENDING --> SCHEDULE_NEXT
    FAILED --> COMPLETE
    RETRY_NEEDED --> TRIGGER_RETRY
    
    SCHEDULE_NEXT --> COMPLETE
    TRIGGER_RETRY --> COMPLETE
    
    CALL_STATUS_API -->|❌ API Error| FAILED
    
    classDef start fill:#E8F4FD,stroke:#4A90E2,color:#2C3E50
    classDef monitoring fill:#F0F8E8,stroke:#7CB342,color:#2C3E50
    classDef api fill:#FDF2E8,stroke:#FF9800,color:#2C3E50
    classDef processing fill:#F8E8F8,stroke:#9C27B0,color:#2C3E50
    classDef decision fill:#FCE4EC,stroke:#E91E63,color:#2C3E50
    classDef endNode fill:#E1F5FE,stroke:#00BCD4,color:#2C3E50
    
    class CHECKER_START start
    class FETCH_PENDING,CHECK_SCHEDULE,FILTER_READY monitoring
    class CALL_STATUS_API,PARSE_RESPONSE,EXTRACT_STATUS api
    class COMPARE_STATUS,UPDATE_SUBSCRIPTION,DETERMINE_ACTION,LOG_CHECK,UPDATE_TIMESTAMP,STORE_RESPONSE processing
    class SUCCESS,PENDING,FAILED,RETRY_NEEDED decision
    class SCHEDULE_NEXT,TRIGGER_RETRY,COMPLETE endNode
```

</details>

**🔍 Explicação do Fluxo Checker:**

O **Checker** é o componente responsável por **monitorar o status de processamento** das inscrições nas instituições:

1. **Monitoramento de Status**:
   - Executa periodicamente para verificar inscrições pendentes
   - Identifica inscrições que precisam de verificação de status
   - Filtra apenas aquelas que atingiram o tempo de verificação programado

2. **Verificação via API**:
   - Chama APIs de status das instituições para consultar andamento
   - Faz parsing das respostas que podem ter formatos diferentes por instituição
   - Extrai informações relevantes sobre o status atual da inscrição

3. **Processamento de Status**:
   - Compara status atual com status anterior armazenado
   - Atualiza informações da inscrição no banco de dados
   - Determina próxima ação baseada no novo status

4. **Logging de Eventos**:
   - Registra cada verificação realizada
   - Atualiza timestamp da última verificação
   - Armazena resposta completa da API para auditoria

5. **Decisões de Fluxo**:
   - **Sucesso**: Inscrição foi processada com sucesso pela instituição
   - **Pendente**: Ainda em processamento, agenda próxima verificação
   - **Falha**: Processamento falhou na instituição, marca como erro
   - **Retry**: Problema temporário, agenda nova tentativa de envio

**🎯 Objetivo do Checker:**
Garantir que todas as inscrições enviadas sejam devidamente processadas pelas instituições, fornecendo visibilidade completa do pipeline de integração e permitindo intervenções quando necessário.

## Outras docs

- Página do produto: https://www.notion.so/quero
- [Anubis Docs](https://github.com/quero-edu/anubis/tree/main/docs)

