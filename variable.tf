variable "project_id" {
  description = "The GCP project ID"
  type = string
}
 
variable "region" {
  description = "The GCP region to deploy resources"
  type = string
  default = "us-east4"
}
 
variable "vpc_name" {
  description = "The name of the VPC to create"
  type = string
}
 
variable "webapp_subnet_cidr" {
  description = "CIDR for the webapp subnet"
  type = string
}
 
variable "db_subnet_cidr" {
  description = "CIDR for the db subnet"
  type = string
}

variable "vm_name" {
  description = "The name of the VM instance"
  type = string
}

variable "vm_zone" {
  description = "The zone of the VM instance"
  type = string
}

variable "vm_machine_type" {
  description = "The machine type of the VM instance"
  type = string
}

variable "vm_image" {
  description = "The image of the VM instance"
  type = string
}

variable "vm_disk_type" {
  description = "The disk type of the VM instance"
  type = string
}

variable "vm_disk_size_gb" {
  description = "The disk size of the VM instance"
  type = string
}

variable "app_port" {
  description = "The port of the VM instance"
  type = string
}