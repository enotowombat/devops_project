[![Build Status](https://travis-ci.org/enotowombat/devops_project.svg?branch=master)](https://travis-ci.org/enotowombat/devops_project)

# DevOps Course Project
# CI/CD for Search Engine application

Search Engine - поисковая машина для сбора текстовой информации с веб-страниц и ссылок, состоит из [индексирующего бота](https://github.com/enotowombat/search_engine_crawler) и [веб-интерфейса](https://github.com/enotowombat/search_engine_ui) для поиска слов и фраз


## Project Environment

- Проект разворачивается в [Google Cloud Platform](https://cloud.google.com/) 
- Приложения работают в [Docker](https://www.docker.com/) контейнерах
- Оркестрация [Kubernetes engine](https://cloud.google.com/kubernetes-engine/) 
- Компоненты собраны в виде [Helm](https://helm.sh/) пакетов (charts)
- CI/CD организован с помощью [Gilab-CI](https://docs.gitlab.com/ee/ci/README.html)
- [Prometheus](https://prometheus.io/) monitoring system
- [Grafana](https://grafana.com/) monitoring visualization
- [Elasticsearch](https://www.elastic.co/products/elasticsearch) search and analytics engine
- [Fluentd](https://www.fluentd.org/) logs collector
- [Kibana](https://www.elastic.co/products/kibana) logs visualization
- Окружение готовится с помощью [Ansible](https://www.ansible.com/)
- В директории `gilab_ci` находится код приложений, их Dockerfiles, чарты и настройки gitlab-ci пайплайнов. Пайплайны выполняются после push в gilab репозитории. Также здесь хранится Dockerfile для mongodb-exporter, образ собирается один раз при инициализации Gitlab CI, в дальнейшем не меняется
- В директории `kubernetes` находятся плейбуки для настройки k8s кластра (в директории `ansible`), чарты общих компонентов инфраструктуры, разворачиваемых вне пайплайнов gitlab-ci. Также оставлены чарты приложений, но в CI/CD не используются
- В директории `grafana dashboards` находятся дашборды grafana
- Директория `docker` присутствует для возможности развернуть приложения с помощью docker compose из образов, сохраненных в репозитории, для этого нужно переименовать .env.example в .env и поменять `USER_NAME`


### Prerequisites

- Для установки окружения требуется Linux хост со следующими установленными компонентами:
[Google Cloud SDK](https://cloud.google.com/sdk/downloads)
[Ansible](http://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)
[Kubuectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
[Helm](https://docs.helm.sh/using_helm/#quickstart)
- Требуется [Docker Hub](https://hub.docker.com/) аккаунт
- Требуется Google Cloud аккаунт с созданным проектом

## Get Started

### Run `install.sh`
- Создается k8s кластер
- Инициализируется Helm
- Устанавливается Gitlab-CI
- Устанавливается Prometheus
- Устанавливается Grafana
- Устанавливается Elasticsearch 
- Устанавливается Fluentd
- Устанавливается Kibana

Параметры создания k8s кластера задаются в `kubernetes/ansible/inventory/group_vars/all`:
Variable|Default Value
-|-
gcp_project | your_project
cluster_name | cluster-1
zone | europe-west1-b
machine_type | n1-standard-1
disk_size | 10
num_nodes | 5

Работоспособность проекта проверялась с параметрами по умолчанию
##### Важно: gcp_project должен быть изменен на свой
Остальные параметры можно поменять в плейбуке ansible, но не рекомендуется

После завершения работы скрипта компонентам нужно несколько минут для старта

`cleanup.sh` удаляет k8s кластер. Persistant диски, loadbalancer'ы остаются, удаление вручную

После запуска окружения требуется ручная донастройка некоторых компонентов


### Manual Configuration

#### Gitlab-CI Configration

#### Ограничение: используются динамические public IP, DNS не настраивается, трансляция имен в адреса выполнятся вручную в `hosts` на локальных машинах

- Получите  EXTERNAL_IP для prom-prometheus-server и nginx: `$ kubectl get service --all-namespaces=true` 
- Добавьте в `hosts` полученные IP (на машине, где запускаются скрипты и где запускается браузер):
nginx IP: gitlab-gitlab search-engine-staging search-engine-production search-engine-review search-engine-kibana search-engine-grafana
prom-prometheus-server IP: prometheus
- Зайдите на http://gitlab-gitlab
- Поставтье собственный пароль
- Зайдите под пользователем root и новым паролем
- Создайте public группу, в качестве имени введите свой Docker ID
- Создайте 3 public проекта именно в таком порядке: se_ui, se_crawler, search-engine
- Добавьте триггер в настройках проекта search-engine. Settings -> CI/CD -> Pipeline triggers. Скопируйте токен
- В настройках группы выберите пункт CI/CD
- Добавьте переменную CI_TOKEN, значение = скопированный ранее токен
- Добавьте переменные: CI_REGISTRY_USER - свой Docker ID, CI_REGISTRY_PASSWORD - пароль от Docker Hub
- Запустите `gitlab_init.sh`
Нужно будет интерактивно ввести следующие параметры:
```
Docker Hub Username
Docker Hub Password
Gitlab CI Username
Gitlab CI Password
```
Будут инициализированы локальные копии Gitlab репозиториев приложений, commit и push приложений, сборка образа mongodb-exporter и push его в Docker Hub
Запустятся пайплайны всех проектов
Проверьте, что пайплайны отработали

#### Grafana Configration

Зайдите на http://search-engine-grafana
User/Password по умолчанию admin/admin
После логина нужно:
- сделать Add data source - > Type = Prometheus URL =  http://prom-prometheus-server
- импортировать дашборды
Дашборды находятся в [grafana dashboards](), их нужно импортировать в grafana: Import/Upload .json File

#### Alertmanager Configration

Alermanager настраиватся в `kubernetes/charts/prometheus/custom_values.yml`
- Для оповещения в slack нужно создать web hook и добавить его url в параметр `slack_api_url`, название канала добавить в параметр `channel`
- Правила для нотификаций настраиваются в секции `alerts`. По умолчанию настроено два правила, для контроля доступности API сервера и нод кластера: `APIServerDown` и `NodeUnavailable`

#### Kibana Configration

Зайдите на http://search-engine-kibana
Создайте шаблон индекса 
`Index name or pattern: fluentd-*`

## Working With Project

### CI/CD 

#### Components Pipeline (Crawler, UI)

`Build`. Собирается Docker образ приложения, выкладывается в Docker Hub репозиторий
`Test`. Выполняются тесты приложения
`Release`. Проставляет версию релиза тегом docker образа, запускает пайплайн общего проекта - деплой на staging
`Review`. По кнопке разворачивается временное окружение для ревью бранча (для master review отсутствует). URL всегда http://review - ограничение из-за отсутствия DNS. Удаляется тоже по нажатию кнопки

#### Search Engine Project Pipeline

`Test`. Заглушка. Тесты проходят компоненты отдельно
`Staging`. Деплой на Staging environment для прохождения ручного тестирования
`Production`. Деплой в Production, выполняется нажатием кнопки по результатам проверки на Staging. В случае неудачного деплоя можно сделать Rollback релиза на предыдущую версию, выполняется по кнопке

Количество экземпляров приложений настраивается для каждого окружения в `gitlab_ci/search-engine/.gitlab-ci.yml`

staging:
Variable  Default Value
UI_REPLICAS  1
CRAWLER_REPLICAS  1

production:
Variable  Default Value
UI_REPLICAS  2
CRAWLER_REPLICAS  2

### Monitoring

#### Metrics

##### UI
web_pages_served - количество обработанных запросов
web_page_gen_time - время генерации веб-страниц, учитывая время обработки запроса

##### Crawler
crawler_pages_parsed - количество обработанных ботом страниц
crawler_site_connection_time - время затраченное ботом на подключение к веб-сайту и загрузку веб-страницы
crawler_page_parse_time - время затраченное ботом на обработку содержимого веб-страницы

#### Prometheus 

Exporters:
`Mongodb exporter`
`RabbitMQ exporter`

Targets:
```
Kubernetes-apiservers
Kubernetes-nodes
Kubernetes-pods
Kubernetes-services-endpoints
Mongo-endpoints
Rabbit-endpoints
UI-endpdoints
Crawler-endpoints
Prometheus
```

#### Grafana
 
Dashboards:

#### UI_Monitoring
Web page generation time 95th percentile
Web page HTTP requests
Rate of UI HTTP requests with error

#### Crawler_Monitoring
Crawler site connection time 95th percentile
Crawler page parse time 95th percentile
Crawler site connection HTTP requests
Crawler page parse requests
Rate of crawler page parse requests with error
Rate of crawler site connection requests with error

#### Search_Engine_Business_Logic_Monitoring
Web pages served
Crawler page parse requests

#### Kubernetes cluster monitoring (via Prometheus)
Network I/O pressure, Total usage, Pods CPU usage, System services CPU usage, Containers CPU usage, All processes CPU usage, Pods memory usage, System services memory usage, Containers memory usage, All processes memory usage, Pods network I/O, Containers network I/O, All processes network I/O


### Alerting

Использутся Alermanager 
Alermanager настраиватся в `kubernetes/charts/prometheus/custom_values.yml`
- Для оповещения в slack нужно создать web hook и добавить его url в параметр `slack_api_url`, название канала добавить в параметр `channel`
- Правила для нотификаций настраиваются в секции `alerts`. По умолчанию настроено два правила, для контроля доступности API сервера и нод кластера: `APIServerDown` и `NodeUnavailable`

### Logging 

Логи приложений можно найти поиском по `ui` и `crawler`. Fluentd парсит json логи приложений, передаваемые параметры можно смотреть отдельно.
