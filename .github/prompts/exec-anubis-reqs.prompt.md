---
mode: 'ask'
---

# Update Codebase According Appointed Requirements for Anubis Rails Application

## Objective
Update the Rails application project according to the entered reference requirements.

## Context
Anubis is a microservice responsible for orchestrating the delivery of paying student data to higher education institution APIs (Kroton, Estácio, etc.). It manages enrollment flows from Quero Bolsa and new marketplaces, organizing payloads and logging structured events with retry mechanisms.

## Input Sources
- **Base Requirements**: #file:inputs/started-requirements.md (Contains description, ER diagrams, and sketched architecture). This is the document of the initial requirements which states the tech stach of the codebase its Models and Overall architecture and .
- **Epic Documentation**: #file:inputs/epico.md (High-level project epic and goals)
- **Existing Codebase**: #folder:src/anubis . This repository  contains all the required Gems already installed and configured. Inclusive the database models for PostgreSQL.
- **Reference Architectures**:
  - Similar microservice pattern and stack: #folder:inputs/repositories/quero-deals
  - Integration examples: #folder:inputs/repositories/estacio-lead-integration
  - Integration examples: #folder:inputs/repositories/kroton-lead-integration

## Requirements Specification

### 1. Diagram Requirements

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

