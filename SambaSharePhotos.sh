#!/bin/bash

SMB="samba"
if ! dpkg -s $SMB >/dev/null 2>&1
then
    tput setaf 4; echo "НЕОБХОДИМА УСТАНОВКА ДОПОЛНИТЕЛЬНОГО ПАКЕТА: $SMB"; tput sgr0
    sudo apt-get -y install $SMB
fi

NEEDADD=$(sudo cat /etc/samba/smb.conf | grep "photos" | wc -l)
if (( ! $NEEDADD))
then
    echo "" | sudo tee -a /etc/samba/smb.conf
    echo "[photos]" | sudo tee -a /etc/samba/smb.conf
    echo "    read only = no" | sudo tee -a /etc/samba/smb.conf
    echo "    browseable = yes" | sudo tee -a /etc/samba/smb.conf
    echo "    writeable = yes" | sudo tee -a /etc/samba/smb.conf
    echo "    delete readonly = yes" | sudo tee -a /etc/samba/smb.conf
    echo "    guest ok = yes" | sudo tee -a /etc/samba/smb.conf
    echo "    path = /mnt/Фото" | sudo tee -a /etc/samba/smb.conf
    echo "    public = yes" | sudo tee -a /etc/samba/smb.conf

    NEEDSTART=$(sudo systemctl status smbd | grep "active (running)" | wc -l)
    if (( ! $NEEDSTART ))
        then
        sudo systemctl enable smbd
        sudo systemctl start smbd
    fi
    clear && echo -en "\e[3J"
    sudo cat /etc/samba/smb.conf
    tput setaf 2; echo "ДОБАВЛЕНИЕ ЗАПИСЕЙ УСПЕШНО ЗАВЕРШЕНО"; tput sgr0
else
    sudo systemctl restart smbd
    clear && echo -en "\e[3J"
    tput setaf 5; echo "ДОБАВЛЕНИЕ ЗАПИСЕЙ НЕ ТРЕБУЕТСЯ"; tput sgr0
fi