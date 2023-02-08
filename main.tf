# Deploying a Web Server in Azure

# configuring the cloud provider - Azure
terraform {
  required_providers {
    azurerm = {
        source = "hashicorp/azurerm"
        version = "3.0.0"
    }
  }
}

# configuring Microsoft Azure
provider "azurerm" {
    features {
      
    }
}

# creating a resource group
resource "azurerm_resource_group" "main" {
  name     = "${var.prefix}-resources"
  location = var.location
  tags = {
    "project" = "first"
  }
} 

# creating a virtual network
resource "azurerm_virtual_network" "main" {
    name = "${var.prefix}-network"
    address_space = [ "10.0.0.0/16" ]
    location = azurerm_resource_group.main.location
    resource_group_name = azurerm_resource_group.main.name
    
    tags = {
    "project" = "first"
  }
}

#creating a network interface - NIC
resource "azurerm_network_interface" "main" {
  name                = "${var.prefix}-nic"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  ip_configuration {
    name                          = var.main_ipconfig1
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
  }
  tags = {
    "project" = "first"
  }
}

# creating a public ip
resource "azurerm_public_ip" "main" {
  name                = "${var.prefix}-PublicIp"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  allocation_method   = "Static"

  tags = {
    "project" = "first"
  }
}


# creating subnet
resource "azurerm_subnet" "main" {
  name                 = "${var.prefix}-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}


# creating a network security group
resource "azurerm_network_security_group" "main" {
  name                = "first_project_SecurityGroup"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "test1"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-all-traffic-between_VMs"
    priority                   = 101
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "AzureLoadBalancer"
  }

  security_rule {
    name                       = "Deny-all-traffic-from-internet"
    priority                   = 102
    direction                  = "Outbound"
    access                     = "Deny"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "AzureLoadBalancer"
  }

  tags = {
    "project" = "first"
  }
}

# associating subnet with nsg
resource "azurerm_subnet_network_security_group_association" "main" {
  subnet_id                 = azurerm_subnet.main.id
  network_security_group_id = azurerm_network_security_group.main.id
}

# Creating a load balancer
resource "azurerm_lb" "main" {
  name                = "${var.prefix}-lb"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  frontend_ip_configuration {
    name                 = "primary"
    public_ip_address_id = azurerm_public_ip.main.id
  }
  tags = {
    "project" = "first"
  }
}

# Creating a backend address pool
resource "azurerm_lb_backend_address_pool" "main" {
  loadbalancer_id = azurerm_lb.main.id
  name            = "backtestpool"
}

# Creating an association to NIC and backend address pool
resource "azurerm_network_interface_backend_address_pool_association" "main" {
  network_interface_id    = azurerm_network_interface.main.id
  ip_configuration_name   = var.main_ipconfig1
  backend_address_pool_id = azurerm_lb_backend_address_pool.main.id
}

# creating a virtual machine avalability set
resource "azurerm_availability_set" "main" {
  name                = "${var.prefix}-avset"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = {
    "project" = "first"
  }
}

# create a template of packer for vm
data "azurerm_image" "image" {
  name                = var.packer_image_name
  resource_group_name = var.managed_image_resource_group_name
}

# create a scale set for azure
resource "azurerm_virtual_machine_scale_set" "vm-ss" {
  name                = "vmscaleset"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  upgrade_policy_mode = "Manual"

  sku {
    name     = "Standard_DS1_v2"
    tier     = "Standard"
    capacity = var.Num_of_VMs
  }

  storage_profile_image_reference {
    id=data.azurerm_image.image.id
  }

  storage_profile_os_disk {
    name              = ""
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_profile_data_disk {
    lun          = 0
    caching        = "ReadWrite"
    create_option  = "Empty"
    disk_size_gb   = 10
  }

  os_profile {
    computer_name_prefix = "vmlab"
    admin_username       = var.username
    admin_password       = var.password
  }

  os_profile_linux_config {
    disable_password_authentication = false

  }

  network_profile {
    name    = "terraformnetworkprofile"
    primary = true

    ip_configuration {
      name                                   = var.main_ipconfig1
      subnet_id                              = azurerm_subnet.main.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.main.id]
      primary = true
    }
  }
  
  tags = {
    "project" = "first"
  }
}
