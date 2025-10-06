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
