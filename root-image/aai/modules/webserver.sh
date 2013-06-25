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
MAIN_CASE+=('webserver')

#===============================================================================
# Сигнальная переменная успешного завершения функции модуля,
# может потребоваться для других модулей, для установки кода завершения
RUN_WEBSERVER=
TXT_WEBSERVER_MAIN="$(gettext 'Веб сервер')"

# Выбранный веб сервер
SET_WEBSERVER=
#===============================================================================

# Выводим строку пункта главного меню
str_webserver()
{
	local TEMP

	[[ "${RUN_WEBSERVER}" ]] && TEMP="\Zb\Z2($(gettext 'ВЫПОЛНЕНО'))\Zn"
	echo "${TXT_WEBSERVER_MAIN} ${TEMP}"
}

# Функция выполнения из главного меню
run_webserver()
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

		if [[ "${SET_WEBSERVER}" ]]
		then
			dialog_warn \
				"\Zb\Z1$(gettext 'Пункт') \"${TXT_WEBSERVER_MAIN}\" $(gettext 'уже выполнен')\Zn \Zb\Z2\"${SET_WEBSERVER}\"\Zn"
			return 1
		fi
	fi

	local DEF_MENU='nginx'

	while true
	do
		DEF_MENU="$(webserver_dialog_menu "${DEF_MENU}")"
		case "${DEF_MENU}" in
			'nginx')
				webserver_nginx || continue
				[[ ! "$SET_WEBSERVER" ]] && set_global_var 'SET_WEBSERVER' "${DEF_MENU}"
				RUN_WEBSERVER=1
				return 0
				;;
			'apache')
				webserver_apache || continue
				[[ ! "$SET_WEBSERVER" ]] && set_global_var 'SET_WEBSERVER' "${DEF_MENU}"
				RUN_WEBSERVER=1
				return 0
				;;
			*)
				return 1
				;;
		esac
	done
}

webserver_dialog_menu()
{
	msg_log "$(gettext 'Запуск диалога'): \"${FUNCNAME}$(for ((TEMP=1; TEMP<=${#}; TEMP++)); do echo -n " \$${TEMP}='$(eval "echo \"\${${TEMP}}\"")'"; done)\"" 'noecho'

	local RETURN

	local P_DEF_MENU="${1}"

	local TITLE="${TXT_WEBSERVER_MAIN}"
	local HELP_TXT="\n$(gettext 'Выберите сервер')\n"
	HELP_TXT+="$(gettext 'По умолчанию'):"

	local DEFAULT_ITEM="${P_DEF_MENU}"
	local ITEMS="'nginx' 'nginx php mariadb(mysql) postgresql'"
	ITEMS+=" 'apache' 'apache php mariadb(mysql) postgresql \Zb\Z3($(gettext 'Пока не поддерживается'))\Zn'"

	HELP_TXT+=" \Zb\Z7\"${DEFAULT_ITEM}\"\Zn\n"

	RETURN="$(dialog_menu "${TITLE}" "${DEFAULT_ITEM}" "${HELP_TXT}" "${ITEMS}" "--cancel-label '${TXT_MAIN_MENU}'")"

	echo "${RETURN}"
	msg_log "$(gettext 'Выход из диалога'): \"${FUNCNAME} return='${RETURN}'\"" 'noecho'
}

webserver_nginx()
{
	pkgs_nginx
	pkgs_php
	pkgs_mariadb
	pkgs_postgresql
}

webserver_apache()
{
	dialog_warn \
		"\Zb\Z1\"${TXT_WEBSERVER_MAIN}\" $(gettext 'пока не поддерживается, помогите проекту, допишите данный функционал')\Zn"
	return 1
}
