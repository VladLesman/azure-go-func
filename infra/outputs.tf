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