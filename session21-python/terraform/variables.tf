variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

variable "bucket_name" {
  type    = string
  default = "radhey-10242-taskboard-assets"
}

variable "vpc_id" {
  description = "VPC to place the security group in"
  type        = string
}
