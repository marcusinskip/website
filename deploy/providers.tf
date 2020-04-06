provider "aws" {
    region = var.region
    version = "~> 2.55"
}

provider "random" {
    version = "~> 2.2"
}

terraform {
  required_version = "~> 0.12.24"
}

