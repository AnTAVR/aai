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
MAIN_CASE+=('xorg')

#===============================================================================
# Сигнальная переменная успешного завершения функции модуля,
# может потребоваться для других модулей, для установки кода завершения
RUN_XORG=
TXT_XORG_MAIN="$(gettext 'Xorg')"

# Разрешение Xorg
SET_XORG_XxYxD=
#===============================================================================

# Выводим строку пункта главного меню
str_xorg()
{
	local TEMP

	[[ "${RUN_XORG}" ]] && TEMP="\Zb\Z2($(gettext 'ВЫПОЛНЕНО'))\Zn"
	echo "${TXT_XORG_MAIN} (~905M+) ${TEMP}"
}

# Функция выполнения из главного меню
run_xorg()
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

		if [[ "${RUN_XORG}" ]]
		then
			dialog_warn \
				"\Zb\Z1$(gettext 'Пункт') \"${TXT_XORG_MAIN}\" $(gettext 'уже выполнен')\Zn"
			return 1
		fi

	fi

	TEMP="$(xorg_dialog_xorg)"
	[[ ! -n "${TEMP}" ]] && return 1
	SET_XORG_XxYxD="${TEMP}"

	xorg_mesa

	xorg_xorg
}

xorg_dialog_xorg()
{
	msg_log "$(gettext 'Запуск диалога'): \"${FUNCNAME}$(for ((TEMP=1; TEMP<=${#}; TEMP++)); do echo -n " \$${TEMP}='$(eval "echo \"\${${TEMP}}\"")'"; done)\"" 'noecho'

	local RETURN

	local TITLE="${TXT_XORG_MAIN}"
	local HELP_TXT="\n$(gettext 'Выберите разрешение экрана для Xorg')\n"
	HELP_TXT+="$(gettext 'По умолчанию'):"

	local DEFAULT_ITEM='1280x1024x24'
	local ITEMS="$(hwinfo --framebuffer | grep ' Mode ' |  awk -F ' ' '{print sq $3 "x" $5 sq " " sq $0 sq}' sq=\')"
	[[ ! -n "${ITEMS}" ]] && ITEMS="
'640x480x8' '-' '800x600x8' '-' '1024x768x8' '-' '1280x1024x8' '-'
'640x480x16' '-' '800x600x16' '-' '1024x768x16' '-' '1280x1024x16' '-'
'640x480x24' '-' '800x600x24' '-' '1024x768x24' '-' '1280x1024x24' '-'
"
	HELP_TXT+=" \Zb\Z7\"${DEFAULT_ITEM}\"\Zn\n"

	RETURN="$(dialog_menu "${TITLE}" "${DEFAULT_ITEM}" "${HELP_TXT}" "${ITEMS}")"

	echo "${RETURN}"
	msg_log "$(gettext 'Выход из диалога'): \"${FUNCNAME} return='${RETURN}'\"" 'noecho'
}

xorg_xorg()
{
#===============================================================================
# Устанавливаем xorg
#===============================================================================
	#extra
	pacman_install "-S xorg"
	pacman_install "-S xorg-xinit"
	pacman_install "-S xdg-user-dirs"
	pacman_install "-S xdg-utils"
	pacman_install "-S xorg-server-utils"
	pacman_install "-S xterm"
	pacman_install "-S ttf-dejavu"
	pacman_install "-S ttf-freefont"
	pacman_install "-S ttf-linux-libertine"
	pacman_install "-S ttf-bitstream-vera"
	pacman_install "-S xscreensaver"
	#community
	pacman_install "-S ttf-liberation"
	pacman_install "-S ttf-droid"
	pacman_install "-S xcursor-vanilla-dmz"
	#aur
#	pacman_install "-S ttf-ms-fonts" 'yaourt'
#	pacman_install "-S ttf-vista-fonts" 'yaourt'

	#extra
	pacman_install "-S gstreamer0.10-plugins"
	pacman_install "-S phonon-gstreamer"
	pacman_install "-S tk" #для git
	pacman_install "-S fltk" #для alsa-tools
	pacman_install "-S gtk2"
	pacman_install "-S gtk3"
	pacman_install "-S qt4"
#	pacman_install "-S qt5"
	pacman_install "-S wxgtk2.8" #для p7zip

	git_commit


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

xorg_mesa()
{
	#extra
	pacman_install "-S mesa-demos"
	pacman_install "-S mesa-libgl"
	#multilib
	pacman_install "-S lib32-mesa-demos" 'yaourt'
	pacman_install "-S lib32-mesa-libgl" 'yaourt'

	git_commit
}
