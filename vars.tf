
# variable for location
variable "location" {
    description = "All the resources in this project should be creted in this location"
    default = "West Europe"
}

# variable for resource group
variable "prefix" {
    description = "Name for all the resources in this resource group"
    default = "firstproject"
}

# variable for resource group
variable "username" {
    description = "String for admin_username"
    default = "SrinidhiChintham"
}

# variable for resource group
variable "password" {
    description = "String for admin_password"
    default = "Strikerduke7$"
}

variable "packer_image_name" {
   description = "Name of the Packer image"
   default     = "myPackerImage"
}

variable "managed_image_resource_group_name" {
   description = "Name of the managed image resource group"
   default     = "firstproject-resources"
}
variable "Num_of_VMs" {
   description = "Number of VMs in Virtual machine set"
   default     = "2"
}

variable "main_ipconfig1" {
   description = "Number of VMs in Virtual machine set"
   default     = "main-config1"
}


variable "tags_for_policy" {
   description = "all the tags to enforce our policy"
   type        = list
   default     = [
      "project",
      "test1"            #Here test1 is a dummy tag used as second value to fill up the list
   ] 
}

variable "subscription"{
description = "Subscription ID"
type  = string
default = "xxxx-xxxx-xxxx-xxx"
}
