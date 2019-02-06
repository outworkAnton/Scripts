#!/bin/bash

sudo apt-get update
clear && echo -en "\e[3J"
LISTAPP="apt-show-versions"
if ! dpkg -s $LISTAPP >/dev/null 2>&1
then
    tput setaf 4; echo "НЕОБХОДИМА УСТАНОВКА ДОПОЛНИТЕЛЬНОГО ПАКЕТА: $LISTAPP"; tput sgr0
    sudo apt-get -y install $LISTAPP
    clear && echo -en "\e[3J"
fi

PACKAGES=$(sudo apt-show-versions -u)

if [ ! -z "$PACKAGES" ]
then
    tput setaf 3; echo "ДОСТУПНО ПАКЕТОВ ДЛЯ ОБНОВЛЕНИЯ: $(echo "$PACKAGES" | wc -l)"
    echo "$PACKAGES"; tput sgr0
    UPGRADELOG=$(sudo apt-get -y dist-upgrade | tee /dev/tty)
    AUTOREMOVE=$(echo "$UPGRADELOG" | grep "sudo apt autoremove" | wc -l)
    if (($AUTOREMOVE))
    then
        tput setaf 4; echo "БУДЕТ ВЫПОЛНЕНА ОЧИСТКА НЕНУЖНЫХ ПАКЕТОВ"; tput sgr0
        sudo apt-get -y autoremove
    fi
    clear && echo -en "\e[3J"
    tput setaf 2; echo "$PACKAGES"; tput sgr0
    tput setaf 2; echo "ОБНОВЛЕНИЕ СИСТЕМЫ УСПЕШНО ЗАВЕРШЕНО"; tput sgr0
else
    clear && echo -en "\e[3J"
    tput setaf 5; echo "ОБНОВЛЕНИЕ СИСТЕМЫ НЕ ТРЕБУЕТСЯ"; tput sgr0
fi
read
