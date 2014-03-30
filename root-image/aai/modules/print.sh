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
MAIN_CASE+=('print')

#===============================================================================
# Сигнальная переменная успешного завершения функции модуля,
# может потребоваться для других модулей, для установки кода завершения
RUN_PRINT=
TXT_PRINT_MAIN="$(gettext 'Принтеры, сканеры')"

# Выбранный драйвер
SET_PRINT=
SET_SCAN=
#===============================================================================

# Выводим строку пункта главного меню
str_print()
{
	local TEMP

	[[ "${RUN_PRINT}" ]] && TEMP="\Zb\Z2($(gettext 'ВЫПОЛНЕНО'))\Zn"
	echo "${TXT_PRINT_MAIN} ${TEMP}"
}

# Функция выполнения из главного меню
run_print()
{
	local TEMP

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


	local DEF_MENU='scan'

	while true
	do
		DEF_MENU="$(print_dialog_menu "${DEF_MENU}")"
		case "${DEF_MENU}" in
			'print' )
				print_print || continue
				RUN_PRINT=1
				;;
			'scan')
				print_scan || continue
				RUN_PRINT=1
				;;
			*)
				return 1
				;;
		esac
	done

}

print_dialog_menu()
{
	msg_log "$(gettext 'Запуск диалога'): \"${FUNCNAME}$(for ((TEMP=1; TEMP<=${#}; TEMP++)); do echo -n " \$${TEMP}='$(eval "echo \"\${${TEMP}}\"")'"; done)\"" 'noecho'

	local RETURN

	local TITLE="${TXT_PRINT_MAIN}"
	local HELP_TXT="\n$(gettext 'Выберите установку устройства')\n"

	local DEFAULT_ITEM=

	local TEMP="\Zb\Z1$(gettext 'пока не поддерживается')\Zn"
	[[ "${SET_PRINT}" ]] && TEMP="\Zb\Z2($(gettext 'ВЫПОЛНЕНО'))\Zn"
	local ITEMS="'print' '$(gettext 'Принтер') ${TEMP}'"

	TEMP=
	[[ "${SET_SCAN}" ]] && TEMP="\Zb\Z2($(gettext 'ВЫПОЛНЕНО'))\Zn"
	ITEMS+=" 'scan' '$(gettext 'Сканеры') ${TEMP}'"

	RETURN="$(dialog_menu "${TITLE}" "${DEFAULT_ITEM}" "${HELP_TXT}" "${ITEMS}" "--cancel-label '${TXT_MAIN_MENU}'")"

	echo "${RETURN}"
	msg_log "$(gettext 'Выход из диалога'): \"${FUNCNAME} return='${RETURN}'\"" 'noecho'

}

print_scan()
{
	if [[ "$SET_SCAN" ]]
	then
		dialog_warn \
			"\Zb\Z1$(gettext 'Сканер уже установлен')\Zn"
		return 1
	fi

	#extra
	pacman_install "-S xsane"

	git_commit

	SET_USER_GRUPS+=',scanner'
	SET_SCAN='sane'
	set_global_var 'SET_SCAN' "${SET_SCAN}"
	return 0
}

# @todo Нужно доделать!!!
print_print()
{
	dialog_warn \
		"\Zb\Z1$(gettext 'пока не поддерживается, помогите проекту, допишите данный функционал')\Zn"
	return 1

	if [[ "$SET_PRINT" ]]
	then
		dialog_warn \
			"\Zb\Z1$(gettext 'Принтер уже установлен')\Zn"
		return 1
	fi

# 	#extra
# 	pacman_install "-S xsane"

# 	git_commit

	SET_USER_GRUPS+=',lp'
	SET_PRINT='print'
	set_global_var 'SET_PRINT' "${SET_PRINT}"
	return 0
}
