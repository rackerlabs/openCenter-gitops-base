terraform {
  backend "s3" {
    bucket       = "opencenter-dev"
    key          = "demo-cluster/tfstate/terraform.tfstate"
    region       = "us-west-2"
    use_lockfile = true
    encrypt      = true
  }
}
