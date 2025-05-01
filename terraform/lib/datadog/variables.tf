variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "catalog_security_group_id" {
  description = "Security group ID for the catalog database"
  type        = string
  default     = ""
}

variable "orders_security_group_id" {
  description = "Security group ID for the orders database"
  type        = string
  default     = ""
}
