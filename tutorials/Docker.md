# Docker. 

## Начало работы - hello-world

### Docker pull

```bash
$ docker pull hello-world
Using default tag: latest
latest: Pulling from library/hello-world
0e03bdcc26d7: Pull complete 
Digest: sha256:8c5aeeb6a5f3ba4883347d3747a7249f491766ca1caa47e5da5dfcf6b9b717c0
Status: Downloaded newer image for hello-world:latest
docker.io/library/hello-world:latest
```

### Версии образов

Скачали версию latest. А какие еще версии доступны?

https://hub.docker.com/_/hello-world?tab=tags

### Повторное скачивание

```bash
$ docker pull hello-world
Using default tag: latest
latest: Pulling from library/hello-world
Digest: sha256:8c5aeeb6a5f3ba4883347d3747a7249f491766ca1caa47e5da5dfcf6b9b717c0
Status: Image is up to date for hello-world:latest
docker.io/library/hello-world:latest
```

### информация об образе

```bash
$ docker images hello-world
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
hello-world         latest              bf756fb1ae65        10 months ago       13.3kB
```

У образа есть имя, тег, идентификатор

### Запуск

### Создание и запуск контейнера

Контейнер = копия(*) образа + настройки 

(*) на самом деле не копия, но мы еще дойдем до этого

```bash
$ docker run hello-world

Hello from Docker!
This message shows that your installation appears to be working correctly.

To generate this message, Docker took the following steps:
 1. The Docker client contacted the Docker daemon.
 2. The Docker daemon pulled the "hello-world" image from the Docker Hub.
    (amd64)
 3. The Docker daemon created a new container from that image which runs the
    executable that produces the output you are currently reading.
 4. The Docker daemon streamed that output to the Docker client, which sent it
    to your terminal.

To try something more ambitious, you can run an Ubuntu container with:
 $ docker run -it ubuntu bash

Share images, automate workflows, and more with a free Docker ID:
 https://hub.docker.com/

For more examples and ideas, visit:
 https://docs.docker.com/get-started/
```

Нужно добавить:

_5. Контейнер остановился._

### Посмотрим, что за контейнер

```bash
$ docker ps -a
CONTAINER ID   IMAGE         COMMAND   CREATED        STATUS                     PORTS    NAMES
54f121ce52e2   hello-world   "/hello"  4 minutes ago  Exited (0) 4 minutes ago            dazzling_hoover
```

У контейнера идентификатор и имя (по умолчанию генерируется что-то)

### повторная команда run

```bash
$ docker run hello-world

Hello from Docker!
...
```

приводит к такому же выводу, но...

```bash
$ docker ps -a
CONTAINER ID   IMAGE         COMMAND   CREATED        STATUS                     PORTS    NAMES
f76547627448   hello-world   "/hello"  About a minut  Exited (0) About a minute ago       hopeful_chaplygin
54f121ce52e2   hello-world   "/hello"  4 minutes ago  Exited (0) 4 minutes ago            dazzling_hoover
```

...приводит к созданию нового контейнера

### Запуск существующего контейнера

```bash
$ docker start dazzling_hoover
dazzling_hoover
```

А где же вывод? Дело в том, что команда start по умолчанию запускает процесс фоном, и не показывает вывод. Однако вывод сохраняется докером и его можно посмотреть:

```bash
$ docker logs dazzling_hoover

Hello from Docker!
...
```

Вы увидите этот вывод несколько раз - по числу запуска контейнера.

Но можно запустить контейнер с присоединением стандартного вывода к терминалу:

```bash
$ docker start -a dazzling_hoover

Hello from Docker!
...
```

Чтобы автоматически удалять остановившиеся контейнеры каждый раз при запуске команды `run`, используйте опцию `--rm`. 
Чтобы не выводить лог контейнера на экран - опция `run -d`.

Дать контейнеру своё имя - `run --name "hello_$USER"`

Попробуйте сами!

## Работа с долгоиграющим контейнером

### Запуск
Будем запускать сервер [nginx](https://hub.docker.com/_/nginx).

```bash
$ docker run --name "web_$USER" --rm nginx
Unable to find image 'nginx:latest' locally
latest: Pulling from library/nginx
bb79b6b2107f: Pull complete 
5a9f1c0027a7: Pull complete 
b5c20b2b484f: Pull complete 
166a2418f7e8: Pull complete 
1966ea362d23: Pull complete 
Digest: sha256:aeade65e99e5d5e7ce162833636f692354c227ff438556e5f3ed0335b7cc2f1b
Status: Downloaded newer image for nginx:latest
/docker-entrypoint.sh: /docker-entrypoint.d/ is not empty, will attempt to perform configuration
/docker-entrypoint.sh: Looking for shell scripts in /docker-entrypoint.d/
/docker-entrypoint.sh: Launching /docker-entrypoint.d/10-listen-on-ipv6-by-default.sh
10-listen-on-ipv6-by-default.sh: Getting the checksum of /etc/nginx/conf.d/default.conf
10-listen-on-ipv6-by-default.sh: Enabled listen on IPv6 in /etc/nginx/conf.d/default.conf
/docker-entrypoint.sh: Launching /docker-entrypoint.d/20-envsubst-on-templates.sh
/docker-entrypoint.sh: Configuration complete; ready for start up
```

Так, и что? А ничего. Дело в том, что мы запустили сервер внутри контейнера,
 и именно там он и принимает входящие запросы на порт 80. Снаружи он не видим - докер же изолирует процессы!

### Интерактивная сессия в контейнер

Давайте для начала заглянем внутрь контейнера, убедимся, что так оно и есть.

Запускаем с опциями "фоном" и "удалить после остановки", а так же убеждаемся, что все ок (в логе).

```bash
$ docker run -d --rm --name "web_$USER" nginx
f614f3b1b088e8965d52f62f5554725789bb0a3e2a1302689921d9cf0dce13b9

$ docker logs "web_$USER"
/docker-entrypoint.sh: /docker-entrypoint.d/ is not empty, will attempt to perform configuration
/docker-entrypoint.sh: Looking for shell scripts in /docker-entrypoint.d/
/docker-entrypoint.sh: Launching /docker-entrypoint.d/10-listen-on-ipv6-by-default.sh
10-listen-on-ipv6-by-default.sh: Getting the checksum of /etc/nginx/conf.d/default.conf
10-listen-on-ipv6-by-default.sh: Enabled listen on IPv6 in /etc/nginx/conf.d/default.conf
/docker-entrypoint.sh: Launching /docker-entrypoint.d/20-envsubst-on-templates.sh
/docker-entrypoint.sh: Configuration complete; ready for start up
```

Теперь запускаем интерактивную сессию внутрь контейнера:

```bash
$ docker exec -it "web_$USER" bash
root@f614f3b1b088:/# 
```

Мы как бы залогинились внутрь нашего контейнера - запустили (exec) там bash в интерактивном режиме (-it). Далее, запускаем там веб-клиент и смотрим ответ на порте 80.

```bash
root@f614f3b1b088:/# curl localhost:80
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
    body {
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
```
Все отлично, внутри контейнера веб-сервер работает. Выходим из интерактивной сессии exit. А также останавливаем контейнер:

```bash
root@f614f3b1b088:/# exit
exit
$ docker stop "web_$USER"
web_ubuntu
```
### Проброс порта из контейнера на хост

Теперь надо пробросить порт 80 из контейнера наружу. За это отвечает опция -p. Чтобы на хосте не возникло конфликта портов при одновременном запуске контейнеров участниками, вот формула запуска, которая обеспечивает уникальный порт для каждого участника. Формула берет номер пользователя в системе (id -u) и прибавляет 1000 для использования непривилигированного порта. Проверьте работу формулы и заметьте свой порт:

```bash
$ echo $((1000+`id -u`))
```

Теперь запускаем 

```bash
$ docker run -d --rm --name "web_$USER" -p $((1000+`id -u`)):80 nginx
e0a4f57151c849fce59966e81b26a862a518b7af59efd5469b18d1184960d63e
$ curl localhost:$((1000+`id -u`))
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
...
```

Отлично, сервис в контейнере виден снаружи. А что там логе nginx?

```bash
$ docker logs "web_$USER"
/docker-entrypoint.sh: /docker-entrypoint.d/ is not empty, will attempt to perform configuration
/docker-entrypoint.sh: Looking for shell scripts in /docker-entrypoint.d/
/docker-entrypoint.sh: Launching /docker-entrypoint.d/10-listen-on-ipv6-by-default.sh
10-listen-on-ipv6-by-default.sh: Getting the checksum of /etc/nginx/conf.d/default.conf
10-listen-on-ipv6-by-default.sh: Enabled listen on IPv6 in /etc/nginx/conf.d/default.conf
/docker-entrypoint.sh: Launching /docker-entrypoint.d/20-envsubst-on-templates.sh
/docker-entrypoint.sh: Configuration complete; ready for start up
172.17.0.1 - - [10/Nov/2020:14:57:08 +0000] "GET / HTTP/1.1" 200 612 "-" "curl/7.68.0" "-"
```

Кто-то "постучался" с ip-адреса 172.17.0.1 - это адрес хоста в локальной подсетке, которую докер создал на на хосте.

### Привязка прота на хосте к определенному сетевому интерфейсу.

А виден ли этот сервер из интернета? Запустим curl на другом устройстве, используя полученный по формуле порт.

```bash
artem@artem-ubuntu2:/media/data/ozon$ curl bigdatamasters.ml:2000
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
...
```

Хм, виден, и это скажем так, неприятная неожиданность. Это ведь наш тестовый сервер, нехорошо его выставлять напоказ хакерам всего мира. Давайте исправим:

```bash
$ docker run -d --rm --name "web_$USER" -p 127.0.0.1:$((1000+`id -u`)):80 nginx``
```

Мы привязали наш порт на хосте к локальному интерфейсу `localhost`, у которого адрес - 127.0.0.1

### Изменения внутри контейнера

Давайте тепрь попробуем как-то изменить начальную страницу nginx, сделаем собственное приветствие. Но ведь это конфигурация nginx, надо ее исправлять.

Давайте снова залезем в контейнер и исправим конфигурацию. Найдем конфиг-файл и каталог, где лежит index.html.

```bash
ubuntu@linux1:~$ docker exec -it "web_$USER" bash
root@7f93288e7218:/# find / -name nginx.conf
/etc/nginx/nginx.conf
find: '/proc/29/map_files': Permission denied
root@7f93288e7218:/# cat /etc/nginx/nginx.conf

user  nginx;
worker_processes  1;

error_log  /var/log/nginx/error.log warn;
pid        /var/run/nginx.pid;


events {
    worker_connections  1024;
}


http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile        on;
    #tcp_nopush     on;

    keepalive_timeout  65;

    #gzip  on;

    include /etc/nginx/conf.d/*.conf;
}
```

Тут ссылка на включаемые файлы:

```bash
root@7f93288e7218:/# ls /etc/nginx/conf.d/*.conf
/etc/nginx/conf.d/default.conf
root@7f93288e7218:/# cat /etc/nginx/conf.d/default.conf
server {
    listen       80;
    listen  [::]:80;
    server_name  localhost;

    #charset koi8-r;
    #access_log  /var/log/nginx/host.access.log  main;

    location / {
        root   /usr/share/nginx/html;
        index  index.html index.htm;
    }
}
```

Ну вот, показывается место, откуда берется заглавная страница сервера:

```bash
root@7f93288e7218:/# cat /usr/share/nginx/html/index.html 
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
...
```

Йес, это оно!

Давайте поменяем содержимое тега title на что-то ваше. Только вот незадача - в этом образе нет ни одного знакомого редактора (nano, vi, emacs)! На помощь приходит sed:

```bash
root@7f93288e7218:/# sed -i 's/Welcome to nginx/Welcome datamove/' /usr/share/nginx/html/index.html 
root@7f93288e7218:/# cat /usr/share/nginx/html/index.html
<!DOCTYPE html>
<html>
<head>
<title>Welcome datamove!</title>
```
Опция -i указывает отредактировать данный файл in place, то есть без потоков ввода-вывода, как мы с вами ранее делали.

Что теперь? надо перестартовать контейнер, и сразу проверяем:

```bash
ubuntu@linux1:~$ docker restart "web_$USER"
web_ubuntu
ubuntu@linux1:~$ curl localhost:$((1000+`id -u`))
<!DOCTYPE html>
<html>
<head>
<title>Welcome datamove!</title>
```

Ок, получилось! А если остановить контейнер и запустить снова?

```bash
$ docker stop "web_$USER"
web_ubuntu
ubuntu@linux1:~$ docker start "web_$USER"
Error response from daemon: No such container: web_ubuntu
Error: failed to start containers: web_ubuntu
```

Ой, мы же использовали опцию `--rm` и уничтожили контейнер со всеми изменениями!

В принципе, есть опция сохранить изменения в контейнера в образ, но это не очень хорошая идея - надо стремиться к тому, чтобы образ собирался "их исходников" командой build, а контейнер можно было удалить в любое время без сожаления.

### Проброс файла с хоста в контейнер

Для того, чтобы решить эту ситуацию, воспользуемся `--mount` - опцией проброса директории или файла с хоста в контейнер.

Начнем с проброса файла.

Загрузите начайльную страницу себе в файл:

```bash
curl -o ~/index.html localhost:80
sed -i 's/Welcome to nginx/Welcome datamove/' ~/index.html
```

Запустите контейнер с опцией --mount 

```bash
$ docker run -d --rm --name "web_$USER" --mount type=bind,source=/home/$USER/index.html,target=/usr/share/nginx/html/index.html -p 127.0.0.1:$((1000+`id -u`)):80 nginx
```

Аргумент `type=bind` указывыает метод проброса файла - привязка файла с хота к файлу в контейнере.

Заметьте, не имеет значения, существует ли файл с путем /usr/share/nginx/html/index.html в контейнере, или нет. Если существует, то пробрасываемый с хоста файл /home/$USER/index.html "заместит" его.

Проверяем:

```bash
$ curl localhost:2000
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
    body {
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
</style>
</head>
<body>
<h1>Welcome datamove!</h1>
...
```

#### --mount vs. -v.

(https://docs.docker.com/storage/volumes/#choose-the--v-or---mount-flag)

Опция -v - это, фактически тоже самое, но с ньюансом и немного большими возможностями.

Вот эквивалент нашей опции:

`-v /home/$USER/index.html:/usr/share/nginx/html/index.html:ro`

Документация советует использовать --mount, но раньше использовалась -v и она много где приводится, в различный тьюториалах. Документация утверждает, что разница в:
* удобстве --mount. Понятнее стало, что на хосте, а что в контейнере.
* в создании директории на хосте. Если вы указываете папку хоста, которой нет на хосте, -v ее создаст, а --mount выдаст ошибку.

### Volumes

(https://docs.docker.com/storage/volumes/)

Так же эти опции создают тома докера (docker volumes), только меняется тип: `type=volume`.

Docker volumes  - это, фактически, файловые системы, которые создает докер и монтирует их в какой-то папке внутри контейнера.

Преимущество bind mount - привязка к файлу на локальной файловой системе хоста.

Преимущество volume - нет привязки к файлу на локальной файловой системе хоста.

Другими словами - это разные use cases. Volumes хорошо использовать для запуска контейнера в облачном кластере (наример, под управлением Cubenetes), а bind-mount - для локальной отладки и других случаев. Например, для сервиса  проверки первого логина я пробрасывал с хоста в контейнер /var/log/wtmp.

## Ссылки

https://docs.docker.com/

## Docker hub

Центральное хранилище образов. Требует логина для публикации. Для компаний требуется подписка.

## Docker Desktop

Адаптация докера для Windows и Мак ОС. На Windows не совместим с собственным движком виртуализации Hyper-V. Volumes не очень работают. Никаких графических приложений (под линуксом можно поместить chrome в контейнер, будет работать.

Не рекомендуется к применению.

## Ньюансы работы с докером

### /var/lib/docker

Сюда устанавливается по умолчанию, трудно передвинуть после начала работы. Может заполнить систему образами и контейнерами.

### bind mount

требует полного пути к директории или файлу на хосте

### Как из контейнера дотянуться до сервисов хоста.

При настройках по умочанию, из контейнера можно ходить в интернет. Но непонятно, как достучаться до сервисов на самом хосте. Например, наше приложение использует базу данных, которая запущена на хосте и слушает на порте 5432. Если бы мы запустили приложение локально, без контейнера, то просто соединялись бы к нему localhost:5432. Но наше приложение теперь как бы в отдельной виртуалке c приватным адресом и за NAT, как домашний раутер.

Для этого надо узнать гейтвей виртуальной сети докера, которая появляется на хосте при установке докера.

```bash
datamove@linux1:~/flask$ ip a show docker0
6: docker0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default 
    link/ether 02:42:14:bd:4f:89 brd ff:ff:ff:ff:ff:ff
    inet 172.17.0.1/16 brd 172.17.255.255 scope global docker0
       valid_lft forever preferred_lft forever
    inet6 fe80::42:14ff:febd:4f89/64 scope link 
       valid_lft forever preferred_lft forever
```

В нашем случае - 172.17.0.1. Именно этот адрес должно использовать приложение для досупа к портам хоста.

Если знаете другой хороший способ, расскажите :)

### host networking

Бывает интересным запустить контейнер так, чтоб у него не было собственного приватного адреса, а сервис в контейнере использовал бы адрес хоста и соответственно, напрямую порты, их не надо пробрасывать.  Для этого используйте опцию `--network host`.

### -u для запуска процесса под другим аккаунтом

По умолчанию, докер запускаети процессы в контейнере как root. Это не хорошо, так как при наличии уязвимости, злоумышленник (например, хакер, взломавший ваш сервер на фласке) может "вырваться" из контейнера на хост и получить там права суперюзера.

Рекомендуется запускать такие сервисы под непривилегированными пользователями, например daemon, nobody. но только если позволяют особенности работы приложения. Например, попытки запустить nginx с опциями -u daemon, -u nobody приведут к ошибкам запуска из-за отсутствия прав на какие-то директории.

А вот запуск образа с нашим фласк-сервером работает:

```bash
$ docker run --rm -d -u nobody flask-datamove 
550381b41ad5a5577985f5dead341207627ad6adad40bbb433f2dc5847ed08ee
datamove@linux1:~/flask$ ps -ef | grep flask
nobody   1034659 1034640 19 12:58 ?        00:00:00 python3 flask-app.py
nobody   1034692 1034659 10 12:58 ?        00:00:00 /usr/bin/python3 /flask-app/flask-app.py
datamove 1034696  797318  0 12:58 pts/19   00:00:00 grep --color=auto flask
```

А вот попытка указать собственного пользователя приведет к ошибке:

```
datamove@linux1:~/flask$ docker run --rm -d -u datamove flask-datamove 
16985f1a44f97650745aac283cf3b624fbb6d1728df25a79af9dcf433281689d
docker: Error response from daemon: unable to find user datamove: no matching entries in passwd file.
```

Да, у нас же в образе чистая Ubuntu, и там есть системный пользователь nobody, но нет студентов!

Попробуем создать пользователя в контейнере следующей командой Dockerfile

```
RUN useradd datamove
```

Собираем образ

Запускаем - сработало!

```bash
datamove@linux1:~/flask$ docker run --rm -d -u datamove flask-datamove 
c6865b96ebc29765e2a8eb1ae5f4788e3a77ccbd913a6ca9206faf6f06d3a2a7
```

Но что это - процесс бегает не под datamove, а под ubuntu!

```bash
datamove@linux1:~/flask$ ps -ef | grep flask
ubuntu   1035098 1035077  7 13:05 ?        00:00:00 python3 flask-app.py
ubuntu   1035131 1035098  3 13:05 ?        00:00:00 /usr/bin/python3 /flask-app/flask-app.py
datamove 1035135  797318  0 13:05 pts/19   00:00:00 grep --color=auto flask
```
Дело в том, что для системы имеют значения номера пользователей в системе. В свежеинсталлированной системе первый пользователь, созданный командой useradd будет иметь id=1000 (запустите `id -u ubuntu`). В контейнере тоже самое - пользователь datamove получил номер 1000, а на хосте этот номер занят (запустите `id 1000` чтобы цбедиться).

Выход в том, чтобы испольовать с -u номер пользователя, а не его имя. Тогда у докера нет ошибки, а вы получаете то, что надо:

```bash
datamove@linux1:~/flask$ docker run --rm -d -u `id -u` flask-datamove 
041bc1f7f418ec7135fdd5feea9dced3f87c8e378e3b40b232624170c36e0c2e
datamove@linux1:~/flask$ ps -ef | grep flask
datamove 1035430 1035409 10 13:24 ?        00:00:00 python3 flask-app.py
datamove 1035465 1035430  7 13:24 ?        00:00:00 /usr/bin/python3 /flask-app/flask-app.py
datamove 1035469  797318  0 13:24 pts/19   00:00:00 grep --color=auto flask
```

Под каким же именем бегает процесс в контейнере, если там нет нашего пользователя?

```bash
datamove@linux1:~/flask$ docker exec -it 041bc1f7f418ec7135fdd5feea9dced3f87c8e378e3b40b232624170c36e0c2e bash
I have no name!@041bc1f7f418:/flask-app$ ps
    PID TTY          TIME CMD
     10 pts/0    00:00:00 bash
     16 pts/0    00:00:00 ps
I have no name!@041bc1f7f418:/flask-app$ id
uid=1077 gid=0(root) groups=0(root)
I have no name!@041bc1f7f418:/flask-app$ 
```

Не под каким. Зато id есть. Видимо, имя линуксу и не нужно.

Зачем это надо. Например, если вы пробрасываете в контейнер папку из вашей домашней директории, то с таким запуском контейнер может писать в нее новые файлы, и они будет появляться под вашим именем. Такой трюк я использовал для образа mlcourse.ai. Там локальная папка на компьютере пользователя замещает домашнюю папку в контейнере, и такой трюк позволяет пользователям ставить свои пакеты командой `pip install --user` - они будут сознатяться в домашней директории пользователя и переживут и удаление контейнера и обновление образов...

юпитер там запускается такой командой:

`docker run --rm -u $(id -u):$(id -g) -v "$PWD:/notebooks" -w /notebooks -e HOME=/notebooks/home -p $PORT:8888 $IMAGE jupyter-notebook --NotebookApp.ip=0.0.0.0 ...`

* -u $(id -u):$(id -g) - запуск с текущим пользователем и его группой
* -v "$PWD:/notebooks" - проброс текущей директории в /notebooks в контейнере. Всё, что в на хосте в текущей папке в контейнере будет доступно в /notebooks, а если к контейнере что-то пишется в /notebook, то появтися в текущей директории и будет принадлежать текущему пользователдю из-за спец. опции -u выше.
* -w /notebooks - делает текущей в контейнере директорию /notebooks 
* -e HOME=/notebooks/home - устанавливает переменную HOME, то есть домашнюю директорию в контейнере.

Таким образом, создавать пользователя нам в контейнере не надо, удалите директиву RUN useradd

