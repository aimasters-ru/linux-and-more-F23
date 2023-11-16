# Github Actions

Сначала разберем примеры, которые использовались в этом курсе и на приемном экзамене.

## Пример с автоматическим принятием Pull-request

https://github.com/datamove/practice-repo/blob/master/.github/workflows/automerge.yml

### Название workflow.

```yaml
name: automerge
```

Здесь определяется название workflow.

### Список триггеров

```
on:
  pull_request_target:
    types:
      - labeled
      - unlabeled
      - synchronize
      - opened
      - edited
      - ready_for_review
      - reopened
      - unlocked
    paths:
    - '*.py'
  status: {}
```

Задачи должны выполняться для все типов пул-реквестов, вернее даже, ситуаций из которых они появились, но только если они касаются файлов с расширением `.py`.

### Оределение задач

```yaml
jobs:
  automerge:
    runs-on: ubuntu-latest
```

Определяется задача automerge, которая выполняется в контейнере из образа ubuntu-latest. (Надо заметить, что это не vanilla образ из докер-хаба, а уже с заточенный для  Github Actions. Например там уже есть curl, git).

### Шаги задачи

Тут у нас единственный шаг под названием merge pull request, который вызывает метод merge гитхабовского REST API с помощью curl

```yaml
    steps:
      - name: merge pull request
        run: |
          curl \
          -X PUT \
          -H "Accept: application/vnd.github.v3+json" \
           --header 'authorization: Bearer ${{ github.token }}' \
          ${{ github.event.pull_request.url }}/merge \
          -d '{"commit_title":"automerging pr ${{github.event.pull_request.number }} for ${{ github.event.pull_request.user.login }}" }'
```

### Откуда я знаю, какие переменные там есть

Вот эти, типа `${{ github.event.pull_request.url }}`?

Это так называемый [контекст](https://docs.github.com/en/free-pro-team@latest/actions/reference/context-and-expression-syntax-for-github-actions#contexts). Структуры данных для [событий](https://docs.github.com/en/free-pro-team@latest/actions/reference/events-that-trigger-workflows) те же, что и для [webhooks](https://docs.github.com/en/free-pro-team@latest/developers/webhooks-and-events/about-webhooks), поэтому описываются в другом разделе документации. Например, для собтытия [pull_request](https://docs.github.com/en/free-pro-team@latest/developers/webhooks-and-events/webhook-events-and-payloads#pull_request)

### github.token

Это специальный авторизационный токен, который GitHub Actions предоставляем вам для работы Gihub API. Вы его не генерировали, вы его не увидите, но он есть. :)

### Секреты

`github.token` эквивалентен `${{ secrets.GITHUB_TOKEN }}`.

Секреты Гитхаба - это безопасное хранилище токенов и другой приватной информации, которая может использоваться в Actions. Например, токены OAuth самого Гитхаба или других сервисов, которые вы хотите интегрировасть с системой сборки (CI).

Секреты, которые начинаются с GITHUB_ создаются автоматически самим гитхабом. 

Секреты испольуются отдельно с каждым репо и создаются в Settings->Secrets.

## Пример с условным принятие Pull-request

https://github.com/datamove/linux-git2/blob/main/.github/workflows/checkmerge.yml

Определение задачи, событий, етс - точно такое же, не привожу его. Ничинаем со steps.

На первом шаге под названием `setup` мы клонируем слепок репо "соискателя" по состоянию на коммит "ref". Для этого используется [встроенное действие checkout версии v2](https://github.com/actions/checkout). Обратите внимание на опцию `fetch-depth: 0`. При значении 1 - только файлы на текущий коммит, а 0 - вся история коммитов (нужно для сравнения разницы в коммитах, например. Но с другой тороны, это можно как-то по другому сделать).

```yaml
      - name: setup
        uses: actions/checkout@v2
        with:
         ref: ${{github.event.pull_request.head.ref}}
         repository: ${{github.event.pull_request.head.repo.full_name}}
         fetch-depth: 0
 ```
 Далее, я проверяю, совпадает ли название вашей ветки с ником гитхаба, как требуется по условию задачи. В блоке `run` просто выполняются команды bash. Выводится ник, ветка, проверяется условие, и в случае невыполнения шаг завершается с кодом 1, и когда в шаге задан флаг `continue-on-error: false` это автоматически фейлит задачу - выполнение останавливается.
 
 ```yaml
      - name: check branch
        id: checkbranch
        continue-on-error: false
        run: |
          echo Github nick ${{ github.event.pull_request.user.login }}
          echo Branch ${{ github.event.pull_request.head.ref }}
          if [ "${{ github.event.pull_request.head.ref }}" != "${{ github.event.pull_request.user.login }}" ]
          then
            echo "Branch name is not the same as github nick"
            exit 1
          fi
```

Проверка заголовка пулл-реквеста делается аналогичным образом. Привожу тут только условия, а не код этих шагов целиком:

```bash
if [ "${{ github.event.pull_request.title }}" != "hw git2 ${{ github.event.pull_request.user.login }}" ]
if [ "${{ github.event.pull_request.commits }}" -ne 1 ]
if [ "${{ github.event.pull_request.changed_files }}" -ne 1 ]
```

Далее я запускаю ваш скрипт и сохраняю его вывод в переменную. Если скрипт не удается запустить (его нет или он неисполняемый), то выдается сообщение об ошибке и выполнение action прекращается. Если запуск скрипта прошел успешно, то его вывод сравниваеся с эталоном.

```yaml
      - name: run programm
        id: runprog
        continue-on-error: false
        run: |
          echo Running ./${{ github.event.pull_request.user.login }}.sh
          out=$(./${{ github.event.pull_request.user.login }}.sh)
          if [ $? -ne 0 ]; then 
           echo Could not run ./"${{ github.event.pull_request.user.login }}.sh"
           exit 1
          fi
          echo Output:${out}
          if [ "$out" != "Hello pull-request" ]; then
           echo Incorrect output $out
           exit 1
          fi
```

К этому шагу все проверки прошли успешно, и пулл-реквест мержится таким же образом, как и в первом примере с безусловным мерджем.

```yaml
      - name: merge pull request
        run: |
          curl \
          -X PUT \
          -H "Accept: application/vnd.github.v3+json" \
           --header 'authorization: Bearer ${{ secrets.GITHUB_TOKEN }}' \
          ${{ github.event.pull_request.url }}/merge \
          -d '{"commit_title":"automerging pr ${{github.event.pull_request.number }} for ${{ github.event.pull_request.user.login }}" }'
```          

## Пример с запуском задачи

Это пример с автозапуском решения со вступительного соревнования. Бот принимал файл, загружал его в репо, и питоновская программа или тетрадка запускалась с докер-образом Kaggle kernels.

Начало обычное - название этого workflow.

```yaml
name: run_solution
```

Далее новшество - секция `env` для определения переменных среды, используемых для дальнейших шагов. Я использую их для того, чтобы не использовать пути и названия в явном виде - делает повторное использование кода и его визуальное восприятие легче.

```yaml
env:
  WORKING: /home/ubuntu/working
  TRUE_ANS: /home/ubuntu/true/right_ans.csv
  PYTHON: /usr/bin/python3
  RUN_SOLUTION: ./run_solution.sh
  CALC_METRIC: ./calc_metric.py
```

Поскольку загрузка файла - это по сути событие push в ветку мастер, то мы так и определяем условие запуска workflow, с добавление фильтра по типам файлов.

```yaml 
on:
  push:
    branches: [ master ]
    paths: 
      - '*-*.py'
      - '*-*.ipynb'
```

Тут интересно - я запускаю задачу не на сервераз гитхаба, а на собственном сервере (виртуальной машине, на котороя я установил софт агента Gihub Actions). Так же я указываю предельное время выполнения задачи. По условию соревнования на прогон давалось 60 минут, тут дается фора на всякий случай.

```yaml
# A workflow run is made up of one or more jobs that can run sequentially or in parallel
jobs:
  run_solution:
    runs-on: [ self-hosted ]
    timeout-minutes: 70   
```
Задача начинается с клонирования репо

```yaml
    steps:
      - name: checkout
        uses: actions/checkout@v2
        with:
          fetch-depth: 0
```

Далее поиск файла, который поменялся от предыдущего коммита. Этот код можно заменить более подходящий, кажется в хуках должно быть отдельное поле для списка файлов в коммите). Обратите внимание на форму вывода найденных файлов, вернее префикс `echo "::set-output name=files::`. Такой префикс используется для сохранения какой-то информации между шагами. Потом увидите, как это используется.

```yaml
      - name: get changed files
        id: getchfile
        run: |
          echo "::set-output name=files::$(git diff-tree --no-commit-id --name-only -r ${{ github.sha }} | xargs)"
          echo ${{ steps.getchfile.outputs.files }}
```

В названии файла содержится название команды на Kaggle, выделим его. Тут используется переменная `${{ steps.getchfile.outputs.files }}` - как раз то, что было созранено на предыдущем шаге. На этом шаге создается и своя переменная.

```yaml
      - name: get the team
        id: team
        run: |
          SOURCE_BASE="${{ steps.getchfile.outputs.files }}"
          TEAM="${SOURCE_BASE%%-*}"
          echo $TEAM
          echo "::set-output name=name::$TEAM"
```          

Наконец запуск приложения. Запускается скрипт, путь к которому бьурется из переменной $RUN_SOLUTION, с агрументом-питоновским файлом или тетрадкой, которая запускается. Напомню, что `RUN_SOLUTION: ./run_solution.sh`, т.е. запускается файл из текущей директории. То есть из папка репо, так как текущая директория и есть папка репо, склонированная на первом шаге (setup).

```yaml
      - name: run the app
        id: run
        run: |
         $RUN_SOLUTION "${{ steps.getchfile.outputs.files }}"
         echo $?
```

По результатам прогона ищем файл submission.csv

```yaml
      - name: find output files
        id: getoutfile
        run: |
          out_files=$(find "$WORKING/${{ steps.team.outputs.name }}" -name submission.csv)
          echo FOUND $out_files
          echo "::set-output name=files::"$out_files
```

Запускаем вычисление метрики, используя ответы.

```yaml
      - name: evaluate the submission
        id: evaluate
        run: |
          echo $TRUE_ANS
          metrics=$($PYTHON $CALC_METRIC $TRUE_ANS "${{steps.getoutfile.outputs.files}}")
          echo $metrics
          echo "::set-output name=metrics::$metrics"
```

На последнем шаге добавляем строчку с вычисленным скором к файлу README.md, в котором таким образом сохраняется табличка с результатами всех участников. Заметьте, что 

```yaml
      - name: commit results
        run: |
          git pull
          echo "| ${{steps.team.outputs.name}} | | ${{steps.evaluate.outputs.metrics}}|" >> README.md
          git commit -m "added ${{ steps.team.outputs.name }} to results" README.md
          git push
```

### Самостоятельная работа

1. В вашем репо `linux-git1` сделайте Action, которое (действие - оно) создает issue с заголовком "Thanks for a pуthon script edit" на каждый пуш с файлом с расширением ".py".

2. Измените его так, чтобы заголовок был "Thanks for a new script" для вновь добавляемых файлов.

3. Добавьте запуск какого-то теста или линтера, и в случае ошибок вместо приветственного issue создавайте issue с заголовком "Test failed"


## Links

* [Events that trigger workflows](https://docs.github.com/en/free-pro-team@latest/actions/reference/events-that-trigger-workflows)
* [Context and expression syntax for github actions](https://docs.github.com/en/free-pro-team@latest/actions/reference/context-and-expression-syntax-for-github-actions)
