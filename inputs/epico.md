# Épico - Microserviço de Integração de Alunos Pagantes com IES (v0)

## Contexto

Atualmente, as integrações entre a Quero e as Instituições de Ensino (IES) são realizadas via APIs e crawlers, distribuídas em notebooks do time de Data no Databricks e em projetos distintos. Esse modelo gera alta dependência de pessoas e ambientes específicos, além de baixa rastreabilidade e pouca escalabilidade.

Esse cenário impacta diretamente:

*   A autonomia dos times de produto e engenharia;
*   A confiabilidade na execução das integrações;
*   A visibilidade de erros e falhas em produção;
*   A evolução e manutenção dos processos, que hoje são manuais e não padronizados.

## User Story

Como **time de produto e engenharia**,  
quero **migrar as integrações atuais para um microserviço centralizado**,  
para **reduzir dependências, padronizar processos, aumentar rastreabilidade e melhorar a produtividade interna**.

## Rota

Microserviço → Orquestração de envios de alunos pagantes → APIs de IES (Kroton e Estácio).

## Escopo

**Contempla**:

*   Envio de alunos pagantes vindos do Quero Bolsa (inscrição de alunos).
*   Construção dos fluxos das APIs atuais (Kroton e Estácio).
*   Envio de alunos pagantes nos novos marketplaces (Ead.com, Guia da Carreira e Mundo Vestibular).
*   Organização dos payloads de inscrição.
*   Registro de logs estruturados com status das tentativas.
*   Retry automático para falhas temporárias.

**Não contempla**:

*   Envio de leads do Quero Captação.
*   Envio de alunos pagantes de outros produtos da Qeevo.
*   Agendamento de envios.
*   Front para reenvio manual de falhas.

## Critérios de Aceite

*   Databricks não é mais necessário para este fluxo.
*   Logs disponíveis para todas as tentativas, com status de sucesso ou erro.
*   Retry automático implementado para falhas temporárias.
*   Envio funcionando para Kroton, Estácio e novos marketplaces.

## Métricas de Sucesso

*   100% das integrações migradas dos notebooks para o microserviço.
*   100% das tentativas registradas em logs rastreáveis.
*   Redução de retrabalho manual e falhas operacionais relacionadas às integrações.