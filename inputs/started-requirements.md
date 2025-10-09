# <img src="assets/anubis.png" alt="Anubis" width="32" height="32" style="vertical-align: middle; display: inline-block; margin-right: 8px;"/> Anubis Projeto - Requisitos

## Descrição

O Anubis é um microserviço responsável pela orquestração do envio de dados de alunos pagantes para APIs de instituições de ensino superior, como Kroton e Estácio. Ele gerencia o fluxo de inscrições vindas do Quero Bolsa e dos novos marketplaces (Ead.com, Guia da Carreira e Mundo Vestibular), organizando os payloads e registrando logs estruturados com o status das tentativas, além de implementar mecanismos automáticos de retry para falhas temporárias.

O escopo do serviço não inclui o envio de leads do Quero Captação, alunos pagantes de outros produtos da Qeevo, agendamento de envios ou interface para reenvio manual de falhas. O foco está na integração eficiente e segura dos dados de alunos pagantes entre os sistemas internos e as APIs das instituições parceiras.

**Tecnologias predominantes:**
- Ruby 3.4.5
- Rails 8.0.3
- Postgres 17
- Kafka
- Rspec
- Simplecov
- AASM
- Tidewave

### Input Sources
- **Base Requirements**: `#file:inputs/started-requirements.md` (Contains description, ER diagrams, and sketched architecture). This is the document to be used as starting point.
- **Epic Documentation**: `#file:inputs/epico.md` (High-level project epic and goals)
- **Existing Codebase**: `#folder:inputs/repositories/anubis` (Starting point for Rails application structure). This repository  contains all the required Gems already installed and configured. Inclusive the database models for PostgreSQL.
- **Reference Architectures**:
  - Similar microservice pattern and stack: `#folder:inputs/repositories/quero-deals`
  - Integration examples: `#folder:inputs/repositories/estacio-lead-integration`
  - Integration examples: `#folder:inputs/repositories/kroton-lead-integration`


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


## Arquitetura do Projeto

![](assets/anubis-architecture.png)

**📋 Explicação da Arquitetura**


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
graph TD
    subgraph "🏗️ Anubis Application"
        A[📱 Controllers] --> B[🎪 OffersServices]
        B --> C[🔌 StockServicesClient]
        C --> D[📡 GraphQL Client]
        B --> E[📨 EventService]
        E --> F[📤 KafkaProducer]
    end
    
    subgraph "☁️ External Services"
        G[🏪 Stock Services API<br/>GraphQL Endpoint]
        H[📋 Kafka Cluster<br/>anubis.event.subscription.sent]
    end
    
    subgraph "🛠️ Infrastructure"
        I[📊 Cache]
        J[📋 Rails Logger]
        K[⚠️ Error Tracking]
    end
    
    D --> G
    F --> H
    C --> I
    C --> J
    E --> J
    C --> K
    E --> K
    
    style C fill:#E8F4FD,stroke:#4A90E2,stroke-width:3px
    style B fill:#F0F8E8,stroke:#67C52A,stroke-width:3px
    style E fill:#FDF2E8,stroke:#F39C12,stroke-width:3px
```


## 📚 Explicação da Arquitetura de Serviços

### 🎯 **Visão Geral da Arquitetura**

A arquitetura dos serviços segue o padrão de **3 camadas (3-Tier Architecture)** com responsabilidades bem definidas:

1. **📱 Presentation Layer**: Controllers que recebem requisições HTTP
2. **🎪 Business Logic Layer**: Serviços que implementam a lógica de negócio
3. **🔌 Data Access Layer**: Clientes que fazem interface com APIs externas

### 🔍 **Análise Detalhada por Serviço**

#### 1. 🔌 **StockServicesClient - Data Access Layer**

**Responsabilidades:**
- **🎯 Propósito**: Cliente GraphQL para comunicação com a API stock-services
- **🔧 Padrão**: Singleton para reutilização de conexões
- **💾 Cache**: Implementa cache Redis para otimização de performance
- **🛡️ Resiliência**: Retry automático e tratamento de erros

**Fluxo de Dados:**

<details>
<summary>📊 Sequence Diagram - StockServicesClient Flow</summary>

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
    participant Caller as 📱 Caller
    participant SSC as 🔌 StockServicesClient
    participant Cache as 💾 Cache
    participant API as 🏪 Stock Services API
    participant Logger as 📋 Logger
    
    Caller->>SSC: get_offers_cached([123])
    SSC->>Cache: Check cache key
    
    alt Cache Hit
        Cache-->>SSC: Return cached data
        SSC-->>Caller: Return offers data
    else Cache Miss
        SSC->>Logger: Log API request
        SSC->>API: GraphQL Query getOffers
        API-->>SSC: Return offers data
        SSC->>Cache: Store in cache (TTL: 5min)
        SSC->>Logger: Log success
        SSC-->>Caller: Return offers data
    end
    
    Note over SSC: Error Handling:<br/>- GraphQL errors<br/>- Network timeouts<br/>- Authentication issues
```

</details>

**Características Técnicas:**
- **🔄 Singleton Pattern**: Uma instância por aplicação
- **⚡ Connection Pooling**: Reutilização de conexões HTTP
- **🛡️ Circuit Breaker**: Proteção contra falhas em cascata
- **📊 Monitoring**: Logs estruturados para observabilidade

#### 2. 🎪 **OffersServices - Business Logic Layer**

**Responsabilidades:**
- **🎯 Propósito**: Orquestração da lógica de negócio para ofertas
- **🔧 Padrão**: Service Object com injeção de dependência
- **✅ Validação**: Validação de entrada e regras de negócio
- **🏗️ Transformação**: Formatação de dados para consumo

**Fluxo de Processamento:**

<details>
<summary>📊 Sequence Diagram - OffersServices Processing Flow</summary>

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
    participant Controller as 📱 Controller
    participant OS as 🎪 OffersServices
    participant SSC as 🔌 StockServicesClient
    participant Cache as 💾 Cache
    participant API as 🏪 Stock Services API
    participant Logger as 📋 Logger
    
    Controller->>OS: get_offer(offer_id)
    OS->>Logger: Log request start
    
    OS->>OS: validate_offer_id!(offer_id)
    
    alt Valid offer_id
        OS->>SSC: get_offers_cached([offer_id])
        SSC->>Cache: Check cache for offer data
        
        alt Cache Hit
            Cache-->>SSC: Return cached offer data
        else Cache Miss
            SSC->>API: GraphQL query getOffers
            API-->>SSC: Return offer data
            SSC->>Cache: Store in cache (TTL: 5min)
        end
        
        SSC-->>OS: Return offer data array
        
        alt Offer data found
            OS->>OS: build_offer_response(offer_data)
            OS->>OS: extract_metadata(offer_data)
            OS->>Logger: Log success
            OS-->>Controller: Return structured offer response
        else No offer data
            OS->>Logger: Log offer not found
            OS-->>Controller: Raise OfferNotFoundError
        end
        
    else Invalid offer_id
        OS->>Logger: Log validation error
        OS-->>Controller: Raise ArgumentError
    end
    
    Note over OS: Response Structure:<br/>├─ offer_id<br/>└─ metadata<br/>   ├─ title, price<br/>   ├─ course info<br/>   ├─ institution info<br/>   └─ campus info
```

</details>

**Características Técnicas:**
- **🔧 Dependency Injection**: StockServicesClient injetado para testabilidade
- **📊 Data Transformation**: Estruturação consistente de dados
- **🛡️ Input Validation**: Validação rigorosa de parâmetros
- **📋 Error Propagation**: Propagação inteligente de erros

#### 3. 📨 **EventService - Business Logic Layer**

**Responsabilidades:**
- **🎯 Propósito**: Publicação de eventos para sistemas externos via Kafka
- **🔧 Padrão**: Service Object com publisher pattern
- **📋 Estruturação**: Padronização de formato de eventos
- **🔑 Partitioning**: Estratégia de chaveamento para Kafka

**Fluxo de Eventos:**

<details>
<summary>📊 Sequence Diagram - EventService Flow</summary>

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
    participant Controller as 📱 Controller
    participant ES as 📨 EventService
    participant Kafka as 📋 Kafka Producer
    participant Topic as 🎪 Kafka Topic
    participant Consumer as 👥 Consumer Groups
    
    Controller->>ES: event_subscription_sent(payload)
    ES->>ES: validate_payload!
    ES->>ES: build_event_payload
    ES->>ES: extract_event_key (subscription_id)
    ES->>ES: build_event_headers
    
    ES->>Kafka: publish(topic, key, payload, headers)
    Kafka->>Topic: Write to partition (based on key)
    Topic-->>Consumer: Event available for consumption
    
    Kafka-->>ES: Delivery confirmation
    ES-->>Controller: Return event_id
    
    Note over ES: Event Structure:<br/>├─ event_id (UUID)<br/>├─ event_type<br/>├─ timestamp<br/>├─ service: 'anubis'<br/>├─ version: '1.0'<br/>└─ data: original_payload
```

</details>

**Características Técnicas:**
- **🔑 Event Sourcing**: Padrão de eventos imutáveis
- **📋 Schema Evolution**: Versionamento de eventos
- **🎯 Partitioning Strategy**: Chaveamento por subscription_id
- **🛡️ At-Least-Once Delivery**: Garantia de entrega

### 🔄 **Padrões Arquiteturais Implementados**

#### 1. **🏗️ Layered Architecture (Arquitetura em Camadas)**
- **Presentation**: Controllers HTTP
- **Business Logic**: Services (OffersServices, EventService)
- **Data Access**: Clients (StockServicesClient)

#### 2. **🔧 Dependency Injection**
```ruby
# Permite fácil substituição para testes
OffersServices.new(stock_client: mock_client)
EventService.new(kafka_producer: mock_producer)
```

#### 3. **🛡️ Circuit Breaker Pattern**
```ruby
# Proteção contra falhas em cascata
conn.request :retry, 
             max: 3, 
             interval: 0.5, 
             backoff_factor: 2
```

#### 4. **💾 Cache-Aside Pattern**
```ruby
# Cache inteligente com TTL
Rails.cache.fetch(cache_key, expires_in: 5.minutes) do
  expensive_api_call
end
```

#### 5. **📋 Publisher-Subscriber Pattern**
```ruby
# Publicação assíncrona de eventos
@kafka_producer.publish(topic: topic, payload: payload)
```

### 🎯 **Benefícios da Arquitetura**

1. **🔧 Separation of Concerns**: Cada camada tem responsabilidade específica
2. **🧪 Testability**: Injeção de dependência facilita testes unitários
3. **📈 Scalability**: Serviços podem ser escalados independentemente
4. **🛡️ Reliability**: Múltiplas camadas de tratamento de erro
5. **📊 Observability**: Logging estruturado em todas as camadas
6. **🔄 Maintainability**: Código organizado e padrões consistentes
7. **⚡ Performance**: Cache inteligente e connection pooling

---

## 📚 Referências

Esta seção contém links para documentações técnicas detalhadas e guias de implementação relacionados ao projeto Anubis:

### 🔧 **Documentação Técnica**

- **[📋 Requirements](../docs/requirements.md)** - Requisitos detalhados do projeto
- **[📊 Kafka Implementation Guide](../docs/kafka-implementation-guide.md)** - Guia completo de implementação Kafka
- **[🌐 Quero Deals](../docs/quero-deals.md)** - Documentação do sistema Quero Deals

### 🏢 **Integrações com Instituições**

- **[🎓 Estácio Lead Integration](../docs/estacio-lead-integration.md)** - Guia de integração com API da Estácio
- **[🎓 Kroton Lead Integration](../docs/kroton-lead-integration.md)** - Guia de integração com API da Kroton

### 📖 **Como Usar as Referências**

Estas documentações fornecem:

- **🔍 Detalhes de Implementação**: Especificações técnicas e exemplos de código
- **🔧 Guias de Configuração**: Configurações necessárias para cada integração
- **📊 Diagramas e Fluxos**: Visualizações detalhadas dos processos
- **🛡️ Tratamento de Erros**: Estratégias de resiliência e recuperação
- **🧪 Exemplos de Teste**: Cenários de teste e validação

> **💡 Dica**: Use estas referências como complemento a este documento principal para obter informações mais específicas sobre implementações e integrações.


