output "name" {
  description = "The name of the agent pool. Pass to `az acr build --agent-pool <name>` from workflows."
  value       = azapi_resource.this.name
}

output "resource" {
  description = "The full resource object of the agent pool."
  value       = azapi_resource.this
}

output "resource_id" {
  description = "The resource ID of the agent pool."
  value       = azapi_resource.this.id
}
