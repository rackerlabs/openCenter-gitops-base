resource "local_file" "ca-certificate" {
  filename        = "${path.root}/ca.crt"
  content         = var.services_ca_crt != "" ? var.services_ca_crt : tls_self_signed_cert.ca[0].cert_pem
  file_permission = "0644"
}

resource "local_file" "ca-certificate-key" {
  filename        = "${path.root}/ca.key"
  content         = var.services_ca_key != "" ? var.services_ca_key : tls_private_key.ca[0].private_key_pem
  file_permission = "0600"
}

resource "tls_private_key" "ca" {
  count     = var.services_ca_key != "" ? 0 : 1
  algorithm = "RSA"
}

resource "tls_self_signed_cert" "ca" {
  count = var.services_ca_crt != "" ? 0 : 1
  #key_algorithm     = "RSA"
  private_key_pem   = tls_private_key.ca[0].private_key_pem
  is_ca_certificate = true

  subject {
    organization = "Rackspace Kubernetes Managed Services CA"
  }

  validity_period_hours = 87600

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
    "client_auth",
    "cert_signing",
  ]
}
