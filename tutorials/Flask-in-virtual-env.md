# Flask in virtualenv

ВНИМАНИЕ - на новом сервере 130.193.42.94 действуют теже логины, как и на старом, с теми же ключами! Добвьте его к себе в .ssh/config

В этот тьюториале познакомимся с модулем virtualenv, создадим виртуальную среду, установим туда модуль Flask - фреймворк для создания веб-сайтов на питоне, и запустим небольшой веб-сервер.

## Пререквизит

У вас уже должен быть питон и в нем уже должен быть установлен модуль virtualenv. 

Если  virtualenv не установлен в системе, вы можете его установить в собственной домашней директории:

`pip install --user virtualenv`

после чего  запускать его: ~/.local/bin/virtualenv

## Создание виртуальной среды

### Все по умолчанию

Попробуем просто:

```bash
ubuntu@linux1:~$ virtualenv venv1
created virtual environment CPython3.8.2.final.0-64 in 590ms
  creator CPython3Posix(dest=/home/ubuntu/venv1, clear=False, global=False)
  seeder FromAppData(download=False, contextlib2=latest, colorama=latest, distro=latest, CacheControl=latest, distlib=latest, msgpack=latest, retrying=latest, certifi=latest, packaging=latest, pep517=latest, urllib3=latest, six=latest, html5lib=latest, pkg_resources=latest, appdirs=latest, pytoml=latest, idna=latest, progress=latest, webencodings=latest, chardet=latest, lockfile=latest, setuptools=latest, pyparsing=latest, requests=latest, ipaddr=latest, wheel=latest, pip=latest, via=copy, app_data_dir=/home/ubuntu/.local/share/virtualenv/seed-app-data/v1.0.1.debian)
  activators BashActivator,CShellActivator,FishActivator,PowerShellActivator,PythonActivator,XonshActivator
```

главное - это `created virtual environment CPython3.8.2.final.0-64 in 590ms`, на остальное можно не обращать внимание.

Команда создала папку `venv1`:

```bash
$ ls -al venv1
total 20
drwxrwxr-x  4 ubuntu ubuntu 4096 Nov 12 16:38 .
drwx------ 21 ubuntu ubuntu 4096 Nov 12 16:38 ..
drwxrwxr-x  2 ubuntu ubuntu 4096 Nov 12 16:39 bin
drwxrwxr-x  3 ubuntu ubuntu 4096 Nov 12 16:38 lib
-rw-rw-r--  1 ubuntu ubuntu  202 Nov 12 16:39 pyvenv.cfg
```

а python в bin - это на самом деле мягкая ссылка:

```bash
$ ls -al venv1/bin/python
lrwxrwxrwx 1 ubuntu ubuntu 16 Nov 12 16:38 venv1/bin/python -> /usr/bin/python3
```

Тем не менее, для нас - это отдельностоящий питон, и туда мы можем ставить пакеты. Но прежде надо активировать среду:

```bash
$ source venv1/bin/activate
(venv1) $
```

В промпте появился индикатор среды - довольно удобно. Питон теперь берется из папки среды:

```bash
(venv1) $ which python
/home/ubuntu/venv1/bin/python
(venv1) $ 
```

Собственно говоря, все что делает activate - это устанавливает новый $PATH

```bash
VIRTUAL_ENV='/home/ubuntu/venv1'
export VIRTUAL_ENV

_OLD_VIRTUAL_PATH="$PATH"
PATH="$VIRTUAL_ENV/bin:$PATH"
export PATH
```

Ну и убедимся, что все работает:

```bash
(venv1) $ python
Python 3.8.2 (default, Jul 16 2020, 14:00:26) 
[GCC 9.3.0] on linux
Type "help", "copyright", "credits" or "license" for more information.
>>> print("Hello world")
Hello world
>>> 
```

Чтобы выйти из среды, надо набрать команду deactivate, которая тоже определяется в activate:

```bash
(venv1) $ deactivate
ubuntu@linux1:~$ which python3
/usr/bin/python3
```

### Если надо другую версию питона, установленную в системе

У меня нет другой, поэтому проиллюстрирую опцию на примере того же самого системного питона.

`virtualenv -p /usr/bin/python3 venv2`

### Опция для копирования бинарников

```bash
$ virtualenv --copies -p /usr/bin/python3 venv2
created virtual environment CPython3.8.2.final.0-64 in 276ms
...
$ ls -al venv2/bin/python
-rwxr-xr-x 1 ubuntu ubuntu 5453504 Nov 12 17:00 venv2/bin/python
```

Теперь это копия бинарника а не ссылка на оригинал в системе.


## Flask

### среда

Создайте виртуальный энвайронмент flaskenv, активируйте его, и установите туда пакет Flask c зависимостям:

`pip install flask`

### код

создайте папку `flask`, а в ней - файл flask-app.py со следующим кодом:

```python
#
# Simple Flask app
#
import os
import pwd

from flask import Flask

port=pwd.getpwnam(os.environ['USER']).pw_uid + 1000
host='127.0.0.1'

app = Flask(__name__)

@app.route('/')
def hello_world():
    return 'Hello world!'

if __name__ == '__main__':
    app.run(debug=True, port=port, host=host)
```

Здесь мы выбраем порт, на котором будет запущен сервер, исходя из ID вашего пользователя в системе + 1000 (прибавление тысячи гарантирует, что мы не попадем в привилигированный диапазон портов только для root). Свой ID можно так же посмотреть командой `id -u`.

### запуск и тестирование

Запустите:
```
(flaskenv) datamove@docker1:~$ python flask-app.py
 * Serving Flask app "flask-app" (lazy loading)
 * Environment: production
   WARNING: This is a development server. Do not use it in a production deployment.
   Use a production WSGI server instead.
 * Debug mode: on
 * Running on http://127.0.0.1:2001/ (Press CTRL+C to quit)
 * Restarting with stat
 * Debugger is active!
 * Debugger PIN: 137-096-599
```

Теперь откройте новый терминал и вызовите там curl с вашим URL:

```
(flaskenv) datamove@docker1:~$ curl http://localhost:5000
Hello world!(flaskenv) ubuntu@cluster1-4-16-40gb:~$ 
```


Вы так же можете зайти браузером на страничку http://localhost:xxxx где хххх - ваш порт (см в логе запуска), но только используя технику проброса порта из ранних лекций (ssh -L). У вас должна появиться надпись `Hello World!`

Посмотрите в терминал, где запущен ваш сервер:

```
127.0.0.1 - - [14/Oct/2019 09:50:17] "GET / HTTP/1.1" 200 -
127.0.0.1 - - [14/Oct/2019 09:50:17] "GET /favicon.ico HTTP/1.1" 404 -
127.0.0.1 - - [14/Oct/2019 09:51:10] "GET / HTTP/1.1" 200 -
127.0.0.1 - - [14/Oct/2019 09:52:06] "GET / HTTP/1.1" 200 -
```

это ваши запросы в логе.

### HTML

Вместо простого текста можно выводить html:

```
return """<html><body>
<h1>Welcome to nginx!</h1>
</body></html>
"""
```

### REST API

Хотя вы можете и приукрасить вашу страничку с помощью HTML, нам наиболее интересно использование сервера через REST API.

Сделайте еще один endpoint, например:

```
from flask import request

@app.route('/do_something/<int:my_param>', methods=['POST'])
def do_something(my_param):
    return(f"PARAMETER {my_param}\nPOST DATA: {request.json}\n")
```

Здесь мы определяем точку входа /do_something для запроса POST, который принимает опциональный параметр-целое число в составе URL. 

Запустите и сделайте вызов следующим образом (передаем объект json в теле запроса):

```
(flaskenv) datamove@docker1:~$ curl -X POST -H "Content-Type: application/json" -d '{"test-key":"test-value"}' http://localhost:5000/do_something/3
PARAMETER 3
POST DATA: {'test-key': 'test-value'}
```

Метод GET используется по умолчанию, то есть как в `hello_world()`. В методе GET параметры передаются в URL следующим образом:

```
(flaskenv) datamove@docker1:~$ curl -X GET -H "Content-Type: application/json" 'http://localhost:5000/do_something_with_parapms?param1=23&param2=36'
```

А вот как мы их получаем в программе с Flask.

```
@app.route('/do_something_with_params', methods=['GET'])
def do_something_with_params():
    param1 = request.args.get('param1')
    param2 = request.args.get('param2')
    return(f"PARAM1 {param1} PARAM2 {param2}\n")
```

Вот еще пример для обработки ошибок и вывода json одновременно:

```
from flask import request, abort, make_response, jsonify

@app.errorhandler(404)
def not_found(error):
    return make_response(jsonify({'error': 'Not found. Bad luck!'}), 404)
```

## Links

* https://flask.palletsprojects.com/en/2.0.x/
* https://en.wikipedia.org/wiki/Flask_(web_framework)

