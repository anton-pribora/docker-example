# Учебный проект на Docker + Node (на примере React)

Суть проекта - показать, как запускать контейнеры в режиме разработки и готовой сборки. 

## update_dev.sh

Сборка и запуск контейнера в режиме разработчика (development). 

## update_pod.sh

Сборка и запуск контейнера в режиме готовой сборки (ptoduction).

## Установка окружения

Виртуальный сетевой интерфейс для закрытой подсети:

```sh
modprobe dummy
echo dummy >> /etc/modules
echo 10.98.0.15 realhost >> /etc/hosts
echo -e "auto dummy0\niface dummy0 inet static\n  address 10.98.0.15/32" >> /etc/network/interfaces.d/dummy0
reboot
```