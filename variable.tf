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
variable "host" {
  description = "The database port to allow through the firewall"
  type        = string
}

variable "instance_name" {
  description = "The name of the instance"
  type        = string
}

variable "mysql_version" {
  description = "The version of MySQL to install"
  type        = string
}

variable "db_tier" {
  description = "The machine type for the database"
  type        = string
}

variable "sql_disk_type"{ 
  description = "The disk type for the database"
  type        = string
}

variable "sql_disk_size_gb" {
  description = "The size of the database disk in GB"
  type        = number
}

variable "db_name" {
  description = "The name of the database"
  type        = string
}

variable "db_user" {
  description = "The database user"
  type        = string
}

variable "password_length" {
  description = "The length of the password"
  type        = number
}

variable "private_ip_name" {
  description = "The name of the private IP"
  type        = string
}

variable "private_ip_purpose" {
  description = "The purpose of the private IP"
  type        = string
}

variable "private_ip_address_type" {
  description = "The type of the private IP address"
  type        = string
}

variable "db_port"{ 
  description = "The port for the database"
  type        = string
}

variable "override_special_characters"{ 
  description = "Override special characters"
  type        = string
}

variable "serviceaccountid"{
  description = "The service account id"
  type        = string
}

variable "serviceaccountname"{
  description = "The service account name"
  type        = string
}