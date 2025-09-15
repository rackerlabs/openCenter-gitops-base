resource "openstack_images_image_v2" "image" {
  name             = "${var.naming_prefix}ubuntu-18.04"
  image_source_url = "http://cloud-images.ubuntu.com/bionic/current/bionic-server-cloudimg-amd64.img"
  container_format = "bare"
  disk_format      = "qcow2"
}
