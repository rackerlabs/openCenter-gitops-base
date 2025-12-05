
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/inventory.tpl",
    {
      address_bastion = var.address_bastion
      worker_nodes    = var.worker_nodes
      master_nodes    = var.master_nodes
      ssh_user        = var.ssh_user
  })
  filename = "infra-inventory"

  depends_on = [var.master_nodes, var.worker_nodes]
}