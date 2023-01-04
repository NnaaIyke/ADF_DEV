
variable "resource_group_name" {
  type        = string
  description = "this is the name given to the datafactory"
  default     = "to-rg"
}

variable "resource_group_location" {
  type    = string
  default = "East US"
}

variable "azure_data_factory" {
  type    = string
  default = "adf-emissions"
}

variable "azure_devops" {
  type    = string
  default = "BBAAviation-Data-Factory"
}

variable "description" {
    default = "Test Azure DevOps Project for Data Factory Pipelines"
}

variable "visibility" {
    default = "private"
}

variable "version_control" {
    default = "Git"
}

variable "work_item_template" {
    default = "Basic"
}