# Yandex Cloud CLI

В этом тьюториале показывается, как работать с Yandex.Cloud с помощью CLI. Это позволяет осуществлять какую-нибудь автоматизацию
процессов и действий. Например, создание виртуальных машин или кластеров скриптами, их запуск и остановка по расписанию етс.

## Пререквизиты

Зарегистрируйтесь на Яндекс облаке (Яндекс дает кредит на пробный период), и залогиньтесь, зайдите в консоль управления по адресу https://console.cloud.yandex.ru

## Утилита управления облаком

Сначала скачиваем интсталлятор, запускаем его

```bash
$ wget https://storage.yandexcloud.net/yandexcloud-yc/install.sh
$ bash install.sh
```

Утилита будет установлена в вашей домашней директории: `~/yandex-cloud/bin/yc`.

На этапе установки, инсталлятор спросит вас, нужно ли добавить этот путь в переменную `PATH`. Если вы откажетесь, то надо будет запускать ее по полному пути:

```bash
$ ~/yandex-cloud/bin/yc
```

иначе просто `yc`.

## Инициализация

Запустите `yc init`. В процессе диалога вам будет предложено зайти на вебсайт и сгенерировать OAuth token. Скопируйте токен с веб-страницы и сохраните этот токен в безопасном месте на вашем лаптопе. Ведите токен по запросу команды.

Далее выберите соответствующую папку (folder) в вашем облаке. Скорее всего у вас будет только default, или другое название, если вы его сами назначали. Зона - это фактически выбор датацентра для ваших ресурсов. Разницы, по сути, нет, но старайтесь, чтоб все ресурсы, которые работают вместе, были в одной зоне - так минимизируются сетевые задержки.

```bash
artem@artem-ubuntu2:/media/data/yac$ ~/yandex-cloud/bin/yc init
Welcome! This command will take you through the configuration process.
Please go to https://oauth.yandex.ru/authorize?response_type=token&client_id=1a6990aa636648e9b2ef855fa7bec2fb in order to obtain OAuth token.

Please enter OAuth token: AgAAAAAZT*********************P_0Xbl-kw
You have one cloud available: 'cloud-dynasty-ka' (id = b1gp5a7fu7pkd41v2n4m). It is going to be used by default.
Please choose folder to use:
 [1] cloud1 (id = b1gah4jfv158374mb46p)
 [2] default (id = b1gqauaasnm6u2atg9lk)
 [3] Create a new folder
Please enter your numeric choice: 2
Your current folder has been set to 'default' (id = b1gqauaasnm6u2atg9lk).
Do you want to configure a default Compute zone? [Y/n] 
Which zone do you want to use as a profile default?
 [1] ru-central1-a
 [2] ru-central1-b
 [3] ru-central1-c
 [4] Don't set default zone
Please enter your numeric choice: 2
Your profile default Compute zone has been set to 'ru-central1-b'.
```

## Проверка конфигурации

```bash
artem@artem-ubuntu2:/media/data/yac$ ~/yandex-cloud/bin/yc config list
token: AgAAAA********************HP_0Xbl-kw
cloud-id: b1gp5a7fu7pkd41v2n4m
folder-id: b1gqauaasnm6u2atg9lk
compute-default-zone: ru-central1-b
```

## Работа с CLI

### Посмотреть инстансы в Compute Cloud

```bash
artem@artem-ubuntu2:/media/data/yac$ ~/yandex-cloud/bin/yc compute instance list
+----------------------+---------+---------------+---------+---------------+-------------+
|          ID          |  NAME   |    ZONE ID    | STATUS  |  EXTERNAL IP  | INTERNAL IP |
+----------------------+---------+---------------+---------+---------------+-------------+
| epda63mhc922jn9lqc40 | linux1  | ru-central1-b | RUNNING | 84.201.177.95 | 10.129.0.23 |
| epdkdc8iktbdjvb3m4gv | docker1 | ru-central1-b | STOPPED | 130.193.42.94 | 10.129.0.26 |
+----------------------+---------+---------------+---------+---------------+-------------+
```

Здесь вывод в виде таблицы - удобно смотреть, но не очень удобно обрабатывать в скрипте. Но можго отформатировать вывод с помощю опции: `yc --format json`, а также json-rest, yaml. Отличие json от json-rest в стиле именования полей:

```
<           "one_to_one_nat": {
---
>           "oneToOneNat": {
```

### Получить сведения об инстансе

```bash
artem@artem-ubuntu2:/media/data/yac$ ~/yandex-cloud/bin/yc compute instance get docker1
id: epdkdc8iktbdjvb3m4gv
folder_id: b1gqauaasnm6u2atg9lk
created_at: "2020-11-13T11:13:21Z"
name: docker1
description: for docker excercises
zone_id: ru-central1-b
platform_id: standard-v2
resources:
  memory: "8589934592"
  cores: "4"
  core_fraction: "20"
status: RUNNING
boot_disk:
  mode: READ_WRITE
  device_name: epd90u3u5cad14b9nb8u
  auto_delete: true
  disk_id: epd90u3u5cad14b9nb8u
network_interfaces:
- index: "0"
  mac_address: d0:0d:14:6b:11:2a
  subnet_id: e2l6b270d8b8206agvcg
  primary_v4_address:
    address: 10.129.0.26
    one_to_one_nat:
      address: 130.193.42.94
      ip_version: IPV4
fqdn: docker1.ru-central1.internal
scheduling_policy: {}
network_settings:
  type: STANDARD
placement_policy: {}
```

### Запустить/остановить инстанс

```bash
artem@artem-ubuntu2:/media/data/yac$ ~/yandex-cloud/bin/yc compute instance start docker1
done (14s)
id: epdkdc8iktbdjvb3m4gv
folder_id: b1gqauaasnm6u2atg9lk
created_at: "2020-11-13T11:13:21Z"
name: docker1
... - те же сведения
```

```
artem@artem-ubuntu2:/media/data/yac$ ~/yandex-cloud/bin/yc compute instance stop docker1
done (9s)
```

### Создать инстанс

Инстанс можно создать без постоянного публичного IP-адреса (по которому инстанс можно найти в интернете и залогиниться), тогда разные адреса будут назначаться автоматически при каждом старте.

Однако, можно и зарезервировать адрес на некоторое время для удобства. Давайте так и поступим.

#### Резервирование адреса

```bash
 ~/yandex-cloud/bin/yc vpc address create --external-ipv4 zone=ru-central1-b
id: e2lstikjiuo6arsp644t
folder_id: b1gqauaasnm6u2atg9lk
created_at: "2023-11-20T09:40:34Z"
external_ipv4_address:
  address: 84.201.179.91
  zone_id: ru-central1-b
  requirements: {}
reserved: true
type: EXTERNAL
ip_version: IPV4
```

Облако зарезервировало для меня адрес 84.201.179.91 и назначило ему идентификатор e2lstikjiuo6arsp644t.

Проверим:

```bash
artem@artem-ubuntu2:/media/data/yac$ ~/yandex-cloud/bin/yc vpc address list
+----------------------+--------------------+----------------+----------+-------+
|          ID          |        NAME        |    ADDRESS     | RESERVED | USED  |
+----------------------+--------------------+----------------+----------+-------+
| e2l9b8bncho5jv4s9lm7 | prodmgmt1          | 158.160.27.17  | true     | true  |
| e2lh9di1bvgrs49v1mhk | prodaddress_edge11 | 158.160.20.241 | true     | true  |
| e2lstikjiuo6arsp644t |                    | 84.201.179.91  | true     | false |
+----------------------+--------------------+----------------+----------+-------+
```

Этот адрес пока не используется (used=false).

#### Создание инстанса

##### Простой вариант

Мы указываем имя, путь к ключю, спеки инстанса и наш зарезервированный адрес. Пользователь по умолчанию будет `yc-user`, а система по умолчанию - Ubuntu 18.04.

```bash
$ ~/yandex-cloud/bin/yc compute instance create --name test1 --public-address 84.201.179.91 --ssh-key ~/.ssh/id_rsa.pub --memory 1 --cores 2 --core-fraction 5
done (16s)
id: epdfaj6qq2vgae1allup
folder_id: b1gqauaasnm6u2atg9lk
created_at: "2020-11-26T12:29:09Z"
name: test1
zone_id: ru-central1-b
platform_id: standard-v2
resources:
  memory: "1073741824"
  cores: "2"
  core_fraction: "5"
status: RUNNING
boot_disk:
  mode: READ_WRITE
  device_name: epdvmnenm3q1reb16umm
  auto_delete: true
  disk_id: epdvmnenm3q1reb16umm
network_interfaces:
- index: "0"
  mac_address: d0:0d:f5:4c:da:d0
  subnet_id: e2l6b270d8b8206agvcg
  primary_v4_address:
    address: 10.129.0.28
    one_to_one_nat:
      address: 84.201.179.91
      ip_version: IPV4
fqdn: epdfaj6qq2vgae1allup.auto.internal
scheduling_policy: {}
network_settings:
  type: STANDARD
placement_policy: {}
```

Возможные ошибки. Если у вас несколько подсетей в выбранной зоне по умолчанию (это не должно случиться для только что созданных аккаунтов, а только для тех, где вы сами создали новые подсети), то `yc` попросит указать, какуб сеть вы хотите использовать. Но тогда и опцию --public-address придется заменить например:

`-network-interface subnet-id=e2l6b270d8b8206agvcg,nat-address=84.201.179.91`

Зайдем на этот инстанс, используя приватный ключ

```bash
$ ssh -i ~/.ssh/id_rsa.pem -l yc-user 130.193.42.169
Welcome to Ubuntu 18.04.4 LTS (GNU/Linux 4.15.0-55-generic x86_64)
...
yc-user@epdfaj6qq2vgae1allup:~$ df -k
Filesystem     1K-blocks    Used Available Use% Mounted on
udev              481976       0    481976   0% /dev
tmpfs             100884    2888     97996   3% /run
/dev/vda2        3029884 1715200   1149568  60% /
tmpfs             504416       0    504416   0% /dev/shm
tmpfs               5120       0      5120   0% /run/lock
tmpfs             504416       0    504416   0% /sys/fs/cgroup
tmpfs             100880       0    100880   0% /run/user/1000
```

интересно, что имя хоста не дали по умолчанию, а диска дали 3 ГБ

Reference: https://cloud.yandex.com/en-ru/docs/cli/cli-ref/managed-services/compute/instance/create

##### типы дисков 

```bash
$ ~/yandex-cloud/bin/yc compute disk-type list
+---------------------------+--------------------------------+
|            ID             |          DESCRIPTION           |
+---------------------------+--------------------------------+
| network-hdd               | Network storage with HDD       |
|                           | backend                        |
| network-ssd               | Network storage with SSD       |
|                           | backend                        |
| network-ssd-io-m3         | Fast network storage with      |
|                           | three replicas                 |
| network-ssd-nonreplicated | Non-replicated network storage |
|                           | with SSD backend               |
+---------------------------+--------------------------------+
```

##### Образы ОС

Воспользуемся выводом в формате json и jq для фильтра, хотя могли бы и просто текст + grep.

```bash
$ yc compute image list --folder-id standard-images --format json-rest| jq '.[] | select(.family|(type=="string") and test("^ubuntu-22"))'
{
  "id": "fd81d2d9ifd50gmvc03g",
  "folderId": "standard-images",
  "createdAt": "2019-02-07T09:43:13Z",
  "name": "ubuntu-1804-1549468804",
  "description": "Ubuntu 18.04 distribution. Official website and documentation: https://www.ubuntu.com",
  "family": "ubuntu-1804",
  "storageSize": "2231369728",
  "minDiskSize": "2621440000",
  "productIds": [
    "f2esunkmqrdb5qhdmaqe"
  ],
  "status": "READY",
  "os": {
    "type": "LINUX"
  }
}
...
```

#### Запуск/останов

```bash
artem@artem-ubuntu2:/media/data/yac$ ~/yandex-cloud/bin/yc compute instance stop test1
done (6s)
```

```bahs
$ ~/yandex-cloud/bin/yc compute instance start test1
done (18s)
id: epdfaj6qq2vgae1allup
folder_id: b1gqauaasnm6u2atg9lk
...
```

#### Удаление инстанса

Удалим и создадим ВМ с более подходящими параметрами.

```bash
$ ~/yandex-cloud/bin/yc compute instance delete test1
done (6s)
```

#### Дальнейшая кастомизация

Если мы хотим не стандартного пользователя `yc-user`, а другого, то опции для этого нет, придется передавать это желание в виде файла на yaml, которым воспользуется конфигуратор инстанса после развертывания стандартного образа.

Содайте файл metadata.yml со следующим содержимым, заменяя ключ на ваш:

```yaml
#cloud-config
users:
  - name: ubuntu
    groups: sudo
    shell: /bin/bash
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    ssh-authorized-keys:
      - ssh-rsa AAAAB3Nza......Pu00jRN
```

Так как ключ уже в этом конфиге, то нам не понадобится  опция --ssh-key. Зато мы добавим опции для передачи метаданных:

`--metadata-from-file user-data=metadata.yml`

и создания загрузочного диска из желаемого нами образа

`--create-boot-disk image-folder-id=standard-images,image-family=ubuntu-2204-lts,size=10`

В дополнение, включим эмулятор последовательного порта, через который получим вывод консоли при инициализации инстанса. Это поможет с выяснением ошибок.

`--metadata serial-port-enable=1`

Всё вместе:

```bash
$ ~/yandex-cloud/bin/yc compute instance create --name test1 --public-address 84.201.179.91 --memory 1 --cores 2 --core-fraction 5 --create-boot-disk image-folder-id=standard-images,image-family=ubuntu-2004-lts,size=10 --metadata-from-file user-data=metadata.yml
done (24s)
id: epd9p7acdpt3sucbhnds
...
```

После создания инстанса заново, надо удалить хеши старых ключей (ssh-keygen -R) , иначе получите ошибку "Host verification jeys change".

Логинимся и проверяем:

```bash
$ ssh -i /media/data/yac/keys/cluster-4-16_50GB_id_rsa.pem -l ubuntu 84.201.179.91
Welcome to Ubuntu 20.04 LTS (GNU/Linux 5.4.0-26-generic x86_64)
...
ubuntu@epd5c97htgtvgtbbu1hl:~$ df -k
Filesystem     1K-blocks    Used Available Use% Mounted on
udev              474096       0    474096   0% /dev
tmpfs             100456    2028     98428   3% /run
/dev/vda2       10257408 1880644   7918140  20% /
```

Все нормально - зашли под ubuntu, система - 20.04, места - 10 ГБ, всё как просили

##### Troublshooting

Если вы не можете зайти на систему под аккаунтом ubuntu, то, вероятно, сделали ошибку с ключем. Попробуйте, пока машина запущена, посмотреть вывод:

```bash
$ yc compute instance get-serial-port-output test1 > output.txt
```

и посмотрите, что там в output.txt в самом конце.

## Советы

* берегите токен!
* для вебсайтов необязательно резервировать статический адрес, можно воспользоваться делегацией DNS в облаке яндекса, а так же их сервисом SSL сертификатов
* вовремя останавливайте и удаляейте ненужные инстансы и другие ресурся (статические адреса и пр)

## Ссылки

* Пробный период https://cloud.yandex.ru/docs/free-trial/concepts/quickstart
* Быстрый старт https://cloud.yandex.ru/docs/cli/quickstart
* Справка по CLI https://cloud.yandex.com/en-ru/docs/cli/cli-ref/
* Квоты и лимиты https://cloud.yandex.ru/docs/overview/concepts/quotas-limits
* metadata https://cloud.yandex.ru/docs/compute/concepts/vm-metadata



