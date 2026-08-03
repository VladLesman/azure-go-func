output "resource_group_name" {
  value       = azurerm_resource_group.rg.name
  description = "Resource Group Name for Ansible"
}

output "function_app_name" {
  value       = azurerm_linux_function_app.func.name
  description = "Function App Name for Ansible"
}

output "function_app_default_hostname" {
  value       = azurerm_linux_function_app.func.default_hostname
  description = "Public URL of the Function App"
}

output "storage_account_name" {
  value       = azurerm_storage_account.sa.name
  description = "Storage account for deployment packages"
}

output "storage_account_primary_access_key" {
  value       = azurerm_storage_account.sa.primary_access_key
  description = "Storage account key for Ansible blob upload"
  sensitive   = true
}

output "deployments_container_name" {
  value       = azurerm_storage_container.deployments.name
  description = "Blob container for function app zip packages"
}
