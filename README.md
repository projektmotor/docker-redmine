# ProjektMOTOR Redmine Docker

Redmine Docker Image depending on offical Redmine Image, including redmine git hosting and some additional themes.

## How to use

* clone this repository
* add additional plugins into ```plugins``` directory
* build docker image (gems installation included):
    ```
    $ docker build -t [YOUR-IMAGE-NAME] .
    ```
* your image is ready for use, the following examples using docker-compose to run redmine
* create ```docker-compose.yml```
    ```
    version: '3.1'

    services:

        web:
            image: projektmotor/docker-redmine:latest
            restart: always
            volumes:
                - ./web/redmine/files/:/usr/src/redmine/files
                - ./web/redmine/config/configuration.yml:/usr/src/redmine/config/configuration.yml
                - ./web/gitolite/repositories/:/home/git/repositories
            ports:
                - 80:3000
                - 2222:2222
            environment:
                REDMINE_DB_MYSQL: mysql
                REDMINE_DB_DATABASE: redmine
                REDMINE_DB_USERNAME: redmine
                REDMINE_DB_PASSWORD: y0ur_passw0rd
                REDMINE_PLUGINS_MIGRATE: 'true'

        mysql:
            image: mysql:5.7
            restart: always
            volumes:
                - ./mysql/data/:/var/lib/mysql
            environment:
                MYSQL_ROOT_PASSWORD: y0ur_r00t_passw0rd
                MYSQL_DATABASE: redmine
                MYSQL_USER: redmine
                MYSQL_PASSWORD: y0ur_passw0rd
    ```
* start your services
    ```
    $ docker-compose up -d
    ```
