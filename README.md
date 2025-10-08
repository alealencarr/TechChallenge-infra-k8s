# TechChallenge Infra Compute 

[Documentação completa do projeto](https://alealencarr.github.io/TechChallenge/)

Cria o cluster Azure Kubernetes Service (AKS), o Azure Container Registry (ACR) e a infraestrutura da Function App.

### Descrição
Este repositório é responsável por provisionar as plataformas de computação da nossa arquitetura. Ele cria o ambiente onde as nossas aplicações (a API principal e a função de autenticação) serão executadas.

### Tecnologias Utilizadas
Terraform: Ferramenta de Infraestrutura como Código (IaC).

Azure Resources:

Azure Kubernetes Service (AKS)

Azure Container Registry (ACR)

Azure Function App

App Service Plan (Consumption)

Storage Account (para a Function App)

### Responsabilidades
Criar o cluster Azure Kubernetes Service (AKS), que será o orquestrador dos nossos contêineres da API principal.

Criar o Azure Container Registry (ACR), o nosso registo Docker privado para armazenar as imagens da aplicação.

Criar a infraestrutura para a nossa função serverless, incluindo a Azure Function App, o seu plano de serviço e a conta de armazenamento necessária.

Garantir que o AKS tem as permissões necessárias para aceder ao ACR.

### Dependências
TechChallenge-infra-foundational: Este repositório depende do Grupo de Recursos e da VNet criados pela infraestrutura de base.

### Processo de CI/CD
O pipeline de CI/CD (.github/workflows/deploy-infra.yml) automatiza a gestão da infraestrutura:

Em Pull Requests: Executa terraform plan para validar as alterações e mostrar o impacto previsto.

Em Merges na main: Executa terraform apply para aplicar as alterações no Azure.
