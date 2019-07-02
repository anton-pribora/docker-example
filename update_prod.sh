#!/usr/bin/env bash

cd $(dirname "$0")

get_free_port() {
    for i in $@
    do
        netstat -lp4n | grep :${i} > /dev/null
        if [[ $? != 0 ]]; then
            echo ${i}
            return 0
        fi
    done
    return 1
}

  PROJECT_NAME=my_project
    APP_FOLDER=${PWD}/app
      APP_PORT=4000             # Порт, на котором поднимается нода в контейнере
     HOST_PORT=$(seq 3100 3200) # Диапазон портов, из которых будет браться первый незанятый порт для проброса
       HOST_IP=$(getent hosts realhost | awk '{print $1}')  # IP-адрес хоста, на котором работают доп. сервисы
       VERSION=$(cat ${APP_FOLDER}/package.json | python -c "import sys,json;print(json.load(sys.stdin)['version'])")
    IMAGE_NAME=${PROJECT_NAME}
CONTAINER_NAME=${PROJECT_NAME}
   DOCKER_FILE=${APP_FOLDER}/DockerfileProd

start_container() {
    docker run \
        --name=$1 \
        --restart unless-stopped \
        \
        --detach \
        \
        --env=REACT_APP_TEST=321 \
        --env=NODE_ENV=production \
        \
        --add-host=database:${HOST_IP} \
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

check_container_port() {
    docker exec ${1} nc -z 127.0.0.1 ${2} 1>&2 2>/dev/stderr
    echo $?
}

wait_for_port() {
    seconds=0
    while [[ $(check_container_port $@) != "0" ]]
    do
        seconds=$(($seconds + 1))
        [[ ${seconds} -gt 60 ]] && error Превышен интервал ожидания порта для $@
        sleep 1
    done
}

echo Шаг первый - билдим контейнер
build_image

echo Шаг второй - подбираем новое имя для нового контейнера
NEXT_NUM=$(docker ps -a --format "{{.Names}}" | grep "^${CONTAINER_NAME}" | sed -E 's/.*-//;s/[^0-9]+//;s/^$/0/' | sort -rn | head -n1)
NEXT_NUM=${NEXT_NUM:-0}
NEXT_NUM=$(($NEXT_NUM + 1))
NEXT_CONTAINER_NAME="${CONTAINER_NAME}-${NEXT_NUM}"

echo "Новое имя контейнера: ${NEXT_CONTAINER_NAME}"

echo Шаг третий - ищем контейнеры, которые запущены, дабы прибить их после обновления
RUNNING_CONTAINERS=$(docker ps -a --format "{{.Names}}" | grep "^${CONTAINER_NAME}")
echo ${RUNNING_CONTAINERS}

echo Шаг четвёртый - запускаем новый контейнер
HOST_PORT=$(get_free_port ${HOST_PORT})  # Берём первый незанятый порт, чтобы поднять на нём приложение
start_container ${NEXT_CONTAINER_NAME}

echo Шаг пятый - ждём пока контейнер поднимется
wait_for_port ${NEXT_CONTAINER_NAME} ${APP_PORT}

echo Шаг шестой - переключаем nginx на новый контейнер
update_nginx

echo Ждём 3 секунды, дабы старые запросы доработали и не было 502 ошибки
sleep 3

echo Шаг седьмой - останавливаем и удаляем старые контейнеры
[[ -n ${RUNNING_CONTAINERS} ]] && docker rm -f ${RUNNING_CONTAINERS}

echo Шаг восьмой - переименоваывем новый контейнер в старый
docker rename ${NEXT_CONTAINER_NAME} ${CONTAINER_NAME}
