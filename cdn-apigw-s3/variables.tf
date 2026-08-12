variable "aws_region" {
  default = "us-east-1"
}

variable "bucket_prefix_pvt" {
  default = "gladdd-%s-%s-private"
}

variable "env" {
  default = "dev"
}

variable "cdn_name" {
  default = "cigna"
}

variable "access_control" {
  default = "private"
}
# bucket_prefix_pvt = "glad-%s-%s-private"
# env               = "Dev"
# cdn_name          = "cigna"
# access_control    = "private"
