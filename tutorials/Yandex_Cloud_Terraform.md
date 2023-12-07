# Terraform with Yandex Cloud

развернем такой же виртуальный сервер, как и в примере с CLI.

## Установка terraform

```bash
$ wget https://hashicorp-releases.yandexcloud.net/terraform/1.6.4/terraform_1.6.4_linux_amd64.zip

$ unzip terraform_1.6.4_linux_amd64.zip
$ ./terraform -v
Terraform v1.6.4
on linux_amd64
```

## alias

Чтобы вызывать терраформ по имени как обычную команду, можно добавить путь к его директории в переменную PATH:

`$ export PATH=~/work/ozon:$PATH`

или можно просто сделать alias: `$ alias terraform=~/work/ozon/terraform` и добавить эту строчку в конец вашего файла конфигурации оболочки ~/.bashrc


## Конфигурация для работы с Облаком Яндекса

Создайте или откройте файл ~/.terraformrc

В нем должно быть следующее:

```
provider_installation {
  network_mirror {
    url = "https://terraform-mirror.yandexcloud.net/"
    include = ["registry.terraform.io/*/*"]
  }
  direct {
    exclude = ["registry.terraform.io/*/*"]
  }
}
```

## Программа на terraform

В папке вашего репозитория создайте подпапку tftest и зайдите туда. После практики не забудьте добавить, закомитить и запушить код.

### Инициализация провайдера

Создайте файл *versions.tf* со следующим содержимым:

```
terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}
```
и запустите

```bash
$ terraform init

Initializing the backend...

Initializing provider plugins...
- Finding latest version of yandex-cloud/yandex...
- Installing yandex-cloud/yandex v0.47.0...
- Installed yandex-cloud/yandex v0.47.0 (self-signed, key ID E40F590B50BB8E40)

Partner and community providers are signed by their developers.
If you'd like to know more about provider signing, you can read about it here:
https://www.terraform.io/docs/plugins/signing.html

The following providers do not have any version constraints in configuration,
so the latest version was installed.

To prevent automatic upgrades to new major versions that may contain breaking
changes, we recommend adding version constraints in a required_providers block
in your configuration, with the constraint strings suggested below.

* yandex-cloud/yandex: version = "~> 0.47.0"

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```

Это процедура устанавливает плагин провайдера (yandex-cloud) в директорию .terraform. Если вы планируете закомитить ваш код в гит, то бинарник плагина точно там не нужен. Так что добавьте .terraform в .gitignore вашего репо.

### Определение провайдера

Создайте файл *tftest1.tf* и поместите туда следующий код, заменяя id на ваши (те же что и для CLI).

```
provider "yandex" {
  token     = "AgAAAA....-kw"
  cloud_id  = "b1gp5a7fu7pkd41v2n4m"
  folder_id = "b1gqauaasnm6u2atg9lk"
  zone      = "ru-central1-b"
}
```

### Instance

#### Декларация ресурса

Декларируем ресурс типа "yandex_compute_instance" под названием "vm1". Под этим названием мы можем потом ссылаться на этот ресурс в другиз частях программы на терраформ.

```
resource "yandex_compute_instance" "node1" {
  name = "test1"
  hostname = "test1"

  resources {
    cores  = 2
    memory = 1
    core_fraction = 5
  }
```

Это было просто, скопировали значения из командной строки.

Однако дальше наступают сложности. 

#### Загрузочный диск

Терраформу нужен id образа, а не название, под которым он известен в Яндекс-облаке ("ubuntu-2204-lts"). Идентификатор тоже у нас есть, это поле "id" в структуре json, колтороке мы получили командой `yc images list` и отфильтровали jq.

```
  boot_disk {
    initialize_params {
      image_id = "fd80bm0rh4rkepi5ksdi"
      size=10
    }
  }
```
#### Сетевой интерфейс

Тоже не всё так просто. Тут дело в том, что CLI умеет работать с дефолтными значениями, а Terraform - нет. Он хочет от пользователя максимальной определенности в том, что тот желает. Поэтому к любому ресурсу, который можно создать, необходимо обращаться по его id в облаке.

На этот раз, вместо того, чтобы искать id имеющихся сетей и подсетей, мы создадим их заново. В этом есть смысл - мы не знаем, для чего могут использоваться уже ранее созданные ресурсы, и как они сконфигурированы, поэтому делаем полность инкапсулированное решение.

Так как сеть - это ресурс, он определяется вне рамок (скобок) другого ресурса. Это мы сделаем позже, а пока просто сошлемся на его идентификатор.

```
  network_interface {
    subnet_id = yandex_vpc_subnet.subnet1.id
    nat       = true
  }
```

#### metadata

Далее даем знать, что у нас есть файл с cloud-config, содержимое которого  мы передаем с метадатой как поле "user-data".

```
  metadata = {
    user-data = file("metadata.yml")
  }
}
```

На этом декларация инстанса закончена.

### Сеть и подсеть

Пришло время создать сеть и подсеть.

```
resource "yandex_vpc_network" "net1" {
  name = "testnet1"
}

resource "yandex_vpc_subnet" "subnet1" {
  name           = "testsubnet1"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.net1.id
  v4_cidr_blocks = ["192.168.1.0/24"]
}
```

Обратите внимание, что мы сначала сослались на подсеть в инстансе, а потом ее определили. Вспомним, что у нас декларативное описание, а terraform сам выбирает последовательность действий по созданию инфраструктуры. Поэтому порядок определения ресурсов не важен.

Для тех кто потерялся в индентации, посмотрите datamove/practice-repo/tftest1/tftest1.tf

### Планирование

Это аналог dry run - терраформ показывает, что он будет делать. Это важный шаг - надо убедиться, что не будут уничтожены какие-то важные ресурсы, просто потому, что ваши изменения предусматривают пересоздание ресурса.


```bash
$ ~/terraform plan

Terraform used the selected providers to generate the following execution plan. Resource actions are
indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # yandex_compute_instance.node1 will be created
  + resource "yandex_compute_instance" "node1" {
      + created_at                = (known after apply)
      + folder_id                 = (known after apply)
      + fqdn                      = (known after apply)
      + gpu_cluster_id            = (known after apply)
      + hostname                  = "test1"
      + id                        = (known after apply)
      + metadata                  = {
          + "user-data" = <<-EOT
                #cloud-config
                users:
                  - name: ubuntu
                    groups: sudo
                    shell: /bin/bash
                    sudo: ['ALL=(ALL) NOPASSWD:ALL']
                    ssh-authorized-keys:
                      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDllwCV3nZiTclRiNO0CUQ5JU4Yrm6VLVFJSlsYAXBjts2RHCaAuJ5fvXv/6h/XJT07n9sBrid4uBl+z1pCrhZ2ql6tH/NUskNDVYZfl//rep0TfSF90sXbVgVUgCrgMwABrgs5NOy2ltcoOvF/Znlyg5d69xaZiHSVcNVp6gCkd4egC2MbJZgqDJEBt9iX8nw/sjcjFq7RuokBscZVMWmC7oMsBGEq4IT8WUnFA4jLep0Myf6hso0CGI2SE/DLM0iguBzfZIKJTEiobea1pvVC3VbBt/ONNaq7uuemd7Wm5ZJ9WRhAHBSc/nVANxyVwMZE5QdUeRQJHysgcarTrxM9
                #      - ssh-rsa AAAAB3Nza......Pu00jRN user@desktop
            EOT
        }
      + name                      = "test1"
      + network_acceleration_type = "standard"
      + platform_id               = "standard-v1"
      + service_account_id        = (known after apply)
      + status                    = (known after apply)
      + zone                      = (known after apply)

      + boot_disk {
          + auto_delete = true
          + device_name = (known after apply)
          + disk_id     = (known after apply)
          + mode        = (known after apply)

          + initialize_params {
              + block_size  = (known after apply)
              + description = (known after apply)
              + image_id    = "fd8vmcue7aajpmeo39kk"
              + name        = (known after apply)
              + size        = 10
              + snapshot_id = (known after apply)
              + type        = "network-hdd"
            }
        }

      + network_interface {
          + index              = (known after apply)
          + ip_address         = (known after apply)
          + ipv4               = true
          + ipv6               = (known after apply)
          + ipv6_address       = (known after apply)
          + mac_address        = (known after apply)
          + nat                = true
          + nat_ip_address     = (known after apply)
          + nat_ip_version     = (known after apply)
          + security_group_ids = (known after apply)
          + subnet_id          = (known after apply)
        }

      + resources {
          + core_fraction = 5
          + cores         = 2
          + memory        = 1
        }
    }

  # yandex_vpc_network.net1 will be created
  + resource "yandex_vpc_network" "net1" {
      + created_at                = (known after apply)
      + default_security_group_id = (known after apply)
      + folder_id                 = (known after apply)
      + id                        = (known after apply)
      + labels                    = (known after apply)
      + name                      = "testnet1"
      + subnet_ids                = (known after apply)
    }

  # yandex_vpc_subnet.subnet1 will be created
  + resource "yandex_vpc_subnet" "subnet1" {
      + created_at     = (known after apply)
      + folder_id      = (known after apply)
      + id             = (known after apply)
      + labels         = (known after apply)
      + name           = "testsubnet1"
      + network_id     = (known after apply)
      + v4_cidr_blocks = [
          + "192.168.10.0/24",
        ]
      + v6_cidr_blocks = (known after apply)
      + zone           = "ru-central1-b"
    }

Plan: 3 to add, 0 to change, 0 to destroy.

──────────────────────────────────────────────────────────────────────────────────────────────────────── 

Note: You didn't use the -out option to save this plan, so Terraform can't guarantee to take exactly
these actions if you run "terraform apply" now.
```

### Запуск

Наконец, команда apply. Выводит сначала план (опускаю его ниже), потом лог действий.

```bash
$ ~/terraform apply



```

Мы видим последовательность действий и id созданных ресурсов. Единственное, чего мы не видим - это внешний динамический IP-адрес инстанса.

Терраформ его знает - он знает всё об инстансах, которыми управляет.

Добавьте следующий фрагмент кода:

```
output "external_ip_address_node1" {
  value = yandex_compute_instance.node1.network_interface.0.nat_ip_address
}
```

и запустите apply снова. Вспоминаем принцип идемпотентности - от повторного запуска ничего не должно измениться, но нам покажут ip-address.

```bash
$ ~/terraform apply
yandex_vpc_network.testnet1: Refreshing state... [id=enp5421len7v59h518i9]
yandex_vpc_subnet.testsubnet1: Refreshing state... [id=e2ltjrel5650liagss2i]
yandex_compute_instance.test1: Refreshing state... [id=epdpbamndo3dqvm6q107]

An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:

Terraform will perform the following actions:

Plan: 0 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + external_ip_address_node1 = "84.201.162.237"

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes


Apply complete! Resources: 0 added, 0 changed, 0 destroyed.

Outputs:

external_ip_address_node1 = 84.201.162.237
```

Можно было и не печатать yes, все равно адрес уже показали :)

### Проверка

Терраформ запускает наш инстанс, мы можем залогиниться и проверить, что все работает (подставьте ваш адрес):

```bash
$ ssh -i /media/data/nplde/mcskey/cluster-4-16_50GB_id_rsa.pem ubuntu@84.201.162.237
```

### Где Terraform хранит состояние?

В результате apply должны появиться файлы terraform.tfstate, terraform.tfstate.backup. Посмотрите их - там описание созданной инфраструктуры в формате json. Эти файлы можно комитить в гит, в качестве бэкапа. К слову сказать, сам терраформ также предлагает сохранять state на его серверах. Это неплохая опция - обеспечивает сохранность, а так же блокирующий доступ - только для одно клиента в каждый конкретный момент времени.

### Уничтожаем ресурсы

```bash
$ ~/terraform destroy
yandex_vpc_network.net1: Refreshing state... [id=enpt93h4nc4stue3a4bv]
yandex_vpc_address.address1: Refreshing state... [id=e2l6v1ccvuptprctiq97]
yandex_vpc_subnet.subnet1: Refreshing state... [id=e2lr2ad7gjrlbpv4tvbd]
yandex_compute_instance.node1: Refreshing state... [id=epdr4aa8q0nojlgpbs4n]

Terraform used the selected providers to generate the following execution plan. Resource actions are
indicated with the following symbols:
  - destroy

Terraform will perform the following actions:

  # yandex_compute_instance.test1 will be destroyed
  - resource "yandex_compute_instance" "test1" {
...
Plan: 0 to add, 0 to change, 3 to destroy.

Changes to Outputs:
  - external_ip_address_node1 = "158.160.76.67" -> null

Do you really want to destroy all resources?
  Terraform will destroy all your managed infrastructure, as shown above.
  There is no undo. Only 'yes' will be accepted to confirm.

  Enter a value: yes

yandex_compute_instance.node1: Destroying... [id=epdr4aa8q0nojlgpbs4n]
yandex_compute_instance.node1: Still destroying... [id=epdr4aa8q0nojlgpbs4n, 10s elapsed]
yandex_compute_instance.node1: Still destroying... [id=epdr4aa8q0nojlgpbs4n, 20s elapsed]
yandex_compute_instance.node1: Still destroying... [id=epdr4aa8q0nojlgpbs4n, 30s elapsed]
yandex_compute_instance.node1: Still destroying... [id=epdr4aa8q0nojlgpbs4n, 40s elapsed]
yandex_compute_instance.node1: Still destroying... [id=epdr4aa8q0nojlgpbs4n, 50s elapsed]
yandex_compute_instance.node1: Destruction complete after 54s
yandex_vpc_subnet.subnet1: Destroying... [id=e2lr2ad7gjrlbpv4tvbd]
yandex_vpc_address.address1: Destroying... [id=e2l6v1ccvuptprctiq97]
yandex_vpc_address.address1: Destruction complete after 2s
yandex_vpc_subnet.subnet1: Destruction complete after 2s
yandex_vpc_network.net1: Destroying... [id=enpt93h4nc4stue3a4bv]
yandex_vpc_network.net1: Destruction complete after 2s

Destroy complete! Resources: 4 destroyed.   
```

## Импорт ресурсов

У вас уже есть внешний статический адрес, который вы зерезервировали с помощью CLI.

Давайте воспользуемся им в программе Terraform. Тут есть одна загвоздка. Мы не можем просто подставить этот адрес куда-то в программу Terraform, так как Terraform может использовать только ресурсы, созданные им самим. Но мы можем импортировать уже имеющийся в облаке ресурс в Terraform. Этот функционал существуют как раз для организаций, которые переходят от ad hoc использования облака к автоматизации.

### Идентификатор ресурса в облаке

Вспомним, как посмотреть ресурсы с помощью CLI Яндекс-облака

```bash
$ ~/yandex-cloud/bin/yc vpc address list
+----------------------+------+---------------+----------+-------+
|          ID          | NAME |    ADDRESS    | RESERVED | USED  |
+----------------------+------+---------------+----------+-------+
| e2l15ar34p52e66sn4pn |      | 84.201.177.95 | true     | true  |
| e2l7bvubdftej4hck4a8 |      | 130.193.34.19 | true     | false |
| e2laadogl013neok30t9 |      | 130.193.42.94 | true     | true  |
+----------------------+------+---------------+----------+-------+
```

Второй адрес как раз тот, что создавали ранее.

### Декларация ресурса

Для того, чтобы импортировать ресурс, его надо декларировать как обычно.

```
resource "yandex_vpc_address" "address1" {
  name = "testaddress1"
  external_ipv4_address {
      zone_id = "ru-central1-b"
  }
}
```

### Импорт ресурса

```bash
$ ~/terraform import yandex_vpc_address.address1 e2l7bvubdftej4hck4a8
yandex_vpc_address.address1: Importing from ID "e2l7bvubdftej4hck4a8"...
yandex_vpc_address.address1: Import prepared!
  Prepared yandex_vpc_address for import
yandex_vpc_address.address1: Refreshing state... [id=e2l7bvubdftej4hck4a8]

Import successful!

The resources that were imported are shown above. These resources are now in
your Terraform state and will henceforth be managed by Terraform.


```

### Создание ресурса со статическим адресом

Теперь добавляем в блок network_interface ресурса yandex_compute_instance ссылку на ресурс статического адреса (добавьте только строчку с nat_ip_address в тело блока):

```
  network_interface {
    subnet_id = yandex_vpc_subnet.subnet1.id
    nat       = true
    nat_ip_address = yandex_vpc_address.address1.external_ipv4_address[0].address
  }
```

Далее по накатанной - terrafrom plan, terraform apply.

### Заметки об использовании статического адреса

Обратите внимание на какой-то странный синтаксис с определением статического адреса. У них тут что-то не продумано? По идее, должна быть ссылка на id ресурса статического адреса. Впрочем, как раз такая особенность может сыграть на руку - мы можем и не импортировать статический IP-адрес, а просто указать его как строку nat_ip_address = "X.X.X.X" в блоке network_interface ресурса yandex_compute_instance. Почему это может быть полезно? Когда мы импортируем IP-address в Terraform, а потом уничтожаем все ресурсы командой destroy, то уничтожается и этот статический IP-адрес, то есть он освобождается из нашего резерва. А это может быть неудобно. 

Итак, вот синтаксис для других случаев (протестируйте их сами!):

### Указать статический адрес без импорта

ресурс "yandex_vpc_address" не нужен, указываем адрес строкой в блоке network_interface ресурса yandex_compute_instance.

```
  network_interface {
    subnet_id = yandex_vpc_subnet.testsubnet1.id
    nat       = true
    nat_ip_address = "X.X.X.X"
  }
```

### Cтатический адрес надо создать в программе, а не импортировать

Такой же систаксис, как и для импорта, просто не надо делать import. (см. папку tutorial/tftest1)


### Уничтожаем ресурсы

```bash
$ ~/terraform destroy
```

Убедитесть командой `~/yandex-cloud/bin/yc vpc address list` что импортированный адрес больше не зарезервирован за вами.

## Переменные и программирование для повторного использования кода

В этот раз попробуем избавиться от всех или большинства строковых значений, заменив их на переменные. 

Это нужно для:

* облегчения повторного использования кода
* создания тестовой среды по шаблону для прода

Создайте еще одну папку tftest2. В неё скопируйте versions.tf и инициализируте проект terraform

### Декларация переменных

Создайте файл variables.tf c декларациями переменных.

В этой части те значения, которые использовали в блоке провайдера.
```
#
# oblako
#
variable "yc_token" {
  description = "yc token"
}

variable "yc_cloud_id" {
  description = "yc cloud_id"
}

variable "yc_folder_id" {
  description = "yc folder_id"
}

variable "yc_zone" {
  description = "yc zone"
}
```

Далее, переменная для id образа. Запишем её со значением по умолчанию, для иллюстрации этой возможности. 

```
#
# image
#
variable "yc_image_id" {
  default = "fd8vmcue7aajpmeo39kk"
}
```

Далее переменная со свойствами инстанса, она будет типа словарь (dict or hash or map)

```
#
# instance variables
#
variable "node1_prop" {
  type = map(string)
  description = "Instance properties for node1"
}
```

Простая переменная, с непростым использованием - покажем, как интерполировать переменные в коде терраформ. Кстати, теги или метки часто используются для облегчения поиска по инфраструктуре.

```
#
# Tags
#
variable "tag_project" {
  description = "Tag for this project (name of the project)"
}
```

### Значения переменных в файле.

Создайте файл test.tfvars со значениями переменных. Заметьте, что тут нет значений переменных yc_token и yc_image_id. Первый мы не больше хотим хардкодить в программе, так как хранить такие чувствительные данные в гите нельзя. Для второй у нас есть дефолтное значение.

```
yc_cloud_id = "b1gp5a7fu7pkd41v2n4m"

yc_folder_id = "b1gqauaasnm6u2atg9lk"

yc_zone = "ru-central1-b"

node1_prop = {
  name = "test1"
  cores = 2
  memory = 1
  core_fraction = 5
  size = 20
}

tag_project = "test"
```

### Изменения в программе

Теперь наша программа tftest2.tf будет выглядеть с переменными вот так. Обратите внимание на использование переменных var.node1_prop[], а так же знака доллара внутри строк для интерполяции переменных `name = "${var.tag_project}net1"`. Похоже на bash, не правда ли?

```
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
```

### Запуск

Начинаем с `~/terraform init` .

Далее запускаем план и используем опцию -vaf-file c файлом значений переменных. Так как токен не мы не пишем даже в этот файл, то его предложат ввести вручную. 

```bash
$ terraform plan -var-file test.tfvars 
var.yc_token
  yc token

  Enter a value: AgAAAA....l-kw


An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # yandex_compute_instance.node1 will be created
...
```

Далее вместо плана запускаем apply и должны придти к другому результату. Проверьте логин.

Теперь вы можете создать другой файл со значениями переменных вместо test.tfvars, например с другими характеристиками ВМ или другим образом, при этом ваша программа не меняется.

Не забудьте уничтожить инстансы после занятия (один инстанс может пригодиться для занятия по Ansible).

## Что осталось за кадром

* использование metadata.yml
* Модули - ещё большее абстрагирование кода
* Секреты - как проще управляять токенами, паролями и проч (никогда не комитьте их в гит!)
* data - позволяет находить что-то у провайдера и использовать это в программе. Например, можно найти id образа ОС по характеристикам.
* taint - позволяет выборочно пометить ресурс для пересоздания.

## Сcылки

* Документация по ресурсам https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/compute_instance
