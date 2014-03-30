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

#gtf 1280 1024 85 получить соответствующий Modeline
#Section "Monitor"
# 1280x1024 @ 85.00 Hz (GTF) hsync: 91.38 kHz; pclk: 159.36 MHz
#  Modeline "1280x1024_85.00"  159.36  1280 1376 1512 1744  1024 1025 1028 1075  -HSync +Vsync
#EndSection
#Section "Screen"
#        SubSection "Display"
#              Modes     "1280x1024_85.00"
#        EndSubSection
#EndSection

# Добавляем функцию модуля в главное меню, пробел в конце обязательно!
MAIN_CASE+=('video')

#===============================================================================
# Сигнальная переменная успешного завершения функции модуля,
# может потребоваться для других модулей, для установки кода завершения
RUN_VIDEO=
TXT_VIDEO_MAIN="$(gettext 'Видео драйвер')"

# Выбранный драйвер
SET_VIDEO=
#===============================================================================

# Выводим строку пункта главного меню
str_video()
{
	local TEMP

	[[ "${RUN_VIDEO}" ]] && TEMP="\Zb\Z2($(gettext 'ВЫПОЛНЕНО'))\Zn"
	echo "${TXT_VIDEO_MAIN} ${TEMP}"
}

# Функция выполнения из главного меню
run_video()
{
	local DEF_MENU
	local VID

	local TEMP

	if [[ "${NO_DEBUG}" ]]
	then
# Проверяем выполнен ли base
		[[ ! "${RUN_BASE}" ]] && TEMP+=" $(str_base)\n"
# Проверяем выполнен ли de пункт меню
		[[ ! "${RUN_DE}" ]] && TEMP+=" $(str_de)\n"

		if [[ "${TEMP}" ]]
		then
			dialog_warn \
				"\Zb\Z1$(gettext 'Не выполнены обязательные пункты меню')\Zn\n${TEMP}"
			return 1
		fi

		if [[ "${SET_VIDEO}" ]]
		then
			dialog_warn \
				"\Zb\Z1$(gettext 'Пункт') \"${TXT_VIDEO_MAIN}\" $(gettext 'уже выполнен')\Zn \Zb\Z2\"${SET_VIDEO}\"\Zn"
			return 1
		fi
	fi

	VID=$(video_get_drv)

	while true
	do
		DEF_MENU="$(video_dialog_def_menu "${VID}")"
		case "${DEF_MENU}" in
			'nvidia' | 'nvidia304' | 'optimus' | 'ati' | 'innotek')
				video_${DEF_MENU} || continue
				set_global_var 'SET_VIDEO' "${DEF_MENU}"
				RUN_VIDEO=1
				return 0
				;;
			*)
				return 1
				;;
		esac
	done
}

video_get_drv()
{
	local VID

	local TEMP=0

	local DISPLAY

	DISPLAY=$(lshw -c display | tr '[:upper:]' '[:lower:]')

	for VID in $(awk '/product:/{print $2}' <<< "${DISPLAY}")
	do
		case "${VID}" in
			'gf108m' | '3rd')
				TEMP=$((TEMP+1))
				;;
		esac
	done

	if [[ "${TEMP}" == '2' ]]
	then
		echo 'optimus'
		return 0
	fi

	TEMP=
	for VID in $(awk '/vendor:/{print $2}' <<< "${DISPLAY}")
	do
		case "${VID}" in
			'nvidia' | 'ati')
				echo "${VID}"
				return 0
				;;
			*)
				[[ ! "${TEMP}" ]] && TEMP="${VID}"
				;;
		esac
	done

	echo "${TEMP}"
	return 1
}

video_dialog_def_menu()
{
	msg_log "$(gettext 'Запуск диалога'): \"${FUNCNAME}$(for ((TEMP=1; TEMP<=${#}; TEMP++)); do echo -n " \$${TEMP}='$(eval "echo \"\${${TEMP}}\"")'"; done)\"" 'noecho'

	local RETURN

	local P_VID="${1}"

	local TITLE="${TXT_VIDEO_MAIN}"
	local HELP_TXT="\n$(gettext 'Выберите видео драйвер для установки')\n"
	HELP_TXT+="$(gettext 'По умолчанию'):"

	local DEFAULT_ITEM="${P_VID}"
	local ITEMS="'none' '-'"
	ITEMS+=" 'nvidia' 'NVIDIA'"
	ITEMS+=" 'nvidia304' 'NVIDIA 304xx'"
	ITEMS+=" 'optimus' 'Bumblebee NVIDIA Optimus'"
#     ITEMS+=" 'nvidia173' 'NVIDIA 173xx \Zb\Z3($(gettext 'Пока не поддерживается'))\Zn'"
#     ITEMS+=" 'nvidia96' 'NVIDIA 96xx \Zb\Z3($(gettext 'Пока не поддерживается'))\Zn'"
	ITEMS+=" 'ati' 'ATI Catalyst'"
	ITEMS+=" 'innotek' 'VirtualBox Graphics Adapter'"

	HELP_TXT+=" \Zb\Z7\"${DEFAULT_ITEM}\"\Zn\n"

	RETURN="$(dialog_menu "${TITLE}" "${DEFAULT_ITEM}" "${HELP_TXT}" "${ITEMS}" "--cancel-label '${TXT_MAIN_MENU}'")"

	echo "${RETURN}"
	msg_log "$(gettext 'Выход из диалога'): \"${FUNCNAME} return='${RETURN}'\"" 'noecho'
}

video_nvidia()
{
	pacman_install "-Rdds mesa-libgl" 'noneeded' 'noexit'
	pacman_install "-Rdds lib32-mesa-libgl" 'noneeded' 'noexit'

	#aur
#	pacman_install "-S nvidia-dkms" 'yaourt'
	#extra
	pacman_install "-S nvidia"
	[[ "${SET_LTS}" ]] && pacman_install "-S nvidia-lts"
	pacman_install "-S nvidia-utils"
#	pacman_install "-S opencl-nvidia"
	#multilib
	pacman_install "-S lib32-nvidia-utils" 'yaourt'
#	pacman_install "-S lib32-opencl-nvidia" 'yaourt'

	pacman_install "-Rnsc ati-dri intel-dri nouveau-dri" 'noneeded' 'noexit'

	git_commit
}

video_nvidia304()
{
	pacman_install "-Rdds mesa-libgl" 'noneeded' 'noexit'
	pacman_install "-Rdds lib32-mesa-libgl" 'noneeded' 'noexit'

	#extra
	pacman_install "-S nvidia-304xx"
	[[ "${SET_LTS}" ]] && pacman_install "-S nvidia-304xx-lts"
	pacman_install "-S nvidia-304xx-utils"
#	pacman_install "-S opencl-nvidia-304xx"
	#multilib
	pacman_install "-S lib32-nvidia-304xx-utils" 'yaourt'
#	pacman_install "-S lib32-opencl-nvidia-304xx" 'yaourt'

	pacman_install "-Rnsc ati-dri intel-dri nouveau-dri" 'noneeded' 'noexit'

	git_commit

}

video_optimus()
{
#	pacman_install "-Rdds mesa-libgl" 'noneeded' 'noexit'
#	pacman_install "-Rdds lib32-mesa-libgl" 'noneeded' 'noexit'

	#community
	pacman_install "-S bumblebee"
	#aur
#	pacman_install "-S nvidia-dkms" 'yaourt'
	#extra
	pacman_install "-S nvidia"
	[[ "${SET_LTS}" ]] && pacman_install "-S nvidia-lts"
	pacman_install "-S nvidia-utils"
#	pacman_install "-S opencl-nvidia"
	#multilib
	pacman_install "-S lib32-nvidia-utils" 'yaourt'
#	pacman_install "-S lib32-opencl-nvidia" 'yaourt'

	pacman_install "-Rnsc ati-dri nouveau-dri" 'noneeded' 'noexit'

	#community
	pacman_install "-S virtualgl"
	pacman_install "-S primus"
	#multilib
	pacman_install "-S lib32-virtualgl" 'yaourt'
	pacman_install "-S lib32-primus" 'yaourt'

	git_commit

	chroot_run systemctl enable 'nvidia-enable.service'

	SET_USER_GRUPS+=',bumblebee'

	git_commit
}

video_ati()
{
#Key-ID: 653C3094
#[catalyst]
#Server = http://catalyst.wirephire.com/repo/catalyst/$arch
#pacman-key -r Key-ID
#pacman-key --lsign-key Key-ID

	pacman_install "-Rdds mesa-libgl" 'noneeded' 'noexit'
	pacman_install "-Rdds lib32-mesa-libgl" 'noneeded' 'noexit'
	#aur
	pacman_install "-S catalyst-utils" 'yaourt'
	pacman_install "-S catalyst-libgl" 'yaourt'
#	pacman_install "-S opencl-catalyst" 'yaourt'
	pacman_install "-S lib32-catalyst-utils" 'yaourt'
	pacman_install "-S lib32-catalyst-libgl" 'yaourt'
#	pacman_install "-S lib32-opencl-catalyst" 'yaourt'
	pacman_install "-S catalyst-hook" 'yaourt'
	pacman_install "-S acpid"

	git_commit

	chroot_run systemctl enable atieventsd
	chroot_run systemctl enable catalyst-hook
	chroot_run systemctl enable temp-links-catalyst

	#aticonfig --initial

	pacman_install "-Rnsc ati-dri intel-dri nouveau-dri" 'noneeded' 'noexit'

	git_commit
}

video_innotek()
{
	#community
	pacman_install "-S virtualbox-guest-modules"
	pacman_install "-S virtualbox-guest-utils"
	[[ "${SET_LTS}" ]] && pacman_install "-S virtualbox-host-modules-lts"

	git_commit
}
