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
MAIN_CASE+=('donate')

#===============================================================================
# Сигнальная переменная успешного завершения функции модуля,
# может потребоваться для других модулей, для установки кода завершения
RUN_DONATE=
TXT_DONATE_MAIN="\Zb\Z2$(gettext 'Пожалуйста, поддержите разработку')\Zn"
#===============================================================================

# Выводим строку пункта главного меню
str_donate()
{
	echo "${TXT_DONATE_MAIN}"
}

# Функция выполнения из главного меню
run_donate()
{
	local TITLE="${TXT_DONATE_MAIN}"
	local TEXT="${DBDIR}modules/aai-donate.txt"

	dialog_textbox \
		"${TITLE}" \
		"${TEXT}" \
		"--exit-label '${TXT_MAIN_MENU}'"
}
