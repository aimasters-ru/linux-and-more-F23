provider "yandex" {
  token     = var.yc_token
  cloud_id  = var.yc_cloud_id
  folder_id = var.yc_folder_id
  zone      = var.yc_zone
}

resource "yandex_compute_instance" "node1" {
  name = var.node1_prop["name"]
  hostname = var.node1_prop["name"]

  resources {
    cores  = var.node1_prop["cores"]
    memory = var.node1_prop["memory"]
    core_fraction = var.node1_prop["core_fraction"]
  }

  boot_disk {
    initialize_params {
      image_id = var.yc_image_id
      size = var.node1_prop["size"]
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet1.id
    nat       = true
    nat_ip_address = yandex_vpc_address.address1.external_ipv4_address[0].address
  }

  metadata = {
    user-data = file("metadata.yml")
  }
}

resource "yandex_vpc_network" "net1" {
  name = "${var.tag_project}net1"
}

resource "yandex_vpc_subnet" "subnet1" {
  name           = "${var.tag_project}subnet1"
  zone           = var.yc_zone
  network_id     = yandex_vpc_network.net1.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

resource "yandex_vpc_address" "address1" {
  name = "${var.tag_project}address1"

  external_ipv4_address {
    zone_id = var.yc_zone
  }
}

output "external_ip_address_node1" {
  value = yandex_compute_instance.node1.network_interface.0.nat_ip_address
}

