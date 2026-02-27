provider "azurerm" {
  features {
    virtual_machine {
      delete_os_disk_on_deletion     = true
      skip_shutdown_and_force_delete = false
    }

    key_vault {
      recover_soft_deleted_key_vaults = true
      purge_soft_delete_on_destroy    = false
    }
  }

  resource_provider_registrations = "none"
}

provider "azapi" {}

data "azurerm_client_config" "current" {}
