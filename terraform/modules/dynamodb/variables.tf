variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "tables" {
  description = "List of DynamoDB table configurations"
  type = list(object({
    name           = string
    hash_key       = string
    range_key      = string
    billing_mode   = string
    read_capacity  = number
    write_capacity = number
    attributes = list(object({
      name = string
      type = string
    }))
  }))
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

