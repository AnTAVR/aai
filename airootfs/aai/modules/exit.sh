#!/bin/sh
#
#
#
#   Copyright (c) 2012-2014 Anthony Lyappiev <archlinux@antavr.ru>
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
#MAIN_CASE+=('exit')

#===============================================================================
# Сигнальная переменная успешного завершения функции модуля,
# может потребоваться для других модулей, для установки кода завершения
TXT_EXIT_MAIN="$(gettext 'Выход')"

#===============================================================================

# Выводим строку пункта главного меню
str_exit()
{
	echo "${TXT_EXIT_MAIN}"
}

# Функция выполнения из главного меню
run_exit()
{
	local P_RUN_EXIT="${1}"

	local TEMP
	[[ ! "${P_RUN_EXIT}" ]] && [[ "${RUN_BASE}" ]] && [[ ! "${SET_BOOTLOADER}" ]] && TEMP+="\Zb\Z1$(gettext 'Пункт') \"${TXT_BOOTLOADER_MAIN}\" $(gettext 'не выполнен')\Zn\n"
	[[ ! "${P_RUN_EXIT}" ]] && [[ "${RUN_BASE_PLUS}" ]] && [[ ! "${RUN_USER}" ]] && TEMP+="\Zb\Z1$(gettext 'Пункт') \"${TXT_USER_MAIN}\" $(gettext 'не выполнен')\Zn\n"

	if [[ "${TEMP}" ]]
	then
		dialog_yesno \
			"${TXT_EXIT_MAIN}" \
			"$(gettext 'Подтвердите выход ПОВЕЛИТЕЛЬ...')\n${TEMP}" \
			"--defaultno --yes-label '$(gettext 'Выполняй холоп!')'"

		case "${?}" in
			'0') #Yes
				msg_info "$(gettext 'Повинуюсь') :("
				;;
			*) #ESC
				return 1
				;;
		esac
	fi
	net_off
	part_unmount
	[[ ! "${P_RUN_EXIT}" ]] && clear
	msg_log "${TXT_EXIT_MAIN}"
	exit ${P_RUN_EXIT}
}
