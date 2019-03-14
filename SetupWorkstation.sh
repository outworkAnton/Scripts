#!/bin/bash

# Variables

USER=$(whoami)
HOSTNAME=$(hostname)

# Functions

function add_fstab_entry () {
    case $1 in
        "LOCAL")
            echo "UUID=$2      $3   ext4        defaults   0       0" | sudo tee -a /etc/fstab
        ;;
        "REMOTE")
            echo "$2         $3    cifs        guest,nofail,uid=1000$4   0       0" | sudo tee -a /etc/fstab
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

function create_and_mount_dirs () {
    DIRS=("$@")
    CIFS="cifs-utils"
    if ! dpkg -s $CIFS >/dev/null 2>&1
    then
        tput setaf 4; echo "НЕОБХОДИМА УСТАНОВКА ДОПОЛНИТЕЛЬНОГО ПАКЕТА: $CIFS"; tput sgr0
        sudo apt-get -y install $CIFS
    fi
    for DIR in ${DIRS[@]}; do
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

function mount_clients () {
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

function share_folders () {
	SAMBA="samba"
    if ! dpkg -s $SAMBA >/dev/null 2>&1
    then
        tput setaf 4; echo "НЕОБХОДИМА УСТАНОВКА ДОПОЛНИТЕЛЬНОГО ПАКЕТА: $SAMBA"; tput sgr0
        sudo apt-get -y install $SAMBA
    fi
	SHARES=("/mnt/Filestorage_1000/Documents" "/mnt/Filestorage_1000/Files" "/mnt/Filestorage_2000/Films" "/mnt/Filestorage_1000/GoogleDrive" "/mnt/Filestorage_1000/Music" "/mnt/Filestorage_500" "/mnt/Photos")
	for SHARE in ${SHARES[@]} 
	do
        NEEDADD=$(sudo cat /etc/samba/smb.conf | grep $SHARE | wc -l)
		HEAD=""
		if (( ! $NEEDADD ))
			then 
				case $SHARE in
					"/mnt/Filestorage_1000/Documents")
						$HEAD="[documents]"
					;;
					"/mnt/Filestorage_1000/Files")
						$HEAD="[files]"
					;;
					"/mnt/Filestorage_2000/Films")
						$HEAD="[films]"
					;;
					"/mnt/Filestorage_1000/GoogleDrive")
						$HEAD="[googledrive]"
					;;
					"/mnt/Filestorage_1000/Music")
						$HEAD="[music]"
					;;
					"/mnt/Filestorage_500")
						$HEAD="[software]"
					;;
					"/mnt/Photos")
						$HEAD="[photos]"
					;;
					*)
					;;
				esac
				echo "" | sudo tee -a /etc/samba/smb.conf
				echo "$HEAD" | sudo tee -a /etc/samba/smb.conf
				echo "    path = $SHARE" | sudo tee -a /etc/samba/smb.conf
				echo "    read only = no" | sudo tee -a /etc/samba/smb.conf
				echo "    browseable = yes" | sudo tee -a /etc/samba/smb.conf
				echo "    writeable = yes" | sudo tee -a /etc/samba/smb.conf
				echo "    delete readonly = yes" | sudo tee -a /etc/samba/smb.conf
				echo "    guest ok = yes" | sudo tee -a /etc/samba/smb.conf
				echo "    public = yes" | sudo tee -a /etc/samba/smb.conf
				echo "" | sudo tee -a /etc/samba/smb.conf
				tput setaf 2; echo "ДОБАВЛЕНИЕ ОБЩЕЙ ПАПКИ $SHARE ЗАВЕРШЕНО"; tput sgr0
			else
				tput setaf 5; echo "ОБЩАЯ ПАПКА $SHARE УЖЕ ДОБАВЛЕНА"; tput sgr0
		fi
    done
	sudo service smbd restart
	clear && echo -en "\e[3J"
    sudo cat /etc/samba/smb.conf
}

function mount_server () {
	MOUNTDIRS=("/mnt/Filestorage_2000" "/mnt/Filestorage_1000" "/mnt/Filestorage_500" "/mnt/Photos")
	for MOUNTDIR in ${MOUNTDIRS[@]} 
	do
		NEEDADD=$(sudo cat /etc/fstab | grep $MOUNTDIR | wc -l)
		if (( ! $NEEDADD ))
			then
				case $MOUNTDIR in
					"/mnt/Filestorage_2000")
						sudo lsblk -o NAME,FSTYPE,SIZE,UUID,MOUNTPOINT
						read -p "ВВЕДИТЕ UUID ДИСКА 2Tb:" UUID2TB
						add_fstab_entry "LOCAL" $UUID2TB $MOUNTDIR
					;;
					"/mnt/Filestorage_1000")
						sudo lsblk -o NAME,FSTYPE,SIZE,UUID,MOUNTPOINT
						read -p "ВВЕДИТЕ UUID ДИСКА 1Tb:" UUID1TB
						add_fstab_entry "LOCAL" $UUID1TB $MOUNTDIR
					;;
					"/mnt/Filestorage_500")
						sudo lsblk -o NAME,FSTYPE,SIZE,UUID,MOUNTPOINT
						read -p "ВВЕДИТЕ UUID ДИСКА 500Gb:" UUID500GB
						add_fstab_entry "LOCAL" $UUID500GB $MOUNTDIR
					;;
					"/mnt/Photos")
						add_fstab_entry "EMPTY"
						add_fstab_entry "COMMENT"
						add_fstab_entry "REMOTE" "//$1/Photos" $MOUNTDIR ",x-systemd.automount"
					;;
					*)
					;;
				esac
				tput setaf 2; echo "ДОБАВЛЕНИЕ ЗАПИСИ ДЛЯ $MOUNTDIR ЗАВЕРШЕНО УСПЕШНО"; tput sgr0
			else
				tput setaf 5; echo "ДОБАВЛЕНИЕ ЗАПИСИ ДЛЯ $MOUNTDIR НЕ ТРЕБУЕТСЯ"; tput sgr0
		fi
	done
	create_and_mount_dirs "${MOUNTDIRS[@]}"
	tput setaf 2; echo "МОНТИРОВАНИЕ ДИСКОВ ЗАВЕРШЕНО УСПЕШНО"; tput sgr0
}

# Main section

CHANGEPERMS=$(sudo cat /etc/sudoers | grep "$USER" | wc -l)
if (( ! $CHANGEPERMS ))
then
    echo "$USER ALL=(ALL:ALL) NOPASSWD:ALL" | sudo EDITOR="tee -a" visudo
	tput setaf 2; echo "ПРАВА НА ВЫПОЛНЕНИЕ КОМАНД ОТ ИМЕНИ РУТА БЕЗ ВВОДА ПАРОЛЯ НАЗНАЧЕНЫ УСПЕШНО"; tput sgr0
else
	tput setaf 5; echo "ТЕКУЩИЙ ПОЛЬЗОВАТЕЛЬ ИМЕЕТ ПРАВА НА ВЫПОЛНЕНИЕ КОМАНД ОТ ИМЕНИ РУТА БЕЗ ВВОДА ПАРОЛЯ"; tput sgr0
fi

case $HOSTNAME in
    "MANECHKA-PC")
        mount_clients "192.168.0.250"
    ;;
    "BEDROOM")
        mount_clients "192.168.137.1"
    ;;
    "Convex-NAS")
        mount_server "192.168.0.101"
		share_folders
    ;;
    *)
        echo "НЕ УДАЛОСЬ ОПРЕДЕЛИТЬ ТИП КЛИЕНТА. ТЕКУЩИЙ IP: $(hostname -I). ИМЯ ХОСТА: $HOSTNAME"
    ;;
esac



