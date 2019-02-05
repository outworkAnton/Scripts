#!/bin/bash

CHROME="google-chrome-stable"
if ! dpkg -s $CHROME >/dev/null 2>&1
then
    tput setaf 4; echo "НЕОБХОДИМА УСТАНОВКА ПАКЕТА: $CHROME"; tput sgr0
    wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
    sudo sh -c 'echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list'
    sudo apt-get update
    sudo apt-get -y install $CHROME
    clear && echo -en "\e[3J"
    tput setaf 2; echo "УСТАНОВКА ПАКЕТА УСПЕШНО ЗАВЕРШЕНА"; tput sgr0
fi

