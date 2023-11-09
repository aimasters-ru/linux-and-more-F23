# Github REST API

## GET issues

```bash
$ curl -X GET https://api.github.com/repos/datamove/practice-repo/issues
[
  {
    "url": "https://api.github.com/repos/datamove/practice-repo/issues/57",
    "repository_url": "https://api.github.com/repos/datamove/practice-repo",
    "labels_url": "https://api.github.com/repos/datamove/practice-repo/issues/57/labels{/name}",
    "comments_url": "https://api.github.com/repos/datamove/practice-repo/issues/57/comments",
    "events_url": "https://api.github.com/repos/datamove/practice-repo/issues/57/events",
    "html_url": "https://github.com/datamove/practice-repo/pull/57",
    "id": 727358338,
    "node_id": "MDExOlB1bGxSZXF1ZXN0NTA4MjY1NDgy",
    "number": 57,
    "title": "add ekatkanovitka.sh",
    "user": {
      "login": "ekatkanovitka",
      "id": 60265043,
      "node_id": "MDQ6VXNlcjYwMjY1MDQz",
      "avatar_url": "https://avatars1.githubusercontent.com/u/60265043?v=4",
      "gravatar_id": "",
      "url": "https://api.github.com/users/ekatkanovitka",
      "html_url": "https://github.com/ekatkanovitka",
      "followers_url": "https://api.github.com/users/ekatkanovitka/followers",
      "following_url": "https://api.github.com/users/ekatkanovitka/following{/other_user}",
      "gists_url": "https://api.github.com/users/ekatkanovitka/gists{/gist_id}",
      "starred_url": "https://api.github.com/users/ekatkanovitka/starred{/owner}{/repo}",
      "subscriptions_url": "https://api.github.com/users/ekatkanovitka/subscriptions",
      "organizations_url": "https://api.github.com/users/ekatkanovitka/orgs",
      "repos_url": "https://api.github.com/users/ekatkanovitka/repos",
      "events_url": "https://api.github.com/users/ekatkanovitka/events{/privacy}",
      "received_events_url": "https://api.github.com/users/ekatkanovitka/received_events",
      "type": "User",
      "site_admin": false
    },
    "labels": [

    ],
    "state": "open",
    "locked": false,
    "assignee": null,
    "assignees": [

    ],
    "milestone": null,
    "comments": 0,
    "created_at": "2020-10-22T12:48:06Z",
    "updated_at": "2020-10-22T12:48:06Z",
    "closed_at": null,
    "author_association": "NONE",
    "active_lock_reason": null,
    "pull_request": {
      "url": "https://api.github.com/repos/datamove/practice-repo/pulls/57",
      "html_url": "https://github.com/datamove/practice-repo/pull/57",
      "diff_url": "https://github.com/datamove/practice-repo/pull/57.diff",
      "patch_url": "https://github.com/datamove/practice-repo/pull/57.patch"
    },
    "body": "",
    "performed_via_github_app": null
  }
]
```

Заметьте, что вернулся массив. По умолчанию, выдаются только открытые тикеты и пулл-реквесты. Можно передать параметер для выбора статуса тикета

```bash
$ curl -X GET https://api.github.com/repos/datamove/practice-repo/issues?state=closed
```

Отфильтруем записи с помощью jq:

```bash
$ curl https://api.github.com/repos/datamove/practice-repo/issues?state=closed | jq '.[].title'  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100 75050  100 75050    0     0   295k      0 --:--:-- --:--:-- --:--:--  295k
"added kadetfrolov.py"
"added aliya_khabirzyanova.py"
"added file oleg_shulgin.py"
"added dmitry_kalinin.py"
"added hethwynq.py"
...
```

Самое время убрать progress-bar. Используйте -s. 


#### Спецификация https://developer.github.com/v3/issues/#list-repository-issues

## POST an issue

reference - https://developer.github.com/v3/issues/#create-an-issue

```bash
$ curl -X POST https://api.github.com/repos/datamove/practice-repo/issues
{
  "message": "Not Found",
  "documentation_url": "https://docs.github.com/rest/reference/issues#create-an-issue"
}
```

Как же так? На самом деле, мы с этим уже встречались - требуется аутентификация.

### Get a token

Залогиньтесь на сайт github.com, в верхнем углу около вашей иконки разверните меню и выберите Settings (это глобальные настройки). Далее выберите Developer settings, Personal access tokens. Нажмите Generate new token.

![rest-repo-token-create.png](img/rest-repo-token-create.png)

Скопируйте сгенерированный токен в буфер и вставьте в файл public_repo_token под вашим аккаунтом на сервере и сохраните файл.

Тут же ограничьте доступ к этому файлу:

`chmod 600 public_repo_token`

### token в заголовке
```
$ H2="Authorization: token "`cat public_repo_token`
$ echo $H2
Authorization: token xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```
(вместо иксов вы должны увидеть ваш токен)

### Используем заголовок в запросе

```bash
$ curl -X POST -H "$H2"  https://api.github.com/repos/datamove/practice-repo/issues
{
  "message": "Invalid request.\n\nFor 'links/0/schema', nil is not an object.",
  "documentation_url": "https://docs.github.com/rest/reference/issues#create-an-issue"
}
```

Тут тоже все понятно, мы ведь никаких данных для тикета не отправили. Добавляем данные - объект json с полями title, body.

```bash
$ curl -X POST -H "$H2" https://api.github.com/repos/datamove/practice-repo/issues -d '{"title":"test issue from datamove", "body": "yep, just a test!"}'
{
  "url": "https://api.github.com/repos/datamove/practice-repo/issues/63",
  "repository_url": "https://api.github.com/repos/datamove/practice-repo",
  "labels_url": "https://api.github.com/repos/datamove/practice-repo/issues/63/labels{/name}",
  "comments_url": "https://api.github.com/repos/datamove/practice-repo/issues/63/comments",
  "events_url": "https://api.github.com/repos/datamove/practice-repo/issues/63/events",
  "html_url": "https://github.com/datamove/practice-repo/issues/63",
  "id": 734609678,
  "node_id": "MDU6SXNzdWU3MzQ2MDk2Nzg=",
  "number": 63,
  "title": "test issue from datamove",
  "user": {
    "login": "artemtrunov",
    "id": 69344942,
    "node_id": "MDQ6VXNlcjY5MzQ0OTQy",
    "avatar_url": "https://avatars1.githubusercontent.com/u/69344942?v=4",
    "gravatar_id": "",
    "url": "https://api.github.com/users/artemtrunov",
    "html_url": "https://github.com/artemtrunov",
    "followers_url": "https://api.github.com/users/artemtrunov/followers",
    "following_url": "https://api.github.com/users/artemtrunov/following{/other_user}",
    "gists_url": "https://api.github.com/users/artemtrunov/gists{/gist_id}",
    "starred_url": "https://api.github.com/users/artemtrunov/starred{/owner}{/repo}",
    "subscriptions_url": "https://api.github.com/users/artemtrunov/subscriptions",
    "organizations_url": "https://api.github.com/users/artemtrunov/orgs",
    "repos_url": "https://api.github.com/users/artemtrunov/repos",
    "events_url": "https://api.github.com/users/artemtrunov/events{/privacy}",
    "received_events_url": "https://api.github.com/users/artemtrunov/received_events",
    "type": "User",
    "site_admin": false
  },
  "labels": [

  ],
  "state": "open",
  "locked": false,
  "assignee": null,
  "assignees": [

  ],
  "milestone": null,
  "comments": 0,
  "created_at": "2020-11-02T15:42:17Z",
  "updated_at": "2020-11-02T15:42:17Z",
  "closed_at": null,
  "author_association": "CONTRIBUTOR",
  "active_lock_reason": null,
  "body": "yep, just a test!",
  "closed_by": null,
  "performed_via_github_app": null
}
```

Теперь можно снова посмотреть тикеты и найти там вновь созданный. Сразу отфильтруем собственные тикеты (подставьте ваш ник вместо artemtrunov):

`$ curl -X GET  https://api.github.com/repos/datamove/practice-repo/issues?creator=artemtrunov`

## Изменяем тикет 

Reference- https://developer.github.com/v3/issues/#update-an-issue

```bash
$ curl -X PATCH -H "$H2" https://api.github.com/repos/datamove/practice-repo/issues/63 -d '{"title":"Patched test issue from datamove", "body": "yep, just a test!"}'
{
  "url": "https://api.github.com/repos/datamove/practice-repo/issues/63",
  "repository_url": "https://api.github.com/repos/datamove/practice-repo",
  "labels_url": "https://api.github.com/repos/datamove/practice-repo/issues/63/labels{/name}",
  "comments_url": "https://api.github.com/repos/datamove/practice-repo/issues/63/comments",
  "events_url": "https://api.github.com/repos/datamove/practice-repo/issues/63/events",
  "html_url": "https://github.com/datamove/practice-repo/issues/63",
  "id": 734609678,
  "node_id": "MDU6SXNzdWU3MzQ2MDk2Nzg=",
  "number": 63,
  "title": "Patched test issue from datamove",
  "user": {
    "login": "artemtrunov",
...
```

## Удаляем

```bash
$ curl -X DELETE -H "$H2" https://api.github.com/repos/datamove/practice-repo/issues/63
{
  "message": "Not Found",
  "documentation_url": "https://docs.github.com/rest"
}

```

Опять!! Тут дело в том, что гитхаб не дает возможность удалять через API. 
Но можно изменить статус на `Closed` запросом PATCH.

### Используем curl в скриптах

* -i выводить заголовок HTTP-ответа и само сообщение (payload)
* -I выводить только заголовок HTTP-ответа 
* -s - не печатать progress bar
* -f (--fail) - выходить с ненулевым кодом
* -S выводить ошибки при ошибках
* -sw '%{http_code}' - выводить только статус-код запроса

## Как же все таки удадить issue? GraphQL

Это пока еще экспериментальное api v4. Довольно спорное.

Нам понадобится не просто номер тикета 63, а идентификатор узла этого тикета, видимо где-то в глобальном графе ресурсов. В принципе, он есть и в выводе результата вызова API v3, который мы делали до этого: `"node_id": "MDU6SXNzdWU3MzQ2MDk2Nzg=",`, но мы попробуем и аналог GET запроса на GraphQL.

Сразу обратите внимание, что даже запрос на чтение в GraphQL - это POST запрос!!

```bash
curl -X POST -H "$H2" https://api.github.com/graphql -d '{"query": "query FindIssueID {repository(owner: \"datamove\", name: \"practice-repo\") {issue(number:63){id}}}"}'
{"data":{"repository":{"issue":{"id":"MDU6SXNzdWU3MzQ2MDk2Nzg="}}}}
```

```
query FindIssueID {
   repository(owner: \"datamove\", name: \"practice-repo\") {
      issue(number:63){id}
   }
}
```
FindIssueID - просто идентификатор запроса, может быть любым

Удаляем с помощью mutation.

```bash
$ curl -X POST -H "$H2" https://api.github.com/graphql -d '{"query": "mutation { deleteIssue(input:{issueId:\"MDU6SXNzdWU3MzQ2MDk2Nzg=\"}) { repository {name}} }" }'
{"data":{"deleteIssue":null},"errors":[{"type":"FORBIDDEN","path":["deleteIssue"],"locations":[{"line":1,"column":12}],"message":"artemtrunov does not have the correct permissions to execute `DeleteIssue`"}]}
```
```
mutation { 
  deleteIssue(input:{issueId:\"MDU6SXNzdWU3MzQ2MDk2Nzg=\"}) { 
     repository {name}
  } 
}
```

Из документации:

_Deleting an issue_

_People with admin permissions in a repository can permanently delete an issue from a repository.
Did this doc help you?_

_You can only delete issues in a repository owned by your user account. You cannot delete issues in a repository owned by another user account, even if you are a collaborator there._

Как и обещала документация, только хозяин репо может удалить тикеты. С токеном хозяина репо:

```bash
$ curl -X POST -H "$H2" https://api.github.com/graphql -d '{"query": "mutation { deleteIssue(input:{issueId:\"MDU6SXNzdWU3MzQ2MDk2Nzg=\"}) { repository {name}} }" }'
{"data":{"deleteIssue":{"repository":{"name":"practice-repo"}}}}
```

Удалил? Проверяем:

```bash
artem@artem-ubuntu2:/media/data/ozon$ curl -X POST -H "$H2" https://api.github.com/graphql -d '{"query": "query FindIssueID {repository(owner: \"datamove\", name: \"practice-repo\") {issue(number:63){id}}}"}'
{"data":{"repository":{"issue":null}},"errors":[{"type":"NOT_FOUND","path":["repository","issue"],"locations":[{"line":1,"column":74}],"message":"Could not resolve to an Issue with the number of 63."}]}
```
### Ссылки на доки по GraphQL

* https://docs.github.com/en/free-pro-team@latest/graphql/reference/mutations#deleteissue
* https://developer.github.com/v4/guides/forming-calls/#example-mutation

## Удалите токен  через тут же страницу девелоперских настроек, от греха подальше!
