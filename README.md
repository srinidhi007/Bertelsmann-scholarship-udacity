# Deploying a Web Server in Azure
In this project we will create IaaC (Infrastructure as Code) and deploy web server in Azure using terraform template and packer template for VM image.

#

## Pre-Requisites
Before deploying, we have to ensure that we have following tools installed.

[An Azure account](https://portal.azure.com/)

[Terraform](https://www.terraform.io/downloads.html)

[Packer](https://www.packer.io/downloads/)

[Azure CLI](https://docs.microsoft.com/en-us/cli/azure/)

#

## Terraform Template (main.tf)

#### configuring the cloud provider 
- Here we are configuring Azure to be our cloud provider 

#### creating a resource group
- We are creating resource group with attributes location(West Europe)  and name (firstproject-resources) 'first project' is prefix. 
- All the resources from hereon, will be created in West Europe and with a prefix 'first project'

#### creating a virtual network
- Provisioning a virtual network with attributes name, location and our created resource group

#### creating a network interface - NIC
- Provisioning a network interface ang configuring it with subnet id and allocating private ip for our resources

#### creating a public ip
- Provisioning a public ip for VMs 

#### creating a subnet
- Provisioning a subnet for created resouce group

#### creating a network security group
- Provisioning a NSG group and adding rules to allow comminication between host machines internally but denying outside traffic.

#### associating subnet with nsg
- The provisioned nsg and subnet are associated with this module

#### Defining Azure policy to tag all indexed resources
- The policy ensures all the resources are tagged and indexed

#### Assigning and enforcing the policy to resource group
- This module ensures that, above created azure policy module is applied to all the resources in resource group, If resources are not following the policy it ensures auditing

#### Creating a load balancer
- Provisioning a load balancer to created Vms. 

#### Creating a backend address pool
- The backend pool ensures communication inside the network interface.

#### association to NIC and backend address pool
- Creating an association to NIC and backend address pool

#### creating a virtual machine avalability set
- Creating an availability set to logically group our created VMs.This will help maintain high availability.

#### create a template of packer for vm
- This module is ensures that the created packer temple is used for provisioning VMs.

#### create a scale set for azure VMs
- provisions a basic Linux Virtual Machine Scale Set on an internal network

#
## Azure policy
- Creating an azure policy is necessary, to do that, run the following command:
```
az policy definition create --name taggingpolicy --display-name "tagging policy" --description "tagging policy for all the resouces" --rules "policy.json" --mode All
```

- After creating the policy, to assign the policy run the following command:
```
az policy assignment create --name 'taggingpolicyassignment' --display-name "tagging policy" --scope /subscriptions/0eb45ed3-1797-4765-b446-7a8a5aa3XXXX --policy "taggingpolicy"
```
To see the expected output, run the following command:
```
az policy assignment list 
```
#### Expected output:
```
{
    "description": null,
    "displayName": "tagging policy",
    "enforcementMode": "Default",
    "id": "/subscriptions/0eb45ed3-1797-4765-b446-7a8a5aa37cb9/providers/Microsoft.Authorization/policyAssignments/taggingpolicyassignment",
    "identity": null,
    "location": null,
    "metadata": {
      "createdBy": "b0436b23-7b1d-4335-99a2-4dce77e050f9",
      "createdOn": "2023-02-08T11:39:36.7533354Z",
      "updatedBy": null,
      "updatedOn": null
    },
    "name": "taggingpolicyassignment",
    "nonComplianceMessages": null,
    "notScopes": null,
    "parameters": null,
    "policyDefinitionId": "/subscriptions/0eb45ed3-1797-4765-b446-7a8a5aa37cb9/providers/Microsoft.Authorization/policyDefinitions/taggingpolicy",  
    "scope": "/subscriptions/0eb45ed3-1797-4765-b446-7a8a5aa37cb9",
    "systemData": {
      "createdAt": "2023-02-08T11:39:36.718983+00:00",
      "createdBy": "chintham.srinidhi@gmail.com",
      "createdByType": "User",
      "lastModifiedAt": "2023-02-08T11:39:36.718983+00:00",
      "lastModifiedBy": "chintham.srinidhi@gmail.com",
      "lastModifiedByType": "User"
    },
```
#

## Packer Template (server.json)

This template is used to created all the VM images from hereon.

### Variables
- client_id
- client_secret
- tenant_id
- subscription_id
This variables can also be used as environment variables, but in this project I will be passing them here, However in the builders section this will be passed with variables.
- client_id, client_secret, tenant_id, subscription_id are created as service principles in Azure account. 

### creating service principles
- Run following command with Azure CLI, This will create a service principle in Azure AD/App registrations. 
- Here we are also assigning a contributor role to it so that during building and deploying it has access to our created service principle.

```
az ad sp create-for-rbac --role="Contributor" --scopes="/subscriptions/0eb45ed3-1797-4765-b446-xxxxxxxxxxxx"
 ```
The expected output will be as follows:
```
{
  "appId": "912ea67c-adc4-4e4d-b4fe-ba90095b1e51",
  "displayName": "azure-cli-2023-01-31-19-42-10",
  "password": "Q6l8Q~Ce9Z2Cp1oVcusszcZAAB5LH7Cl1b.oGcdz",
  "tenant": "5f973f3c-ca76-4078-a3d2-075229a32084"
}
```
We can also check the created service principle in Azure portal -> Azure AD -> App registrations. 

#

### Running packer template

Then, to create the packer image, run following command:
``` 
packer build server.json 
```
To check the created image, run:
```
az image list
```
Expected Output:
```
[
  {
    "extendedLocation": null,
    "hyperVGeneration": "V1",
    "id": "/subscriptions/0eb45ed3-1797-4765-b446-7a8a5aa37cb9/resourceGroups/FIRSTPROJECT-RESOURCES/providers/Microsoft.Compute/images/myPackerImage",
    "location": "westeurope",
    "name": "myPackerImage",
    "provisioningState": "Succeeded",
    "resourceGroup": "FIRSTPROJECT-RESOURCES",
    "sourceVirtualMachine": {
      "id": "/subscriptions/0eb45ed3-1797-4765-b446-7a8a5aa37cb9/resourceGroups/pkr-Resource-Group-ihsl7c3dbt/providers/Microsoft.Compute/virtualMachines/pkrvmihsl7c3dbt",
      "resourceGroup": "pkr-Resource-Group-ihsl7c3dbt"
    },
    "storageProfile": {
      "dataDisks": [],
      "osDisk": {
        "blobUri": null,
        "caching": "ReadWrite",
        "diskEncryptionSet": null,
        "diskSizeGb": 30,
        "managedDisk": {
          "id": "/subscriptions/0eb45ed3-1797-4765-b446-7a8a5aa37cb9/resourceGroups/pkr-Resource-Group-ihsl7c3dbt/providers/Microsoft.Compute/disks/pkrosihsl7c3dbt",
          "resourceGroup": "pkr-Resource-Group-ihsl7c3dbt"
        },
        "osState": "Generalized",
        "osType": "Linux",
        "snapshot": null,
        "storageAccountType": "Standard_LRS"
      },
      "zoneResilient": false
    },
    "tags": {},
    "type": "Microsoft.Compute/images"
  }
]
```
#

### Running Terraform template
- As our template is ready now, we can provision the desired infrastructure by using following commands:
```
terraform init
```

```
terraform plan -out solution.plan
```
Then run,
```
terraform apply
```
#

### Changing Variables (Vars.tf)
- In order to follow best security principles and limiting the use of coded values, we are using input variables in vars.tf file.
- Terraform variables allow us to write configure input variables which are easier to re-use.
- It is possible to change the variable name and its key-values in the attribute section, for example:

```
variable "prefix" {
    description = "Name for all the resources in this resource group"
    default = "firstproject"
}
```

Here, it is possible to change the input variable "prefix" and its key-value "firstproject" in default attribute.
