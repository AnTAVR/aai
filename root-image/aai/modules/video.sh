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

	for VID in "$(lshw -c display | awk '/vendor/{print $2}')"
	do
		VID="$(tr '[:upper:]' '[:lower:]' <<< "${VID}")"
		case "${VID}" in
			'nvidia')
				break
				;;
			'optimus')
				break
				;;
			'ati')
				break
				;;
		esac
	done

	while true
	do
		DEF_MENU="$(video_dialog_def_menu "${VID}")"
		case "${DEF_MENU}" in
			'nvidia')
				video_nvidia
				set_global_var 'SET_VIDEO' "${DEF_MENU}"
				RUN_VIDEO=1
				return 0
				;;
			'nvidia304')
				video_nvidia304
				set_global_var 'SET_VIDEO' "${DEF_MENU}"
				RUN_VIDEO=1
				return 0
				;;
			'optimus')
				video_optimus
				set_global_var 'SET_VIDEO' "${DEF_MENU}"
				RUN_VIDEO=1
				return 0
				;;
			'ati')
				video_ati
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

	HELP_TXT+=" \Zb\Z7\"${DEFAULT_ITEM}\"\Zn\n"

	RETURN="$(dialog_menu "${TITLE}" "${DEFAULT_ITEM}" "${HELP_TXT}" "${ITEMS}" "--cancel-label '${TXT_MAIN_MENU}'")"

	echo "${RETURN}"
	msg_log "$(gettext 'Выход из диалога'): \"${FUNCNAME} return='${RETURN}'\"" 'noecho'
}

video_nvidia()
{
	local PACS

	pacman_install "-Rdds mesa-libgl" '3' 'noexit'
	pacman_install "-Rdds lib32-mesa-libgl" '3' 'noexit'
	#extra
	PACS='nvidia nvidia-utils'
#     PACS+=' opencl-nvidia'
#     dkms-nvidia
	pacman_install "-S ${PACS}" '1'
	PACS='lib32-nvidia-utils'
	pacman_install "-S ${PACS}" '2'

	pacman_install "-Rnsc ati-dri intel-dri nouveau-dri" '3' 'noexit'

	git_commit
}

video_nvidia304()
{
	local PACS

	pacman_install "-Rdds mesa-libgl" '3' 'noexit'
	pacman_install "-Rdds lib32-mesa-libgl" '3' 'noexit'
	#extra
	PACS='nvidia nvidia-304xx-utils'
#     PACS+=' opencl-nvidia-304xx'
	pacman_install "-S ${PACS}" '1'
	PACS='lib32-nvidia-304xx-utils'
	pacman_install "-S ${PACS}" '2'

	pacman_install "-Rnsc ati-dri intel-dri nouveau-dri" '3' 'noexit'

	git_commit

}

video_optimus()
{
	local PACS

#	pacman_install "-Rdds mesa-libgl" '3' 'noexit'
#	pacman_install "-Rdds lib32-mesa-libgl" '3' 'noexit'
	#community
	PACS='bumblebee'
	#extra
	PACS=+' nvidia nvidia-utils'
#     PACS+=' opencl-nvidia'
#     dkms-nvidia
	pacman_install "-S ${PACS}" '1'
	PACS='lib32-nvidia-utils'
	pacman_install "-S ${PACS}" '2'

	pacman_install "-Rnsc ati-dri nouveau-dri" '3' 'noexit'

	#community
	PACS='virtualgl primus'
	pacman_install "-S ${PACS}" '2'
	#multilib
	PACS='lib32-virtualgl lib32-primus'
	pacman_install "-S ${PACS}" '2'

	chroot_run systemctl enable 'nvidia-enable.service'

	SET_USER_GRUPS+=',bumblebee'

	git_commit
}

video_ati()
{
	local PACS

	pacman_install "-Rdds mesa-libgl" '3' 'noexit'
	pacman_install "-Rdds lib32-mesa-libgl" '3' 'noexit'
	#community
	PACS='catalyst-dkms catalyst-utils'
#     PACS+=' opencl-catalyst'
	pacman_install "-S ${PACS}" '1'
	PACS='lib32-catalyst-utils'
	pacman_install "-S ${PACS}" '2'
	git_commit
	chroot_run systemctl enable dkms.service

	pacman_install "-Rnsc ati-dri intel-dri nouveau-dri" '3' 'noexit'

	git_commit
}
