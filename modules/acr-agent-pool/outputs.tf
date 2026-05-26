output "agent_pool_name" {
  description = "Name of the agent pool. Pass to `az acr build --agent-pool <name>` from workflows."
  value       = azapi_resource.agent_pool.name
}

output "agent_pool_resource_id" {
  description = "Resource ID of the agent pool."
  value       = azapi_resource.agent_pool.id
}

output "subnet_id" {
  description = "Resource ID of the subnet created for the agent pool."
  value       = azurerm_subnet.agent_pool.id
}
