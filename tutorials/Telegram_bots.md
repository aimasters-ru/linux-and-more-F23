# Telegram Bots

В этом тьюториале - программируем бота на Python используя библиотеку [Python Telegram Bot](https://github.com/python-telegram-bot/python-telegram-bot).

Выбор библиотеки - субъективный. Do your own reserch!

## подготовка

Создайте виртуальную среду, активируйте, установите пакеты:

```python
pip install python-telegram-bot
pip install django
```

## Initialisation

Импорты библиотек, сразу все, чтоб потом не отвлекаться

```python
import logging
import os

from telegram.ext import Updater
from telegram.ext import CommandHandler
from telegram.ext import MessageHandler, Filters
from telegram.ext import ConversationHandler


from telegram import ReplyKeyboardMarkup
from telegram import InlineKeyboardButton, InlineKeyboardMarkup
```

Инициализация состоит в запуске цикла опроса сервера, чтобы получать новые сообщения (updates).
Опционально используем прокси, например socks. На случай блокировки телеграмма, например. Поместите ваш токен в файл, защитите его маской 600. 

```python
if 'TG_PROXY' in os.environ:
  REQUEST_KWARGS['proxy_url'] = os.environ['TG_PROXY']

tg_token = open('token_file').read()

updater = Updater(token=tg_token, use_context=True) #, request_kwargs=REQUEST_KWARGS)

dispatcher = updater.dispatcher
```

## Handlers (обработка команд)

### Command handler

Сначала мы определяем функцию, которую диспетчер вызовет, когда боту придет апдейт с нужной командой. В нашем случае ниже - это /start.  Далее, привязываем эту функцию-callback к команде - создаем command handler. Наконец, регистрируем его в диспетчере.

```python
#
# This handler returns tg id (used in checker)
#
def id_callback(update, context):

    chat_id = update.effective_chat.id

    update.message.reply_text(
        f'Ваш телеграмм-id: {chat_id}\n'
    )

# handler for text command
id_handler = CommandHandler('start', id_callback)
dispatcher.add_handler(id_handler)
```

Здесь определяется обработчик команды /start. Когда пользователь ее запускает (или нажимает на кнопку start при переходе в бот по ссылке), в бот приходит обновление и dispatcher запускает вызов `id_callback`, который мы зарегистрировали. Строго говоря, /start не обязательно обрабатывать.

Все обратные вызовы (callback) принимают первым агрументом структуру `update` из которой мы получаем присланные сообщения, и структуру context, в которой хранится состояние диалога.

В контексте так же передаются аргументы команде, если пользователь подал команду с аргументами, например `/start privet`.

```python
if len(context.args) != 0:
    update.message.reply_text(
        f'Вы послали параметры команды: {context.args}\n'
    )
```

Можно вызывать reply_text() несколько раз, это будут разные сообщения.

### Message handler

Сообщений и типов сообщений довольно много, поэтому есть возможность определить callback с помощью фильтра на что-то конкретное.

В простейшем случае текстового сообщения воспользуемся фильтром Filters.text. Так же, в этом примере проиллюстрируем как послать сообщение произвольному пользователю (но помните, этот пользователь должен запустить бот командой /start перед тем как бот получит возможность ему писать. 

```python
def alert_callback(update, context):
    chat_id = update.effective_chat.id
    message_received = update.message.text
    
    reply_message = f"Dear admin! User {chat_id} sent this to the bot:"
    reply_message += update.message.text

    context.bot.send_message(chat_id=admin_chat_id, text=reply_message)

# Handler for any text message
alert_handler = MessageHandler(Filters.text, alert_callback)
dispatcher.add_handler(alert_handler)
```

Больше о фильтрах в документации: https://python-telegram-bot.readthedocs.io/en/stable/telegram.ext.filters.html

➡️ Можно использовать фильтры с регулярными выражениями, фильтры на тип документа (если пользователь послал файл или фото).
⚠️ Порядок определения хэндлеров имеет значение! Первый сматченный фильтр запускает свой callback.
⚠️ Иногда фото надо обрабатывать как фото, а не document.image

Фильтр Filters.status_update можно использовать в группах. Например, отследить, что бота добавили в группу:

```python
def new_member(update, context):
    for member in update.message.new_chat_members:
        if member.username == update.message.bot.username:
            update.message.reply_text(f'Thanks for adding me! chat_id is {update.message.chat.id}')

new_member_handler = MessageHandler(Filters.status_update.new_chat_members, new_member)
```
⚠️ У телеграмма есть группы и супергруппы. Разница не очень вменяемо описывается. Если хотите добавить бота в группу, лучше сразу превратите простую группу в супергруппу. Это делается в настройках группы. Такая группа получает @username и новый id, который образуется из старого путем приписывания -100 в начало. :) теперь этот id можно куда-то сохранить и использовать его, когда бот должен написать в группу. 

### Как выглядит update

```python
{
 'update_id': 241336728, 
 'message': 
  { 
   'message_id': 987, 
   'date': 1600178782, 
   'chat': {
       'id': 163729590, 
       'type': 'private', 
       'username': 'fateev_da', 
       'first_name': 'Дмитрий', 
       'last_name': 'Фатеев'
       }, 
   'text': '/submit', 
   'entities': [{'type': 'bot_command', 'offset': 0, 'length': 7}], 
   'caption_entities': [], 
   'photo': [], 
   'new_chat_members': [], 
   'new_chat_photo': [], 
   'delete_chat_photo': False, 
   'group_chat_created': False, 
   'supergroup_chat_created': False, 
   'channel_chat_created': False, 
   'from': {
      'id': 163729590, 
      'first_name': 'Дмитрий', 
      'is_bot': False, 
      'last_name': 'Фатеев', 
      'username': 'fateev_da', 
      'language_code': 'ru'
    }
  }, 
  '_effective_user': 
        {
        'id': 163729590, 
        'first_name': 'Дмитрий', 
        'is_bot': False, 
        'last_name': 'Фатеев', 
        'username': 'fateev_da', 
        'language_code': 'ru'
        }, 
  '_effective_chat': 
        {
        'id': 163729590, 
        'type': 'private', 
        'username': 'fateev_da', 
        'first_name': 'Дмитрий', 
        'last_name': 'Фатеев'
        }, 
   '_effective_message': {
           'message_id': 987, 
           'date': 1600178782, 
           'chat': {
              'id': 163729590, 
              'type': 'private', 
              'username': 'fateev_da', 
              'first_name': 'Дмитрий', 
              'last_name': 'Фатеев'
            }, 
           'text': '/submit', 
           'entities': [{'type': 'bot_command', 'offset': 0, 'length': 7}], 
           'caption_entities': [], 
           'photo': [], 
           'new_chat_members': [], 
           'new_chat_photo': [], 
           'delete_chat_photo': False, 
           'group_chat_created': False, 
           'supergroup_chat_created': False, 
           'channel_chat_created': False, 
           'from': {
             'id': 163729590, 
             'first_name': 'Дмитрий', 
             'is_bot': False, 
             'last_name': 'Фатеев', 
             'username': 'fateev_da', 
             'language_code': 'ru'
           }
   }
}
```

## Загрузка файлов

В бота можно загружать файлы, которые он хранинт "вечно" на серверах телеграмма. Каждый документ получает внутренней id, по которому можно скачать документ или "послать" его другому пользователю. Файлв привязаны к боту, id файла работает только в боте, использовать загруженный файл вне бота не получится. Рассмотрим такой сценарий: один пользователь загрузил файл в бот, затем бот "послал" этот файл другому пользователю или в группу.

### Загрузка файла из бота

Обработчик определяется с фильтром для документа:

```python
MessageHandler(Filters.document, upload_file)
```

В обработчике находим нужное в `update.message.document`:

```python
      message = update.message
      document = message.document

      #download
      newFile = document.get_file()
      
      # define target file name for download
      download_as = f"downloads/{document.file_name}"

      # check/create the dir
      Path("downloads").mkdir(parents=False, exist_ok=True)
      
      newFile.download(download_as)
      self.logger.info(f"Downloaded {download_as}")
```

### Отсылка файла

После моих экспериментов самым простым и элегантным методом оказался следующий. 

Если надо переслать файл пользователя в группу, то просто пересылаем сообщение (загрузка файла - это message) в нужный чат:

```python
      #forward uploaded file to а group chat
      forwarded = message.forward(chat_id)
      self.logger.info(f"FORWARDED {forwarded}\nLINK {forwarded.link}")
```
Тут как раз важно, что мы имеем дело с супергруппой, это работает 

Отдельно мы можем хранить в базе данных и id загруженного документа: `document.file_id`, и можем сформировать из него ссылку для загрузки файла пользователем: `f"file://tg/files/{document.file_id}"`. Python-telegram-bot сделал для нашего удобства метод `message.link`.

## Conversations (диалоговый бот)

Главная фишка диалога - отслеживать состояние диалога для каждого пользователя. Диалог начинается, когда срабатывает обработчик, опледеленный в поле `entry_points`. Их там может быть и несколько, помещайте их в порядке приоритета для срабатывания - более специфичные фильтры вперед. Далее мы определяем состояния диалога, которые определяются целочисленными константами от 0 и больше. В каждом состоянии бот будет откликаться на те сообщения, которые указаны и сматчатся в обработчиках для этого состояния. А если пользователь перестал откликаться, диалог может прекратиться по таймауту. Для этого предусмотрено специальное состояние ConversationHandler.TIMEOUT с фиксированным значением -2.

В диалоге ниже по команде /start бот спрашивает ФИО пользователя. Фамилия должна начинаться с заглавной буквы и содержать буквы или тире (для двойных фамилий), далее пробел и имя из букв. При успехе, спрашивает email. После ввода чего-то похожего на имейл (матчится @) диалог заканчивается.

```python
ENTER_NAME, ENTER_EMAIL, *_ = range(10)

start_conv_handler = ConversationHandler(
        entry_points=[CommandHandler('start', start_callback)],

        states={
            ENTER_NAME: [
                MessageHandler(Filters.regex(r'^^[А-ЯA-Z][А-ЯA-Zа-яa-z-]+\s\w+$'), valid_name),
                MessageHandler(Filters.text, invalid_name)
             ],

            ENTER_EMAIL: [
                MessageHandler(Filters.regex(r'@'),valid_email),
                MessageHandler(Filters.text, invalid_email)
             ],

             ConversationHandler.TIMEOUT: [
                 MessageHandler(Filters.text | Filters.command, timeout)
             ]
        },

        conversation_timeout = datetime.timedelta(seconds=60), 

        fallbacks=[ MessageHandler(Filters.text | Filters.command, done) ]   
)

dispatcher.add_handler(start_conv_handler)
```

Теперь реализуем функции-обратные вызовы. Отличительной особенностью этих функций для диалога является возврат числа-состояния, в которое переходит диалог. Переход в новое состояние диалога активирует обработчики, зарегистрированные для данного состояния.

```python
def start_callback(update, context):

    chat_id = update.effective_chat.id
    logger.info(f"{chat_id} sent /start")

    reply_message = f"Hello from bot!"
    reply_message += " Введите ваше имя:"
    
    update.message.reply_text(reply_message)
    
    **return ENTER_NAME**
```

Call-back для правильного имени (если пользователь ввел текст, который начинается с заглавной буквы и в нем только буквы, пробелы и тире).

```python
def valid_name(update, context):
  logger.info(f"valid_name got {update.message.text}")
  
  name = update.message.text
    
  update.message.reply_text(
        f'Привет {name}!\nВведите email.'
  )

  return ENTER_EMAIL
```

Хэндлер для имени в неправильном формате. Просим пользователя ввести имя снова, возвращаем диалог в состояние ввода имени:

```python
def invalid_name(update, context):
  logger.info(f"invalid_name got {update.message.text}")
  update.message.reply_text(
    'Кажется Вы ввели неправильное имя. '
    'Убедитесь, что Вы вводите имя и фамилию, которые должны должны начинаться с заглавной буквы. '
    'Пример: Андрей Петров'
  )
  return ENTER_NAME
```

Из этой точки только один выход - ввести правильное имя. Но если пользователь вместо этого забросил диалог, вызывается функция, определенная для состояния TIMEOUT:

```python
def timeout(update, context):
  update.message.reply_text(
    'Не дождался ввода. Запустите команду снова.',
    silent=True
  )

  return ConversationHandler.END
```

Она и заканчивает диалог, возвращая специальную константу `ConversationHandler.END`, равную -1. Опция `silent=True` означает, что на это сообщение не будет звукового оповещения.

Аналогично определяем вызовы для хэндлеров в состоянии ожидании ввода email. Только при успешном вводе email диалог заканчивается - функция должна  вернуть `ConversationHandler.END`.

### Данные диалога

Рассмотрим такую проблему. На первом шаге диалога пользователь вводит ФИО, на втором - емейл. Мы их берем из самих сообщений, присланных пользователем бота. Но если мы не сохранили куда-то ФИО, при выходе из функции `valid_name()` мы его потеряем - старые сообщения более недоступны. 

В Python-telegram-bot можно сохранять данные в контексте, который всегда передается в функцию callback. 
Данные можно хранить для пользователя в структуре (словаре) `context.user_data`. Например, так мы сохраним имя пользователя в `valid_name()`:

```python
context.user_data['name'] = update.message.text
```

А вот так его возьмем в `valid_email()`:

```python
name = context.user_data['name']
update.message.reply_text(f"Вы ввели: name={name}, email={email}")
```

Есть еще структуры:

* для чата - `context.chat_data`, 
* для бота - `context.bot_data` (по сути, глобальная переменная, доступная в любых чатах данного бота)

Не совсем понятна разница между user_data и chat_data, так как при общении с ботом у юзера всего один чат. Возможно, что понадобится для ботов, которые добавлены в группу.

Помните, контекст не сохраняется при остановке бота. Ценные данные надо хранить в БД, о чем следующая глава.

### Проблемы с диалогами

Диалог внутри диалога не запрещен, что неудобно. Не задавайте начало диалога с MessageHandler, как следствие. Только по командам.

## bot + Django ORM

Прикручиваем базу данных к боту. В простейшем виде, будем собирать в базу те данные, которые нам пользователь дал, то есть фио и имейл.

Мы рассмотрим простую реализацию. Однако при наличии времени, лучше всего абстрагировать базу данных от бота, чтобы можно было ее поменять на другую без изменения кода бота.

В дебри Django я углубляться тоже не буду. На сайте Django отличный [тьюториал](https://docs.djangoproject.com/en/4.0/intro/tutorial01/).

### Начало проекта Django

```bash
$  django-admin startproject botapp .
$  django-admin startapp botdb 
```

Делаем модель данных в файле botapp/botdb/models.py. Здесь сразу иллюстрирую создание и применение собственной модели User, так как нам хочется добавить в структуру User дополнительное поле - chat_id, в котором будем хранить id пользователя бота в телеграмме. Это надо делать сразу, так как в процессе эксплуатации нельзя просто так взять и поменять модель User. Это официальная рекомендация в [документации Django](https://docs.djangoproject.com/en/3.1/topics/auth/customizing/#using-a-custom-user-model-when-starting-a-project).

Класс Student тоже иллюстрирует использование нашего нового User. Это полезно, если у вас может быть несколько ролей у пользователя.

```python
from django.db import models

from django.contrib.auth.models import AbstractUser

# This is a custom user model, since we want to add a custom field - chat_id
class User(AbstractUser):
    chat_id = models.PositiveBigIntegerField(null=True, blank=True, unique=True)

# Student - we difine it since User may have many roles: Student, Teacher, Admin etc
class Student(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='student')
    name = models.CharField(max_length=100, blank=False, default='')
    email = models.CharField(max_length=100, blank=False, default='')
    def __str__(self):
        return f"{self.user.first_name} {self.user.last_name}"
```

Добавляем приложение в botapp/settings.py

```python
INSTALLED_APPS = [
    'django.contrib.admin',
...
    'imdb.apps.BotdbConfig',

]
```
Инициализируем базу данных. По умолчанию - sqlite - для нее в этот момент создается файл `sqlite.db`

```bash
$ python manage.py makemigrations
$ python manage.py migrate
```

### Запуск бота как административная команда Django

Само по себе приложение Django (с вебсайтом, админкой етс) нам не нужно, поэтому мы не будем запускать его командой `python manage.py runserver`, как в тьюториалах по Django.

Мы будем запускать бот административной командой. Для этого создайте файл bot.py в директории botdb/mangement/commands (эти папки придется создать)

Сначала импорты и прочее:

```python
import logging
import os

from django.core.management.base import BaseCommand
from django.conf import settings

from telegram.ext import Updater

# на этот раз у нас весь код диалога в отдельном файле start_conv.py
from bottg.start_conv import start_conv_handler

config_profile = 'dev'

logging_level = os.environ.get("DEBUG_LEVEL", "INFO")
logging.basicConfig(level=eval(f"logging.{logging_level}"),
                    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')

logger = logging.getLogger(config_profile)
```

Далее код для Django - определение команды.

```python
class Command(BaseCommand):
    help = "Telegram-bot"

    def handle(self, *args, **kwargs):

        tg_token = open('token_file').read()

        updater = Updater(token=tg_token, use_context=True) #, request_kwargs=REQUEST_KWARGS)

        dispatcher = updater.dispatcher

        dispatcher.add_handler(start_conv_handler)

        logger.info("Added handlers and now start polling")
        
        # Start_polling
        updater.start_polling()
```

Собственно код для этого диалога у нас уже есть, только теперь реализуем обработчик `valid_email()`, который должен загружать собранные данные в базу.

```python

def valid_email(update, context):

    email = update.message.text
    context.user_data['email'] = email

    return create_user(update, context)
```

Отделяем логику бота от БД (хотя бы так). Вместо возврата числа вызываем другую функцию, которая вернет число. Так же ниже используем функции-помощники, которые уменьшают количество boiler-plate кода: service_unavalable(), conv_end(). Они просто выдают соответсвующие собщения и возвращают ConversationHandler.END

```
def create_user(update, context):
    chat_id = update.effective_chat.id
    name = context.user_data['name']
    email = context.user_data['email']
    
    #check if the person is identified already
    #Or we just make sure it's created anyway
    user, created = User.objects.get_or_create(username=chat_id, chat_id=chat_id)

    # Something goes wrong in the infra. Return error message and end the dialog
    if user is None:
      return service_unavailable(update)

    # Check if already have such Student
    try:
      s = Student.objects.get(user_id=user.id)
    except MultipleObjectsReturned:
      # но по идее, тут не должны быть никогда, должны срабатывать условия уникальности `user` при создании объекта.
      pass
    except ObjectDoesNotExist:
      #создаем новый объект Student и сохраняем его.
      s = Student(user=user, name=name, email=email)
      s.save()
      response_msg = f"Спасибо за регистрацию! " 
      return conv_end(update, context, msg=response_msg)
    except:
      return service_unavailable(update)
```

Наконец, все готово для запуска бота:

`python manage.py bot`

## Элементы пользовательского интерфейса бота

Интерфейс бота довольно скудный, но в некоторых случаях это может дать приемущество. Например, это выравнивает шансы - можно сделать продукт без дизайнера и графики. Не нужно быть и знатоком проектирования UI и UX - легко понять у вас интерфейс плохой, неудобный или все ок с ним.

### Использование Mаrkdown

Чтобы приукрасить или отформатировать вывод, можно использовать язык разметки. Добавляем в опции для reply_message(): `parse_mode="MarkdownV2"`.

Смотри [описание](https://core.telegram.org/bots/api#markdownv2-style)

### Кнопки

Кнопки позволяют быстро взаимодействовать с ботом. 

#### Кнопки в чате (InlineKeyboardMarkup)

Кнопки интстанциируются классом InlineKeyboardButton 

```python
from telegram import ReplyKeyboardMarkup, InlineKeyboardMarkup, InlineKeyboardButton

cancel_button = InlineKeyboardButton("Cancel", callback_data='cancel')
show_host_fp_button = InlineKeyboardButton("Host fingerprints", callback_data='show_host_fp')
```

Они посылают боту строку callback_data, длиной до 64 байтов. Помните, что юникод - это два байта для кириллицы.

Далее кнопки собираются вместе:

`reply_markup = InlineKeyboardMarkup([show_host_fp_button, cancel_button])`

и передаются с ответом:

`update.message.reply_text('Chose:', reply_markup=reply_markup)`

Кнопки можно разместить и на нескольких строках:

`reply_markup = InlineKeyboardMarkup([[show_host_fp_button, reset_guest_pwd_button], [cancel_button]])`

На нажатие кнопки вызывается обработчик запросов Query Callback.

Он определяется следующим образом. В этом примере - для состояния LOGIN_ACTION:

```python
           LOGIN_ACTION: [
                CallbackQueryHandler(show_host_fp, pattern=r'^show_host_fp$'),
                CallbackQueryHandler(reset_guest_pwd, pattern=r'reset_guest_pwd'),
```

Функция `show_host_fp()` будет вызываться, когда пользователь нажмет на кнопку, у которой callback_data сматчится с pattern.

Неслучайно эти обработчики названы CallbackQueryHandler - обработка этих запросов отличается от обработки простых сообщений. Во-первых, данные запроса передаются в поле update.callback_query. Во-вторых, можно отредактировать текущее сообщение. Например, убрать кнопки. Для этого надо вызвать `query.answer()` и `query.edit_message_text()`:

```python
def show_host_fp(update, handler):
  query = update.callback_query
  query.answer()
  
  fp = generate_host_key_fingerprints()
  
  if not fp:
    fp = ['Что-то пошло не так']

  query.edit_message_text(
     "".join(fp)
  )
  return ConversationHandler.END
```

Заметим, что такое различие в синтаксисе вызывает некоторые неудобства в ботах с диалогами, где смешиваются и сообщения и кнопки.

#### Своя клавиатура (ReplyKeyboardMarkup)

Эта клавиатура "всплывает" вместо стандартной, и на ней можно определить свои клавиши. Нажатие этих клавиш просто отсылает сообщение в чат, то есть обработка производится обычными MessageHandler.

## Отладка и советы

Зарегистрируйте обработчик ошибок:

```python
def error(update, context):
    """Log Errors caused by Updates."""
    logger.warning('Update "%s" caused error "%s"', update, context.error)
    update.message.reply_text(
     'Ошибка. Начните снова.',
    silent=True
    )

    return ConversationHandler.END

dispatcher.add_error_handler(error)
```

Ошибки в боте, которые приводят к активации этого хендлера, особенно те, что выводят стек, надо чинить! Иначе бот может "зависнуть" для всех, или для конкретного пользователя, и его придется перезагружать.

Помещайте каждый диалог в свой файл.

Используйте функции-помощники для уменьшения boiler-plate кода.
