

#  Дипломная работа по профессии «Системный администратор» SYS-25 Копаческу Владимир

Содержание
==========
* [Задача](#Задача)
* [Инфраструктура](#Инфраструктура)
    * [Сайт](#Сайт)
    * [Мониторинг](#Мониторинг)
    * [Логи](#Логи)
    * [Сеть](#Сеть)
    * [Резервное копирование](#Резервное-копирование)
    * [Дополнительно](#Дополнительно)
* [Выполнение работы](#Выполнение-работы)
* [Критерии сдачи](#Критерии-сдачи)
* [Как правильно задавать вопросы дипломному руководителю](#Как-правильно-задавать-вопросы-дипломному-руководителю) 

---------

## Задача
Ключевая задача — разработать отказоустойчивую инфраструктуру для сайта, включающую мониторинг, сбор логов и резервное копирование основных данных. Инфраструктура должна размещаться в [Yandex Cloud](https://cloud.yandex.com/) и отвечать минимальным стандартам безопасности: запрещается выкладывать токен от облака в git. Используйте [инструкцию](https://cloud.yandex.ru/docs/tutorials/infrastructure-management/terraform-quickstart#get-credentials).

**Перед началом работы над дипломным заданием изучите [Инструкция по экономии облачных ресурсов](https://github.com/netology-code/devops-materials/blob/master/cloudwork.MD).**

## Инфраструктура
Для развёртки инфраструктуры используйте Terraform и Ansible.  

Не используйте для ansible inventory ip-адреса! Вместо этого используйте fqdn имена виртуальных машин в зоне ".ru-central1.internal". Пример: example.ru-central1.internal  

Важно: используйте по-возможности **минимальные конфигурации ВМ**:2 ядра 20% Intel ice lake, 2-4Гб памяти, 10hdd, прерываемая. 

**Так как прерываемая ВМ проработает не больше 24ч, перед сдачей работы на проверку дипломному руководителю сделайте ваши ВМ постоянно работающими.**

Ознакомьтесь со всеми пунктами из этой секции, не беритесь сразу выполнять задание, не дочитав до конца. Пункты взаимосвязаны и могут влиять друг на друга.

### Сайт
Создайте две ВМ в разных зонах, установите на них сервер nginx, если его там нет. ОС и содержимое ВМ должно быть идентичным, это будут наши веб-сервера.

Используйте набор статичных файлов для сайта. Можно переиспользовать сайт из домашнего задания.

Создайте [Target Group](https://cloud.yandex.com/docs/application-load-balancer/concepts/target-group), включите в неё две созданных ВМ.

Создайте [Backend Group](https://cloud.yandex.com/docs/application-load-balancer/concepts/backend-group), настройте backends на target group, ранее созданную. Настройте healthcheck на корень (/) и порт 80, протокол HTTP.

Создайте [HTTP router](https://cloud.yandex.com/docs/application-load-balancer/concepts/http-router). Путь укажите — /, backend group — созданную ранее.

Создайте [Application load balancer](https://cloud.yandex.com/en/docs/application-load-balancer/) для распределения трафика на веб-сервера, созданные ранее. Укажите HTTP router, созданный ранее, задайте listener тип auto, порт 80.

Протестируйте сайт
`curl -v <публичный IP балансера>:80` 

### Мониторинг
Создайте ВМ, разверните на ней Zabbix. На каждую ВМ установите Zabbix Agent, настройте агенты на отправление метрик в Zabbix. 

Настройте дешборды с отображением метрик, минимальный набор — по принципу USE (Utilization, Saturation, Errors) для CPU, RAM, диски, сеть, http запросов к веб-серверам. Добавьте необходимые tresholds на соответствующие графики.

### Логи
Cоздайте ВМ, разверните на ней Elasticsearch. Установите filebeat в ВМ к веб-серверам, настройте на отправку access.log, error.log nginx в Elasticsearch.

Создайте ВМ, разверните на ней Kibana, сконфигурируйте соединение с Elasticsearch.

### Сеть
Разверните один VPC. Сервера web, Elasticsearch поместите в приватные подсети. Сервера Zabbix, Kibana, application load balancer определите в публичную подсеть.

Настройте [Security Groups](https://cloud.yandex.com/docs/vpc/concepts/security-groups) соответствующих сервисов на входящий трафик только к нужным портам.

Настройте ВМ с публичным адресом, в которой будет открыт только один порт — ssh.  Эта вм будет реализовывать концепцию  [bastion host]( https://cloud.yandex.ru/docs/tutorials/routing/bastion) . Синоним "bastion host" - "Jump host". Подключение  ansible к серверам web и Elasticsearch через данный bastion host можно сделать с помощью  [ProxyCommand](https://docs.ansible.com/ansible/latest/network/user_guide/network_debug_troubleshooting.html#network-delegate-to-vs-proxycommand) . Допускается установка и запуск ansible непосредственно на bastion host.(Этот вариант легче в настройке)

### Резервное копирование
Создайте snapshot дисков всех ВМ. Ограничьте время жизни snaphot в неделю. Сами snaphot настройте на ежедневное копирование.

### Дополнительно
Не входит в минимальные требования. 

1. Для Zabbix можно реализовать разделение компонент - frontend, server, database. Frontend отдельной ВМ поместите в публичную подсеть, назначте публичный IP. Server поместите в приватную подсеть, настройте security group на разрешение трафика между frontend и server. Для Database используйте [Yandex Managed Service for PostgreSQL](https://cloud.yandex.com/en-ru/services/managed-postgresql). Разверните кластер из двух нод с автоматическим failover.
2. Вместо конкретных ВМ, которые входят в target group, можно создать [Instance Group](https://cloud.yandex.com/en/docs/compute/concepts/instance-groups/), для которой настройте следующие правила автоматического горизонтального масштабирования: минимальное количество ВМ на зону — 1, максимальный размер группы — 3.
3. В Elasticsearch добавьте мониторинг логов самого себя, Kibana, Zabbix, через filebeat. Можно использовать logstash тоже.
4. Воспользуйтесь Yandex Certificate Manager, выпустите сертификат для сайта, если есть доменное имя. Перенастройте работу балансера на HTTPS, при этом нацелен он будет на HTTP веб-серверов.

## Выполнение работы
На этом этапе вы непосредственно выполняете работу. При этом вы можете консультироваться с руководителем по поводу вопросов, требующих уточнения.

⚠️ В случае недоступности ресурсов Elastic для скачивания рекомендуется разворачивать сервисы с помощью docker контейнеров, основанных на официальных образах.

**Важно**: Ещё можно задавать вопросы по поводу того, как реализовать ту или иную функциональность. И руководитель определяет, правильно вы её реализовали или нет. Любые вопросы, которые не освещены в этом документе, стоит уточнять у руководителя. Если его требования и указания расходятся с указанными в этом документе, то приоритетны требования и указания руководителя.

## Критерии сдачи
1. Инфраструктура отвечает минимальным требованиям, описанным в [Задаче](#Задача).
2. Предоставлен доступ ко всем ресурсам, у которых предполагается веб-страница (сайт, Kibana, Zabbix).
3. Для ресурсов, к которым предоставить доступ проблематично, предоставлены скриншоты, команды, stdout, stderr, подтверждающие работу ресурса.
4. Работа оформлена в отдельном репозитории в GitHub или в [Google Docs](https://docs.google.com/), разрешён доступ по ссылке. 
5. Код размещён в репозитории в GitHub.
6. Работа оформлена так, чтобы были понятны ваши решения и компромиссы. 
7. Если использованы дополнительные репозитории, доступ к ним открыт. 

## Как правильно задавать вопросы дипломному руководителю
Что поможет решить большинство частых проблем:
1. Попробовать найти ответ сначала самостоятельно в интернете или в материалах курса и только после этого спрашивать у дипломного руководителя. Навык поиска ответов пригодится вам в профессиональной деятельности.
2. Если вопросов больше одного, присылайте их в виде нумерованного списка. Так дипломному руководителю будет проще отвечать на каждый из них.
3. При необходимости прикрепите к вопросу скриншоты и стрелочкой покажите, где не получается. Программу для этого можно скачать [здесь](https://app.prntscr.com/ru/).

Что может стать источником проблем:
1. Вопросы вида «Ничего не работает. Не запускается. Всё сломалось». Дипломный руководитель не сможет ответить на такой вопрос без дополнительных уточнений. Цените своё время и время других.
2. Откладывание выполнения дипломной работы на последний момент.
3. Ожидание моментального ответа на свой вопрос. Дипломные руководители — работающие инженеры, которые занимаются, кроме преподавания, своими проектами. Их время ограничено, поэтому постарайтесь задавать правильные вопросы, чтобы получать быстрые ответы :)



Для выполнения задания необходимо:
1. Установить Terraform:
```
- sudo apt update
- wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
- sudo apt update
- sudo apt install terraform
- terraform -v
```
![alt text](https://github.com/Replica63/diplom-kvv/blob/main/img/1.png)

2. Для работы с terraform нужно создать файл конфигурации:

```
nano ~/.terraform
```
```
provider_installation {
  network_mirror {
    url = "https://terraform-mirror.yandexcloud.net/"
    include = ["registry.terraform.io/*/*"]
  }
  direct {
    exclude = ["registry.terraform.io/*/*"]
  }
}

```
далее создаю каталог в котором буду работать с terraform, в нем создаю файд main.tf который является основным конфигурационным файлом, 
в котором описываю ресурсы, которые необходимо создать и управлять, определяем провайдера, ресурсы, переменные и другие настройки для инфраструктуры.
Для написания кода и создания файлов буду использовать VScode.

```
terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
required_version = ">=0.13"
}

# Описание доступа и токена
provider "yandex" {
  service_account_key_file = "/home/kvv/authorized_key.json"
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone = "ru-central1-a"
}
```
дальше создаю файл variables.tf, который используется для определения переменных в конфигурации. В нем можно задать параметры, которые будут использоваться в коде.

```

variable "cloud_id" {
default = "***"
}

variable "folder_id" {
default = "***"
}
```
следующим шагом создаем пару ключей командой ssh-keygen -t ed25519 и прописываем публичный ключ в файл meta.txt
```
#cloud-config
 users:
  - name: kvv
    groups: sudo
    shell: /bin/bash
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    ssh-authorized-keys:
      - ssh-ed25519 AAAAC********3U2NR kvv@kvv
```
Для удобства выполнения задания, для каждой описываем файл конфигурации XXXX.tf
Ссылки:
![Файл конфигурации Websrver](https://github.com/Replica63/diplom-kvv/blob/main/terraform/webserver.tf)
![Файл конфигурации Bastion](https://github.com/Replica63/diplom-kvv/blob/main/terraform/bastion.tf)
![Файл конфигурации Kibana.tf](https://github.com/Replica63/diplom-kvv/blob/main/terraform/kibana.tf)
![Файл конфигурации Elasticsearch.tf](https://github.com/Replica63/diplom-kvv/blob/main/terraform/elasticsearch.tf)
![Файл конфигурации Zabbix.tf](https://github.com/Replica63/diplom-kvv/blob/main/terraform/zabbix.tf)
![Файл конфигурации Networks.tf](https://github.com/Replica63/diplom-kvv/blob/main/terraform/networks.tf)
![Файл конфигурации Группы безопасности](https://github.com/Replica63/diplom-kvv/blob/main/terraform/security_group.tf)
![Файл конфигурации Снимки](https://github.com/Replica63/diplom-kvv/blob/main/terraform/snapshot.tf)
![Файл конфигурации Вывода](https://github.com/Replica63/diplom-kvv/blob/main/terraform/outputs.tf)
![Файл конфигурации Балансировщика](https://github.com/Replica63/diplom-kvv/blob/main/terraform/alb.tf)


Результат выполнения:

![alt text](https://github.com/Replica63/diplom-kvv/blob/main/img/2.png)

![alt text](https://github.com/Replica63/diplom-kvv/blob/main/img/3.png)

![alt text](https://github.com/Replica63/diplom-kvv/blob/main/img/4.png)

![alt text](https://github.com/Replica63/diplom-kvv/blob/main/img/5.png)

![alt text](https://github.com/Replica63/diplom-kvv/blob/main/img/6.png)

![alt text](https://github.com/Replica63/diplom-kvv/blob/main/img/7.png)

![alt text](https://github.com/Replica63/diplom-kvv/blob/main/img/8.png)

![alt text](https://github.com/Replica63/diplom-kvv/blob/main/img/9.png)

![alt text](https://github.com/Replica63/diplom-kvv/blob/main/img/10.png)

![alt text](https://github.com/Replica63/diplom-kvv/blob/main/img/11.png)

![alt text](https://github.com/Replica63/diplom-kvv/blob/main/img/12.png)

![alt text](https://github.com/Replica63/diplom-kvv/blob/main/img/13.png)

![alt text](https://github.com/Replica63/diplom-kvv/blob/main/img/14.png)

![alt text](https://github.com/Replica63/diplom-kvv/blob/main/img/15.png)

![alt text](https://github.com/Replica63/diplom-kvv/blob/main/img/16.png)

![alt text](https://github.com/Replica63/diplom-kvv/blob/main/img/17.png)

Доступ к ВМ:
![alt text](https://github.com/Replica63/diplom-kvv/blob/main/img/18.png)

Cледующий шаг, устанавливаем ансибл:

```
- sudo apt update
- sudo apt upgrade
- sudo apt install software-properties-common
- sudo apt-add-repository ppa:ansible/ansible
- sudo apt install ansible
- ansible --version
```
![alt text](https://github.com/Replica63/diplom-kvv/blob/main/img/19.png)

Приступаем к настройке Ansible. Также использую для работы с файлами VSCode.
Файл конфигураци ansible.cfg
```
[defaults]
inventory = /home/kvv/diplom/terraform/ansible/hosts.ini
forks = 5
remote_user = user
default_become                 = true
default_become_method          = sudo
default_become_user            = user
allow_world_readable_tmpfiles  = true
host_key_checking = False

[privilege_escalation]
become = True
become_method = sudo
```
Конфигурация файла Hosts.ini находится в папке ansible
```
# hosts.ini
[bastion_host]
bastion ansible_host=158.160.42.241 ansible_ssh_user=user

[webservers]
nginx-1 ansible_host=nginx-1.ru-central1.internal
nginx-2 ansible_host=nginx-2.ru-central1.internal

[elasticsearch_host]
elasticsearch ansible_host=elasticsearch.ru-central1.internal

[kibana_host]
kibana ansible_host=kibana.ru-central1.internal

[zabbix_host]
zabbix ansible_host=zabbix-server.ru-central1.internal

[webservers:vars]
ansible_ssh_user=user
ansible_ssh_common_args='-o ProxyCommand="ssh -W %h:%p user@158.160.42.241"'


[elasticsearch_host:vars]
ansible_ssh_user=user
ansible_ssh_common_args='-o ProxyCommand="ssh -W %h:%p user@158.160.42.241"'

[kibana_host:vars]
ansible_ssh_user=user
ansible_ssh_common_args='-o ProxyCommand="ssh -W %h:%p user@158.160.42.241"'

[zabbix_host:vars]
ansible_ssh_user=user
ansible_ssh_common_args='-o ProxyCommand="ssh -W %h:%p user@158.160.42.241"'
ansible_python_interpreter=/usr/bin/python3
```
Проверяю доступность хостов:
```
ansible all -m ping
```
Результат:
![alt text](https://github.com/Replica63/diplom-kvv/blob/main/img/20.png)

Теперь разворачиваем nginx

```
---
- name: Test Connection to my servres
  hosts: webservers
  become: yes

  tasks:
    - name: update apt packages # Обновление пакетов
      apt:
        force_apt_get: true
        upgrade: dist
        update_cache: yes
      become: true

    - name: Install nginx on all servers # Установка nginx
      apt: 
        name: nginx
        state: latest
        update_cache: yes

- name: copy index.html webserver 1 # Копирование index.html на первый сервер
  hosts: nginx-1
  become: yes

  tasks:
    - name: copy index_new.html
      ansible.builtin.copy:
        src: ./www/index1.html
        dest: /var/www/html/index.html
        owner: root
        group: sudo
        mode: "0644"

- name: copy index.html webserver 2 # Копирование index.html на второй сервер
  hosts: nginx-2
  become: yes
  
  tasks:
    - name: copy index_new.html
      ansible.builtin.copy:
        src: ./www/index2.html
        dest: /var/www/html/index.html
        owner: root
        group: sudo
        mode: "0644"

```
Index файлы находятся в папке /wwww
Результат:
![alt text](https://github.com/Replica63/diplom-kvv/blob/main/img/21.png)
![alt text](https://github.com/Replica63/diplom-kvv/blob/main/img/22.png)

Дальше скачиваю установочные пакеты Elasticsearch,Kibana, Filebeats здесь:
Elasticsearch: ![alt text](https://mirror.yandex.ru/mirrors/elastic/7/pool/main/e/elasticsearch/)

Filebeat: ![alt text](https://mirror.yandex.ru/mirrors/elastic/7/pool/main/f/filebeat/)

Kibana: ![alt text](https://mirror.yandex.ru/mirrors/elastic/7/pool/main/k/kibana/)

После указываем к ним путь в playbook.yml, для каждой задачи свой.
ссылки на playbook:
![elasticsearch_playbook.yml](https://github.com/Replica63/diplom-kvv/blob/main/ansible/elasticsearch_playbook.yml)
![filebeat_playbook.yml](https://github.com/Replica63/diplom-kvv/blob/main/ansible/filebeat_playbook.yml)
![kibana_playbook.yml](https://github.com/Replica63/diplom-kvv/blob/main/ansible/kibana_playbook.yml)
![alt text](https://github.com/Replica63/diplom-kvv/blob/main/img/23.png)
![alt text](https://github.com/Replica63/diplom-kvv/blob/main/img/24.png)
![alt text](https://github.com/Replica63/diplom-kvv/blob/main/img/25.png)
Дальше разворачиваем и настраиваем ZABBIX SERVER И  ZABBXI AGENT НА HOSTS, файлы в папке ansible/zabbix:
![zabbix_serv.yml](https://github.com/Replica63/diplom-kvv/blob/main/ansible/zabbix/zabbix_serv.yml)
![zabbix_agent.yml](https://github.com/Replica63/diplom-kvv/blob/main/ansible/zabbix/zabbix_agent.yml)
![zabbix_server.conf](https://github.com/Replica63/diplom-kvv/blob/main/ansible/zabbix/zabbix_server.conf)
![zabbix_agentd.conf.j2](https://github.com/Replica63/diplom-kvv/blob/main/ansible/zabbix/zabbix_agentd.conf.j2)

![alt text](https://github.com/Replica63/diplom-kvv/blob/main/img/26.png)
![alt text](https://github.com/Replica63/diplom-kvv/blob/main/img/27.png)
![alt text](https://github.com/Replica63/diplom-kvv/blob/main/img/28.png)
![alt text](https://github.com/Replica63/diplom-kvv/blob/main/img/29.png)
![alt text](https://github.com/Replica63/diplom-kvv/blob/main/img/30.png)

Сайты доступны по пдресу http://158.160.165.84/
Доступ к zabbix по адресу http://178.154.206.115/zabbix/
логин:Admin
пароль:zabbix
Доступ к Kibana по адресу http://158.160.46.50:5601/
