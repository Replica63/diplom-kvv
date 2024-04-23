terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
required_version = ">=0.13"
}

# Описание доступа и токена
provider "yandex" {
  service_account_key_file = "/home/kvv/authorized_key.json"
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone = "ru-central1-a"
}