provider "yandex" {
  token     = "AgAAAAA************************-kw"
  cloud_id  = "b1gp5a7fu7pkd41v2n4m"
  folder_id = "b1gqauaasnm6u2atg9lk"
  zone      = "ru-central1-b"
}

resource "yandex_compute_instance" "node1" {
  name = "test1"
  hostname = "test1"

  resources {
    cores  = 2
    memory = 1
    core_fraction = 5
  }

  boot_disk {
    initialize_params {
      image_id = "fd8vmcue7aajpmeo39kk"
      size="10"
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
  name = "testnet1"
}

resource "yandex_vpc_subnet" "subnet1" {
  name           = "testsubnet1"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.net1.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}


resource "yandex_vpc_address" "address1" {
  name = "testaddress1"

  external_ipv4_address {
     zone_id = "ru-central1-b"
  }
}



output "external_ip_address_node1" {
  value = yandex_compute_instance.node1.network_interface.0.nat_ip_address
}



