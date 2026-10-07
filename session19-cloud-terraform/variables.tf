variable "aws_region" {
  description = "Region to deploy into"
  type        = string
  default     = "ap-south-1"
}

variable "project" {
  description = "Name prefix for all resources"
  type        = string
  default     = "radhey-10242"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "Public subnet CIDR"
  type        = string
  default     = "10.0.1.0/24"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "ssh_cidr" {
  description = "CIDR allowed to SSH (restrict to your IP in production)"
  type        = string
  default     = "0.0.0.0/0"
}

variable "bucket_name" {
  description = "Globally unique S3 bucket name"
  type        = string
  default     = "radhey-10242-cloud-tf-app"
}
