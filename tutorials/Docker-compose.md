# Docker-compose

Определяем и запускаем несколько сервисов вместе.

## Задача

1. Запустим ваш сервис в контейнере
2. Запустим в контейнерах два сервиса и раутер запросов (nginx)

## 1. Сервис с помошью docker-compose

* определение свойств сервиса в конфиг файле (yaml)
* cборка образа

### 1.1 Пререквизиты

Зайдите (cd) в папку с прошлого тьюториала, где у вас сохранены следующие файлы:

* flask-app.py с тестовым сервисом
*  port=5000
*  host='0.0.0.0'
* requirements.txt
* Dockerfile

У кого это нет с прошлого занятия, возьмите в папке `flask` в этом репо, `cd` в эту папку и соберите образ, если не собирали ранее:

`$ docker build -t flask-${USER,,}:latest .`

Да, точка на конце - это аргумент (означает, что context в текущей директории). `${USER,,}` - означает првести $USER к нижнему регистру, а иначе docker не принимает.

### 1.2 docker-compose.yml

Создайте файл `docker-compose.yml` со следующим содержанием. 
Обратите внимание, что тут мы (пока) прописываем название образа и порта, так что замените на ваши:

```yaml
version: '3'

services:
    web:
      image: flask-datamove
      ports:
        - "127.0.0.1:2001:5000"
```

Мы определили сервис под названием `web`, для которого надо использовать образ `flask-${USER,,}` (т.е. `flask-datamove` для меня) и пробросить порт заданным образом.
 

#### Запустите сервис

```bash
$ docker-compose -p $USER up
Creating network "datamove_default" with the default driver
Creating datamove_web_1 ... done
Attaching to datamove_web_1
web_1  |  * Serving Flask app "flask-app" (lazy loading)
web_1  |  * Environment: production
web_1  |    WARNING: This is a development server. Do not use it in a production deployment.
web_1  |    Use a production WSGI server instead.
web_1  |  * Debug mode: on
web_1  |  * Running on http://0.0.0.0:5000/ (Press CTRL+C to quit)
web_1  |  * Restarting with stat
web_1  |  * Debugger is active!
web_1  |  * Debugger PIN: 159-334-307
```

Мы видим, что докер создал сеть "datamove_default", сделал для нас контейнер под названием datamove_web_1, и запустил его, присоединив вывод к терминалу.

Если мы сейчас прервем выполнение Ctrl-C и запустим снова, то увидим, что новый контейнер не создается:

```bash
$ docker-compose -p $USER up
Starting datamove_web_1 ... done
Attaching to datamove_web_1
...
```

Мы пока получили такой же результат, как и запуская контейнер командой `docker run`, но выгода уже очевидна - мы записали опции для этой команды в файл и теперь нам не надо их заново печатать каждый раз.

Мы дали опцию `-p $USER` (название проекта), чтобы не было конфликта названий контейнера. По умолчанию в качестве проекта используется имя текущей папки, т.е. flask в нашем случае. Без этой опции у всех, у кого проект в папке flask, использовалось бы одно название контейнера.

### 1.3 Cборка контейнера

Но можно и совместить сборку с запуском. Создайте файл `docker-compose-build.yml` со следующим содержанием: 

```yaml
version: '3'

services:
    web:
      build:
        context: .
        dockerfile: Dockerfile
      ports:
        - "127.0.0.1:2000:5000"
```

Мы определили сервис под названием `web`, для которого надо собрать образ используя Dockerfile и контекст из текущей директории.

Заметьте, что мы не определили название образа (tag), поэтому образ будет собран заново, и название ему тоже дается по имени проекта + имя сервиса (e.g. datamove_web в моем случае).

#### Запустите сервис

Здесь мы так же используем опцию -f (указать файл docker-compose).

```bash
$ docker-compose -p $USER -f docker-compose-build.yml up
Building web
Step 1/7 : FROM ubuntu:20.04
...
Successfully built 33825454a79d
Successfully tagged datamove_web:latest
WARNING: Image for service web was built because it did not already exist. To rebuild this image you must use `docker-compose build` or `docker-compose up --build`.
Recreating datamove_web_1 ... done
Attaching to datamove_web_1
web_1  |  * Serving Flask app "flask-app" (lazy loading)
web_1  |  * Environment: production
web_1  |    WARNING: This is a development server. Do not use it in a production deployment.
web_1  |    Use a production WSGI server instead.
web_1  |  * Debug mode: on
web_1  |  * Running on http://0.0.0.0:5000/ (Press CTRL+C to quit)
web_1  |  * Restarting with stat
web_1  |  * Debugger is active!
web_1  |  * Debugger PIN: 298-713-662
```

Мы так же можем не присоединять вывод контейнера к терминалу (знакомая -d) и посмотреть логи  контейнера командой `docker-compose logs` (для всех контейнеров сразу) или `docker logs datamove_web_1` (для каждого контейнера индивидуально).

## 2. Больше сервисов

В нашем приложении мы одновременно делаем интерфейсы WEB (html), и REST (json). Мы это делали в тьюториале [Docker.md](Docker.md). Давайте поместим их в разные контейнеры. Только для простоты, мы не будем делать два разных приложения, а сделаем два сервиса с одним и тем же приложением.

### 2.1 Два сервиса

Создайте docker-compose-rest.yml со следующим содержимым, заменяя ваш ник и порт:

```bash
version: '3'

services:
    web:
      build:
        context: .
        dockerfile: Dockerfile
      ports:
        - "127.0.0.1:2002:5000"
    rest:
      image: flask-datamove
      ports:
        - "127.0.0.1:3002:5000"
```
Здесь у нас два сервиса - `web`, `rest`. Один из них собрается на месте, для другого используется готовый образ.

Заметьте, что мы не можем использовать тот же порт два раза снаружи контейнера, поэтому заменяем его для нового сервиса `rest`.

#### Запускаем

Видим, что запускаются оба сервиса.

```bash
datamove@linux1:~/flask$ docker-compose -p $USER -f docker-compose-rest.yml up
Creating network "datamove_default" with the default driver
Creating datamove_web_1  ... done
Creating datamove_rest_1 ... done
Attaching to datamove_rest_1, datamove_web_1
rest_1  |  * Serving Flask app "flask-app" (lazy loading)
rest_1  |  * Environment: production
rest_1  |    WARNING: This is a development server. Do not use it in a production deployment.
rest_1  |    Use a production WSGI server instead.
rest_1  |  * Debug mode: on
rest_1  |  * Running on http://0.0.0.0:5000/ (Press CTRL+C to quit)
rest_1  |  * Restarting with stat
web_1   |  * Serving Flask app "flask-app" (lazy loading)
web_1   |  * Environment: production
web_1   |    WARNING: This is a development server. Do not use it in a production deployment.
web_1   |    Use a production WSGI server instead.
web_1   |  * Debug mode: on
web_1   |  * Running on http://0.0.0.0:5000/ (Press CTRL+C to quit)
web_1   |  * Restarting with stat
rest_1  |  * Debugger is active!
rest_1  |  * Debugger PIN: 136-774-235
web_1   |  * Debugger is active!
web_1   |  * Debugger PIN: 732-757-574
```

Мы их можем индивидуально подергать на своих портах. Проделайте это самостоятельно.

### 2.2 Сервисы и раутер

В качестве маршрутизатора запросов используем `nginx`, который часто используется в таких целях.

Мы уже запускали `nginx` и умеем пробрасывать его конфигурационный файл.

Создайте новый файл docker-compose-nginx.yml (или скопируйте -rest.yml) и отредактируйте (заменяя ник в названии образа и пути к конфиг-файлу `nginx`, порт на ваши):

```yaml
version: '3'

services:
    web:
      build:
        context: .
        dockerfile: Dockerfile
    rest:
      image: flask-datamove
    router:
      image: nginx
      ports:
        - "127.0.0.1:2002:80"
      volumes:
        - /home/datamove/flask/nginx.conf:/etc/nginx/nginx.conf:ro    
```

Вы видите, что пробрасывать порты контейнеров нам нет необходимости, так как мы не будем к ним напрямую обращаться. К ним  будет обращаться только контейнер `nginx` по виртуальной сети, которая объединяет все три контейнера. Это - так называема схема "обратное проксирование" (reverse proxy). Также, тут мы познакомились с директивой проброса файла. 

Содержимое nginx.conf ниже.

```
events { worker_connections 1024; }

http {

  server {
    listen 80 default_server;
    return 422; # Unprocessable Entity
  }

  server {
      server_name       www.example.com;
      location / {
        proxy_pass      http://web:5000;
      }
  }

  server {
      server_name      rest.example.com;
      location / {
        proxy_pass     http://rest:5000;
      }
  }
}
```

Сдесь мы делаем маршрутизацию по имени хоста. Все запросы к www.example.com должны направляться в контейнер web, а все запросы к rest.example.com - в контейнер rest. Запросы на другие хосты не обрабатываются - возвращается ошибка 422. Мы можем обращаться к нашим фласк-серверам в контейнерах по именам контейнеров, так как внутри виртуальной сети докера контейнеры - это хосты, а их имена соответствуют названиям сервисов. 

#### Запускаем

`docker-compose -p $USER -f docker-compose-nginx.yml up`

В другом окне делаем тестовые запросы:

```bash
ubuntu@linux1:~/flask$ curl -H "Host: www.example.com" http://localhost:2002
Hello world!ubuntu@linux1:~/flask$ 
ubuntu@linux1:~/flask$ 
ubuntu@linux1:~/flask$ curl -S --fail http://localhost:2002
curl: (22) The requested URL returned error: 422 
ubuntu@linux1:~/flask$ curl -H "Host: rest.example.com" http://localhost:2002
Hello world!ubuntu@linux1:~/flask$ 
```

Соответственно в первом окне появятся логи запросов:

```
web_1     | 192.168.16.4 - - [16/Nov/2020 16:16:18] "GET / HTTP/1.0" 200 -
router_1  | 192.168.16.1 - - [16/Nov/2020:16:16:18 +0000] "GET / HTTP/1.1" 200 12 "-" "curl/7.68.0"
router_1  | 192.168.16.1 - - [16/Nov/2020:16:16:21 +0000] "GET / HTTP/1.1" 422 0 "-" "curl/7.68.0"
rest_1    | 192.168.16.4 - - [16/Nov/2020 16:16:54] "GET / HTTP/1.0" 200 -
router_1  | 192.168.16.1 - - [16/Nov/2020:16:16:54 +0000] "GET / HTTP/1.1" 200 12 "-" "curl/7.68.0"=
```

Видно, что запросы идут в разные контейнеры или nginx сам выдает ошибку.

К слову сказать, так же можно сделать маршрутизацию по url (location /) или даже используя заголовки запросов:

```
if ($http_content_type = “application/json”) {
  set $proxy “rest.example.com”;
}
# then use: proxy_pass $proxy
```

Поиграйте с раутером сами!

## 3. Другие опции docker-compose

* build - просто собрать образы
* create - сделать контейнеры, без запуска
* down - остановить контейнеры, удалить их, образы, сети, и тома (последнее особенно важно!)
* stop - просто остановить сервисы, ничего не удаляя. Пользуейтесь этим, чтоб не удалять
* ps - список контейнеров

И другие команды, см.  `docker-compose -h`

## 4. Использование переменных в docker-compose

Можно использовать переменные среды из оболочки. Например, мы хотим, чтобы порт приложения был переменной. 
Тогда заменяем соответствующую строчку в yaml-файле (скопируйте в docker-compose-vars.yml):

```
      ports:
        - "127.0.0.1:2002:80"
```
на:
```
      ports:
        - "127.0.0.1:${APP_PORT}:80"
```

А запускаем следующим образом:

```bash
export APP_PORT=$((`id -u` + 1000))
datamove@linux1:~/flask$ docker-compose -p $USER -f docker-compose-vars.yml up
```

Вариант без экспорта:

```bash
datamove@linux1:~/flask$ APP_PORT=2002 docker-compose -p $USER -f docker-compose-vars.yml up
```

Заметьте, что, разумеется, можно использовать и уже установленные переменные, например $USER:

```yml
    rest:
      image: flask-${USER}
```
Сделайте такое изменение, а так же в volumes и запустите команду выше. Теперь ваш файл стал шаблоном с переменными.
Внимание - это сработает, если у вас не заглавных букв в $USER. Иначе, вам надо от них избавится. Т.е. :

```yml
    rest:
      image: flask-${user}
```
и запускать

```bash
datamove@linux1:~/flask$ user=${USER,,} docker-compose -p $USER -f docker-compose-vars.yml up
```

Третий способ - создать в той же папке файл `.env` с определением переменных:

```bash
$ cat .env
APP_PORT=2002
```
В этом случае docker-compose устанавливает их сам. Значения в файле могут быть переписаны установкой соответствующих переменных среды. Т.е. команда `export APP_PORT=3002` будет иметь приоритет перед значениями в `.env`. Польуйтесь с осторожностью - все что не на виду - легко упустить из виду :). Поэтому мой любимый способ - №2.

