# Nextcloud

```yalm
version: '3.1'

services:

  nextcloud:
    image: hasangnu/nextcloud
    container_name: nextcloud
    restart: always
    ports:
      - 8480:80
      - 8443:443
    volumes:
      - ./data/nextcloud/apps/:/var/www/html/apps
      - ./data/nextcloud/config/:/var/www/html/config
      - ./data/nextcloud/data/:/var/www/html/data

  db:
    image: hasangnu/mariadb
    container_name: nextcloud_mariadb
    command: --transaction-isolation=READ-COMMITTED --binlog-format=ROW
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: nextcloud
      MYSQL_DATABASE: nextcloud
      MYSQL_USER: nextcloud
      MYSQL_PASSWORD: nextcloud
    volumes:
     - ./data/mariadb:/var/lib/mysql

```

```
docker-compose up -d
```
