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
MAIN_CASE+=('user')

#===============================================================================
# Сигнальная переменная успешного завершения функции модуля,
# может потребоваться для других модулей, для установки кода завершения
RUN_USER=
TXT_USER_MAIN="$(gettext 'Пользователи')"

#===============================================================================

# Выводим строку пункта главного меню
str_user()
{
    local TEMP

    [[ "${RUN_USER}" ]] && TEMP="\Zb\Z2($(gettext 'ВЫПОЛНЕНО'))\Zn"
    echo "${TXT_USER_MAIN} ${TEMP}"
}

# Функция выполнения из главного меню
run_user()
{
    local NAME

    local TEMP

    if [[ "${NO_DEBUG}" ]]
    then
# Проверяем выполнен ли base
	[[ ! "${RUN_BASE}" ]] && TEMP+=" $(str_base)\n"

	if [[ "${TEMP}" ]]
	then
	    dialog_warn \
		"\Zb\Z1$(gettext 'Не выполнены обязательные пункты меню')\Zn\n${TEMP}"
	    return 1
	fi
    fi

    local DEF_MENU='new_admin'

    while true
    do
	NAME=
	DEF_MENU="$(user_dialog_menu "${DEF_MENU}")"
	case "${DEF_MENU}" in
	    'root')
		user_set_passw 'root' || continue

		DEF_MENU='new_admin'
		;;
	    'new_admin')
# Проверяем выполнен ли base_plus
	        if [[ "${NO_DEBUG}" ]]
	        then
		    if [[ ! "${RUN_BASE_PLUS}" ]]
		    then
			dialog_warn \
			    "\Zb\Z1$(gettext 'Пункт') \"${TXT_BASE_PLUS_MAIN}\" $(gettext 'не выполнен')\Zn"
			return 1
		    fi
		fi

# 		if [[ "${RUN_USER}" ]]
# 		then
# 		    dialog_warn \
# 			"\Zb\Z1$(gettext 'Администратор уже создан')\Zn"
# 		    continue
# 		fi

		NAME="$(user_dialog_name)"
		[[ ! -n "${NAME}" ]] && continue
	
		chroot_run useradd -m -G wheel,storage,adm,ecryptfs -U "${NAME}"
		if [[ "${?}" != '0' ]]
		then
		    dialog_warn \
			"\Zb\Z1$(gettext 'Пользователь не создан, возможно он уже присутствует в системе')\Zn"
		    continue
		fi
		user_set_passw "${NAME}" || continue
		user_ecryptfs "${NAME}"
		RUN_USER=1
		return 0
		;;
	    *)
		return 1
		;;
	esac
    done
}

user_set_passw()
{
    local P_USER="${1}"
    local PASS
    local PASS2

    while true
    do
	PASS="$(user_dialog_password)"
	[[ ! "${PASS}" ]] && return 1
	if (( ${#PASS} < 7 ))
	then
	    dialog_warn \
		"\Zb\Z1$(gettext 'Очень короткий пароль! Введите пароль более 6 символов')\Zn"
	    continue
	fi

	PASS2="$(user_dialog_password '1')"

	if [[ "${PASS}" != "${PASS2}" ]]
	then
	    dialog_warn \
		"\Zb\Z1$(gettext 'Пароли не совпадают')\Zn"
	    continue
	fi
	chroot_run bash -c "\"echo '${P_USER}:${PASS}' | chpasswd\""
	if [[ "${?}" != '0' ]]
	then
	    dialog_warn \
		"\Zb\Z1$(gettext 'Пользователь не создан, возможно он уже присутствует в системе')\Zn"
		continue
	fi
	return
    done
}
# @todo Нужно доделать!!!
user_ecryptfs()
{
    local P_USER="${1}"
    return
    dialog_yesno \
	"$(gettext 'Шифрование папки пользователя') \Zb\Z2\"${P_USER}\"\Zn" \
	"$(gettext 'Зашифровать домашнюю папку?')"
    case "${?}" in
	'0') #Yes
	    modprobe ecryptfs
	    chroot_run ecryptfs-migrate-home -u "${P_USER}"
	    ;;
    esac
}

user_dialog_menu()
{
    msg_log "$(gettext 'Запуск диалога'): \"${FUNCNAME}$(for ((TEMP=1; TEMP<=${#}; TEMP++)); do echo -n " \$${TEMP}='$(eval "echo \"\${${TEMP}}\"")'"; done)\"" 'noecho'

    local RETURN

    local P_DEF_MENU="${1}"

    local TITLE="${TXT_USER_MAIN}"
    local HELP_TXT="\n$(gettext 'Выберите действие')\n"

    local DEFAULT_ITEM="${P_DEF_MENU}"
    local ITEMS="'root' '$(gettext 'Установить пароль для root')'"
    ITEMS+=" 'new_admin' '$(gettext 'Добавление администратора')'"

    RETURN="$(dialog_menu "${TITLE}" "${DEFAULT_ITEM}" "${HELP_TXT}" "${ITEMS}" "--cancel-label '${TXT_MAIN_MENU}'")"

    echo "${RETURN}"
    msg_log "$(gettext 'Выход из диалога'): \"${FUNCNAME} return='${RETURN}'\"" 'noecho'
}

user_dialog_name()
{
    msg_log "$(gettext 'Запуск диалога'): \"${FUNCNAME}$(for ((TEMP=1; TEMP<=${#}; TEMP++)); do echo -n " \$${TEMP}='$(eval "echo \"\${${TEMP}}\"")'"; done)\"" 'noecho'

    local RETURN

    local TITLE="${TXT_USER_MAIN}"
    local HELP_TXT="\n$(gettext 'Введите логин нового пользователя')\n"
    HELP_TXT+="$(gettext 'По умолчанию'):"

    local TEXT='admin'

    HELP_TXT+=" \Zb\Z7\"${TEXT}\"\Zn\n"

    RETURN="$(dialog_inputbox "${TITLE}" "${HELP_TXT}" "${TEXT}" '--no-cancel')"

    echo "${RETURN}"
    msg_log "$(gettext 'Выход из диалога'): \"${FUNCNAME} return='${RETURN}'\"" 'noecho'
}

user_dialog_password()
{
    msg_log "$(gettext 'Запуск диалога'): \"${FUNCNAME}$(for ((TEMP=1; TEMP<=${#}; TEMP++)); do echo -n " \$${TEMP}='$(eval "echo \"\${${TEMP}}\"")'"; done)\"" 'noecho'

    local RETURN

    local P_S="${1}"

    local TITLE="${TXT_USER_MAIN}"
    local HELP_TXT="  $(gettext 'Сильный пароль должен состоять более чем из 8 символов,')\n"
    HELP_TXT+="  $(gettext 'содержать цифры и лат. буквы в нижнем и верхнем регистре.')\n"
    HELP_TXT+="  \Zb\Z1$(gettext 'Использование других символов не рекомендуется!!!')\Zn\n"

    local TEXT=''

    if [[ "${P_S}" ]]
    then
	HELP_TXT+="\n$(gettext 'Введите повтор пароля')"
    else
	HELP_TXT+="\n$(gettext 'Введите пароль')"
    fi

    RETURN="$(dialog_inputbox "${TITLE}" "${HELP_TXT}" "${TEXT}" '--no-cancel')"

    echo "${RETURN}"
    msg_log "$(gettext 'Выход из диалога'): \"${FUNCNAME} return='${RETURN}'\"" 'noecho'
}
