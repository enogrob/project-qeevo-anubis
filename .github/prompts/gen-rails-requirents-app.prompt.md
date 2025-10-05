---
mode: 'agent'
---

# Rails Application Requirements Generator

## Objective
Generate a comprehensive Rails application requirements document that serves as a complete specification for the Anubis microservice, including technical architecture, user stories, acceptance criteria, and implementation guidelines.

## Context
Anubis is a microservice responsible for orchestrating the delivery of paying student data to higher education institution APIs (Kroton, Estácio, etc.). It manages enrollment flows from Quero Bolsa and new marketplaces, organizing payloads and logging structured events with retry mechanisms.

## Input Sources
- **Base Requirements**: #file:inputs/started-requirements.md (Contains description, ER diagrams, and sketched flow diagrams)
- **Epic Documentation**: #file:inputs/epico.md (High-level project epic and goals)
- **Existing Codebase**: #folder:inputs/repositories/anubis (Starting point for Rails application structure)
- **Reference Architectures**:
  - Similar microservice pattern and stack: #folder:inputs/repositories/quero-deals
  - Integration examples: #folder:inputs/repositories/estacio-lead-integration
  - Integration examples: #folder:inputs/repositories/kroton-lead-integration

## Requirements Specification

### 1. Document Structure Requirements
Create a comprehensive requirements document with the following sections:
- **Executive Summary**: Project overview, scope, and objectives
- **System Architecture**: High-level system design and component interactions
- **Data Model**: Complete ERD with relationships, constraints, and data flows
- **Functional Requirements**: Detailed user stories with acceptance criteria
- **Non-Functional Requirements**: Performance, security, scalability, and reliability specs
- **API Specifications**: REST endpoints with request/response formats
- **Integration Requirements**: External API integrations and data flows
- **Technical Stack**: Rails-specific implementation details
- **Testing Strategy**: Unit, integration, and end-to-end testing approaches
- **Deployment & Operations**: Infrastructure, monitoring, and maintenance

### 2. User Stories & Acceptance Criteria
Structure user stories using the format:
```
**As a** [role]
**I want** [functionality]
**So that** [business value]

**Acceptance Criteria:**
- Given [context]
- When [action]
- Then [expected outcome]
```

Focus on these key personas:
- System Administrator (manages integrations and monitoring)
- Student Data Processor (handles enrollment flows)
- Institution API Consumer (receives student data)
- Operations Team (monitors and troubleshoots)

### 3. Technical Architecture Requirements
Include detailed specifications for:
- **Rails Models**: ActiveRecord models with associations, validations, scopes
- **Controllers**: RESTful controllers with proper error handling
- **Services**: Business logic encapsulation and single responsibility
- **Jobs**: Background processing with Solid Queue integration
- **Database Design**: PostgreSQL schema with indexes and constraints
- **API Design**: Consistent REST API with proper HTTP status codes
- **Authentication**: Token-based authentication for external APIs
- **Error Handling**: Comprehensive error logging and retry mechanisms

### 4. Diagram Requirements
Replace all sketched diagrams with professional Mermaid diagrams:

**Visual Standards:**
- Use pastel color themes compatible with both dark and light browser themes
- Include relevant emojis for visual engagement and clarity
- Organize complex diagrams using subgraphs for better readability
- Size diagrams to fit A4 paper when printed (max width: 180mm)
- Use consistent color coding across all diagrams

**Required Diagrams:**
- System Architecture Overview (component diagram)
- Data Flow Diagrams (sequence diagrams for key processes)
- Entity Relationship Diagram (enhanced with data types and constraints)
- Integration Flow Charts (flowcharts for sync/async processes)
- State Machine Diagrams (for subscription status transitions)
- Deployment Architecture (infrastructure diagram)

**Mermaid Theme Configuration:**
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
```

### 5. Rails-Specific Implementation Details
Include comprehensive coverage of:
- **Gemfile**: Required gems with version constraints
- **Configuration**: Environment-specific settings and secrets management
- **Database Migrations**: Complete migration files with proper indexing
- **Routing**: RESTful routes with nested resources where appropriate
- **Validations**: Model validations with custom validators
- **Callbacks**: ActiveRecord callbacks for business logic
- **Concerns**: Shared modules for DRY code organization
- **Serializers**: JSON serialization for API responses
- **Testing**: RSpec test structure with factories and fixtures

### 6. Quality Standards
Ensure the requirements document meets these criteria:
- **Completeness**: All functional and non-functional requirements covered
- **Clarity**: Clear, unambiguous language with concrete examples
- **Consistency**: Consistent terminology and formatting throughout
- **Traceability**: Requirements linked to business objectives
- **Testability**: Each requirement includes measurable acceptance criteria
- **Maintainability**: Document structure supports easy updates and revisions

## Output Deliverable
Generate: #file:outputs/anubis-rails-requirements-app.md

The output should be a production-ready requirements document that can serve as:
- Technical specification for development team
- Reference guide for code reviews and testing
- Documentation for future maintenance and enhancements
- Foundation for project planning and estimation