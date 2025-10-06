---
mode: 'agent'
---

# Update Requirements Started Document for Anubis Rails Application

## Objective
Update the Rails application requirements document that will serve as an input specification for the Anubis microservice project.

## Context
Anubis is a microservice responsible for orchestrating the delivery of paying student data to higher education institution APIs (Kroton, Estácio, etc.). It manages enrollment flows from Quero Bolsa and new marketplaces, organizing payloads and logging structured events with retry mechanisms.

## Input Sources
- **Base Requirements**: #file:inputs/started-requirements.md (Contains description, ER diagrams, and sketched flow diagrams). This is the document to be used as starting point.
- **Epic Documentation**: #file:inputs/epico.md (High-level project epic and goals)
- **Existing Codebase**: #folder:inputs/repositories/anubis (Starting point for Rails application structure). This repository  contains all the required Gems already installed and configured. Inclusive the database models for PostgreSQL.
- **Reference Architectures**:
  - Similar microservice pattern and stack: #folder:inputs/repositories/quero-deals
  - Integration examples: #folder:inputs/repositories/estacio-lead-integration
  - Integration examples: #folder:inputs/repositories/kroton-lead-integration

## Requirements Specification

### 1. Diagram Requirements
Replace all sketched diagrams with professional Mermaid diagrams:

**Visual Standards:**
- Use pastel color themes compatible with both dark and light browser themes
- Include relevant emojis for visual engagement and clarity
- Organize complex diagrams using subgraphs for better readability
- Size diagrams to fit A4 paper when printed (max width: 180mm)
- Use consistent color coding across all diagrams

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

## Output Deliverable
Generate: #file:outputs/anubis-rails-requirements-app.md that will start using as a base the content of #file:inputs/started-requirements.md
- Do one Diagram at a time, replacing the sketched diagrams with professional Mermaid diagrams.
- Ensure all diagrams follow the specified visual standards and Mermaid theme configuration.
- Maintain the original structure and content of the document, only replacing the diagrams.
