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

### 📋 Informações Relevantes do Modelo de Dados

#### 🏛️ Entidades Principais e Seus Propósitos

**🔌 Integration (Integrações)**
- **Propósito**: Representa cada API de instituição de ensino (Kroton, Estácio, etc.)
- **Campos Críticos**:
  - `name`: Nome da instituição para identificação
  - `type`: Tipo de integração (REST, SOAP, GraphQL)
  - `key`: Chave de identificação única da API
  - `interval`: Intervalo em minutos para sincronização via cron

**🎯 IntegrationFilter (Filtros de Integração)**
- **Propósito**: Define regras de negócio específicas por instituição
- **Campos Críticos**:
  - `filter`: JSON contendo regras (ex: cursos aceitos, regiões, faixa etária)
  - `type`: Tipo de filtro (course, region, demographic, etc.)
  - `enabled`: Flag para ativar/desativar filtro dinamicamente

**📦 Subscription (Inscrições)**
- **Propósito**: Representa cada inscrição de aluno a ser processada
- **Campos Críticos**:
  - `order_id`: ID do pedido no sistema origem (Quero Bolsa, etc.)
  - `origin`: Marketplace de origem (quero_bolsa, ead_com, etc.)
  - `cpf`: CPF do aluno para identificação única
  - `payload`: Dados completos do aluno em formato JSON
  - `status`: Estado atual (pending, sent, confirmed, failed)
  - Timestamps para controle de fluxo temporal

**🔐 IntegrationToken (Tokens de Autenticação)**
- **Propósito**: Gerencia tokens de acesso às APIs das instituições
- **Campos Críticos**:
  - `key`: Tipo de token (access_token, api_key, bearer, etc.)
  - `value`: Valor do token criptografado
  - `valid_until`: Data de expiração para renovação automática

**📝 SubscriptionEvent (Log de Eventos)**
- **Propósito**: Auditoria completa de todas as operações
- **Campos Críticos**:
  - `status`: Resultado da operação (success, error, retry)
  - `operation_name`: Nome da operação (register_sync, checker, cron)
  - `error_message`: Detalhes de erro para debugging
  - `request`/`response`: Payloads completos para análise

#### 🔄 Relacionamentos e Fluxo de Dados

🏗️ Hierarquia de Dependências

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
graph TD
    subgraph "🏛️ Configuração de Instituições"
        INT["🔌 Integration<br/>📋 Instituição de Ensino<br/>(Kroton, Estácio, etc.)"]
        
        subgraph "🎯 Regras de Negócio"
            FILTER1["🧰 IntegrationFilter<br/>📚 Filtro de Cursos"]
            FILTER2["🌍 IntegrationFilter<br/>📍 Filtro Regional"]
            FILTER3["👥 IntegrationFilter<br/>🎯 Filtro Demográfico"]
        end
        
        subgraph "🔐 Autenticação"
            TOKEN1["🎫 IntegrationToken<br/>🔑 Access Token"]
            TOKEN2["🗝️ IntegrationToken<br/>🔐 API Key"]
            TOKEN3["🎟️ IntegrationToken<br/>⏰ Refresh Token"]
        end
    end
    
    subgraph "📦 Processamento de Inscrições"
        SUB1["📝 Subscription<br/>👤 Aluno Quero Bolsa"]
        SUB2["📝 Subscription<br/>👤 Aluno EAD.com"]
        SUB3["📝 Subscription<br/>👤 Aluno Guia Carreira"]
        
        subgraph "📊 Auditoria e Logs"
            EVENT1["📋 SubscriptionEvent<br/>✅ Envio Sucesso"]
            EVENT2["📋 SubscriptionEvent<br/>🔄 Tentativa Retry"]
            EVENT3["📋 SubscriptionEvent<br/>❌ Erro Processamento"]
            EVENT4["📋 SubscriptionEvent<br/>🔍 Verificação Status"]
        end
    end
    
    %% Relacionamentos principais
    INT -->|"has_many<br/>🎯 define regras"| FILTER1
    INT -->|"has_many<br/>🎯 define regras"| FILTER2
    INT -->|"has_many<br/>🎯 define regras"| FILTER3
    
    INT -->|"has_many<br/>🔐 autentica"| TOKEN1
    INT -->|"has_many<br/>🔐 autentica"| TOKEN2
    INT -->|"has_many<br/>🔐 autentica"| TOKEN3
    
    INT -->|"has_many<br/>📦 processa"| SUB1
    INT -->|"has_many<br/>📦 processa"| SUB2
    INT -->|"has_many<br/>📦 processa"| SUB3
    
    FILTER1 -->|"has_many<br/>✅ aplica filtro"| SUB1
    FILTER2 -->|"has_many<br/>✅ aplica filtro"| SUB2
    FILTER3 -->|"has_many<br/>✅ aplica filtro"| SUB3
    
    SUB1 -->|"has_many<br/>📝 registra eventos"| EVENT1
    SUB1 -->|"has_many<br/>📝 registra eventos"| EVENT2
    SUB2 -->|"has_many<br/>📝 registra eventos"| EVENT3
    SUB3 -->|"has_many<br/>📝 registra eventos"| EVENT4
    
    classDef integration fill:#E8F4FD,stroke:#4A90E2,color:#2C3E50
    classDef filter fill:#F0F8E8,stroke:#7CB342,color:#2C3E50
    classDef token fill:#FDF2E8,stroke:#FF9800,color:#2C3E50
    classDef subscription fill:#F8E8F8,stroke:#9C27B0,color:#2C3E50
    classDef event fill:#FCE4EC,stroke:#E91E63,color:#2C3E50
    
    class INT integration
    class FILTER1,FILTER2,FILTER3 filter
    class TOKEN1,TOKEN2,TOKEN3 token
    class SUB1,SUB2,SUB3 subscription
    class EVENT1,EVENT2,EVENT3,EVENT4 event
```

**Fluxo de Processamento:**
1. **Integration** define a instituição de destino
2. **IntegrationFilter** determina quais alunos são elegíveis
3. **Subscription** armazena dados do aluno para processamento
4. **IntegrationToken** fornece autenticação para API calls
5. **SubscriptionEvent** registra cada tentativa e resultado

#### 📊 Estados e Transições

**Status da Subscription:**
- `pending`: Aguardando processamento
- `filtered`: Não passou nos filtros da instituição
- `sent`: Enviado para API da instituição
- `confirmed`: Confirmado pela instituição
- `failed`: Falha no processamento
- `retry`: Agendado para nova tentativa

**Tipos de SubscriptionEvent:**
- `register_sync`: Processamento individual em tempo real
- `register_cron`: Processamento em lote via cron
- `checker`: Verificação de status na instituição
- `token_refresh`: Renovação de tokens
- `retry_attempt`: Tentativa de reenvio

#### 🛡️ Considerações de Segurança e Performance

**Segurança:**
- CPF deve ser hasheado/criptografado em produção
- Tokens devem ser armazenados com criptografia
- Payload pode conter dados sensíveis - considerar anonimização

**Performance:**
- Indexar `order_id`, `cpf`, `status` para consultas rápidas
- Particionamento de `SubscriptionEvent` por data
- Cache de `IntegrationFilter` para reduzir consultas
- Cleanup automático de eventos antigos

**Monitoramento:**
- Métricas por status de subscription
- Alertas para falhas em integrações específicas
- Dashboard de performance por instituição

## Fluxos do Projeto
![](assets/1-anubis-overview.png)

**📋 Explicação da Visão Geral:**


### 🔧 Arquitetura de Serviços
![](assets/2-anubis-services.png)


**⚙️ Explicação da Arquitetura de Serviços:**

#### 📋 Fluxo Register Sync
![](assets/3-register-sync.png)

**🔄 Explicação do Register Sync:**


#### ⏰ Fluxo Register Cron
![](assets/4-register-cron.png)

**⏰ Explicação do Register Cron:**


#### 🔍 Fluxo Checker
![](assets/5-checker.png)


**🔍 Explicação do Fluxo Checker:**
