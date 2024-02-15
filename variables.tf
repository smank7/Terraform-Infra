variable "project_id" {
  description = "The GCP project ID"
  default = "daring-fin-414402"
}
 
variable "region" {
  description = "The GCP region to deploy resources"
  default = "us-east4"
}
 
variable "vpc_name" {
  description = "The name of the VPC to create"
  default    = "santoshi"
}
 
variable "webapp_subnet_cidr" {
  description = "CIDR for the webapp subnet"
  default     = "10.0.1.0/24"
}
 
variable "db_subnet_cidr" {
  description = "CIDR for the db subnet"
  default     = "10.0.2.0/24"
}