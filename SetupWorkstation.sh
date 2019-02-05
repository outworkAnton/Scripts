#!/bin/bash

USER=$(whoami)
HOSTNAME=$(hostname)

CHANGEPERMS=$(sudo cat /etc/sudoers | grep "$USER" | wc -l)
if (( ! $CHANGEPERMS ))
then
    echo "$USER ALL=(ALL:ALL) NOPASSWD:ALL" | sudo EDITOR="tee -a" visudo
fi

case $HOSTNAME in
    "MANECHKA-PC")
        mount_clients "192.168.0.250"
    ;;
    "BEDROOM")
        mount_clients "192.168.137.1"
    ;;
    "CONVEX-NAS")
        mount_server "192.168.0.101"
    ;;
    *)
        echo "НЕ УДАЛОСЬ ОПРЕДЕЛИТЬ ТИП КЛИЕНТА. ТЕКУЩИЙ IP: $(hostname -I). ИМЯ ХОСТА: $HOSTNAME"
    ;;
esac

# Functions

mount_clients () {
    NEEDADD=$(sudo cat /etc/fstab | grep "/documents" | wc -l)
    if (( ! $NEEDADD ))
    then
        MOUNTDIRS=("/mnt/Документы" "/mnt/Файлы" "/mnt/Фильмы" "/mnt/Программы" "/mnt/Гугл" "/mnt/Музыка" "/mnt/Фото")
        
        if [[ $1 -eq "192.168.0.250" ]]
        then
            ONACCESSMOUNT=",x-systemd.automount"
            sudo lsblk -o NAME,FSTYPE,SIZE,UUID,MOUNTPOINT
            read -p "ВВЕДИТЕ UUID ДИСКА:" UUID
            add_fstab_entry "LOCAL" $UUID ${MOUNTDIRS[6]}
            PHOTOMOUNTED=1
        else
            ONACCESSMOUNT=""
            PHOTOMOUNTED=0
        fi
        
        add_fstab_entry "EMPTY"
        add_fstab_entry "COMMENT"
        add_fstab_entry "REMOTE" "//$1/documents" ${MOUNTDIRS[0]} $ONACCESSMOUNT
        add_fstab_entry "REMOTE" "//$1/files" ${MOUNTDIRS[1]} $ONACCESSMOUNT
        add_fstab_entry "REMOTE" "//$1/films" ${MOUNTDIRS[2]} $ONACCESSMOUNT
        add_fstab_entry "REMOTE" "//$1/software" ${MOUNTDIRS[3]} $ONACCESSMOUNT
        add_fstab_entry "REMOTE" "//$1/googledrive" ${MOUNTDIRS[4]} $ONACCESSMOUNT
        add_fstab_entry "REMOTE" "//$1/music" ${MOUNTDIRS[5]} $ONACCESSMOUNT
        if (( ! $PHOTOMOUNTED))
        then
            add_fstab_entry "REMOTE" "//$1/photos" ${MOUNTDIRS[6]} $ONACCESSMOUNT
        fi
        
        create_and_mount_dirs $MOUNTDIRS
    else
        clear && echo -en "\e[3J"
        tput setaf 5; echo "ДОБАВЛЕНИЕ ЗАПИСЕЙ НЕ ТРЕБУЕТСЯ"; tput sgr0
    fi
}

mount_server () {
    NEEDADD=$(sudo cat /etc/fstab | grep "/Filestorage_2000" | wc -l)
    if (( ! $NEEDADD ))
    then
        MOUNTDIRS=("/mnt/Filestorage_2000" "/mnt/Filestorage_1000" "/mnt/Filestorage_500" "/mnt/Photos")
        sudo lsblk -o NAME,FSTYPE,SIZE,UUID,MOUNTPOINT
        read -p "ВВЕДИТЕ UUID ДИСКА 2Tb:" UUID2TB
        add_fstab_entry "LOCAL" $UUID2TB ${MOUNTDIRS[0]}
        read -p "ВВЕДИТЕ UUID ДИСКА 1Tb:" UUID1TB
        add_fstab_entry "LOCAL" $UUID1TB ${MOUNTDIRS[1]}
        read -p "ВВЕДИТЕ UUID ДИСКА 500Gb:" UUID500GB
        add_fstab_entry "LOCAL" $UUID500GB ${MOUNTDIRS[2]}
        add_fstab_entry "EMPTY"
        add_fstab_entry "COMMENT"
        add_fstab_entry "REMOTE" "//$1/Photos" ${MOUNTDIRS[3]}
        
        create_and_mount_dirs $MOUNTDIRS
    else
        clear && echo -en "\e[3J"
        tput setaf 5; echo "ДОБАВЛЕНИЕ ЗАПИСЕЙ НЕ ТРЕБУЕТСЯ"; tput sgr0
    fi
}

add_fstab_entry () {
    case $1 in
        "LOCAL")
            echo "UUID=$2      $3   ext4        defaults   0       0" | sudo tee -a /etc/fstab
        ;;
        "REMOTE")
            echo "//$2         $3    cifs        guest,nofail,uid=1000$4   0       0" | sudo tee -a /etc/fstab
        ;;
        "COMMENT")
            echo "#remote" | sudo tee -a /etc/fstab
        ;;
        "EMPTY")
            echo "" | sudo tee -a /etc/fstab
        ;;
        *)
        ;;
    esac
    
}

create_and_mount_dirs () {
    CIFS="cifs-utils"
    if ! dpkg -s $CIFS >/dev/null 2>&1
    then
        tput setaf 4; echo "НЕОБХОДИМА УСТАНОВКА ДОПОЛНИТЕЛЬНОГО ПАКЕТА: $CIFS"; tput sgr0
        sudo apt-get -y install $CIFS
    fi
    for DIR in ${1[@]}; do
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
}

[documents]
read only = no
browseable = yes
writeable = yes
delete readonly = yes
guest ok = yes
path = /mnt/Filestorage_1000/Documents
public = yes

[files]
read only = no
browseable = yes
writeable = yes
delete readonly = yes
guest ok = yes
path = /mnt/Filestorage_1000/Files
public = yes

[films]
read only = no
browseable = yes
writeable = yes
delete readonly = yes
guest ok = yes
path = /mnt/Filestorage_2000/Films
public = yes

[googledrive]
read only = no
browseable = yes
writeable = yes
delete readonly = yes
guest ok = yes
path = /mnt/Filestorage_1000/GoogleDrive
public = yes

[music]
read only = no
browseable = yes
writeable = yes
delete readonly = yes
guest ok = yes
path = /mnt/Filestorage_1000/Music
public = yes

[software]
read only = no
browseable = yes
writeable = yes
delete readonly = yes
guest ok = yes
path = /mnt/Filestorage_500
public = yes

[photos]
read only = no
browseable = yes
writeable = yes
delete readonly = yes
guest ok = yes
path = /mnt/Photos
public = yes