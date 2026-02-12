variable "location" { type = string }
variable "name" { type = string }
variable "image_repository" { type = string }  # ex: "app"
variable "image_tag" { type = string }         # ex: "dev" or sha

variable "tags" {
  type    = map(string)
  default = {}
}

