variable "region" {
  type    = string
  default = "us-east-1"
}

variable "images" {
  type = map(any)
  default = {
    "PROD" = "ami-06deb6bd572fb29e9"
    "DEV"  = "ami-0d3a94f66b42eaa0f"
  }
}

variable "my_profile" {
  type    = string
  default = "Add_Profile_Here"
}