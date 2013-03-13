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
#===============================================================================

# Выводим строку пункта главного меню
str_print()
{
    local TEMP

    [[ "${RUN_PRINT}" ]] && TEMP="\Zb\Z2($(gettext 'ВЫПОЛНЕНО'))\Zn"
    echo "${TXT_PRINT_MAIN} \Zb\Z3($(gettext 'Пока не поддерживается'))\Zn ${TEMP}"
}

# Функция выполнения из главного меню
run_print()
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
    fi

    dialog_warn \
	"\Zb\Z1\"${TXT_PRINT_MAIN}\" $(gettext 'пока не поддерживается, помогите проекту, допишите данный функционал')\Zn"
    return 1
}
