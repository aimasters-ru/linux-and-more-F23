#
# oblako
#
variable "yc_token" {
  description = "yc token"
}


variable "yc_cloud_id" {
  description = "yc cloud_id"
}

variable "yc_folder_id" {
  description = "yc folder_id"
}

variable "yc_zone" {
  description = "yc zone"
}

#
# image
#
variable "yc_image_id" {
#  default = {
#    ru-central1-b = "fd8vmcue7aajpmeo39kk"
#  }
  default = "fd8vmcue7aajpmeo39kk"
}

#
# instance variables
#
variable "node1_prop" {
  type = map(string)
  description = "Instance properties for node1"
}

#
# Tags
#

variable "tag_project" {
  description = "Tag for this project (name of the project)"
}
