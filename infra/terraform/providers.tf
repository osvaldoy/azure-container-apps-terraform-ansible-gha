provider "azurerm" {
  features {}

  # Avoid failing when the account cannot register providers (common in locked-down subscriptions)
  #resource_provider_registrations = "none"
}
