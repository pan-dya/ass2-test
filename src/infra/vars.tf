variable "path_to_ssh_public_key" {}
variable "my_ip_address" {}
variable "allow_all_ip_addresses_to_access_database_server" {}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}
#cidr block for 1st subnet
variable "subnet1_cidr" {
  default = "10.0.1.0/24"
}
#cidr block for 2nd subnet
variable "subnet2_cidr" {
  default = "10.0.2.0/24"
}
variable "subnet3_cidr" {
  default = "10.0.3.0/24"
}
