## Enter provider details
## To get the details mentioned in the provider section, go to Azure CLI, and enter below command
    ## az ad sp create-for-rbac --name "<SP-NAME>" --role="Contributor" --scopes="/subscriptions/<SUBSCRIPTION-ID>"
    ## The output will be in json format
    ## If the above command gives an error, give a new Service Provider name and try again
    ## app_id = client_id; password = client_secret; tenant = tenant_id

provider "azurerm" {
    features {}

    client_id = "XXXXXXX"
    client_secret = "XXXXXXX"
    tenant_id = "XXXXXXX"
    subscription_id = "XXXXXXX"
}


## Enter Resource Group details
resource "azurerm_resource_group" "my_rg" {
    name = "my-resource-group"
    location = "East US"
}


## Create Virtual Network
resource "azurerm_virtual_network" "my_vnet" {
    name = "my-vnet"
    location = azurerm_resource_group.my_rg.location
    resource_group_name = azurerm_resource_group.my_rg.name
    address_space = [ "10.0.0.0/16" ]
}


## Create the public subnets
resource "azurerm_subnet" "public_subnet_1" {
    name = "public-subnet-1"
    resource_group_name = azurerm_resource_group.my_rg.name
    virtual_network_name = azurerm_virtual_network.my_vnet.name
    address_prefixes = [ "10.0.0.0/24" ]
}

resource "azurerm_subnet" "public_subnet_2" {
    name = "public-subnet-2"
    resource_group_name = azurerm_resource_group.my_rg.name
    virtual_network_name = azurerm_virtual_network.my_vnet.name
    address_prefixes = [ "10.0.1.0/24" ]
}


## Create the private subnets
resource "azurerm_subnet" "private_subnet_1" {
    name = "private-subnet-1"
    resource_group_name = azurerm_resource_group.my_rg.name
    virtual_network_name = azurerm_virtual_network.my_vnet.name
    address_prefixes = [ "10.0.2.0/24" ]
}

resource "azurerm_subnet" "private_subnet_2" {
    name = "private-subnet-2"
    resource_group_name = azurerm_resource_group.my_rg.name
    virtual_network_name = azurerm_virtual_network.my_vnet.name
    address_prefixes = [ "10.0.3.0/24" ]
}


## Create a reserved public ip for NAT Gateway
resource "azurerm_public_ip" "nat_reserved_ip" {
    name = "nat-reserved-ip"
    location = azurerm_resource_group.my_rg.location
    resource_group_name = azurerm_resource_group.my_rg.name
    allocation_method = "Static"
    sku = "Standard"
}


## Create NAT Gateway
resource "azurerm_nat_gateway" "my_nat_gw" {
    name = "my-nat-gateway"
    location = azurerm_resource_group.my_rg.location
    resource_group_name = azurerm_resource_group.my_rg.name
    sku_name = "Standard"

    idle_timeout_in_minutes = 10
}

## Create a Public IP for NAT Gateway
resource "azurerm_public_ip" "nat_public_ip" {
    name = "nat-public-ip"
    location = azurerm_resource_group.my_rg.location
    resource_group_name = azurerm_resource_group.my_rg.name
    allocation_method = "Static"
    sku = "Standard"
}

## NAT Gateway association with Public IP
resource "azurerm_nat_gateway_public_ip_association" "nat_public_ip_assoc" {
    nat_gateway_id = azurerm_nat_gateway.my_nat_gw.id
    public_ip_address_id = azurerm_public_ip.nat_public_ip.id
}

## NAT Gateway association with private subnet
resource "azurerm_subnet_nat_gateway_association" "nat_private_subnet_assoc" {
    subnet_id = azurerm_subnet.private_subnet_1.id
    nat_gateway_id = azurerm_nat_gateway.my_nat_gw.id
}

## Create Route Tables to route Internet traffic through NAT Gateway
resource "azurerm_route_table" "private_rt" {
    name = "private-route-table"
    location = azurerm_resource_group.my_rg.location
    resource_group_name = azurerm_resource_group.my_rg.name
}

resource "azurerm_route" "internet_route" {
    name = "private-route-table"
    resource_group_name = azurerm_resource_group.my_rg.name
    route_table_name = azurerm_route_table.private_rt.name
    address_prefix = "0.0.0.0/0"
    next_hop_type = "Internet"
}

resource "azurerm_subnet_route_table_association" "private_rt_assoc" {
    subnet_id = azurerm_subnet.private_subnet_1.id
    route_table_id = azurerm_route_table.private_rt.id
}


## Create Route Tables: Public and Default
resource "azurerm_route_table" "public_rt" {
    name = "public-route-table"
    location = azurerm_resource_group.my_rg.location
    resource_group_name = azurerm_resource_group.my_rg.name
}

resource "azurerm_route" "default_route" {
    name = "default-route"
    resource_group_name = azurerm_resource_group.my_rg.name
    route_table_name = azurerm_route_table.public_rt.name
    address_prefix = "0.0.0.0/0"
    next_hop_type = "Internet"
}

## Associate Public Route Table with Public Subnets
resource "azurerm_subnet_route_table_association" "public_subnet_1_rt_assoc" {
    subnet_id = azurerm_subnet.public_subnet_1.id
    route_table_id = azurerm_route_table.public_rt.id
}

resource "azurerm_subnet_route_table_association" "public_subnet_2_rt_assoc" {
    subnet_id = azurerm_subnet.public_subnet_2.id
    route_table_id = azurerm_route_table.public_rt.id
}


## Create Security Group
resource "azurerm_network_security_group" "my_sg" {
    name = "my-security-group"
    location = azurerm_resource_group.my_rg.location
    resource_group_name = azurerm_resource_group.my_rg.name
}

## Associate Security Group with Public-Subnet-1
resource "azurerm_subnet_network_security_group_association" "sg_public_subnet_1_association" {
    subnet_id = azurerm_subnet.public_subnet_1.id
    network_security_group_id = azurerm_network_security_group.my_sg.id
}

## Associate Security Group with Public-Subnet-2
resource "azurerm_subnet_network_security_group_association" "sg_public_subnet_2_association" {
    subnet_id = azurerm_subnet.public_subnet_2.id
    network_security_group_id = azurerm_network_security_group.my_sg.id
}

## Network security ingress and egress rules
resource "azurerm_network_security_rule" "allow_ssh_http" {
    name = "allow-ssh-http"
    priority = 1000
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_ranges = [ "22", "80", "8080" ]
    source_address_prefix = "0.0.0.0/0"
    destination_address_prefix = "*"
    resource_group_name = azurerm_resource_group.my_rg.name
    network_security_group_name = azurerm_network_security_group.my_sg.name
}


## Create two network interfaces, one for app-machine and another for tools-machine
resource "azurerm_network_interface" "app_machine_nic" {
    name = "app-machine-nic"
    location = azurerm_resource_group.my_rg.location
    resource_group_name = azurerm_resource_group.my_rg.name

    ip_configuration {
      name = "internal"
      subnet_id = azurerm_subnet.public_subnet_1.id
      private_ip_address_allocation = "Dynamic"
      public_ip_address_id = azurerm_public_ip.app_public_ip.id
    }
}

resource "azurerm_network_interface" "tools_machine_nic" {
    name = "tools-machine-nic"
    location = azurerm_resource_group.my_rg.location
    resource_group_name = azurerm_resource_group.my_rg.name

    ip_configuration {
      name = "internal"
      subnet_id = azurerm_subnet.public_subnet_2.id
      private_ip_address_allocation = "Dynamic"
      public_ip_address_id = azurerm_public_ip.tools_public_ip.id
    }
}


## Create Public IPs for both the VMs
resource "azurerm_public_ip" "app_public_ip" {
    name = "app-public-ip"
    location = azurerm_resource_group.my_rg.location
    resource_group_name = azurerm_resource_group.my_rg.name
    allocation_method = "Static"
}

resource "azurerm_public_ip" "tools_public_ip" {
    name = "tools-public-ip"
    location = azurerm_resource_group.my_rg.location
    resource_group_name = azurerm_resource_group.my_rg.name
    allocation_method = "Static"
}


## Generate SSH Key-Pair and save private key to file locally
resource "tls_private_key" "key" {
    algorithm = "RSA"
    rsa_bits = 4096
}

resource "local_file" "private_key" {
    content = tls_private_key.key.private_key_pem
    filename = "/Path/to/the/file/azure-key.pem"
}

## Create VMs "app-machine" and "tools-machine"
resource "azurerm_linux_virtual_machine" "azure_app_machine" {
    name = "azure-app-machine"
    resource_group_name = azurerm_resource_group.my_rg.name
    location = azurerm_resource_group.my_rg.location
    size = "Standard_B2ms"
    admin_username = "azureuser_app"
    network_interface_ids = [ azurerm_network_interface.app_machine_nic.id ]

    admin_ssh_key {
      username = "azureuser_app"
      public_key = tls_private_key.key.public_key_openssh
    }

    os_disk {
      caching = "ReadWrite"
      storage_account_type = "Premium_LRS"
    }

    source_image_reference {
      publisher = "Canonical"
      offer = "0001-com-ubuntu-server-jammy"
      sku = "22_04-lts-gen2"
      version = "latest"
    }
}

resource "azurerm_linux_virtual_machine" "azure_tools_machine" {
    name = "azure-tools-machine"
    resource_group_name = azurerm_resource_group.my_rg.name
    location = azurerm_resource_group.my_rg.location
    size = "Standard_B2ms"
    admin_username = "azureuser_tools"
    network_interface_ids = [ azurerm_network_interface.tools_machine_nic.id ]

    admin_ssh_key {
      username = "azureuser_tools"
      public_key = tls_private_key.key.public_key_openssh
    }

    os_disk {
      caching = "ReadWrite"
      storage_account_type = "Premium_LRS"
    }

    source_image_reference {
      publisher = "Canonical"
      offer = "0001-com-ubuntu-server-jammy"
      sku = "22_04-lts-gen2"
      version = "latest"
    }
}
