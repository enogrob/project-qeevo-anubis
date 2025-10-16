---
mode: 'agent'
---

# Update Codebase According the next Requirements for Anubis Rails Application

## Objective
Update the Rails application project according to the next new requirements.

## Context
Anubis is a microservice responsible for orchestrating the delivery of paying student data to higher education institution APIs (Kroton, Estácio, etc.). It manages enrollment flows from Quero Bolsa and new marketplaces, organizing payloads and logging structured events with retry mechanisms.

## Input Sources
- **Epic Documentation**: #file:inputs/epico.md (High-level project epic and goals)
- **Existing Codebase**: #folder:src/anubis . This repository reflects the current state of the Anubis application.
- **Existing Documentation**: #file:inputs/started-requirements.md
- **Previous Feature implemented**: #file:issues/#4277/4277.md
- **Next Feature to be implemented**: #file:issues/#4278/4278.md
- **Reference Architectures**:
  - Similar microservice pattern and stack: #folder:inputs/repositories/quero-deals
  - Integration examples: #folder:inputs/repositories/estacio-lead-integration
  - Integration examples: #folder:inputs/repositories/kroton-lead-integration

## Requirements

- Implement all features described in the current feature file (#file:issues/#4278/4278.md).
- Follow best practices for code quality, security, and performance.
- Ensure the application is well-documented, including code comments and updated README files.
- Write unit and integration tests to cover new functionalities. For unit tests add under #folder:src/anubis/spec folder and integration in #folder:src/anubis/script for the new services.
- Use the reference architectures as a guide for structuring the code and implementing features if required.
- Ensure compatibility with the latest stable versions of Ruby and Rails.
- Maintain a clean and organized codebase, adhering to standard conventions and patterns.
- After implemented, update accordingly the documentation in #file:inputs/started-requirements.md to reflect the new state of the application and also #file:docs/test-specifications.md if necessary.

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

