terraform {
  backend "s3" {
    bucket       = "genelab"
    key          = "migu4903-dev-cluster/tfstate/terraform.tfstate"
    region       = "us-west-2"
    use_lockfile = true
    encrypt      = true
  }
}
