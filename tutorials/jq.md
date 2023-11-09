# jq

В этом примере используется датасет из каталога товаров Amazon. Скачайте (wget)

`http://deepyeti.ucsd.edu/jianmo/amazon/metaFiles/meta_Luxury_Beauty.json.gz`

и разархивируйте

`gunzip meta_Luxury_Beauty.json.gz`

## jq - форматирование

Без опций и аргументов используется для форматирования json.

```bash
$ cat meta_Luxury_Beauty.json | head -2 | jq
{
  "category": [],
  "tech1": "",
  "description": [
    "If you haven't experienced the pleasures of bathing in the Dead Sea, Bath Crystals are the next best thing. Rich in health-inducing minerals including magnesium, calcium, sodium, potassium and more, they soothe your body with relaxation, easing muscle tension and softening your skin. Immerse yourself in the waters of well-being."                              
  ],
  "fit": "",
  "title": "AHAVA Bath Salts",
  "also_buy": [],
  "image": [],
  "tech2": "",
  "brand": "",
  "feature": [],
  "rank": "1,633,549 in Beauty & Personal Care (",
  "also_view": [],
  "details": {
    "\n    Product Dimensions: \n    ": "3 x 3.5 x 6 inches ; 2.2 pounds",
    "Shipping Weight:": "2.6 pounds",
    "Domestic Shipping: ": "Item can be shipped within U.S.",
    "International Shipping: ": "This item is not eligible for international shipping.",
    "ASIN:": "B0000531EN",
    "Item model number:": "017N"
  },
  "main_cat": "Luxury Beauty",
  "similar_item": "",
  "date": "",
  "price": "",
  "asin": "B0000531EN"
}
```

## jq - фильтр

### .

Точка - это текущая запись, или вернее, указатель на ее начало (корень)

### Взять индивидуальное поле

```bash
$ cat meta_Luxury_Beauty.json | head -2 | jq '.title'
"Crabtree &amp; Evelyn - Gardener's Ultra-Moisturising Hand Therapy Pump - 250g/8.8 OZ"
"AHAVA Bath Salts"
```

Так же точно выбираются и объекты (словари)

```bash
$ cat meta_Luxury_Beauty.json | head -2 | jq '.details'
{
  "\n    Product Dimensions: \n    ": "2.2 x 2.2 x 7 inches ; 8.8 ounces",
  "Shipping Weight:": "14.4 ounces (",
  "Domestic Shipping: ": "Item can be shipped within U.S.",
  "International Shipping: ": "This item can be shipped to select countries outside of the U.S.",
  "ASIN:": "B00004U9V2",
  "Item model number:": "4113"
}
{
  "\n    Product Dimensions: \n    ": "3 x 3.5 x 6 inches ; 2.2 pounds",
  "Shipping Weight:": "2.6 pounds",
  "Domestic Shipping: ": "Item can be shipped within U.S.",
  "International Shipping: ": "This item is not eligible for international shipping.",
  "ASIN:": "B0000531EN",
  "Item model number:": "017N"
}
```

или поля объектов:

```bash
$ cat meta_Luxury_Beauty.json | head -2 | jq '.details."Shipping Weight:"'
"14.4 ounces ("
"2.6 pounds"
```

заметьте кавычки для строк с пробелами и другими символами (например, двоеточие)

### Сделать новые json-записи

```bash
$ cat meta_Luxury_Beauty.json | head -2 | jq '{title, ship_weight:.details."Shipping Weight:" }'
{
  "title": "Crabtree &amp; Evelyn - Gardener's Ultra-Moisturising Hand Therapy Pump - 250g/8.8 OZ",
  "ship_weight": "14.4 ounces ("
}
{
  "title": "AHAVA Bath Salts",
  "ship_weight": "2.6 pounds"
}
```

Заметьте, что если не меняем название поля, то можно сократить `title:.title` до `title`.

### Сделать новые json-записи из комбинации полей

```bash
$ cat meta_Luxury_Beauty.json | head -2 | jq '{title:(.main_cat + " - " + .title), ship_weight:.details."Shipping Weight:" }'
{
  "title": "Luxury Beauty - Crabtree &amp; Evelyn - Gardener's Ultra-Moisturising Hand Therapy Pump - 250g/8.8 OZ",
  "ship_weight": "14.4 ounces ("
}
{
  "title": "Luxury Beauty - AHAVA Bath Salts",
  "ship_weight": "2.6 pounds"
}
```

## Последовательность фильтров

Как и в баше, можно сделать конвеер с помощью |

```bash
$ cat meta_Luxury_Beauty.json | head -2 | jq '.details | ."Shipping Weight:"'
"14.4 ounces ("
"2.6 pounds"
```

Это ничем не отличается от `jq '.details."Shipping Weight:"'`, но далее другие примеры.

```bash
$ cat meta_Luxury_Beauty.json | head -2 | jq '.details | "ASIN", ."Shipping Weight:" '
"ASIN"
"14.4 ounces ("
"ASIN"
"2.6 pounds"
```

```bash
$ cat meta_Luxury_Beauty.json | head -2 | jq '.details | { ASIN:."ASIN:", ship_weight:."Shipping Weight:" } '
{
  "ASIN": "B00004U9V2",
  "ship_weight": "14.4 ounces ("
}
{
  "ASIN": "B0000531EN",
  "ship_weight": "2.6 pounds"
}
```

Работает так же "внутри" нового словаря:

```bash
$ cat meta_Luxury_Beauty.json | head -2 | jq '{asin, ship_weight:.details."Shipping Weight:" | sub("pounds"; "p.") | sub("ounces"; "ou.") }'
{
  "asin": "B00004U9V2",
  "ship_weight": "14.4 ou. ("
}
{
  "asin": "B0000531EN",
  "ship_weight": "2.6 p."
}
```

Разделитель _запятая_ имеет приоритет перед разделителем _палка_. Но можно (и даже полезно для наглядности) использовать группировку:

```bash
$ cat meta_Luxury_Beauty.json | head -2 | jq '{asin, ship_weight:(.details."Shipping Weight:" | sub("pounds"; "p.") | sub("ounces"; "ou.")) }'
```

### Работа с массивами

Обращение к массиву осуществляется посредством скобок []

```bash
$ cat meta_Luxury_Beauty.json | head -2 | jq '.also_buy[0]'
"B00GHX7H0A"
null
```

или

```bash
$ cat meta_Luxury_Beauty.json | head -2 | jq '.also_buy | .[0]'
"B00GHX7H0A"
null

```

Cрез массива: `.[2:4]`

`massive[].field` - все поля field элементов массива

Длина массива

```bash
$ cat meta_Luxury_Beauty.json | head -2 | jq '.also_buy|length'
32
0
```

Сделать что угодно с елементами массива:

```bash
datamove@linux1:~$ cat meta_Luxury_Beauty.json | head -2 | jq '.also_buy | map("asin_" + .)'
[
  "asin_B00GHX7H0A",
  "asin_B00FRERO7G",
  "asin_B00R68QXCS",
...
```

### Модификация полей

Очень часто надо просто заменить значения наскольких полей. Достигается знаком присвоения =.

```bash
$ cat meta_Luxury_Beauty.json | head -2 | jq '.details."Shipping Weight:"=(.details."Shipping Weight:" | sub("pounds"; "p.") | sub("ounces"; "ou."))'
```

Или завести новые поля:

```bash
$ cat meta_Luxury_Beauty.json | head -2 | jq '.rating=4.5' | tail -5
  "date": "",
  "price": "",
  "asin": "B0000531EN",
  "rating": 4.5
}
```

Или удалить какие-то:

```bash
$ cat meta_Luxury_Beauty.json | head -2 | jq '.rating=4.5 | del(.date)' | tail -5
  "similar_item": "",
  "price": "",
  "asin": "B0000531EN",
  "rating": 4.5
}
```

также работает и объединенное присваивание: `|= += -= *= /= %= //=`


## Логические выражения

```bash
$ cat meta_Luxury_Beauty.json | head -2 | jq '.asin=="B0000531EN"'
false
true
```

#### Выбор записей на основе логического выражения

```bash
$ cat meta_Luxury_Beauty.json | head -2 | jq 'select(.asin=="B0000531EN") | .asin'
"B0000531EN"
```

Но это не всегда так просто, иногда нужна промежуточная переменная:

`([ .[].number ] | min) as $m | map(select(.number== $m))`

Впрочем, выбирать элемент массива по min,max какого-то поля можно и с помощью встроенной функции:

`max_by(.asin)`

### Функции

* со строками

startswith("foo") endswith("foo") length ascii_upcase ascii_downcase sub("x", "y") gsub("x", "y")

tonumber->number split->array index("string")->number

test - регулярное выражение
capture - вернуть сматченные значения

* с числами

exp log sin cos tan asin acos atan floor sqrt

tostring->string

* с массивами

sort reverse unique contains inside

length,map,group,reduce, min, max

`echo '[1,2,3,4]'| jq 'reduce .[] as $item (0; .+$item)'`

all, any, flaten

join->string

* с датами

now gmtime todate mktime

string->strptime

strftime->string


## А так же

* циклы
* if then else
* обработка исключений
* определение функций
* определение переменных
* использование функций из библиотек
* определение типа данных
* экспорт в другие форматы (csv, base64, URL quoting ...)

## Ссылки

* https://hyperpolyglot.org/json - компактный справочник
* https://stedolan.github.io/jq/manual/ - полное руководство

