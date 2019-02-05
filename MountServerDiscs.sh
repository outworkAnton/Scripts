#!/bin/bash

USER=$(whoami)
HOSTNAME=$(hostname)

case $HOSTNAME in
    "MANECHKA-PC")
        SERVER="192.168.0.250"
    ;;
    "BEDROOM")
        SERVER="192.168.137.1"
    ;;
    *)
        echo "НЕ УДАЛОСЬ ОПРЕДЕЛИТЬ ТИП КЛИЕНТА. ТЕКУЩИЙ IP: $(hostname -I). ИМЯ ХОСТА: $HOSTNAME"
        read -p "ВВЕДИТЕ IP АДРЕС СЕРВЕРА:" SERVER
    ;;
esac

NEEDADD=$(sudo cat /etc/fstab | grep "/documents" | wc -l)
if (( ! $NEEDADD ))
    then
        MOUNTDIRS=("/mnt/Документы" "/mnt/Файлы" "/mnt/Фильмы" "/mnt/Программы" "/mnt/Гугл" "/mnt/Музыка" "/mnt/Фото")

        if [[ $HOSTNAME -eq "MANECHKA-PC" ]]
        then
            ONACCESSMOUNT=",x-systemd.automount"
            sudo blkid
            read -p "ВВЕДИТЕ UUID ДИСКА:" UUID
            echo "UUID=$UUID      ${MOUNTDIRS[6]}    ext4        defaults   0       0" | sudo tee -a /etc/fstab
            MOUNTPHOTO=""
        else
            ONACCESSMOUNT=""
            MOUNTPHOTO="//$SERVER/photos          ${MOUNTDIRS[6]}    cifs        guest,nofail,uid=1000$ONACCESSMOUNT   0       0"
        fi

        echo "" | sudo tee -a /etc/fstab
        echo "#remote" | sudo tee -a /etc/fstab
        echo "//$SERVER/documents      ${MOUNTDIRS[0]}    cifs        guest,nofail,uid=1000$ONACCESSMOUNT   0       0" | sudo tee -a /etc/fstab
        echo "//$SERVER/files          ${MOUNTDIRS[1]}    cifs        guest,nofail,uid=1000$ONACCESSMOUNT   0       0" | sudo tee -a /etc/fstab
        echo "//$SERVER/films          ${MOUNTDIRS[2]}    cifs        guest,nofail,uid=1000$ONACCESSMOUNT   0       0" | sudo tee -a /etc/fstab
        echo "//$SERVER/software       ${MOUNTDIRS[3]}    cifs        guest,nofail,uid=1000$ONACCESSMOUNT   0       0" | sudo tee -a /etc/fstab
        echo "//$SERVER/googledrive    ${MOUNTDIRS[4]}    cifs        guest,nofail,uid=1000$ONACCESSMOUNT   0       0" | sudo tee -a /etc/fstab
        echo "//$SERVER/music          ${MOUNTDIRS[5]}    cifs        guest,nofail,uid=1000$ONACCESSMOUNT   0       0" | sudo tee -a /etc/fstab
        if [ ! -z "$MOUNTPHOTO" ]; then echo "$MOUNTPHOTO" | sudo tee -a /etc/fstab; fi

        CIFS="cifs-utils"
        if ! dpkg -s $CIFS >/dev/null 2>&1
        then
            tput setaf 4; echo "НЕОБХОДИМА УСТАНОВКА ДОПОЛНИТЕЛЬНОГО ПАКЕТА: $CIFS"; tput sgr0
            sudo apt-get -y install $CIFS
        fi

        for DIR in ${MOUNTDIRS[@]}; do
            if [ ! -d $DIR ]; then sudo mkdir $DIR; echo "СОЗДАНИЕ $DIR ЗАВЕРШЕНО"; fi
            if [[ $(stat -c '%U' $DIR) -ne $USER ]]; then sudo chown -R $USER $DIR; echo "СМЕНА ВЛАДЕЛЬЦА $DIR ЗАВЕРШЕНА"; fi
            sudo chmod -R a+rwx $DIR; echo "ПРОЦЕСС ИЗМЕНЕНИЯ ПРАВ $DIR ЗАВЕРШЕН"
        done

        sudo mount -a
        if [ $? -eq 0 ]
        then
            clear && echo -en "\e[3J"
            sudo cat /etc/fstab
            tput setaf 2; echo "ДОБАВЛЕНИЕ ЗАПИСЕЙ УСПЕШНО ЗАВЕРШЕНО"; tput sgr0
        else
            tput setaf 1; echo "ДОБАВЛЕНИЕ ЗАПИСЕЙ ЗАВЕРШИЛОСЬ НЕУДАЧНО"; tput sgr0
        fi

    else
        clear && echo -en "\e[3J"
        tput setaf 5; echo "ДОБАВЛЕНИЕ ЗАПИСЕЙ НЕ ТРЕБУЕТСЯ"; tput sgr0
fi
