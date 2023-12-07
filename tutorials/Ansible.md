# Ansible

## Подготовка

### virtual env

Сделаем питоновскую среду и установим туда Ansible.

```bash
$ virtualenv -p /usr/bin/python3 ansenv
Already using interpreter /usr/bin/python3
Using base prefix '/usr'
New python executable in /home/artem/work/ozon/ansenv/bin/python3
Also creating executable in /home/artem/work/ozon/ansenv/bin/python
Installing setuptools, pkg_resources, pip, wheel...done.

(base) artem@artem-ubuntu0:~/work/ozon$ source ansenv/bin/activate
```

### Ansible installation

```bash
(ansenv) $ pip install ansible
```

Убедитесть, что вы можете зайти на облачный сервер по ssh использую ключ.

### Project dir

Так как мы будем писать код на Ansible, то хорошо бы сохранить его в репозиторий. Зайдите в папку linux-git1, создайте подпапку ansible и зайдите в нее. Это будет папка проекта, куда поместим все файлы с конфигурацией и кодом.

### Configuration file

В папке проекта создайте ansible.cfg со следующим содержимым, заменяя путь к ключу, и remote_user, если на вашей системе, которую вы собрались конфигурировать, не ubuntu является суперюзером.

```
[defaults]
inventory = hosts
remote_user = ubuntu
private_key_file = /home/artem/.ssh/id_rsa.pem\

[privilege_escalation]
become = True
```

Опция become=True означает, что на конфигурируемой системе надо "стать" пользователем root. Механизм по умолчанию - sudo.

## Inventory file

Создайте файл под названием hosts и поместите туда следующее, заменяя на IP-адрес вашей облачной машины.

```
[test1]
130.193.42.94
```

Проверяем подключение

```bash
(ansenv) $ ansible all -m ping 
130.193.42.94 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
```

Отлично, все работает!

## Установка пакета

Сделаем простую задачу, которую часто приходится делать - установим что-то, например, git.

### Playbook

Создайте файл git.yml со следующим содержимым:

```yaml
- hosts: test1
  tasks: 
   - name: Update apt and install git
     apt: update_cache=yes name=git state=latest
```

### Запуск

```bash
(ansenv) $ ansible-playbook git.yml

PLAY [test1] *********************************************************************************************************

TASK [Gathering Facts] ***********************************************************************************************
ok: [130.193.41.170]

TASK [Update apt and install git] ************************************************************************************
changed: [130.193.41.170]

PLAY RECAP ***********************************************************************************************************
130.193.41.170             : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```

### Повторный запуск

Исходя их принципа идемпотентности, повторный запуск должен привести к такому же итоговому результату. Ансибл собрал факты и увидел, что пакет git уже установлен, так что повторно его ставить не надо.

```bash
$ ansible-playbook git.yml

PLAY [test1] *********************************************************************************************************

TASK [Gathering Facts] ***********************************************************************************************
ok: [130.193.41.170]

TASK [Update apt and install git] ************************************************************************************
ok: [130.193.41.170]

PLAY RECAP ***********************************************************************************************************
130.193.41.170             : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```

### Как это масштабировать на много хостов

Разные наборы пакетов и других задач на разные группы хостов.

В Ansible есть понятие _роли_ сервера. Это помогает упорядочить плейбуки. Для этого создана специальная структура директорий.

Разберем на примере установки docker.

## Установка Docker

### Ручная установка (делать не надо)
Впомним из слайдов занятия по основам системного администрирования, как мы добавляли репозиторий докера для установки докера

```bash
$ curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

$ sudo apt-key fingerprint 0EBFCD88
pub   rsa4096 2017-02-22 [SCEA]
      9DC8 5822 9FC7 DD38 854A  E2D8 8D81 803C 0EBF CD88
uid           [ unknown] Docker Release (CE deb) <docker@docker.com>
sub   rsa4096 2017-02-22 [S]

$ sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

$ tail -2 /etc/apt/sources.list
deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable
# deb-src [arch=amd64] https://download.docker.com/linux/ubuntu focal stable

$ sudo apt update
$ sudo apt install docker-ce
```

### Ansible playbook

Создайте несколько директорий рекурсивно:

`mkdir -p roles/docker/tasks`

откройте для редактирования файл `roles/docker/tasks/main.yml`

и сохраните в него следующие фрагменты-задачи.

#### Добавление ключей GPG

```yaml
- name: Add Docker GPG apt Key
  apt_key:
        url: https://download.docker.com/linux/ubuntu/gpg
        state: present

```

#### Добавление репозитория

```yaml
- name: Add Docker Repository
  apt_repository:
        repo: deb https://download.docker.com/linux/ubuntu bionic stable
        state: present
```

#### Установка пакета после обновления индекса репо

```yaml
- name: Update apt and install docker-ce
  apt: update_cache=yes name=docker-ce state=latest
```

#### Добавление суперюзера в группу docker

```yaml
- name: Add Ubuntu to docker group
  user:
    name: ubuntu
    groups: docker
    append: yes
```

### Плейбук для установки докера

Создайте файл docker.yml со следующим содержимым:

```yaml
- hosts: test1
  roles:
   - docker
```

### Запуск плейбука

```bash
(ansenv) $ ansible-playbook docker.yml

PLAY [test1] *********************************************************************************************************

TASK [Gathering Facts] ***********************************************************************************************
ok: [130.193.41.170]

TASK [docker : Add Docker GPG apt Key] *******************************************************************************
changed: [130.193.41.170]

TASK [docker : Add Docker Repository] ********************************************************************************
changed: [130.193.41.170]

TASK [Update apt and install docker-ce] ******************************************************************************
changed: [130.193.41.170]

TASK [Add Ubuntu to docker group] ************************************************************************************
changed: [130.193.41.170]

PLAY RECAP ***********************************************************************************************************
130.193.41.170             : ok=5    changed=4    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```

### Добавление пользователей

В этом примере познакомимся с "циклами", переменными, и как брать джанные из файлов.

#### Широкими мазками

Мы поместим список пользователей для нашего тестового сервера в переменную как массив. Далее будем декларировать действия с элементами этого массива:

* создать пользователей
* сделать им папки .ssh
* загрузить ключи с гитхаба

#### Плейбук для создания пользователей

Создайте файл users.yml. В нем добавочная директива - определение переменных ansible. У нас массив, а скаляр определяется проще: `myvar: 33`. Есть и словари.

```yaml
- hosts: test1
  vars:
    user_data:
      - datamove
      - pklemenkov
  roles:
    - users
```

Для простоты, я добавил двух пользователей. Замените кого-то из них на своего пользователя (ник на гитхабе).

#### Определение роли users

Создайте директорию roles/users/tasks и в ней файл main.yml

Первым делом, для отладки печатаем содержимое переменной user_data и убеждаемся, что файл с пользователями считался корректно

```yaml
# create users
- debug: msg="students are {{ user_data }}"
```

Создаем группу для пользователей

```yaml
- name: create group
  group:
    name: students
    state: present
```

Создаем аккаунты. Вот тут как раз используются циклы. Ключевое слово with_items, без него создается только один аккаунт. Переменная цикла - items. Способ интерполяции знаком нам - "{{ }}".

```yaml
- name: Add user accounts
  user:
    name: "{{ item }}"
    shell: /bin/bash
    home: "/home/users/{{ item }}"
    groups: [students]
    state: present
  with_items: "{{ user_data }}"
```

Каждый пользователь должен рассчитывать на приватность файлов, делаем аналог chmod 700, то есть разрешаем вход в директорию, чтение и запись только самому пользователю.

```yaml
- name: restrict student dir permissions
  file:
    path: "/home/users/{{ item }}"
    mode: 0700
  with_items: "{{ user_data }}"
```

Далее создаем для пользователей директорию .ssh и скачиваем с гитхаба его ключи.

```yaml
- name: Create .ssh dir
  file:
    path: "/home/users/{{ item }}/.ssh"
    owner: "{{ item }}"
    group: "{{ item }}"
    state: directory
    mode: 0700
  with_items: "{{ user_data }}"

- name: Add public ssh keys of users
  authorized_key:
    user: "{{ item }}"
    exclusive: yes
    key: https://github.com/{{ item }}.keys
    state: present
  with_items: "{{ user_data }}"
```

### Запуск

```bash
$ ansible-playbook users.yml 

PLAY [test1] *********************************************************************************************************

TASK [Gathering Facts] ***********************************************************************************************
ok: [130.193.41.170]

TASK [users : debug] *************************************************************************************************
ok: [130.193.41.170] => {
    "msg": "students are ['datamove', 'pklemenkov']"
}

TASK [users : create group] ******************************************************************************************
changed: [130.193.41.170]

TASK [users : Add user accounts] *************************************************************************************
changed: [130.193.41.170] => (item=datamove)
changed: [130.193.41.170] => (item=pklemenkov)

TASK [users : restrict student dir permissions] **********************************************************************
changed: [130.193.41.170] => (item=datamove)
changed: [130.193.41.170] => (item=pklemenkov)

TASK [users : Create .ssh dir] ***************************************************************************************
changed: [130.193.41.170] => (item=datamove)
changed: [130.193.41.170] => (item=pklemenkov)

TASK [Add public ssh keys of users] **********************************************************************************
changed: [130.193.41.170] => (item=datamove)
changed: [130.193.41.170] => (item=pklemenkov)

PLAY RECAP ***********************************************************************************************************
130.193.41.170             : ok=7    changed=5    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```

### Обсуждение

Вы видите, что вся суть работы с ansible - найти соответствующий вашей задаче модуль. А их в Ansible несколько сотен. Так же есть и маркетплейс с моджулями или плейбуками других, что иногда бывает удобно.

### Данные из файла

#### Файлы данных
Для переменных и файлов данных есть специальные папки, в которых Ansible ищет соответствующие объекты. Мы создаем папку files, в ней файл со списком пользователей. 

```bash
(ansenv) $ mkdir files
(ansenv) $ echo datamove > files/students.txt
(ansenv) $ echo pklemenkov >> files/students.txt
```

#### Переменные

То как мы определили пользхователей (прямо в плейбуке) не удобно - а вдруг они понадобятся в другом плейбуке? Добавлять и удалять тоже неудобно. Скорее всего у нас есть список пользователей. Так давайте и держать этот список в отдельном файле, чтоб все плейбуки могди им воспользоваться.

Определения переменных хранятся в файлах в директории host_vars (для хостов индивидуально) или group_vars для групп хостов (они определяются в inventory - это файл hosts у нас). Специальная группа хостов all включает в себя все определенные в inventory хосты. Мы уже ею пользовались в самом начале, когда делали ping. 

Сделаем папку для хранения файлов с переменными.

```bash
$ mkdir -p group_vars/all
```

Создайте файл group_vars/all/all.yml со следующим содержимым

```
user_data_file: students.txt
user_data: "{{ lookup('file', user_data_file).split('\n') }}"
```

В первую переменную помещаем название файла. Обратите внимание, что это не полный и не относительный путь, просто имя файла. Ansible будет искать его в стандартных папках, и найдёт в у нас в files. Во вторую переменную считываем файл и превращаем строки в массив (знакомый питоновский синтаксис, ведь и сам Ансибл написан на питоне).

#### плейбук

Плейбук users-datafile.yml предельно прост, так как всё, что можно, берётся из дефолтных значений.

```yaml
- hosts: test1
  roles:
    - users
```

Запустите сами и убедитесь, что ничего нового не сделано, но все `ok`.

## Отладка

`ansible-playbook -vv`, `-vvv`, `--list-tasks`

## Что осталось за кадром

Ansible - вселенная :)

* handlers - способ что-то сделать после завершения какой-то таски - например рестартовать
* templates - подстановка переменных в шаблоны, например для конфиг файлов
* редактирование файлов
* встроенные переменные самого ансибла
* как лучше организовать среды - для тестирования, для прода
* как делать свои модули
* ...


## Links

* ansible.cfg example https://raw.githubusercontent.com/ansible/ansible/devel/examples/ansible.cfg
* переменные https://docs.ansible.com/ansible/latest/user_guide/playbooks_variables.html
* Просто о переменых https://www.linuxtechi.com/use-variables-in-ansible-playbook/
* playbook best practice guide https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html

