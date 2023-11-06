variable "instance_type" {
  description = "Type of EC2 instance to provision"
  default     = "t3.nano"
}

variable "ami_filter" {
  description = "filter and owner for AMI"
  type = object({
    name  = string
    owner = string
  })

  default = {
    name  = "bitnami-tomcat-*-x86_64-hvm-ebs-nami"
    owner = "979382823631"
  }
}

data "aws_vpc" "default" {
  default = true
}

variable "environment" {
  description = "Devlopment environment"
  type = object({
    name = string
    network_prefix = string
  })
  default = {
    name = "dev"
    prefix = "10.0"
  }
}

variable "min_size" {
  description = "minimum number of instances in the asg"
  default = 1
}
variable "max_size" {
  description = "maximum number of instances in the asg"
  default = 2
}