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
MAIN_CASE+=('de')

#===============================================================================
# Сигнальная переменная успешного завершения функции модуля,
# может потребоваться для других модулей, для установки кода завершения
RUN_DE=
TXT_DE_MAIN="$(gettext 'Рабочий стол')"

# Переменная хранящая тип DE
SET_DE=
# Сигнальная переменная что Xorg уже установелн
SET_XORG=
# Разрешение Xorg
SET_XORG_XxYxD=
#===============================================================================

# Выводим строку пункта главного меню
str_de()
{
	local TEMP

	[[ "${RUN_DE}" ]] && TEMP="\Zb\Z2($(gettext 'ВЫПОЛНЕНО'))\Zn"
	echo "${TXT_DE_MAIN} ${TEMP}"
}

# Функция выполнения из главного меню
run_de()
{
	local TEMP

	if [[ "${NO_DEBUG}" ]]
	then
# Проверяем выполнен ли base_plus
		[[ ! "${RUN_BASE_PLUS}" ]] && TEMP+=" $(str_base_plus)\n"

		if [[ "${TEMP}" ]]
		then
			dialog_warn \
				"\Zb\Z1$(gettext 'Не выполнены обязательные пункты меню')\Zn\n${TEMP}"
			return 1
		fi

#		if [[ "${SET_DE}" ]]
#		then
#			dialog_warn \
#				"\Zb\Z1$(gettext 'Пункт') \"${TXT_DE_MAIN}\" $(gettext 'уже выполнен')\Zn \Zb\Z2\"${SET_DE}\"\Zn"
#			return 1
#		fi

	fi

	local DEF_MENU='kde'

	while true
	do
		DEF_MENU="$(de_dialog_menu "${DEF_MENU}")"
		case "${DEF_MENU}" in
			'no')
				dialog_yesno \
					"$(gettext 'Установить Xorg?')" \
					"$(gettext 'Установить комплект Xorg?')"
				case "${?}" in
					'0') #Yes
						de_install_xorg || continue
						[[ ! "$SET_DE" ]] && set_global_var 'SET_DE' "${DEF_MENU}"
					;;
				esac
				RUN_DE=1
				return 0
				;;
			'openbox' | 'lxde' | 'xfce4' | 'kde' | 'gnome' | 'mate' | 'cinnamon' | 'awesome')
				de_install_xorg || continue
				de_${DEF_MENU} || continue
				[[ ! "$SET_DE" ]] && set_global_var 'SET_DE' "${DEF_MENU}"
				RUN_DE=1
				return 0
				;;
			*)
				return 1
				;;
		esac
	done
}

de_dialog_menu()
{
	msg_log "$(gettext 'Запуск диалога'): \"${FUNCNAME}$(for ((TEMP=1; TEMP<=${#}; TEMP++)); do echo -n " \$${TEMP}='$(eval "echo \"\${${TEMP}}\"")'"; done)\"" 'noecho'

	local RETURN

	local P_DEF_MENU="${1}"

	local TITLE="${TXT_DE_MAIN}"
	local HELP_TXT="$(gettext 'Можно установить несколько, но по умолчанию прописан будет первый установленный')\n"
	HELP_TXT+="\n$(gettext 'Выберите рабочий стол')\n"
	HELP_TXT+="$(gettext 'По умолчанию'):"

	local DEFAULT_ITEM="${P_DEF_MENU}"
	local ITEMS="'no' '$(gettext 'Сам установлю, потом...')'"
	ITEMS+=" 'openbox' 'Open Box ($(gettext 'консольный вход'))'"
	ITEMS+=" 'kde' 'KDE'"
	ITEMS+=" 'xfce4' 'Xfce4 ($(gettext 'консольный вход'))'"
	ITEMS+=" 'lxde' 'LXDE'"
	ITEMS+=" 'e17' 'Enlightenment ($(gettext 'консольный вход'))'"
	ITEMS+=" 'gnome' 'GNOME'"
	ITEMS+=" 'mate' 'Mate ($(gettext 'консольный вход'))'"
	ITEMS+=" 'cinnamon' 'Cinnamon ($(gettext 'консольный вход'))'"
	ITEMS+=" 'awesome' 'Awesome ($(gettext 'консольный вход'))'"

	HELP_TXT+=" \Zb\Z7\"${DEFAULT_ITEM}\"\Zn\n"

	RETURN="$(dialog_menu "${TITLE}" "${DEFAULT_ITEM}" "${HELP_TXT}" "${ITEMS}" "--cancel-label '${TXT_MAIN_MENU}'")"

	echo "${RETURN}"
	msg_log "$(gettext 'Выход из диалога'): \"${FUNCNAME} return='${RETURN}'\"" 'noecho'
}

de_install_xorg()
{
	local TEMP

	[[ "${SET_XORG}" ]] && return 0

	TEMP="$(de_dialog_xorg)"
	[[ ! -n "${TEMP}" ]] && return 1
	SET_XORG_XxYxD="${TEMP}"

	pkgs_de_mesa

	pkgs_de_xorg

	set_global_var 'SET_XORG' '1'
}


de_dialog_xorg()
{
	msg_log "$(gettext 'Запуск диалога'): \"${FUNCNAME}$(for ((TEMP=1; TEMP<=${#}; TEMP++)); do echo -n " \$${TEMP}='$(eval "echo \"\${${TEMP}}\"")'"; done)\"" 'noecho'

	local RETURN

	local TITLE="${TXT_DE_MAIN}"
	local HELP_TXT="\n$(gettext 'Выберите разрешение экрана для Xorg')\n"
	HELP_TXT+="$(gettext 'По умолчанию'):"

	local DEFAULT_ITEM='1280x1024x24'
	local ITEMS="$(hwinfo --framebuffer | grep ' Mode ' |  awk -F ' ' '{print sq $3 "x" $5 sq " " sq $0 sq}' sq=\')"
#  local ITEMS="
#'640x480x8' '-' '800x600x8' '-' '1024x768x8' '-' '1280x1024x8' '-'
#'640x480x16' '-' '800x600x16' '-' '1024x768x16' '-' '1280x1024x16' '-'
#'640x480x24' '-' '800x600x24' '-' '1024x768x24' '-' '1280x1024x24' '-'
#"
	HELP_TXT+=" \Zb\Z7\"${DEFAULT_ITEM}\"\Zn\n"

	RETURN="$(dialog_menu "${TITLE}" "${DEFAULT_ITEM}" "${HELP_TXT}" "${ITEMS}")"

	echo "${RETURN}"
	msg_log "$(gettext 'Выход из диалога'): \"${FUNCNAME} return='${RETURN}'\"" 'noecho'
}


# Устанавливаем openbox
de_openbox()
{
	local PACS

#===============================================================================
# Устанавливаем openbox
#===============================================================================
	#community
	PACS='obconf obmenu openbox openbox-themes'
	#aur
	PACS+=' obkey-git'
#3ddesktop
	pacman_install "-S ${PACS}" '2'
	git_commit

	mkdir -p "${NS_PATH}/etc/skel/.config/openbox"
	cp "${NS_PATH}/etc/xdg/openbox/"{rc.xml,menu.xml,autostart,environment} "${NS_PATH}/etc/skel/.config/openbox"

	msg_log "$(gettext 'Настраиваю') /etc/skel/.config/openbox/rc.xml"
	sed -i "
s/<name>Clearlooks<\/name>/<name>Simple-Aubergine<\/name>/;
s/<number>4<\/number>/<number>2<\/number>/;
#s/entry in parent menu -->/entry in parent menu --\&gt;/;
" "${NS_PATH}/etc/skel/.config/openbox/rc.xml"

	if [[ ! "$SET_DE" ]]
	then
		msg_log "$(gettext 'Настраиваю') /etc/skel/.zprofile"
		echo '[[ -z ${DISPLAY} && ${XDG_VTNR} -eq 1 ]] && exec startx &> ~/.xlog' >> "${NS_PATH}/etc/skel/.zprofile"

		msg_log "$(gettext 'Настраиваю') /etc/skel/.xinitrc"
		echo 'exec openbox-session' >> "${NS_PATH}/etc/skel/.xinitrc"
	fi

	git_commit
#-------------------------------------------------------------------------------

#===============================================================================
# Устанавливаем тему курсора
#===============================================================================
	echo "export XCURSOR_THEME='Vanilla-DMZ'" >> "${NS_PATH}/etc/skel/.config/openbox/environment"

	git_commit

	#aur
	PACS='archlinux-artwork'
	pacman_install "-S ${PACS}" '2'
	git_commit

#===============================================================================
# Устанавливаем archlinux-xdg-menu
#===============================================================================
	#community
	PACS='archlinux-xdg-menu'
	#aur
#  PACS+=' arch-bubble-icons'
#3ddesktop
	pacman_install "-S ${PACS}" '2'
	git_commit

	msg_log "$(gettext 'Настраиваю') /etc/skel/.config/openbox/menu.xml"
	cat "${DBDIR}modules/etc/skel/.config/openbox/menu.xml" > "${NS_PATH}/etc/skel/.config/openbox/menu.xml"
	git_commit
#-------------------------------------------------------------------------------


#===============================================================================
# Устанавливаем xterm и добавляем настройки Xorg
#===============================================================================
	#extra
	PACS='xterm'
	pacman_install "-S ${PACS}" '2'
	git_commit

	msg_log "$(gettext 'Добавляю') Xresources > /etc/skel/.config/openbox/autostart"
	echo '([[ -f ~/.Xresources ]] && xrdb -merge ~/.Xresources) &' >> "${NS_PATH}/etc/skel/.config/openbox/autostart"
	echo '([[ -f ~/.Xmodmap ]] && xmodmap ~/.Xmodmap) &' >> "${NS_PATH}/etc/skel/.config/openbox/autostart"
	git_commit
#-------------------------------------------------------------------------------


#===============================================================================
# Устанавливаем oblogout
#===============================================================================
	#community
	PACS='oblogout'
	pacman_install "-S ${PACS}" '1'

	#aur
#    PACS='obsession'
#    pacman_install "-S ${PACS}" '2'
	git_commit
#-------------------------------------------------------------------------------


#===============================================================================
# Устанавливаем compton
#===============================================================================
#     #aur
	PACS='compton-git'
	pacman_install "-S ${PACS}" '2'
	git_commit

	mkdir -p "${NS_PATH}/etc/skel/.config/compton"

	msg_log "$(gettext 'Настраиваю') /etc/skel/.config/compton/compton.conf"
	sed "
/^menu-opacity =/s/^/#/;
/^inactive-opacity =/s/^/#/;
" "${NS_PATH}/etc/xdg/compton.conf.example" > "${NS_PATH}/etc/skel/.config/compton/compton.conf"

	msg_log "$(gettext 'Добавляю') compton > /etc/skel/.config/openbox/autostart"
	echo 'compton --config ~/.config/compton/compton.conf -b &' >> "${NS_PATH}/etc/skel/.config/openbox/autostart"
	git_commit
#-------------------------------------------------------------------------------


#===============================================================================
# Устанавливаем notify-osd
#===============================================================================
#  #extra
#  PACS='xfce4-notifyd'
	#community
	PACS='notify-osd'
	pacman_install "-S ${PACS}" '1'
	git_commit

	msg_log "$(gettext 'Добавляю') notify-osd > /etc/skel/.config/openbox/autostart"
	echo '/usr/lib/notify-osd/notify-osd &' >> "${NS_PATH}/etc/skel/.config/openbox/autostart"
	git_commit
#-------------------------------------------------------------------------------

#===============================================================================
# Устанавливаем nitrogen
#===============================================================================
	#extra
	PACS='nitrogen'
	#community
	PACS+=' archlinux-wallpaper'
	pacman_install "-S ${PACS}" '1'
	git_commit

	mkdir -p "${NS_PATH}/etc/skel/.config/nitrogen"

	msg_log "$(gettext 'Настраиваю') /etc/skel/.config/nitrogen/nitrogen.cfg"
	cat "${DBDIR}modules/etc/skel/.config/nitrogen/nitrogen.cfg" > "${NS_PATH}/etc/skel/.config/nitrogen/nitrogen.cfg"
	cat "${DBDIR}modules/etc/skel/.config/nitrogen/bg-saved.cfg" > "${NS_PATH}/etc/skel/.config/nitrogen/bg-saved.cfg"

	msg_log "$(gettext 'Добавляю') nitrogen > /etc/skel/.config/openbox/autostart"
	echo 'nitrogen --restore &' >> "${NS_PATH}/etc/skel/.config/openbox/autostart"

	git_commit
#-------------------------------------------------------------------------------


#===============================================================================
# Устанавливаем tint2
#===============================================================================
	#extra
	PACS='orage'
	#community
	PACS+=' tint2'
	#aur
#  PACS+=' tintwizard'
	pacman_install "-S ${PACS}" '2'
	git_commit

	mkdir -p "${NS_PATH}/etc/skel/.config/tint2"

	msg_log "$(gettext 'Настраиваю') /etc/skel/.config/tint2/tint2rc"
	cat "${DBDIR}modules/etc/skel/.config/tint2/tint2rc" > "${NS_PATH}/etc/skel/.config/tint2/tint2rc"

	msg_log "$(gettext 'Добавляю') tint2 > /etc/skel/.config/openbox/autostart"
	echo 'tint2 &' >> "${NS_PATH}/etc/skel/.config/openbox/autostart"

	git_commit
#-------------------------------------------------------------------------------


#===============================================================================
# Устанавливаем volumeicon
#===============================================================================
#community
	PACS='volumeicon'
	pacman_install "-S ${PACS}" '1'
	git_commit

	mkdir -p "${NS_PATH}/etc/skel/.config/volumeicon"

	msg_log "$(gettext 'Настраиваю') /etc/skel/.config/volumeicon/volumeicon"
	cat "${DBDIR}modules/etc/skel/.config/volumeicon/volumeicon" > "${NS_PATH}/etc/skel/.config/volumeicon/volumeicon"

	msg_log "$(gettext 'Добавляю') volumeicon > /etc/skel/.config/openbox/autostart"
	echo 'volumeicon &' >> "${NS_PATH}/etc/skel/.config/openbox/autostart"

	git_commit
#-------------------------------------------------------------------------------


#===============================================================================
# Устанавливаем numlockx
#===============================================================================
	#community
	PACS='numlockx'
	pacman_install "-S ${PACS}" '1'
	git_commit

	msg_log "$(gettext 'Добавляю') numlockx > /etc/skel/.config/openbox/autostart"
	echo 'numlockx &' >> "${NS_PATH}/etc/skel/.config/openbox/autostart"

	git_commit
#-------------------------------------------------------------------------------


#===============================================================================
# Устанавливаем gmrun
#===============================================================================
	#community
	PACS='gmrun'
	pacman_install "-S ${PACS}" '1'
	git_commit

	msg_log "$(gettext 'Настраиваю') /etc/skel/.config/openbox/rc.xml"
	sed -i '
0,/^<keyboard>/{
//{
	a   <keybind key="A-F2"><action name="Execute"><command>gmrun</command></action></keybind>
};
};
' "${NS_PATH}/etc/skel/.config/openbox/rc.xml"
	git_commit
#-------------------------------------------------------------------------------


#===============================================================================
# Устанавливаем conky
#===============================================================================
	#extra
	PACS='conky'
	pacman_install "-S ${PACS}" '1'
	git_commit

	mkdir -p "${NS_PATH}/etc/skel/.config/conky"

	msg_log "$(gettext 'Настраиваю') /etc/skel/.config/conky"
	cat "${DBDIR}modules/etc/skel/.config/conky/conkyrc1" > "${NS_PATH}/etc/skel/.config/conky/conkyrc1"
	cat "${DBDIR}modules/etc/skel/.config/conky/conkyrc1.sh" > "${NS_PATH}/etc/skel/.config/conky/conkyrc1.sh"
	chmod +x "${NS_PATH}/etc/skel/.config/conky/conkyrc1.sh"

	cat "${DBDIR}modules/etc/skel/.config/conky/conkyrc2" > "${NS_PATH}/etc/skel/.config/conky/conkyrc2"
	cat "${DBDIR}modules/etc/skel/.config/conky/conkyrc2.sh" > "${NS_PATH}/etc/skel/.config/conky/conkyrc2.sh"
	chmod +x "${NS_PATH}/etc/skel/.config/conky/conkyrc2.sh"

	cat "${DBDIR}modules/etc/skel/.config/conky/conkyrc3" > "${NS_PATH}/etc/skel/.config/conky/conkyrc3"
	cat "${DBDIR}modules/etc/skel/.config/conky/conkyrc3.sh" > "${NS_PATH}/etc/skel/.config/conky/conkyrc3.sh"
	chmod +x "${NS_PATH}/etc/skel/.config/conky/conkyrc3.sh"


	msg_log "$(gettext 'Добавляю') conky > /etc/skel/.config/openbox/autostart"
	echo '(sleep 2 && conky -c ~/.config/conky/conkyrc1 -q) &' >> "${NS_PATH}/etc/skel/.config/openbox/autostart"
	echo '(sleep 3 && conky -c ~/.config/conky/conkyrc2 -q) &' >> "${NS_PATH}/etc/skel/.config/openbox/autostart"
	echo '(sleep 4 && conky -c ~/.config/conky/conkyrc3 -q) &' >> "${NS_PATH}/etc/skel/.config/openbox/autostart"
	git_commit
#-------------------------------------------------------------------------------


#===============================================================================
# Устанавливаем sbxkb
#===============================================================================
	#community
	PACS='sbxkb'
	pacman_install "-S ${PACS}" '1'
	git_commit

	msg_log "$(gettext 'Добавляю') sbxkb > /etc/skel/.config/openbox/autostart"
	echo '(sleep 5 && sbxkb) &' >> "${NS_PATH}/etc/skel/.config/openbox/autostart"

	git_commit
#-------------------------------------------------------------------------------


#===============================================================================
# Добавляем xscreensaver
#===============================================================================
	msg_log "$(gettext 'Добавляю') xscreensaver > /etc/skel/.config/openbox/autostart"
	echo '#xscreensaver -no-splash &' >> "${NS_PATH}/etc/skel/.config/openbox/autostart"

	git_commit
#-------------------------------------------------------------------------------
	return 0
}

# Устанавливаем lxde
de_lxde()
{
	local PACS

	#community
	PACS='lxde'
	pacman_install "-S ${PACS}" '1'
	git_commit

	if [[ ! "$SET_DE" ]]
	then
# включаем lxdm
		chroot_run systemctl disable 'getty@tty1.service'
		chroot_run systemctl enable 'lxdm.service'
	fi

	git_commit
	return 0
}


# Устанавливаем xfce4
de_xfce4()
{
	local PACS

	#extra
	PACS='xfce4 xfce4-goodies'
	pacman_install "-S ${PACS}" '1'
	git_commit

	if [[ ! "$SET_DE" ]]
	then
		msg_log "$(gettext 'Настраиваю') /etc/skel/.zprofile"
		echo '[[ -z ${DISPLAY} && ${XDG_VTNR} -eq 1 ]] && exec startx &> ~/.xlog' >> "${NS_PATH}/etc/skel/.zprofile"

		msg_log "$(gettext 'Настраиваю') /etc/skel/.xinitrc"
		echo 'exec startxfce4' >> "${NS_PATH}/etc/skel/.xinitrc"
	fi

	git_commit
	return 0
}

# Устанавливаем e17
de_e17()
{
	local PACS

	#extra
	PACS='enlightenment17'
	pacman_install "-S ${PACS}" '1'
	git_commit

	if [[ ! "$SET_DE" ]]
	then
		msg_log "$(gettext 'Настраиваю') /etc/skel/.zprofile"
		echo '[[ -z ${DISPLAY} && ${XDG_VTNR} -eq 1 ]] && exec startx &> ~/.xlog' >> "${NS_PATH}/etc/skel/.zprofile"

		msg_log "$(gettext 'Настраиваю') /etc/skel/.xinitrc"
		echo 'exec enlightenment_start' >> "${NS_PATH}/etc/skel/.xinitrc"
	fi

	git_commit
	return 0
}

# Устанавливаем kde
de_kde()
{
	local PACS

	#extra
#	PACS='kdebase-plasma kde-wallpapers kdeartwork'
	PACS='kde'
	PACS+=' kdemultimedia-kmix oxygen-gtk2 oxygen-gtk3'
	#community
	PACS+=' kde-gtk-config'
	pacman_install "-S ${PACS}" '1'
	#extra
	PACS="kde-l10n-${SET_LOCAL%_*}"
	pacman_install "-S ${PACS}" '2'

	git_commit

	if [[ ! "$SET_DE" ]]
	then
# включаем kdm
		chroot_run systemctl disable 'getty@tty1.service'
		chroot_run systemctl enable 'kdm.service'
	fi

	msg_log "$(gettext 'Настраиваю') /usr/share/config/kdm/kdmrc"
	sed -i "
# Включаем NumLock
/^NumLock=/s/^/#/;
0,/^#NumLock=/{
//{
	a NumLock=On
};
};
" "${NS_PATH}/usr/share/config/kdm/kdmrc"

	git_commit

# 	pkgs_dolphin
# 	pkgs_kdeadmin
# 	pkgs_kdesdk
# 	pkgs_kdeutils
# 	pkgs_kdegraphics
# 	pkgs_kpatience
# 
# 	dialog_yesno \
# 		"$(gettext 'Установить дополнительные пакеты')" \
# 		"$(gettext 'Установить группу kdepim')?" \
# 		'--defaultno'
# 	case "${?}" in
# 		'0') #Yes
# 			pkgs_kdepim
# 			;;
# 	esac

#     #extra
#     PACS='archlinux-themes-kdm'
#     pacman_install "-S ${PACS}" '1'
#     #aur
#     PACS='ksplash-archpaint2'
#     pacman_install "-S ${PACS}" '2'
# 
#     msg_log "$(gettext 'Настраиваю') /usr/share/config/kdm/kdmrc"
#     sed -i "
# # Добавляем скин
# /^Theme=/s/^/#/;
# 0,/^#Theme=/{
#   //{
#     a Theme=/usr/share/apps/kdm/themes/archlinux-simplyblack
#   };
# };
# " "${NS_PATH}/usr/share/config/kdm/kdmrc"

#  mkdir -p "${NS_PATH}/etc/skel/.kde4/share/config/"

#  cat "${DBDIR}modules/etc/skel/.kde4/share/config/plasma-desktop-appletsrc" > "${NS_PATH}/etc/skel/.kde4/share/config/plasma-desktop-appletsrc"
#  cat "${DBDIR}modules/etc/skel/.kde4/share/config/ksplashrc" > "${NS_PATH}/etc/skel/.kde4/share/config/ksplashrc"

#	git_commit

	return 0
}

# Устанавливаем gnome
de_gnome()
{
	local PACS

# 	pacman_install "-Rnsc bluez" '3' 'noexit'

	#extra
	PACS='gnome gnome-extra'
	pacman_install "-S ${PACS}" '1'
	git_commit


	if [[ ! "$SET_DE" ]]
	then
# включаем gdm
		chroot_run systemctl disable 'getty@tty1.service'
		chroot_run systemctl enable 'gdm.service'
	fi

	git_commit
	return 0
}

# Устанавливаем mate
de_mate()
{
	local PACS

# 	pacman_install "-Rnsc bluez" '3' 'noexit'

	msg_log "$(gettext 'Добавляю') mate > /etc/pacman.conf"
	grep 'mate' "${NS_PATH}/etc/pacman.conf" > /dev/null && echo '' || echo '

[mate]
SigLevel = Optional TrustAll
Server = http://repo.mate-desktop.org/archlinux/$arch
' >> "${NS_PATH}/etc/pacman.conf"

	pacman_install '-Syy' '1'

	#mate
	PACS='mate mate-extras'
	pacman_install "-S ${PACS}" '1'
	git_commit

	if [[ ! "$SET_DE" ]]
	then
		msg_log "$(gettext 'Настраиваю') /etc/skel/.zprofile"
		echo '[[ -z ${DISPLAY} && ${XDG_VTNR} -eq 1 ]] && exec startx &> ~/.xlog' >> "${NS_PATH}/etc/skel/.zprofile"

		msg_log "$(gettext 'Настраиваю') /etc/skel/.xinitrc"
		echo 'exec mate-session' >> "${NS_PATH}/etc/skel/.xinitrc"
	fi

	git_commit
	return 0
}

# Устанавливаем cinnamon
de_cinnamon()
{
	local PACS

# 	pacman_install "-Rnsc bluez" '3' 'noexit'

	#community
	PACS='cinnamon cinnamon-control-center cinnamon-screensaver nemo'
	pacman_install "-S ${PACS}" '1'
	git_commit


	if [[ ! "$SET_DE" ]]
	then
		msg_log "$(gettext 'Настраиваю') /etc/skel/.zprofile"
		echo '[[ -z ${DISPLAY} && ${XDG_VTNR} -eq 1 ]] && exec startx &> ~/.xlog' >> "${NS_PATH}/etc/skel/.zprofile"

		msg_log "$(gettext 'Настраиваю') /etc/skel/.xinitrc"
		echo 'exec gnome-session-cinnamon' >> "${NS_PATH}/etc/skel/.xinitrc"
	fi

	git_commit
	return 0
}

# Устанавливаем awesome
de_awesome()
{
	local PACS

	#community
	PACS='awesome'
	pacman_install "-S ${PACS}" '1'
	git_commit


	if [[ ! "$SET_DE" ]]
	then
		msg_log "$(gettext 'Настраиваю') /etc/skel/.zprofile"
		echo '[[ -z ${DISPLAY} && ${XDG_VTNR} -eq 1 ]] && exec startx &> ~/.xlog' >> "${NS_PATH}/etc/skel/.zprofile"

		msg_log "$(gettext 'Настраиваю') /etc/skel/.xinitrc"
		echo 'exec awesome' >> "${NS_PATH}/etc/skel/.xinitrc"
	fi

	git_commit
	return 0
}
