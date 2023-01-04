
#Azure DF RG for Dev Environment
resource "azurerm_resource_group" "datadev" {
  name      = "${var.resource_group_name}-dev-001"
  location  = var.resource_group_location
}

#Azure DF RG for Test Environment
resource "azurerm_resource_group" "datatest" {
  name      = "${var.resource_group_name}-test-001"
  location  = var.resource_group_location
}

#Creating the Azure Data Factory
resource "azurerm_data_factory" "datafactorydev" {
  name                               = "${var.azure_data_factory}-dev"
  managed_virtual_network_enabled    = true
  location                           = azurerm_resource_group.datadev.location
  resource_group_name                = azurerm_resource_group.datadev.name
}

resource "azurerm_data_factory" "datafactorytest" {
  name                               = "${var.azure_data_factory}-test"
  managed_virtual_network_enabled    = true
  location                           = azurerm_resource_group.datatest.location
  resource_group_name                = azurerm_resource_group.datatest.name
}

#Creating an Azure DevOPs project
resource "azuredevops_project" "ado" {
  name               = var.azure_devops
  visibility         = var.visibility
  version_control    = var.version_control
  work_item_template = var.work_item_template
  description        = var.description
  features = {
      "boards" = "enabled"
      "repositories" = "enabled"
      "pipelines" = "enabled"
      "testplans" = "enabled"
      "artifacts" = "enabled"
  }
}

#Resources to create a Virtual Network
resource "azurerm_virtual_network" "this" {
  name                = "VN-adf-dev001"
  address_space       = ["10.96.24.0/21"]
  location            = var.resource_group_location
  resource_group_name = azurerm_resource_group.datadev.name

  tags = {
    Environment = "Development"
    Description = "This Vnet is used Azure Data Factory."
  }
}

#Resources to create a subnet for service
resource "azurerm_subnet" "this" {
  name                 = "adf-service-Subnet-001"
  resource_group_name  = azurerm_resource_group.datadev.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["10.96.24.0/24"]

    enforce_private_link_service_network_policies = true
}

resource "azurerm_subnet" "endpoint" {
  name                 = "adf-endpoint-Subnet-001"
  resource_group_name  = azurerm_resource_group.datadev.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["10.96.25.0/24"]

  enforce_private_link_endpoint_network_policies = true
}

resource "azurerm_public_ip" "pip" {
  name                = "pip-adfvpn-dev-001"
  sku                 = "Standard"
  location            = var.resource_group_location
  resource_group_name = azurerm_resource_group.datadev.name
  allocation_method   = "Static"
}

resource "azurerm_lb" "adflb" {
  name                = "lb-adfvpn-dev-001"
  sku                 = "Standard"
  location            = var.resource_group_location
  resource_group_name = azurerm_resource_group.datadev.name

  frontend_ip_configuration {
    name                 = azurerm_public_ip.pip.name
    public_ip_address_id = azurerm_public_ip.pip.id
  }
}

resource "azurerm_lb_backend_address_pool" "this" {
  loadbalancer_id = azurerm_lb.adflb.id
  name            = "BackEndAddressPool"
}

# resource "azurerm_lb_backend_address_pool_address" "this" {
#   name                    = "my backend pool"
#   backend_address_pool_id = azurerm_lb_backend_address_pool.this.id
#   virtual_network_id      = azurerm_virtual_network.this.id
#   ip_address              = "10.0.0.1"
# }

resource "azurerm_lb_probe" "this" {
  loadbalancer_id = azurerm_lb.adflb.id
  name            = "adf-dev-running-probe"
  protocol        = "Tcp"
  port            = 22
}

resource "azurerm_lb_rule" "this" {
  loadbalancer_id                = azurerm_lb.adflb.id
  name                           = "adf-dev-LBRule"
  protocol                       = "Tcp"
  frontend_port                  = 1433
  backend_port                   = 1433
  # backend_address_pool_ids       = azurerm_lb_backend_address_pool.this.id
  probe_id                       = azurerm_lb_probe.this.id
  idle_timeout_in_minutes        = 15
  frontend_ip_configuration_name = azurerm_public_ip.pip.name
}

resource "azurerm_private_link_service" "this" {
  name                = "adf-privatelink-dev-001"
  location            = var.resource_group_location
  resource_group_name = azurerm_resource_group.datadev.name
  

  nat_ip_configuration {
    name      = azurerm_public_ip.pip.name
    primary   = true
    subnet_id = azurerm_subnet.this.id
  }

  load_balancer_frontend_ip_configuration_ids = [
    azurerm_lb.adflb.frontend_ip_configuration.0.id,
  ]
}

resource "azurerm_private_endpoint" "this" {
  name                = "adf-endpoint-dev-001"
  location            = var.resource_group_location
  resource_group_name = azurerm_resource_group.datadev.name
  subnet_id           = azurerm_subnet.endpoint.id

  private_service_connection {
    name                           = "adf-privateserviceconnection-dev-001"
    private_connection_resource_id = azurerm_private_link_service.this.id
    is_manual_connection           = false
  }
   
}