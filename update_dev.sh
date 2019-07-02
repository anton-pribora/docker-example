#!/usr/bin/env bash

cd $(dirname "$0")

  PROJECT_NAME=my_project
    APP_FOLDER=${PWD}/app
      APP_PORT=3000          # Порт, на котором поднимается нода в контейнере
     HOST_PORT=3111          # Порт, который будет пробрасываться из хоста в контейнер
       HOST_IP=$(getent hosts realhost | awk '{print $1}')
       VERSION=dev
    IMAGE_NAME=${PROJECT_NAME}
CONTAINER_NAME=${PROJECT_NAME}
   DOCKER_FILE=${APP_FOLDER}/DockerfileDev

start_container() {
    docker run \
        --name=${CONTAINER_NAME} \
        --restart unless-stopped \
        \
        --detach \
        \
        --env=REACT_APP_TEST=123 \
        --env=NODE_ENV=develoment \
        \
        --add-host=database:${HOST_IP} \
        \
        --volume=${APP_FOLDER}:/app \
        \
        --publish=${HOST_IP}:${HOST_PORT}:${APP_PORT} \
        \
        ${IMAGE_NAME}:${VERSION}
}

build_image() {
    docker build -f ${DOCKER_FILE} -t ${IMAGE_NAME}:${VERSION} ${APP_FOLDER}
}

check_image() {
    docker image inspect ${IMAGE_NAME}:${VERSION} 1>/dev/null 2>&1
}

check_container() {
    docker container inspect ${CONTAINER_NAME} 1>/dev/null 2>&1
}

update_nginx() {
    sed -i "s~proxy_pass http://.*;~proxy_pass http://${HOST_IP}:${HOST_PORT};~" conf/nginx.conf
    nginx -t && service nginx reload
}

error() {
    echo $@ 1>&2
    exit 1
}

case $1 in 
    rebuild)
        check_container && docker rm -fv ${CONTAINER_NAME}
        check_image     && docker image rm ${IMAGE_NAME}:${VERSION}
        build_image     || error Не удалось собрать образ
        start_container || error Не удалось запустить контейнер
        update_nginx    || error Не удалось перезапустить nginx
        ;;
    rm)
        check_container && docker rm -fv ${CONTAINER_NAME}
        check_image     && docker image rm ${IMAGE_NAME}:${VERSION}
        ;;
    *)
        if check_container
        then
            docker restart ${CONTAINER_NAME}
        else
            check_image || build_image || error Не удалось собрать образ
            (start_container && update_nginx) || error Не удалось запустить контейнер
        fi
        ;;
esac
