# <img src="assets/anubis.png" alt="Anubis" width="32" height="32" style="vertical-align: middle; display: inline-block; margin-right: 8px;"/> Anubis Projeto - Requisitos

## Descrição

O Anubis é um microserviço responsável pela orquestração do envio de dados de alunos pagantes para APIs de instituições de ensino superior, como Kroton e Estácio. Ele gerencia o fluxo de inscrições vindas do Quero Bolsa e dos novos marketplaces (Ead.com, Guia da Carreira e Mundo Vestibular), organizando os payloads e registrando logs estruturados com o status das tentativas, além de implementar mecanismos automáticos de retry para falhas temporárias.

O escopo do serviço não inclui o envio de leads do Quero Captação, alunos pagantes de outros produtos da Qeevo, agendamento de envios ou interface para reenvio manual de falhas. O foco está na integração eficiente e segura dos dados de alunos pagantes entre os sistemas internos e as APIs das instituições parceiras.


## Modelo de Dados (ER Diagram)

📊 Diagrama Entidade-Relacionamento

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

### 🛡️ Considerações de Segurança

**Segurança:**
- CPF deve ser não precisa ser hasheado/criptografado em produção
- Tokens não devem ser armazenados com criptografia


## Fluxos do Projeto

### 🌟 Visão Geral do Sistema Anubis

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
graph TB
    subgraph "🌐 Data Sources"
        QB["📚 Quero Bolsa<br/>Students"]
        EAD["💻 Ead.com<br/>Students"]
        GC["🎓 Guia da Carreira<br/>Students"]
        MV["🌍 Mundo Vestibular<br/>Students"]
    end
    
    subgraph "🎯 Anubis Microservice"
        API["🔌 Rails API<br/>Endpoints"]
        PROC["⚙️ Processing Engine<br/>Payload Organization"]
        RETRY["🔄 Retry Mechanism<br/>Auto Recovery"]
        LOG["📊 Structured Logging<br/>Event Tracking"]
    end
    
    subgraph "🏫 Institution APIs"
        KROTON["🏛️ Kroton API<br/>Student Integration"]
        ESTACIO["🎓 Estácio API<br/>Student Integration"]
    end
    
    subgraph "💾 Database"
        DB["🗃️ PostgreSQL<br/>Subscriptions & Events"]
    end
    
    QB --> API
    EAD --> API
    GC --> API
    MV --> API
    
    API --> PROC
    PROC --> RETRY
    PROC --> LOG
    RETRY --> LOG
    
    PROC --> KROTON
    PROC --> ESTACIO
    RETRY --> KROTON
    RETRY --> ESTACIO
    
    API --> DB
    PROC --> DB
    RETRY --> DB
    LOG --> DB
    
    classDef sourceStyle fill:#E8F4FD,stroke:#4A90E2,stroke-width:2px
    classDef anubisStyle fill:#F0F8E8,stroke:#27AE60,stroke-width:2px
    classDef institutionStyle fill:#FDF2E8,stroke:#E67E22,stroke-width:2px
    classDef dbStyle fill:#F8E8F8,stroke:#8E44AD,stroke-width:2px
    
    class QB,EAD,GC,MV sourceStyle
    class API,PROC,RETRY,LOG anubisStyle
    class KROTON,ESTACIO institutionStyle
    class DB dbStyle
```

**📋 Explicação da Visão Geral:**
O sistema Anubis atua como um orquestrador central que recebe dados de alunos pagantes de múltiplas fontes (Quero Bolsa e novos marketplaces), processa e organiza os payloads, implementa mecanismos de retry para falhas temporárias, e envia os dados para as APIs das instituições de ensino superior. Todo o processo é registrado com logs estruturados para rastreabilidade completa.


### 🔧 Arquitetura de Serviços

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
graph TB
    subgraph "🌐 External Services"
        WEBHOOK["🔔 Webhook Events<br/>Student Enrollments"]
        CRON["⏰ Scheduled Jobs<br/>Periodic Sync"]
    end
    
    subgraph "🎯 Anubis Rails Application"
        subgraph "📝 Controllers Layer"
            CTRL["🎮 SubscriptionsController<br/>API Endpoints"]
        end
        
        subgraph "⚙️ Service Layer"
            REG_SYNC["🔄 RegisterSyncService<br/>Immediate Processing"]
            REG_CRON["⏰ RegisterCronService<br/>Batch Processing"]
            CHECKER["🔍 CheckerService<br/>Status Verification"]
        end
        
        subgraph "🗃️ Models Layer"
            SUB["📦 Subscription"]
            INT["🔌 Integration"]
            FILTER["🎯 IntegrationFilter"]
            TOKEN["🔐 IntegrationToken"]
            EVENT["📊 SubscriptionEvent"]
        end
        
        subgraph "🔧 Jobs Layer"
            SYNC_JOB["🚀 SyncJob<br/>Async Processing"]
            CHECK_JOB["👀 CheckJob<br/>Status Monitoring"]
        end
    end
    
    subgraph "🏫 External APIs"
        KROTON_API["🏛️ Kroton API"]
        ESTACIO_API["🎓 Estácio API"]
    end
    
    subgraph "💾 Storage"
        POSTGRES["🐘 PostgreSQL<br/>Primary Database"]
        REDIS["🔴 Redis<br/>Job Queue"]
    end
    
    WEBHOOK --> CTRL
    CRON --> REG_CRON
    
    CTRL --> REG_SYNC
    CTRL --> CHECKER
    
    REG_SYNC --> SYNC_JOB
    REG_CRON --> SYNC_JOB
    CHECKER --> CHECK_JOB
    
    SYNC_JOB --> SUB
    CHECK_JOB --> SUB
    
    SUB --> INT
    SUB --> FILTER
    SUB --> EVENT
    INT --> TOKEN
    
    SYNC_JOB --> KROTON_API
    SYNC_JOB --> ESTACIO_API
    CHECK_JOB --> KROTON_API
    CHECK_JOB --> ESTACIO_API
    
    SUB --> POSTGRES
    INT --> POSTGRES
    FILTER --> POSTGRES
    TOKEN --> POSTGRES
    EVENT --> POSTGRES
    
    SYNC_JOB --> REDIS
    CHECK_JOB --> REDIS
    
    classDef externalStyle fill:#E8F4FD,stroke:#4A90E2,stroke-width:2px
    classDef controllerStyle fill:#F0F8E8,stroke:#27AE60,stroke-width:2px
    classDef serviceStyle fill:#FDF2E8,stroke:#E67E22,stroke-width:2px
    classDef modelStyle fill:#F8E8F8,stroke:#8E44AD,stroke-width:2px
    classDef jobStyle fill:#E8F4FD,stroke:#3498DB,stroke-width:2px
    classDef apiStyle fill:#FDF2E8,stroke:#E74C3C,stroke-width:2px
    classDef storageStyle fill:#F0F8E8,stroke:#16A085,stroke-width:2px
    
    class WEBHOOK,CRON externalStyle
    class CTRL controllerStyle
    class REG_SYNC,REG_CRON,CHECKER serviceStyle
    class SUB,INT,FILTER,TOKEN,EVENT modelStyle
    class SYNC_JOB,CHECK_JOB jobStyle
    class KROTON_API,ESTACIO_API apiStyle
    class POSTGRES,REDIS storageStyle
```

**⚙️ Explicação da Arquitetura de Serviços:**
A arquitetura do Anubis segue os padrões Rails com separação clara de responsabilidades. Os webhooks e jobs agendados alimentam o sistema através de controllers, que delegam para services específicos. Os jobs assíncronos processam as integrações, enquanto os models gerenciam a persistência no PostgreSQL e o Redis gerencia a fila de jobs.

#### 📋 Fluxo Register Sync

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
sequenceDiagram
    participant EXT as 🌐 External System
    participant API as 🎮 SubscriptionsController
    participant REG as 🔄 RegisterSyncService
    participant SUB as 📦 Subscription Model
    participant JOB as 🚀 SyncJob
    participant IES as 🏫 Institution API
    participant LOG as 📊 SubscriptionEvent
    
    EXT->>+API: POST /subscriptions<br/>📤 Student Data
    API->>+REG: call(student_data)<br/>🔄 Process Registration
    
    REG->>+SUB: find_or_create_by<br/>🔍 Check Existing
    SUB-->>-REG: subscription_record<br/>📦 Subscription Instance
    
    alt New Subscription
        REG->>SUB: update(status: 'pending')<br/>⏳ Set Pending Status
        REG->>+JOB: perform_async<br/>🚀 Queue Processing
        JOB-->>-REG: job_enqueued<br/>✅ Job Queued
    else Existing Subscription
        REG->>SUB: update(status: 'duplicate')<br/>🔄 Mark Duplicate
    end
    
    REG->>+LOG: create(operation: 'register_sync')<br/>📝 Log Operation
    LOG-->>-REG: event_logged<br/>✅ Event Recorded
    
    REG-->>-API: result<br/>✅ Registration Result
    API-->>-EXT: 200 OK<br/>✅ Success Response
    
    Note over JOB,IES: Asynchronous Processing
    JOB->>+IES: POST student_data<br/>📤 Send to Institution
    
    alt Success Response
        IES-->>JOB: 200/201 OK<br/>✅ Success
        JOB->>SUB: update(status: 'sent')<br/>✅ Mark Sent
        JOB->>LOG: create(status: 'success')<br/>📝 Log Success
    else Error Response
        IES-->>JOB: 4xx/5xx Error<br/>❌ Error
        JOB->>SUB: update(status: 'failed')<br/>❌ Mark Failed
        JOB->>LOG: create(status: 'error')<br/>📝 Log Error
        JOB->>JOB: schedule_retry<br/>🔄 Schedule Retry
    end
```

**🔄 Explicação do Register Sync:**
O fluxo Register Sync processa registros de alunos em tempo real. Quando um sistema externo envia dados de um aluno, o controller recebe a requisição e delega para o RegisterSyncService, que verifica se já existe uma subscription para aquele aluno. Se for nova, agenda um job assíncrono para enviar os dados para a API da instituição. Todo o processo é logado para rastreabilidade.

#### ⏰ Fluxo Register Cron

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
sequenceDiagram
    participant CRON as ⏰ Cron Scheduler
    participant REG as ⏰ RegisterCronService
    participant INT as 🔌 Integration Model
    participant FILT as 🎯 IntegrationFilter
    participant API as 🌐 External Data API
    participant SUB as 📦 Subscription Model
    participant JOB as 🚀 SyncJob
    participant LOG as 📊 SubscriptionEvent
    
    CRON->>+REG: execute<br/>⏰ Start Scheduled Sync
    
    REG->>+INT: where(enabled: true)<br/>🔍 Get Active Integrations
    INT-->>-REG: integrations[]<br/>📋 Integration List
    
    loop For Each Integration
        REG->>+FILT: where(integration_id: id)<br/>🎯 Get Filters
        FILT-->>-REG: filters[]<br/>📋 Filter List
        
        loop For Each Filter
            REG->>+API: GET /students<br/>📥 Fetch Student Data
            Note over API: Apply filter parameters<br/>🎯 Query with filters
            API-->>-REG: student_data[]<br/>📦 Filtered Students
            
            loop For Each Student
                REG->>+SUB: find_or_create_by<br/>🔍 Check Existing
                SUB-->>-REG: subscription<br/>📦 Subscription Record
                
                alt New or Outdated
                    REG->>SUB: update(status: 'pending')<br/>⏳ Set Pending
                    REG->>+JOB: perform_async<br/>🚀 Queue Processing
                    JOB-->>-REG: job_queued<br/>✅ Job Enqueued
                    
                    REG->>+LOG: create(operation: 'register_cron')<br/>📝 Log Operation
                    LOG-->>-REG: event_logged<br/>✅ Event Recorded
                else Up to Date
                    Note over REG: Skip processing<br/>⏭️ Already current
                end
            end
        end
    end
    
    REG->>+LOG: create(operation: 'cron_completed')<br/>📝 Log Completion
    LOG-->>-REG: summary_logged<br/>✅ Summary Recorded
    
    REG-->>-CRON: execution_summary<br/>✅ Sync Completed
```

**⏰ Explicação do Register Cron:**
O fluxo Register Cron executa sincronizações programadas em lote. O scheduler ativa o RegisterCronService, que busca todas as integrações ativas e seus filtros. Para cada combinação, faz requisições para APIs externas buscando dados de alunos que atendem aos critérios dos filtros. Novos registros ou atualizações são enfileirados para processamento assíncrono.

#### 🔍 Fluxo Checker

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
sequenceDiagram
    participant CRON as ⏰ Cron Scheduler
    participant CHK as 🔍 CheckerService
    participant SUB as 📦 Subscription Model
    participant IES as 🏫 Institution API
    participant LOG as 📊 SubscriptionEvent
    participant JOB as 🚀 SyncJob
    
    CRON->>+CHK: execute<br/>🔍 Start Status Check
    
    CHK->>+SUB: where(status: ['sent', 'failed'])<br/>📋 Get Sent Subscriptions
    Note over SUB: Find subscriptions that need<br/>status verification
    SUB-->>-CHK: subscriptions[]<br/>📦 Subscription List
    
    loop For Each Subscription
        CHK->>+IES: GET /status/{student_id}<br/>🔍 Check Status
        
        alt Success Response
            IES-->>CHK: status_data<br/>✅ Status Retrieved
            
            alt Status Changed
                CHK->>SUB: update(status: new_status)<br/>🔄 Update Status
                CHK->>+LOG: create(operation: 'status_check')<br/>📝 Log Status Change
                LOG-->>-CHK: event_logged<br/>✅ Event Recorded
                
                alt Status is 'rejected' or 'failed'
                    CHK->>+JOB: perform_async<br/>🔄 Schedule Retry
                    JOB-->>-CHK: retry_scheduled<br/>⏰ Retry Queued
                end
            else Status Unchanged
                CHK->>SUB: update(checked_at: now)<br/>⏰ Update Check Time
                Note over CHK: No status change,<br/>just update timestamp
            end
            
        else Error Response
            IES-->>CHK: error_response<br/>❌ API Error
            CHK->>+LOG: create(status: 'check_error')<br/>📝 Log Check Error
            LOG-->>-CHK: error_logged<br/>❌ Error Recorded
        end
    end
    
    CHK->>+LOG: create(operation: 'checker_completed')<br/>📝 Log Completion
    LOG-->>-CHK: summary_logged<br/>✅ Summary Recorded
    
    CHK-->>-CRON: check_summary<br/>✅ Check Completed
```

**🔍 Explicação do Fluxo Checker:**
O fluxo Checker verifica periodicamente o status das subscriptions que foram enviadas para as instituições. O CheckerService busca todas as subscriptions com status 'sent' ou 'failed' e consulta a API da instituição para verificar se houve mudanças no status. Se o status mudou, atualiza o registro e registra o evento. Em caso de rejeição ou falha, agenda um novo retry automaticamente.
