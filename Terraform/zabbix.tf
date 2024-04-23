# Описание Zabbix VM

resource "yandex_compute_instance" "zabbix-server" {

  name                      = "zabbix-server"
  hostname                  = "zabbix-server"
  zone                      = "ru-central1-a"
  allow_stopping_for_update = true

  resources {
    core_fraction = 20
    cores         = 2
    memory        = 2
  }

  boot_disk {
    initialize_params {
      image_id = "fd8dlvgiatiqd8tt2qke"
      size     = 10
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.bastion-external-segment.id

    security_group_ids = [
                           yandex_vpc_security_group.internal-ssh-sg.id,
                           yandex_vpc_security_group.external-ssh-sg.id,
                           yandex_vpc_security_group.zabbix-server-sg.id,
                           yandex_vpc_security_group.egress-sg.id
                         ]

    nat        = true
    ip_address = "192.168.50.20"
  }

  metadata = {
    user-data = "${file("/home/kvv/diplom/terraform/meta.txt")}"
  }

  scheduling_policy {
    preemptible = true
  }

}

