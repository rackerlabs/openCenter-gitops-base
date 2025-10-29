variable "additional_block_devices" {
  description = "List of additional block devices to attach to instances"
  type = list(object({
    source_type           = string # "blank", "image", "volume", "snapshot"
    volume_size           = number
    volume_type           = optional(string, "")
    boot_index            = number # Must be > 0 for non-boot devices
    destination_type      = optional(string, "volume")
    delete_on_termination = optional(bool, true)
    mountpoint            = string
    filesystem            = optional(string, "ext4")
    label                 = string
  }))
  default = []
}

variable "allowed_addresses" {
  type    = list(string)
  default = []
}

variable "availability_zone" {
  type    = string
  default = "nova"
}

variable "flavor_name" {
  type = string
}

variable "image_id" {
  type = string
}

variable "image_name" {
  type = string
}

variable "naming_prefix" {
  type = string
}

variable "network_id" {
  type = string
}

variable "node_count" {
  type = number
}

variable "node_type" {
  type = string
}

variable "node_bfv_source_type" {
  type        = string
  description = "he source type of the device. Must be one of blank, image, volume, or snapshot. Changing this creates a new server."
}

variable "node_bfv_destination_type" {
  type        = string
  description = "The destination type of the device. Must be one of volume or local."
}

variable "node_bfv_delete_on_termination" {
  type        = bool
  default     = true
  description = "If true, the volume will be deleted when the server is terminated."
}

variable "node_bfv_volume_size" {
  type        = number
  description = "volume size for boot from volume nodes"
}

variable "node_bfv_volume_type" {
  type        = string
  description = "boot from volume type for nodes"
}

variable "security_group_ids" {
  type    = list(string)
  default = []
}

variable "servergroup_id" {
  type    = string
  default = ""
}

variable "subnet_id" {
  type = string
}

variable "user_data" {
  type    = string
  default = ""
}

variable "pf9_onboard" {
  type = bool
}

variable "bastion_floating_ip" {
  type    = string
  default = ""
}

variable "ssh_user" {
  type = string
}

variable "bastion_ssh_port" {
  type    = number
  default = 22
}

variable "ssh_private_key_path" {
  type    = string
  default = "./id_rsa"
}

variable "key_pair" {
  type = object({
    id          = string
    name        = string
    private_key = string
    public_key  = string
  })
}
