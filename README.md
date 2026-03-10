#  Azure Container Apps · Terraform · OIDC · GitHub Actions

Production-style Dev/Prod setup using:

* Azure Container Apps
* Azure Container Registry (ACR)
* Terraform with remote state (Azure Storage)
* GitHub Actions with OIDC (no client secrets)
* Dev auto-deploy + Prod manual approval
* Budget + concurrency controls

---

#  Architecture Overview

```
                        ┌────────────────────────────┐
                        │        GitHub Actions       │
                        │  (OIDC → Azure AD login)    │
                        └──────────────┬──────────────┘
                                       │
                                       ▼
                           ┌─────────────────────┐
                           │ Azure AD App (SP)   │
                           │ OIDC Federated Auth │
                           └─────────┬───────────┘
                                     │ RBAC
                                     ▼
 ┌────────────────────────────────────────────────────────────────┐
 │                         Azure Subscription                      │
 │                                                                │
 │  Resource Group: rg-portfolio-ca-dev                          │
 │                                                                │
 │  ┌──────────────────────────────────────────────────────────┐  │
 │  │ Azure Container Apps Environment (cae-*)                │  │
 │  │                                                          │  │
 │  │  ┌────────────────────────────────────────────────────┐  │  │
 │  │  │ Container App (ca-*)                               │  │  │
 │  │  │ - User Assigned Identity                           │  │  │
 │  │  │ - Pulls image from ACR                             │  │  │
 │  │  └────────────────────────────────────────────────────┘  │  │
 │  │                                                          │  │
 │  │ Log Analytics Workspace                                 │  │
 │  └──────────────────────────────────────────────────────────┘  │
 │                                                                │
 │  Azure Container Registry (acr*)                              │
 │                                                                │
 │  Terraform Remote State                                        │
 │  RG: rg-tfstate-dev                                            │
 │  Storage Account: sttfstate*                                   │
 │  Container: tfstate                                            │
 │                                                                │
 └────────────────────────────────────────────────────────────────┘
```

---

#  Authentication Model (OIDC)

This project uses **OIDC (OpenID Connect)** instead of client secrets.

## Flow

1. GitHub Action requests a short-lived OIDC token.
2. Azure AD validates the federated credential.
3. Azure issues an access token for the Service Principal.
4. Terraform and Azure CLI use this token.
5. No secrets stored in GitHub.

## Why this is enterprise-grade

* No client secrets
* No certificate rotation needed
* Short-lived tokens
* Federated identity bound to:

  * repo
  * branch
  * environment

---

#  Terraform Remote State

Remote state is stored in Azure Storage.

## Backend Configuration

```hcl
terraform {
  backend "azurerm" {}
}
```

Configured dynamically in CI:

```bash
terraform init -reconfigure \
  -backend-config="resource_group_name=rg-tfstate-dev" \
  -backend-config="storage_account_name=sttfstate..." \
  -backend-config="container_name=tfstate" \
  -backend-config="key=dev/container-apps.tfstate" \
  -backend-config="use_azuread_auth=true"
```

## Why remote state?

* Shared state across machines and CI
* Locking support
* No drift between local and CI
* Enterprise practice

---

# How to Run Locally

##  Login to Azure

```bash
az login
az account set --subscription <SUB_ID>
```

## Initialize Terraform

```bash
cd infra/terraform

terraform init -reconfigure \
  -backend-config="resource_group_name=rg-tfstate-dev" \
  -backend-config="storage_account_name=sttfstate..." \
  -backend-config="container_name=tfstate" \
  -backend-config="key=dev/container-apps.tfstate" \
  -backend-config="use_azuread_auth=true"
```

## Plan

```bash
terraform plan -var-file=envs/dev.tfvars
```

## Apply

```bash
terraform apply -var-file=envs/dev.tfvars
```

---

# 🚀 Deployment Model

## Dev (Automatic)

Triggered when:

```
push → main → app/**
```

Pipeline steps:

1. Azure login (OIDC)
2. Build Docker image
3. Push to ACR
4. Verify tag exists
5. Terraform apply (update image_tag only)

Image tag = `github.sha`

---

## Infra Dev (Manual)

Workflow:

```
terraform-infra-apply-dev.yml
```

Triggered via:

```
workflow_dispatch
```

Used for:

* Infrastructure changes
* Scaling config
* Resource updates
* Policy adjustments

---

## Prod (Manual & Protected)

* `deploy-prod.yml` → manual
* `terraform-infra-apply-prod.yml` → manual
* GitHub Environment `prod` has required approvals

---

# Budget & Cost Control

Configured in Azure:

* Monthly budget: CAD $20
* Alerts:

  * 50%
  * 80%
  * 100%

Why:

* Prevent unexpected cost spikes
* Enforce financial discipline
* Portfolio demonstration of FinOps awareness

---

# Concurrency Protection

In workflows:

```yaml
concurrency:
  group: dev-deploy
  cancel-in-progress: true
```

Prevents:

* Parallel deploy collisions
* Race conditions on state
* Inconsistent image updates

---

# Runbook (How to Operate)

## 🔹 Deploy new version (Dev)

1. Modify app code
2. Commit to main
3. GitHub builds + deploys automatically

## 🔹 Apply infra change (Dev)

1. Modify Terraform
2. Merge to main
3. Run:

   * Actions → terraform-infra-apply-dev → Run workflow

## Deploy to Prod

1. Validate in Dev
2. Trigger:

   * Actions → deploy-prod → Run workflow
3. Approve environment if required

## Infra change Prod

1. Modify Terraform
2. Merge to main
3. Run:

   * terraform-infra-apply-prod
4. Approve environment

---

# Security Posture

* No secrets in repo
* OIDC authentication
* Least privilege RBAC
* Storage Blob Data Contributor only for state
* Reader role for management plane
* Environment protection in GitHub

---

# Project Structure

```
.
├── app/
│   └── Dockerfile
├── infra/
│   └── terraform/
│       ├── backend.tf
│       ├── main.tf
│       ├── providers.tf
│       ├── variables.tf
│       └── envs/
│           ├── dev.tfvars
│           └── prod.tfvars
└── .github/
    └── workflows/
        ├── deploy-dev.yml
        ├── deploy-prod.yml
        ├── terraform-infra-apply-dev.yml
        ├── terraform-infra-apply-prod.yml
        └── terraform-pr.yml
```

---

# Design Principles

* Infrastructure as Code
* GitOps workflow
* Immutable container versions
* Environment separation
* Zero secret CI/CD
* Minimal RBAC
* Cost visibility
* Production-aligned portfolio

---




