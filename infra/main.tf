terraform {
  required_version = ">= 1.3.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
  
  backend "azurerm" {
    resource_group_name  = "rg-tfstate-gofunc"
    storage_account_name = "stgofunctfstate001"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "rg-${var.project_name}-finops-${var.environment}-001"
  location = var.location

  tags = {
    Environment = var.environment
    Owner       = "Vlad"
    Project     = var.project_name
    CostCenter  = "FreeTier"
    FinOpsFOCUS = "Compliant"
  }
}

# Storage Account
resource "azurerm_storage_account" "sa" {
  name                     = "sa${var.project_name}${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = azurerm_resource_group.rg.tags
}

# Service Plan (Y1 Serverless Free)
resource "azurerm_service_plan" "asp" {
  name                = "asp-${var.project_name}-free"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Linux"
  sku_name            = "Y1"

  tags = azurerm_resource_group.rg.tags
}

# Container for deployment packages (Linux Consumption needs package URL, not config-zip)
resource "azurerm_storage_container" "deployments" {
  name                  = "deployments"
  storage_account_name  = azurerm_storage_account.sa.name
  container_access_type = "private"
}

# Function App
resource "azurerm_linux_function_app" "func" {
  name                = "func-${var.project_name}-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  storage_account_name       = azurerm_storage_account.sa.name
  storage_account_access_key = azurerm_storage_account.sa.primary_access_key
  service_plan_id            = azurerm_service_plan.asp.id

  # MS docs: for custom handlers select .NET stack; worker runtime stays "custom".
  # Empty linuxFxVersion makes az CLI fail zip deploy with "Could not detect runtime".
  site_config {
    always_on = false
    application_stack {
      dotnet_version = "8.0"
    }
  }

  # Linux Consumption (Y1): WEBSITE_RUN_FROM_PACKAGE must be a blob URL (set by Ansible).
  # Do NOT set it to "1" — that value is not supported on Linux Y1.
  app_settings = {
    "FUNCTIONS_EXTENSION_VERSION"    = "~4"
    "FUNCTIONS_WORKER_RUNTIME"       = "custom"
    "ENVIRONMENT"                    = var.environment
    "ENABLE_ORYX_BUILD"              = "false"
    "SCM_DO_BUILD_DURING_DEPLOYMENT" = "false"
  }

  tags = azurerm_resource_group.rg.tags

  lifecycle {
    ignore_changes = [
      app_settings["WEBSITE_RUN_FROM_PACKAGE"],
    ]
  }
}

# FinOps Budget
resource "azurerm_consumption_budget_resource_group" "budget" {
  name              = "budget-zero-cost-guardrail"
  resource_group_id = azurerm_resource_group.rg.id
  amount            = 1
  time_grain        = "Monthly"

  time_period {
    start_date = "2026-08-01T00:00:00Z"
  }

  notification {
    enabled        = true
    threshold      = 80.0
    operator       = "GreaterThan"
    threshold_type = "Actual"
    contact_emails = ["your-email@example.com"]
  }
}