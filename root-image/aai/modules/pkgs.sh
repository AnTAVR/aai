#!/bin/sh
#
#
#
#   Copyright (c) 2012-2013 Anthony Lyappiev <archlinux@antavr.ru>
#   http://archlinux.antavr.ru
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

# Добавляем функцию модуля в главное меню, пробел в конце обязательно!
MAIN_CASE+=('pkgs')

#===============================================================================
# Сигнальная переменная успешного завершения функции модуля,
# может потребоваться для других модулей, для установки кода завершения
RUN_PKGS=
TXT_PKGS_MAIN="$(gettext 'Дополнительное ПО')"

APPS=''

#===============================================================================

# Выводим строку пункта главного меню
str_pkgs()
{
    local TEMP

    [[ "${RUN_PKGS}" ]] && TEMP="\Zb\Z2($(gettext 'ВЫПОЛНЕНО'))\Zn"
    echo "${TXT_PKGS_MAIN} ${TEMP}"
}

# Функция выполнения из главного меню
run_pkgs()
{
    local TEMP

    local APP

    if [[ "${NO_DEBUG}" ]]
    then
# Проверяем выполнен ли base_plus
	[[ ! "${RUN_BASE_PLUS}" ]] && TEMP+=" $(str_base_plus)\n"
# Проверяем выполнен ли de пункт меню
	[[ ! "${RUN_DE}" ]] && TEMP+=" $(str_de)\n"

	if [[ "${TEMP}" ]]
	then
	    dialog_warn \
		"\Zb\Z1$(gettext 'Не выполнены обязательные пункты меню')\Zn\n${TEMP}"
	    return 1
	fi
    fi

    TEMP="$(pkgs_dialog_app)"
    for APP in ${TEMP}
    do
	pkgs_${APP}
	RUN_PKGS=1
    done
}

pkgs_dialog_app()
{
    msg_log "$(gettext 'Запуск диалога'): \"${FUNCNAME}$(for ((TEMP=1; TEMP<=${#}; TEMP++)); do echo -n " \$${TEMP}='$(eval "echo \"\${${TEMP}}\"")'"; done)\"" 'noecho'

    local RETURN

    local TITLE="${TXT_PKGS_MAIN}"
    local HELP_TXT="\n$(gettext 'Выберите дополнительное ПО')\n"

    local ITEMS="${APPS}"

    RETURN="$(dialog_checklist "${TITLE}" "${HELP_TXT}" "${ITEMS}" "--cancel-label '${TXT_MAIN_MENU}'")"

    echo "${RETURN}"
    msg_log "$(gettext 'Выход из диалога'): \"${FUNCNAME} return='${RETURN}'\"" 'noecho'
}

pkgs_de_xorg()
{
    local PACS
#===============================================================================
# Устанавливаем xorg
#===============================================================================
    #extra
    PACS='xorg xorg-xinit xdg-user-dirs xdg-utils'
    PACS+=' ttf-dejavu ttf-freefont ttf-linux-libertine ttf-bitstream-vera'
    PACS+=' xscreensaver'
    PACS+=' gstreamer0.10-plugins phonon-gstreamer'
    #community
    PACS+=' ttf-liberation ttf-droid'
    pacman_install "-S ${PACS}" '1'
#   #aur
#   PACS='ttf-ms-fonts'
# #  PACS='ttf-vista-fonts'
#    pacman_install "-S ${PACS}" '2'

    git_commit

    msg_log "$(gettext 'Настраиваю') /etc/skel/.Xresources"
    cat "${DBDIR}modules/etc/skel/.Xresources" > "${NS_PATH}/etc/skel/.Xresources"

    msg_log "$(gettext 'Добавляю') alias startx > /etc/skel/.zshrc"
    echo 'which startx 2>&1 > /dev/null && alias startx="startx &> ~/.xlog"' >> "${NS_PATH}/etc/skel/.zshrc"
    cat "${NS_PATH}/etc/skel/.zshrc" > "${NS_PATH}/root/.zshrc"
#-------------------------------------------------------------------------------



#===============================================================================
# Настраиваем раскладку в Xorg
#===============================================================================
    mkdir -p "${NS_PATH}/etc/X11/xorg.conf.d/"

    local XOPTIONS="$(grep "[[:space:]]${SET_KEYMAP}[[:space:]]" "${DBDIR}keymaps.db")"
    local XLAYOUT="$(awk '{print $3}' <<< "${XOPTIONS}")"
    local XMODEL="$(awk '{print $4}' <<< "${XOPTIONS}")"
    local XVARIANT="$(awk '{print $5}' <<< "${XOPTIONS}")"
    XOPTIONS="$(awk '{print $6}' <<< "${XOPTIONS}")"

    msg_log "$(gettext 'Настраиваю') /etc/X11/xorg.conf.d/00-keyboard.conf"
    {
	echo -e 'Section\t"InputClass"'
	echo -e '\tIdentifier\t"system-keyboard"'
	echo -e '\tMatchIsKeyboard\t"on"'
	[[ ! "${XLAYOUT}" ]] && echo -ne '# '
	echo -e "\tOption\t\"XkbLayout\" \"${XLAYOUT}\""
	[[ ! "${XMODEL}" ]] && echo -ne '# '
	echo -e "\tOption\t\"XkbModel\" \"${XMODEL}\""
	[[ ! "${XVARIANT}" ]] && echo -ne '# '
	echo -e "\tOption\t\"XkbVariant\" \"${XVARIANT}\""
	[[ ! "${XOPTIONS}" ]] && echo -ne '# '
	echo -e "\tOption\t\"XkbOptions\" \"${XOPTIONS}\""
	echo -e 'EndSection'
    } > "${NS_PATH}/etc/X11/xorg.conf.d/00-keyboard.conf"
#  chroot_run localectl --no-convert set-x11-keymap "${XLAYOUT}" "${XMODEL}" "${XVARIANT}" "${XOPTIONS}"
#-------------------------------------------------------------------------------



#===============================================================================
# Настраиваем разрешение монитора для Xorg
#===============================================================================
    msg_log "$(gettext 'Настраиваю') /etc/X11/xorg.conf.d/00-monitor.conf"
    {
	echo -e 'Section\t"Monitor"'
	echo -e '\tIdentifier\t"Monitor0"'
	echo -e '\tVendorName\t"Unknown"'
	echo -e 'EndSection'
	echo -e ''
	echo -e 'Section\t"Device"'
	echo -e '\tIdentifier\t"Device0"'
	echo -e 'EndSection'
	echo -e ''
	echo -e 'Section\t"Screen"'
	echo -e '\tIdentifier\t"Screen0"'
	echo -e '\tDevice\t"Device0"'
	echo -e '\tMonitor\t"Monitor0"'
	echo -e "\tDefaultDepth\t${SET_XORG_XxYxD##*x}"
	echo -e '\tSubSection\t"Display"'
	echo -e "\t\tDepth\t${SET_XORG_XxYxD##*x}"
	echo -e "\t\tModes\t\"${SET_XORG_XxYxD%x*}\""
	echo -e '\tEndSubSection'
	echo -e 'EndSection'
    } > "${NS_PATH}/etc/X11/xorg.conf.d/00-monitor.conf"
    git_commit
}

pkgs_de_mesa()
{
    local PACS
    #extra
    PACS='mesa-demos mesa-libgl'
    pacman_install "-S ${PACS}" '2'
    #multilib
    PACS='lib32-mesa-demos lib32-mesa-libgl'
    pacman_install "-S ${PACS}" '2'
    git_commit
}

pkgs_base_plus_yaourt()
{
    local PACS
    #core
    PACS='base-devel'
    pacman_install "-S ${PACS}" '1'
    git_commit

    #extra
    PACS='namcap ccache pkgstats'
    #community
    PACS+=' pkgtools upx'
    pacman_install "-S ${PACS}" '1'
    git_commit


# Устанавливаем не официальный репозиторий для установки yaourt
# curl -O https://aur.archlinux.org/packages/pa/package-query/package-query.tar.gz
# tar zxvf package-query.tar.gz
# cd package-query
# makepkg -si
# cd ..
# curl -O https://aur.archlinux.org/packages/ya/yaourt/yaourt.tar.gz
# tar zxvf yaourt.tar.gz
# cd yaourt
# makepkg -si
# cd ..
    msg_log "$(gettext 'Добавляю') archlinuxfr > /etc/pacman.conf"
    cp -Pb "${NS_PATH}/etc/pacman.conf" "${NS_PATH}/etc/pacman.conf.bak"
    echo '' >> "${NS_PATH}/etc/pacman.conf"
    echo '[archlinuxfr]' >> "${NS_PATH}/etc/pacman.conf"
    echo '# The French Arch Linux communities packages.' >> "${NS_PATH}/etc/pacman.conf"
    echo 'SigLevel = PackageOptional' >> "${NS_PATH}/etc/pacman.conf"
    echo 'Server = http://repo.archlinux.fr/$arch' >> "${NS_PATH}/etc/pacman.conf"

    pacman_install '-Syy' '1'

    #aur
    PACS='yaourt'
    pacman_install "-S ${PACS}" '1'
    git_commit

# удаляем репозиторий archlinuxfr добавленный ранее для установки yaourt
    msg_log "$(gettext 'Удаляю') archlinuxfr > /etc/pacman.conf"
    cp -Pb "${NS_PATH}/etc/pacman.conf.bak" "${NS_PATH}/etc/pacman.conf"
    pacman_install '-Syy' '1'

    msg_log "$(gettext 'Настраиваю') /etc/yaourtrc"
    sed -i '
# Разрешаем экспорт пакетов
/^EXPORT=/s/^/#/;
0,/^#EXPORT=/{
  //{
    a EXPORT=1
  };
};
# Разрешаем экспорт исходных кодов пакетов
/^EXPORTSRC=/s/^/#/;
0,/^#EXPORTSRC=/{
  //{
    a EXPORTSRC=1
  };
};
' "${NS_PATH}/etc/yaourtrc"

#    msg_log "$(gettext 'Добавляю') pacman-color > /etc/skel/.zshrc"
#    echo 'which pacman-color 2>&1 > /dev/null && alias pacman="pacman-color"' >> "${NS_PATH}/etc/skel/.zshrc"
#    cat "${NS_PATH}/etc/skel/.zshrc" > "${NS_PATH}/root/.zshrc"
    git_commit

# aurvote Нужно зарегистрироваться https://aur.archlinux.org/account.php
    #aur
    PACS='aurvote customizepkg downgrade'
    pacman_install "-S ${PACS}" '2'
    git_commit
#-------------------------------------------------------------------------------
}

pkgs_base_plus_gobject()
{
    local PACS
     #extra
     PACS='python2-gobject'
     pacman_install "-S ${PACS}" '1'
     git_commit
    msg_log "$(gettext 'Добавляю') timestamp > /etc/mkinitcpio.conf"
    sed -i '
# Добавляем хук timestamp
/^HOOKS=/{
    h;
    s/^/#/;
    P;g;
    //{
	s/timestamp//g;s/ \{1,\}/ /g;
	s/base/timestamp base/;
    };
};
' "${NS_PATH}/etc/mkinitcpio.conf"

    git_commit
}

pkgs_base_plus_aspell_loc()
{
    local PACS
    PACS="aspell-${SET_LOCAL%_*}"
    pacman_install "-S ${PACS}" '2'
    git_commit
}

pkgs_base_plus_zramswap()
{
    local PACS
    PACS='zramswap'
    pacman_install "-S ${PACS}" '2'
    git_commit
    SERVICES+=" 'zramswap.service' '-' 'on'"
}

pkgs_base_plus_cdemu()
{
    local PACS
    PACS='cdemu-client'
    pacman_install "-S ${PACS}" '1'
    git_commit
    SERVICES+=" 'cdemu-daemon.service' '-' 'off'"
}

pkgs_base_plus_crypt_swapfile()
{
    local PACS
#     pacman_install '-U /aai/db/my_pkgs/crypt-swapfile-1.0-1-any.pkg.tar.xz' '0' 'noexit'
#     git_commit
# 
#     SERVICES+=" 'crypt-swapfile.service' '-' 'off'"
}

pkgs_base_plus_cpu_temperature_save()
{
    local PACS
    pacman_install '-U /aai/db/my_pkgs/cpu-temperature-save-1.0-1-any.pkg.tar.xz' '0' 'noexit'
    git_commit

    SERVICES+=" 'cpu-temperature-save.timer' '-' 'off'"
}

pkgs_base_plus_alsa()
{
    local PACS
    #extra
    PACS='alsa-utils alsa-firmware alsa-plugins'
    PACS+=' alsa-oss'
    pacman_install "-S ${PACS}" '1'
    git_commit

    msg_log "$(gettext 'Настраиваю') /etc/modules-load.d/snd-alsa-oss.conf"
    cat "${DBDIR}modules/etc/modules-load.d/snd-alsa-oss.conf" > "${NS_PATH}/etc/modules-load.d/snd-alsa-oss.conf"
    git_commit
}

pkgs_base_plus_squashfs()
{
    local PACS
    #community
    PACS='squashfs-tools'
    pacman_install "-S ${PACS}" '1'
#     pacman_install '-U /aai/db/my_pkgs/mkinitcpio-squashfs-usr-file-1.0-1-any.pkg.tar.xz' '0' 'noexit'
    git_commit

#     msg_log "$(gettext 'Добавляю') squashfs > /etc/mkinitcpio.conf"
#     sed -i '
# # Добавляем хук squashfs-usr-file
# /^HOOKS=/{
#     h;
#     s/^/#/;
#     P;g;
#     //{
# 	s/squashfs-usr-file//g;s/ \{1,\}/ /g;
# 	s/filesystems/filesystems squashfs-usr-file/;
#     };
# };
# # Добавляем модуль squashfs
# /^MODULES=/{
#     h;
#     s/^MODULES/#MODULES/;
#     P;g;
#     /^MODULES=/{
# 	s/squashfs//g;s/ \{1,\}/ /g;
# 	s/="/="squashfs /;
#     };
# };
# ' "${NS_PATH}/etc/mkinitcpio.conf"
# 
#     git_commit
}

pkgs_base_plus_archives()
{
    local PACS
    #extra
    PACS='unzip cpio'
    #community
    PACS+=' unshield'
    pacman_install "-S ${PACS}" '1'
    git_commit
}

pkgs_base_plus_man_pages_loc()
{
    local PACS
    PACS="man-pages-${SET_LOCAL%_*}"
    pacman_install "-S ${PACS}" '2'
    git_commit

# Закомментировал потому что очень долго выполняется!!!
#   msg_info "$(gettext 'Пожалуйста, подождите')..."
#   chroot_run bash -c "'LANG=$(awk '{print $1}' <<< "${SET_LOCAL}") mandb --quiet'"
# 
#   git_commit
}

pkgs_base_plus_crypt()
{
    local PACS
    #extra
    PACS='truecrypt'
    #community
    PACS+=' encfs ecryptfs-utils'
    pacman_install "-S ${PACS}" '1'

    git_commit

# Добавляем в pam модуль авторасшифровки домашней папки пользователя
    msg_log "$(gettext 'Настраиваю') /etc/pam.d/system-auth"
    sed -i '
/eCryptfs/s/^/#/;
/^auth[ \t]*required[ \t]*pam_unix.so/{
  a auth      required  pam_ecryptfs.so unwrap # eCryptfs
};
/^password[ \t]*required[ \t]*pam_unix.so/{
  i password  required  pam_ecryptfs.so # eCryptfs
};
/^session[ \t]*required[ \t]*pam_limits.so/{
  i session   required  pam_ecryptfs.so unwrap # eCryptfs
};
' "${NS_PATH}/etc/pam.d/system-auth"

    chroot_run groupadd ecryptfs
    git_commit
}

pkgs_base_plus_fs()
{
    local PACS
    #extra
    PACS='dosfstools avfs'
    #community
    PACS+=' exfat-utils'
    pacman_install "-S ${PACS}" '1'
    git_commit
}

pkgs_base_plus_hd()
{
    local PACS
    #core
    PACS='sdparm'
    #extra
    PACS+=' gpart'
    #community
    PACS+=' extundelete anyfs-tools'
    pacman_install "-S ${PACS}" '1'
    git_commit
}

pkgs_base_plus_laptop()
{
    local PACS
    #extra
    PACS='upower bluez bluez-firmware'
    #community
    PACS+=' laptop-mode-tools apcupsd powertop'
    # acpi acpid
    pacman_install "-S ${PACS}" '1'

    git_commit

    SERVICES+=" 'upower.service' '-' 'off'"
    SERVICES+=" 'bluetooth.service' '-' 'off'"
    SERVICES+=" 'laptop-mode.service' '-' 'off'"
    SERVICES+=" 'apcupsd.service' '-' 'off'"
}

pkgs_base_plus_mlocate()
{
    local PACS
    #core
    PACS='mlocate'
    pacman_install "-S ${PACS}" '1'

    git_commit

    chroot_run updatedb

    git_commit
}

pkgs_base_plus_utils()
{
    local PACS
    #extra
    PACS='beep whois postfix proftpd lirc lirc-utils rtkit irqbalance fbset'
    PACS+=' htop lsof strace'
    #community
    PACS+=' linux-tools cpupower libtraceevent perf usbip x86_energy_perf_policy'
    PACS+=' audit lshw hwinfo flashrom grc chrony mcelog iotop'
    pacman_install "-S ${PACS}" '1'

    git_commit

    SERVICES+=" 'postfix.service' '-' 'off'"
    SERVICES+=" 'proftpd.service' '-' 'off'"
    SERVICES+=" 'irexec.service' '-' 'off'"
    SERVICES+=" 'lirc.service' '-' 'off'"
    SERVICES+=" 'lircm.service' '-' 'off'"
    SERVICES+=" 'rtkit-daemon.service' '-' 'off'"
    SERVICES+=" 'irqbalance.service' '-' 'off'"
    SERVICES+=" 'cpupower.service' '-' 'on'"
    SERVICES+=" 'usbipd.service' '-' 'off'"
    SERVICES+=" 'auditd.service' '-' 'off'"
    SERVICES+=" 'chronyd.service' '-' 'off'"
    SERVICES+=" 'mcelog.service' '-' 'off'"
}

pkgs_base_plus_sensors()
{
    local PACS
    #extra
    PACS='lm_sensors dmidecode'
    #community
    PACS+=' i2c-tools'
    pacman_install "-S ${PACS}" '1'
    git_commit
    chroot_run bash -c "'(while :; do echo \"\"; done ) | sensors-detect'"

    git_commit

    SERVICES+=" 'fancontrol.service' '-' 'off'"
    SERVICES+=" 'healthd.service' '-' 'off'"
    SERVICES+=" 'lm_sensors.service' '-' 'off'"
    SERVICES+=" 'sensord.service' '-' 'off'"
}

pkgs_base_plus_preload()
{
    local PACS
    #community
    PACS='preload'
    pacman_install "-S ${PACS}" '1'
    git_commit

    SERVICES+=" 'preload.service' '-' 'on'"
}

pkgs_base_plus_aria2()
{
    local PACS
    #community
    PACS='aria2'
    pacman_install "-S ${PACS}" '1'
    git_commit

# Добавляем пред настройки для aria2
    msg_log "$(gettext 'Настраиваю') /etc/skel/.aria2/aria2.conf"
    mkdir -p "${NS_PATH}/etc/skel/.aria2"
    cat "${DBDIR}modules/etc/skel/.aria2/aria2.conf" > "${NS_PATH}/etc/skel/.aria2/aria2.conf"

    git_commit
}

pkgs_base_plus_net()
{
    local PACS
    #core
    PACS='net-tools isdn4k-utils iw wireless-regdb'
    #extra
    PACS+=' modemmanager nss-mdns'
# samba
    #community
    PACS+=' openresolv arp-scan dsniff ntop'
    pacman_install "-S ${PACS}" '1'

    git_commit

    SERVICES+=" 'ntop.service' '-' 'off'"
}

pkgs_base_plus_iptables()
{
    local PACS

    #core
    PACS='iptables'
    pacman_install "-S ${PACS}" '1'
    git_commit

# включаем iptables
    msg_log "$(gettext 'Настраиваю') /etc/iptables/iptables.rules"
    cat "${DBDIR}modules/etc/iptables/iptables.rules" > "${NS_PATH}/etc/iptables/iptables.rules"

# включаем ip6tables
    cat "${DBDIR}modules/etc/iptables/ip6tables.rules" > "${NS_PATH}/etc/iptables/ip6tables.rules"

    git_commit

    SERVICES+=" 'ip6tables.service' '-' 'off'"
    SERVICES+=" 'iptables.service' '-' 'off'"
}

pkgs_base_plus_ufw()
{
    local PACS
    #community
    PACS='ufw'
    pacman_install "-S ${PACS}" '1'
    git_commit

    msg_log "$(gettext 'Настраиваю') /etc/ufw/ufw.conf"
    sed -i '
# Включаем ufw
/^ENABLED=/s/^/#/;
0,/^#ENABLED=/{
  //{
    a ENABLED=yes
  };
};
# Полностью отключаем лог
/^LOGLEVEL=/s/^/#/;
0,/^#LOGLEVEL=/{
  //{
    a LOGLEVEL=off
  };
};
' "${NS_PATH}/etc/ufw/ufw.conf"

    SERVICES+=" 'ufw.service' '-' 'off'"

    git_commit
}

pkgs_base_mc()
{
    local PACS
    #extra
    PACS='p7zip zip unrar smbclient mtools cvs aspell cdrkit cdparanoia'
    #community
    PACS+=' mc unarj unace python2-pytz python2-boto cabextract'
    pacman_install "-S ${PACS}" '1'

    git_commit
}

pkgs_base_sudo()
{
    local PACS
    #core
    PACS='sudo'
    pacman_install "-S ${PACS}" '1'

    git_commit

# Разрешаем использование sudo пользователям в группе wheel
    msg_log "$(gettext 'Настраиваю') /etc/sudoers"
    sed -i '
/^%wheel ALL=(ALL) ALL/s/^/#/;
/^# %wheel ALL=(ALL) ALL$/{
    h;
    s/^# //;
    H;
    g;
};
' "${NS_PATH}/etc/sudoers"

    git_commit
}

pkgs_base_zsh()
{
    local PACS
    #extra
    PACS='zsh grml-zsh-config'
    pacman_install "-S ${PACS}" '1'

    git_commit

# Меняем оболочку по умолчанию для новых пользователей
    chroot_run useradd -D --shell /bin/zsh
# Меняем оболочку по умолчанию для root
    chroot_run usermod --shell /bin/zsh root

    git_commit
}

pkgs_base_hd()
{
    local PACS
    #core
    PACS='hdparm'
    #extra
    PACS+=' smartmontools parted gptfdisk fsarchiver testdisk ddrescue'
    #community
    PACS+=' partclone partimage'
    pacman_install "-S ${PACS}" '1'

    git_commit

    SERVICES+=" 'smartd.service'  '-' 'off'"
    SERVICES+=" 'partimaged.service'  '-' 'off'"
}

pkgs_base_fs()
{
    local PACS
    #core
    PACS='mkinitcpio-nfs-utils nfs-utils nilfs-utils dmraid'
    #extra
    PACS+=' ntfs-3g'
    #community
    PACS+=' nbd'
    pacman_install "-S ${PACS}" '1'

    git_commit

    SERVICES+=" 'blkmapd.service'  '-' 'off'"
    SERVICES+=" 'nfsd.service'  '-' 'off'"
    SERVICES+=" 'rpc-gssd.service'  '-' 'off'"
    SERVICES+=" 'rpc-idmapd.service'  '-' 'off'"
    SERVICES+=" 'rpc-mountd.service'  '-' 'off'"
    SERVICES+=" 'rpc-statd.service'  '-' 'off'"
    SERVICES+=" 'rpc-svcgssd.service'  '-' 'off'"
    SERVICES+=" 'dmraid.service'  '-' 'off'"
    SERVICES+=" 'nbd.service'  '-' 'off'"
}

pkgs_base_utils()
{
    local PACS
    #extra
    PACS='lftp irssi rsync wget'
    #community
    PACS+=' darkhttpd elinks js haveged'
    pacman_install "-S ${PACS}" '1'

    git_commit

    SERVICES+=" 'rsyncd.service'  '-' 'off'"
    SERVICES+=" 'haveged.service'  '-' 'off'"
}

pkgs_base_btrfs()
{
    local PACS
    #core
    PACS='btrfs-progs'
    pacman_install "-S ${PACS}" '1'

    git_commit

#     msg_log "$(gettext 'Добавляю') btrfs > /etc/mkinitcpio.conf"
#     sed -i '
# # Добавляем хук btrfs
# /^HOOKS=/{
#     h;
#     s/^/#/;
#     P;g;
#     //{
# 	s/btrfs//g;s/ \{1,\}/ /g;
# 	s/filesystems/btrfs filesystems/;
#     };
# };
# ' "${NS_PATH}/etc/mkinitcpio.conf"
# 

#     git_commit
}

pkgs_base_pkgfile()
{
    local PACS
    #community
    PACS='pkgfile'
    pacman_install "-S ${PACS}" '1'
    git_commit

# Добавляем определение в каком пакете можно найти не существующую команду
    msg_log "$(gettext 'Добавляю') pkgfile > /etc/skel/.zshrc"
    echo '[ -r /usr/share/doc/pkgfile/command-not-found.zsh ] && source /usr/share/doc/pkgfile/command-not-found.zsh' >> "${NS_PATH}/etc/skel/.zshrc"
    cat "${NS_PATH}/etc/skel/.zshrc" > "${NS_PATH}/root/.zshrc"

# Включаем ежедневное обновление базы по крону
    cat "${DBDIR}modules/etc/cron.daily/pkgfile" > "${NS_PATH}/etc/cron.daily/pkgfile"
    chmod +x "${NS_PATH}/etc/cron.daily/pkgfile"

# Обновляем базу pkgfile
    chroot_run pkgfile --update

    git_commit
}

pkgs_dolphin()
{
    local PACS
    #extra
    PACS='kdebase-dolphin kdegraphics-thumbnailers ruby kdesdk-dolphin-plugins kdemultimedia-ffmpegthumbs'
    PACS+=' kdebase-konsole kdebase-kdialog kdeutils-kwallet'
    pacman_install "-S ${PACS}" '1'
    #aur
    PACS='kde-servicemenus-rootactions'
    pacman_install "-S ${PACS}" '2'
    #extra
    PACS="kde-l10n-${SET_LOCAL%_*}"
    pacman_install "-S ${PACS}" '2'

    git_commit
}
APPS+=" 'dolphin' '$(gettext 'Файловый менеджер') (+AUR)' 'on'"

pkgs_kdeadmin()
{
    local PACS
    #extra
    PACS='kdeadmin kdeadmin-kcron kdeadmin-ksystemlog kdeadmin-kuser kdebase-kdepasswd'
    pacman_install "-S ${PACS}" '1'
    #extra
    PACS="kde-l10n-${SET_LOCAL%_*}"
    pacman_install "-S ${PACS}" '2'

    git_commit
}

pkgs_kdesdk()
{
    local PACS
    #extra
    PACS='kdesdk jre7-openjdk'
    pacman_install "-S ${PACS}" '1'
    #extra
    PACS="kde-l10n-${SET_LOCAL%_*}"
    pacman_install "-S ${PACS}" '2'

    git_commit
}

pkgs_kdepim()
{
    local PACS
    #extra
    PACS='kdepim'
    pacman_install "-S ${PACS}" '1'
    #extra
    PACS="kde-l10n-${SET_LOCAL%_*}"
    pacman_install "-S ${PACS}" '2'

    git_commit
}

pkgs_kdeutils()
{
    local PACS
    #extra
    PACS='kdeutils'
    pacman_install "-S ${PACS}" '1'
    #extra
    PACS="kde-l10n-${SET_LOCAL%_*}"
    pacman_install "-S ${PACS}" '2'

    git_commit
}

pkgs_kdewebdev()
{
    local PACS
    #extra
    PACS='kdewebdev'
    pacman_install "-S ${PACS}" '1'
    #extra
    PACS="kde-l10n-${SET_LOCAL%_*}"
    pacman_install "-S ${PACS}" '2'

    git_commit
}

pkgs_kdegraphics()
{
    local PACS
    #extra
    PACS='kdegraphics'
    pacman_install "-S ${PACS}" '1'
    #extra
    PACS="kde-l10n-${SET_LOCAL%_*}"
    pacman_install "-S ${PACS}" '2'

    git_commit
}

pkgs_kate()
{
    local PACS
    #extra
    PACS=' kdesdk-kate kdebase-konsole kdebindings-python'
    pacman_install "-S ${PACS}" '1'
    #extra
    PACS="kde-l10n-${SET_LOCAL%_*}"
    pacman_install "-S ${PACS}" '2'

    git_commit
}
APPS+=" 'kate' '$(gettext 'Хороший текстовый редактор')' 'on'"

pkgs_geany()
{
    local PACS
    #community
    PACS='geany geany-plugins'
    pacman_install "-S ${PACS}" '1'

    git_commit
}
APPS+=" 'geany' '$(gettext 'Текстовый редактор')' 'off'"

pkgs_sublime()
{
    local PACS
    #aur
    PACS='sublime-text'
    pacman_install "-S ${PACS}" '2'

    git_commit
}
APPS+=" 'sublime' '$(gettext 'Отличный текстовый редактор!!!') (AUR)' 'off'"

pkgs_vim()
{
    local PACS
    #extra
    PACS='vim'
    #community
    PACS+=' vim-plugins'
    pacman_install "-S ${PACS}" '1'

    PACS="vim-spell-${SET_LOCAL%_*}"
    pacman_install "-S ${PACS}" '2'

    git_commit
}
APPS+=" 'vim' '$(gettext 'Консольный текстовый редактор')' 'off'"

pkgs_acestream()
{
    local PACS
    #aur
    PACS='acestream'
    pacman_install "-S ${PACS}" '2'

    git_commit
}
APPS+=" 'acestream' '$(gettext 'Медиа-платформа нового поколения') (AUR)' 'off'"

pkgs_smplayer()
{
    local PACS
    #extra
    PACS='smplayer smplayer-themes'
    pacman_install "-S ${PACS}" '1'

    git_commit
}
APPS+=" 'smplayer' '$(gettext 'Видео плеер')' 'on'"

pkgs_bino()
{
    local PACS
    #aur
    PACS='bino'
    pacman_install "-S ${PACS}" '2'

    git_commit
}
APPS+=" 'bino' '$(gettext '3D Видео плеер') (AUR)' 'off'"

pkgs_audacious()
{
    local PACS
    #extra
    PACS='audacious rhythmbox'
    pacman_install "-S ${PACS}" '1'

    git_commit
}
APPS+=" 'audacious' '$(gettext 'Аудио плеер')' 'on'"

pkgs_tvtime()
{
    local PACS
    #community
    PACS='tvtime'
    pacman_install "-S ${PACS}" '1'
    #aur
    PACS='alevt kradio'
    pacman_install "-S ${PACS}" '2'
    git_commit
}
APPS+=" 'tvtime' '$(gettext 'ТВ и РАДИО тюнер') (+AUR)' 'off'"

pkgs_k3b()
{
    local PACS
    #extra
    PACS='k3b dvd+rw-tools vcdimager transcode emovix cdrdao cdparanoia'
    #community
    PACS+=' nrg2iso'
    pacman_install "-S ${PACS}" '1'

    git_commit
}
APPS+=" 'k3b' '$(gettext 'Запись CD')' 'on'"

pkgs_avidemux()
{
    local PACS
    #extra
    PACS='avidemux-qt mkvtoolnix-gtk mencoder mediainfo-gui'
    #community
    PACS+=' mediainfo-gui'
    pacman_install "-S ${PACS}" '1'

    git_commit
}
APPS+=" 'avidemux' '$(gettext 'Конвертер видео')' 'off'"

pkgs_openshot()
{
    local PACS
    #community
    PACS='openshot'
    pacman_install "-S ${PACS}" '1'
    git_commit
}
APPS+=" 'openshot' '$(gettext 'Редактор видео')' 'off'"

pkgs_soundkonverter()
{
    local PACS
    #extra
    PACS='cdrkit faac faad2 ffmpeg flac fluidsynth lame mplayer speex timidity++ vorbis-tools wavpack'
    #community
    PACS+=' rubyripper ruby-gtk2 soundkonverter mac mp3gain twolame vorbisgain'
    pacman_install "-S ${PACS}" '1'
    #aur
    PACS='split2flac-git isomaster'
    pacman_install "-S ${PACS}" '2'
    git_commit
}
APPS+=" 'soundkonverter' '$(gettext 'Конвертер аудио') (+AUR)' 'off'"

pkgs_snapshot()
{
    local PACS
    #extra
    PACS='kdegraphics-ksnapshot'
    pacman_install "-S ${PACS}" '1'
    git_commit
}
APPS+=" 'snapshot' '$(gettext 'Снимки экрана')' 'on'"

pkgs_xvidcap()
{
    local PACS
    #aur
    PACS='xvidcap'
    pacman_install "-S ${PACS}" '2'
    git_commit
}
APPS+=" 'xvidcap' '$(gettext 'Запись видео с экрана') (AUR)' 'on'"

pkgs_okular()
{
    local PACS
    #extra
    PACS='kdegraphics-okular kdegraphics-mobipocket kdegraphics-gwenview'
    pacman_install "-S ${PACS}" '1'
    git_commit
}
APPS+=" 'okular' '$(gettext 'Просмотр документов')' 'on'"

pkgs_hardinfo()
{
    local PACS
    #community
    PACS='hardinfo'
    pacman_install "-S ${PACS}" '1'
    git_commit
}
APPS+=" 'hardinfo' '$(gettext 'Информация о системе')' 'on'"

pkgs_diffuse()
{
    local PACS
    #community
    PACS='diffuse qgit'
    pacman_install "-S ${PACS}" '1'
    git_commit
}
APPS+=" 'diffuse' '$(gettext 'Работа с git репозиторием')' 'on'"

pkgs_gparted()
{
    local PACS
    #extra
    PACS='gparted'
    pacman_install "-S ${PACS}" '1'
    git_commit
}
APPS+=" 'gparted' '$(gettext 'Работа с разделами')' 'on'"

pkgs_tesseract()
{
    local PACS
    #community
    PACS='yagf tesseract ocrfeeder tesseract-data'
    pacman_install "-S ${PACS}" '1'
    #aur
    PACS='tesseract-gui'
    pacman_install "-S ${PACS}" '2'
    git_commit
}
APPS+=" 'tesseract' '$(gettext 'Система распознавания текста') (+AUR)' 'off'"

pkgs_libreoffice()
{
    local PACS
    #extra
    PACS='libreoffice libreoffice-extensions jdk7-openjdk'
    pacman_install "-S ${PACS}" '1'
    #extra
    PACS="libreoffice-${SET_LOCAL%_*}"
    pacman_install "-S ${PACS}" '2'
    git_commit
}
APPS+=" 'libreoffice' '$(gettext 'Офисные программы')' 'on'"

pkgs_gimp()
{
    local PACS
    #extra
    PACS='gimp'
    #community
    PACS+=' gimp-ufraw gimp-plugin-fblur gimp-plugin-gmic gimp-plugin-lqr gimp-plugin-mathmap'
    PACS+=' gimp-plugin-wavelet-decompose gimp-plugin-wavelet-denoise gimp-refocus'
    pacman_install "-S ${PACS}" '1'
    #extra
    PACS="gimp-help-${SET_LOCAL%_*}"
    pacman_install "-S ${PACS}" '2'
    git_commit
}
APPS+=" 'gimp' '$(gettext 'Графический редактор')' 'on'"

pkgs_inkscape()
{
    local PACS
    #extra
    PACS='inkscape'
    pacman_install "-S ${PACS}" '1'
    git_commit
}
APPS+=" 'inkscape' '$(gettext 'Векторный редактор')' 'on'"

pkgs_firefox()
{
    local PACS
    #extra
    PACS='firefox flashplugin icedtea-web-java7'
    #community
    PACS+=' gecko-mediaplayer'
    pacman_install "-S ${PACS}" '1'
    #extra
    PACS="firefox-i18n-${SET_LOCAL%_*}"
    pacman_install "-S ${PACS}" '2'
    git_commit
# http://adblockplus.org/ru/
# https://addons.mozilla.org/ru/firefox/addon/adblock-plus-pop-up-addon/
# http://www.binaryturf.com/free-software/colorfultabs-for-firefox/
# https://addons.mozilla.org/en-US/firefox/addon/cookies-manager-plus/
# https://addons.mozilla.org/ru/firefox/addon/css-usage/
# https://addons.mozilla.org/ru/firefox/addon/abpcustomization/
# https://addons.mozilla.org/ru/firefox/addon/default-fullzoom-level/
# http://developercompanion.com/
# https://addons.mozilla.org/ru/firefox/addon/video-downloadhelper/
# https://addons.mozilla.org/ru/firefox/addon/download-statusbar/
# https://addons.mozilla.org/ru/firefox/addon/elemhidehelper/
# https://addons.mozilla.org/ru/firefox/addon/firebug/
# https://addons.mozilla.org/ru/firefox/addon/fireftp/
# https://addons.mozilla.org/ru/firefox/addon/foxyproxy-standard/
# http://groups.google.com/group/quick-translator/browse_thread/thread/a03e58bd9ea45775
# https://addons.mozilla.org/ru/firefox/addon/imacros-for-firefox/
# https://addons.mozilla.org/ru/firefox/addon/validator/
# https://addons.mozilla.org/ru/firefox/addon/kde-wallet-password-integratio/
# https://addons.mozilla.org/ru/firefox/addon/total-validator/
# https://addons.mozilla.org/ru/firefox/addon/simple-markup-validator/
# https://addons.mozilla.org/ru/firefox/addon/showip/
# http://seleniumhq.org/download/
# https://addons.mozilla.org/ru/firefox/addon/oxygen-kde-patched/
}
APPS+=" 'firefox' '$(gettext 'Интернет браузер')' 'on'"

pkgs_opera()
{
    local PACS
    #extra
    PACS='flashplugin icedtea-web-java7'
    #community
    PACS+=' opera gecko-mediaplayer'
    pacman_install "-S ${PACS}" '1'
    git_commit
}
APPS+=" 'opera' '$(gettext 'Интернет браузер')' 'off'"

pkgs_claws()
{
    local PACS
    #extra
    PACS='claws-mail claws-mail-extra-plugins'
    PACS+=' spamassassin razor bogofilter'
    #community
    PACS+=' dspam p3scan'
    pacman_install "-S ${PACS}" '1'
    git_commit
    chroot_run /usr/bin/vendor_perl/sa-update
    chroot_run /usr/bin/vendor_perl/sa-compile
    git_commit
}
APPS+=" 'claws' '$(gettext 'EMAIL клиент')' 'on'"

pkgs_filezilla()
{
    local PACS
    #extra
    PACS='filezilla'
    pacman_install "-S ${PACS}" '1'
    git_commit
}
APPS+=" 'filezilla' '$(gettext 'FTP клиент')' 'on'"

#Хороший торрент клиент но при работе вылетает (((
# kernel: qbittorrent[5140]: segfault at 680000003f ip 00007f963956ad63 sp 00007f962c55ba00 error 4 in libc-2.17.so[7f96394ef000+1a4000]
pkgs_qbittorrent()
{
    local PACS
    #aur
    PACS='qbittorrent'
    pacman_install "-S ${PACS}" '2'
    git_commit
}
APPS+=" 'qbittorrent' '$(gettext 'TORRENT клиент') (AUR)' 'off'"

pkgs_pidgin()
{
    local PACS
    #extra
    PACS='pidgin'
    #community
    PACS+=' pidgin-encryption pidgin-libnotify pidgin-toobars'
    pacman_install "-S ${PACS}" '1'
    #aur
    PACS='pidgin-bot-sentry'
    pacman_install "-S ${PACS}" '2'
    git_commit
}
APPS+=" 'pidgin' '$(gettext 'ICQ, QIP и т.п.') (+AUR)' 'on'"

pkgs_skype()
{
    local PACS
    #extra
    PACS='ekiga'
    #community
    PACS+=' skype-call-recorder'
    #multilib
    PACS+=' skype'
# lib32-libcanberra lib32-libpulse
    pacman_install "-S ${PACS}" '1'
    git_commit
}
APPS+=" 'skype' '$(gettext 'Skype, Ekiga')' 'on'"

pkgs_cryptkeeper()
{
    local PACS
    #community
    PACS='gpg-crypter'
    pacman_install "-S ${PACS}" '1'
    #aur
    PACS='cryptkeeper'
    pacman_install "-S ${PACS}" '2'
    git_commit
}
APPS+=" 'cryptkeeper' '$(gettext 'GUI для шифрования папок') (+AUR)' 'on'"

pkgs_mmex()
{
    local PACS
    #aur
    PACS='mmex'
    pacman_install "-S ${PACS}" '2'
    git_commit
}
APPS+=" 'mmex' '$(gettext 'Менеджер личных финансов') (AUR)' 'off'"

pkgs_clamav()
{
    local PACS
    #extra
    PACS='clamav'
    pacman_install "-S ${PACS}" '1'
    git_commit

    msg_log "$(gettext 'Настраиваю') /etc/clamav/clamd.conf"
    sed -i "
/^Example/s/^/#/;
" "${NS_PATH}/etc/clamav/clamd.conf"
    msg_log "$(gettext 'Настраиваю') /etc/clamav/freshclam.conf"
    sed -i "
/^Example/s/^/#/;
" "${NS_PATH}/etc/clamav/freshclam.conf"
    msg_info "$(gettext 'Пожалуйста, подождите')..."
    chroot_run freshclam
    git_commit
}
APPS+=" 'clamav' '$(gettext 'Антивирус')' 'off'"

pkgs_stardict()
{
    local PACS
    #community
    PACS='stardict'
    pacman_install "-S ${PACS}" '1'
    git_commit
}
APPS+=" 'stardict' '$(gettext 'Словарь')' 'off'"

pkgs_mixxx()
{
    local PACS
    #community
    PACS='mixxx'
    pacman_install "-S ${PACS}" '1'
    git_commit
}
APPS+=" 'mixxx' '$(gettext 'Цифровая DJ система')' 'off'"

pkgs_myrulib()
{
    local PACS
    #aur
    PACS='myrulib'
    pacman_install "-S ${PACS}" '2'
    git_commit
}
APPS+=" 'myrulib' '$(gettext 'Домашняя библиотека') (AUR)' 'off'"

pkgs_blender()
{
    local PACS
    #community
    PACS='blender'
    pacman_install "-S ${PACS}" '1'
    git_commit
}
APPS+=" 'blender' '$(gettext '3D моделирование')' 'off'"

pkgs_sweethome3d()
{
    local PACS
    #aur
    PACS='sweethome3d'
    pacman_install "-S ${PACS}" '2'
    git_commit
}
APPS+=" 'sweethome3d' '$(gettext '3D дизайн интерьера') (AUR)' 'off'"

pkgs_virtualbox()
{
    local PACS
    #community
    PACS='virtualbox virtualbox-host-modules'
    pacman_install "-S ${PACS}" '1'
    #aur
    PACS='virtualbox-ext-oracle'
    pacman_install "-S ${PACS}" '2'
    git_commit
    msg_log "$(gettext 'Настраиваю') /etc/modules-load.d/vbox.conf"
    cat "${DBDIR}modules/etc/modules-load.d/vbox.conf" > "${NS_PATH}/etc/modules-load.d/vbox.conf"
    git_commit
}
APPS+=" 'virtualbox' '$(gettext 'Виртуальная машина') (+AUR)' 'off'"

pkgs_ettercap()
{
    local PACS
    #community
    PACS='ettercap-gtk'
    pacman_install "-S ${PACS}" '1'
    #aur
    PACS='netdiscover hydra nikto'
    pacman_install "-S ${PACS}" '2'
    git_commit
    chroot_run nikto -update
    git_commit
}
APPS+=" 'ettercap' '$(gettext 'Анализ безопасности сети') (+AUR)' 'off'"

pkgs_wireshark()
{
    local PACS
    #extra
    PACS='wireshark-gtk'
    pacman_install "-S ${PACS}" '1'
    git_commit
}
APPS+=" 'wireshark' '$(gettext 'Анализатор трафика для сетей Ethernet')' 'off'"

pkgs_eric()
{
    local PACS
    #extra
    PACS='eric'
    pacman_install "-S ${PACS}" '1'
    #aur
    PACS='eric5-i18n'
    pacman_install "-S ${PACS}" '2'
    git_commit
}
APPS+=" 'eric' '$(gettext 'Python редактор') (+AUR)' 'off'"

pkgs_netbeans()
{
    local PACS
    #community
    PACS='netbeans'
    pacman_install "-S ${PACS}" '1'
    git_commit
}
APPS+=" 'netbeans' '$(gettext 'Java, PHP, C, C++ редактор')' 'off'"

pkgs_kdevelop()
{
    local PACS
    #community
    PACS='kdevelop'
    #community
    PACS+=' qtcreator poedit'
    pacman_install "-S ${PACS}" '1'
    #extra
    PACS="kde-l10n-${SET_LOCAL%_*}"
    pacman_install "-S ${PACS}" '2'
    git_commit
}
APPS+=" 'kdevelop' '$(gettext 'Разработка на C++')' 'off'"

pkgs_kpatience()
{
    local PACS
    #community
    PACS='kdegames-kpatience'
    pacman_install "-S ${PACS}" '1'
    #extra
    PACS="kde-l10n-${SET_LOCAL%_*}"
    pacman_install "-S ${PACS}" '2'
    git_commit
}
APPS+=" 'kpatience' '$(gettext 'Игра. Пасьянсы')' 'on'"

pkgs_urbanterror()
{
    local PACS
    #community
    PACS='urbanterror'
    pacman_install "-S ${PACS}" '1'
    git_commit
}
APPS+=" 'urbanterror' '$(gettext 'Игра. 3D Шутер от первого лица')' 'off'"

pkgs_spring()
{
    local PACS
    #community
    PACS='springlobby spring'
    pacman_install "-S ${PACS}" '1'
    git_commit
}
APPS+=" 'spring' '$(gettext 'Игра. 3D Стратегия')' 'off'"

pkgs_ufoai()
{
    local PACS
    #community
    PACS='ufoai'
    pacman_install "-S ${PACS}" '1'
    git_commit
}
APPS+=" 'ufoai' '$(gettext 'Игра. Смесь ролевой игры и стратегии')' 'off'"

pkgs_0ad()
{
    local PACS
    #community
    PACS='0ad'
    pacman_install "-S ${PACS}" '1'
    git_commit
}
APPS+=" '0ad' '$(gettext 'Игра. 3D Стратегия')' 'off'"

pkgs_apache()
{
    local PACS
    #extra
    PACS='apache'
    pacman_install "-S ${PACS}" '1'
    git_commit

    mkdir -p "${NS_PATH}"/etc/httpd/conf/{sites-available,sites-enabled}

    git_commit
}

pkgs_nginx()
{
    local PACS
    #community
    PACS='nginx'
    pacman_install "-S ${PACS}" '1'

    git_commit

    cp -Pb "${DBDIR}modules/etc/nginx/nginx.conf" "${NS_PATH}/etc/nginx/nginx.conf"
    cp -Pb "${DBDIR}modules/etc/nginx/mime.types" "${NS_PATH}/etc/nginx/mime.types"
    cp -Pb "${DBDIR}modules/etc/nginx/uwsgi_params" "${NS_PATH}/etc/nginx/uwsgi_params"
    cat "${DBDIR}modules/etc/nginx/proxy.conf" > "${NS_PATH}/etc/nginx/proxy.conf"

    mkdir -p "${NS_PATH}"/etc/nginx/{sites-available,sites-enabled,templates}

    cp -Pb "${DBDIR}"modules/etc/nginx/templates/* "${NS_PATH}"/etc/nginx/templates/
    cp -Pb "${DBDIR}"modules/etc/nginx/sites-available/* "${NS_PATH}"/etc/nginx/sites-available/

    ln -srf "${NS_PATH}/etc/nginx/sites-available/localhost.conf" "${NS_PATH}/etc/nginx/sites-enabled/localhost.conf"

    mkdir -p "${NS_PATH}"/srv/http/nginx/{public,private,logs,backup}
    cp -Pb "${NS_PATH}"/usr/share/html/* "${NS_PATH}"/srv/http/nginx/public/

    ln -sr "${NS_PATH}/usr/share/webapps/phpMyAdmin" "${NS_PATH}/srv/http/nginx/public/phpmyadmin"
    ln -sr "${NS_PATH}/usr/share/webapps/phppgadmin" "${NS_PATH}/srv/http/nginx/public/phppgadmin"

    chroot_run systemctl enable nginx.service
    git_commit
}

pkgs_php()
{
    local PACS
    #extra
    PACS='php php-sqlite php-apc php-gd php-mcrypt php-pear php-pspell php-snmp php-tidy php-xsl php-intl'
    PACS+=' php-fpm'
#    PACS+=' php-apache'
    pacman_install "-S ${PACS}" '1'
    git_commit

    cp -Pb "${DBDIR}modules/etc/php/php.ini" "${NS_PATH}/etc/php/php.ini"

    chroot_run systemctl enable php-fpm.service
    git_commit
}

pkgs_mariadb()
{
    local PACS
    #extra
    PACS='mariadb'
    #community
    PACS+=' phpmyadmin'
    pacman_install "-S ${PACS}" '1'
    git_commit

    chroot_run systemctl enable mysqld.service
    git_commit
# Поменять в /etc/webapps/phpmyadmin/config.inc.php
# $cfg['Servers'][$i]['AllowNoPassword'] = false;
# $cfg['Servers'][$i]['AllowNoPassword'] = true;
}


pkgs_postgresql()
{
    local PACS
    #extra
    PACS='php-pgsql'
    #community
    PACS+=' postgresql pgadmin3'
#    phppgadmin
    pacman_install "-S ${PACS}" '1'
    git_commit

    mkdir -p "${NS_PATH}"/var/lib/postgres/data
    chroot_run chown -Rh -c postgres:postgres "${NS_PATH}"/var/lib/postgres/data
    chroot_run bash -c "su postgres -c 'initdb --locale en_US.UTF-8 -D /var/lib/postgres/data && exit'"

    chroot_run systemctl enable postgresql.service
    git_commit

# su root
# su - postgres
# createuser -DRSP <username>
# -D Пользователь не может создавать базы данных
# -R Пользователь не может создавать аккаунты
# -S Пользователь не является суперпользователем
# -P Запрашивать пароль при создании
# createdb -O username databasename [-E database_encoding]
}
