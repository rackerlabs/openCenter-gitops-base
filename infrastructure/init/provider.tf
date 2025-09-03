terraform {
  backend "s3" {
    bucket       = "opencenter-dev"
    key          = "opencenter-dev/tfstate/terraform.tfstate"
    region       = "us-west-2"
    use_lockfile = true
    encrypt      = true
  }
}
