# variable "key_name" {
#   description = "The name of the SSH key pair"
#   type        = string
# }


variable "ami_id" {
  description = "The AMI ID to use for the instances"
  type        = string
}

variable "key_name" {
  description = "The name of the SSH key to use for the instances"
  type        = string
}
