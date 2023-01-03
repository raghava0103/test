terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.48.0"
    }
  }
}
provider "azurerm" {
  features {}
  
   subscription_id = "5e033ca6-1e01-4dca-b6d5-4e779d0e0aeb"
}

resource "azurerm_resource_group" "rg" {
  name     = "RG-CLIENT-TEST-POC"
  location = "East US"
}

resource "azurerm_kubernetes_cluster" "cluster" {
  name                = "k8scluster"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "k8scluster"

  default_node_pool {
    name       = "default"
    node_count = "2"
    vm_size    = "standard_d2_v2"
  }

  identity {
    type = "SystemAssigned"
  }
}
#########################Cosmos DB########################
resource "azurerm_cosmosdb_account" "acc" {
  name = "${var.cosmos_db_account_name}"
  location = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  offer_type = "Standard"
  kind = "GlobalDocumentDB"
  enable_automatic_failover = true
  consistency_policy {
    consistency_level = "Session"
  }
  
  geo_location {
    location = "${var.failover_location}"
    failover_priority = 1
  }
  geo_location {
    location = "${var.resource_group_location}"
    failover_priority = 0
  }
}
resource "azurerm_cosmosdb_sql_database" "db" {
  name = "sql-db"
  resource_group_name = "${azurerm_cosmosdb_account.acc.resource_group_name}"
  account_name = "${azurerm_cosmosdb_account.acc.name}"
}
resource "azurerm_cosmosdb_sql_container" "coll" {
  name = "products"
  resource_group_name = "${azurerm_cosmosdb_account.acc.resource_group_name}"
  account_name = "${azurerm_cosmosdb_account.acc.name}"
  database_name = "${azurerm_cosmosdb_sql_database.db.name}"
  partition_key_path = "/productsID"
}
########################storage account########################
resource "azurerm_storage_account" "lab" {
  name                     = "storageasendiaon"
  resource_group_name      = "RG-CLIENT-TEST-POC"
  location                 = "East US"
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    environment = "Terraform Storage"
    CreatedBy   = "Admin"
  }
}
