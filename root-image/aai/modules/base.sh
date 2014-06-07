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


# Отправлять разработчику сообщение если в базах не оказалось нужных данных
POST_LOCALIZE=

# Добавляем функцию модуля в главное меню, пробел в конце обязательно!
MAIN_CASE+=('base')

#===============================================================================
# Сигнальная переменная успешного завершения функции модуля,
# может потребоваться для других модулей, для проверки зависимости
RUN_BASE=
TXT_BASE_MAIN="$(gettext 'Базовая система')"

DEFAULT_COUNTRY='UA'

# Домен страны
SET_COUNTRY=
# Часовой пояс
SET_TIMEZONE=
# Тип аппаратных часов
SET_LOCALTIME=

# Локаль
SET_LOCAL=

# Раскладка клавиатуры консоли
SET_KEYMAP=
# Дополнительная раскладка клавиатуры консоли
SET_KEYMAP_TOGGLE=
# Шрифт консоли
SET_FONT=
# Карта шрифта консоли
SET_FONT_MAP=
# Карта шрифта консоли unicode
SET_FONT_UNIMAP=

# Имя компьютера
SET_HOSTNAME=
#===============================================================================

# Выводим строку пункта главного меню
str_base()
{
	local TEMP="\Zb\Z1($(gettext 'ОБЯЗАТЕЛЬНО!!!'))\Zn"

	[[ "${RUN_BASE}" ]] && TEMP="\Zb\Z2($(gettext 'ВЫПОЛНЕНО'))\Zn"
	echo "${TXT_BASE_MAIN} (~1165M) ${TEMP}"
}

# Функция выполнения из главного меню
run_base()
{
	local COUNTRY
	local TIMEZONE
	local LOCALTIME

	local LOCAL

	local KEYMAP
	local KEYMAP_TOGGLE
	local FONT
	local FONT_MAP
	local FONT_UNIMAP

	local HOSTNAME

	local TEMP
	local TEMPS


	if [[ "${NO_DEBUG}" ]]
	then
# Проверяем подключена ли сеть
		[[ ! "${RUN_NET}" ]] && TEMP+=" $(str_net)\n"
# Проверяем выполнен ли part пункт меню
		[[ ! "${RUN_PART}" ]] && TEMP+=" $(str_part)\n"

		if [[ "${TEMP}" ]]
		then
			dialog_warn \
				"\Zb\Z1$(gettext 'Не выполнены обязательные пункты меню')\Zn\n${TEMP}"
			return 1
		fi

		if [[ "${RUN_BASE}" ]]
		then
			dialog_warn \
				"\Zb\Z1$(gettext 'Пункт') \"${TXT_BASE_MAIN}\" $(gettext 'уже выполнен')\Zn"
			return 1
		fi
	fi

	while true
	do
		TEMP="$(base_dialog_country "${COUNTRY}")"
		[[ ! -n "${TEMP}" ]] && return 1
		COUNTRY="${TEMP}"


		TEMP="$(base_dialog_timezone "${COUNTRY}")"
		[[ ! -n "${TEMP}" ]] && continue
		TIMEZONE="${TEMP}"


		TEMP="$(base_dialog_localtime "${TIMEZONE}" "${COUNTRY}")"
		[[ ! -n "${TEMP}" ]] && continue
		LOCALTIME="${TEMP}"


		TEMP="$(base_dialog_local "${TIMEZONE}" "${COUNTRY}")"
		[[ ! -n "${TEMP}" ]] && continue
		LOCAL="${TEMP}"


		TEMP="$(base_dialog_keymap "${LOCAL}" "${COUNTRY}")"
		[[ ! -n "${TEMP}" ]] && continue
		KEYMAP="${TEMP}"


		TEMP="$(base_dialog_keymap_toggle "${LOCAL}" "${COUNTRY}")"
		[[ ! -n "${TEMP}" ]] && continue
		KEYMAP_TOGGLE="${TEMP}"


		TEMP="$(base_dialog_font "${LOCAL}" "${COUNTRY}")"
		[[ ! -n "${TEMP}" ]] && continue
		FONT="${TEMP}"


		TEMP="$(base_dialog_font_map "${FONT}")"
		[[ ! -n "${TEMP}" ]] && continue
		FONT_MAP="${TEMP}"


		TEMP="$(base_dialog_font_unimap "${FONT}")"
		[[ ! -n "${TEMP}" ]] && continue
		FONT_UNIMAP="${TEMP}"


		TEMP="$(base_dialog_hostname "${COUNTRY}")"
		[[ ! -n "${TEMP}" ]] && continue
		HOSTNAME="${TEMP}"


# Проверяем правильность ввода параметров, если не правильно введено,
# то повторяем выбор, если отмена то выход
		[[ "${KEYMAP_TOGGLE}" = 'none' ]] && KEYMAP_TOGGLE=
		[[ "${FONT_MAP}" = 'none' ]] && FONT_MAP=
		[[ "${FONT_UNIMAP}" = 'none' ]] && FONT_UNIMAP=

		dialog_yesno \
			"$(gettext 'Подтвердите свой выбор')" \
			"
\Zb\Z7COUNTRY=\Zn${COUNTRY}\n
\Zb\Z7TIMEZONE=\Zn${TIMEZONE}\n
\Zb\Z7LOCALTIME=\Zn${LOCALTIME}\n
\Zb\Z7LOCAL=\Zn${LOCAL}\n
\Zb\Z7KEYMAP=\Zn${KEYMAP}\n
\Zb\Z7KEYMAP_TOGGLE=\Zn${KEYMAP_TOGGLE}\n
\Zb\Z7FONT=\Zn${FONT}\n
\Zb\Z7FONT_MAP=\Zn${FONT_MAP}\n
\Zb\Z7FONT_UNIMAP=\Zn${FONT_UNIMAP}\n
\Zb\Z7HOSTNAME=\Zn${HOSTNAME}\n
" \
			'--defaultno'
		case "${?}" in
			'0') #Yes
# Устанавливаем выбранные переменные в глобальные
				set_global_var 'SET_COUNTRY' "${COUNTRY}"
				set_global_var 'SET_TIMEZONE' "${TIMEZONE}"
				set_global_var 'SET_LOCALTIME' "${LOCALTIME}"

				set_global_var 'SET_LOCAL' "${LOCAL}"

				set_global_var 'SET_KEYMAP' "${KEYMAP}"
				set_global_var 'SET_KEYMAP_TOGGLE' "${KEYMAP_TOGGLE}"
				set_global_var 'SET_FONT' "${FONT}"
				set_global_var 'SET_FONT_MAP' "${FONT_MAP}"
				set_global_var 'SET_FONT_UNIMAP' "${FONT_UNIMAP}"

				set_global_var 'SET_HOSTNAME' "${HOSTNAME}"

				TEMPS="$(base_dialog_mirrorlist "${COUNTRY}")"
				if [[ -n "${TEMPS}" ]] && [[ "${?}" == '0' ]]
				then
					echo '' > /etc/pacman.d/mirrorlist
					for TEMP in ${TEMPS}
					do
						grep "http://${TEMP}/" /etc/pacman.d/mirrorlist.bak >> /etc/pacman.d/mirrorlist
					done
				fi

				base_install
				[[ "${?}" -ne '0' ]] && return 1

				RUN_BASE=1
				return 0
				;;
		esac
	done
}


base_dialog_mirrorlist()
{
	msg_log "$(gettext 'Запуск диалога'): \"${FUNCNAME}$(for ((TEMP=1; TEMP<=${#}; TEMP++)); do echo -n " \$${TEMP}='$(eval "echo \"\${${TEMP}}\"")'"; done)\"" 'noecho'
	msg_info "$(gettext 'Пожалуйста, подождите')..."

	local RETURN

	local P_COUNTRY="${1}"

	local COUNTRY='-'
	local LINE

	local TEMP

	local TITLE="${TXT_BASE_MAIN}"
	local HELP_TXT="$(gettext 'Домен'): \Zb\Z2\"${P_COUNTRY}\"\Zn\n"
	HELP_TXT+="\n$(gettext 'Выберите зеркала')\n"

	[[ ! -f /etc/pacman.d/mirrorlist.bak ]] && cp -Pb /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak

	local ITEMS="$(sed 's/^##$//;/^## Generated on/d;/^## Arch Linux/d' /etc/pacman.d/mirrorlist.bak |
	while read LINE
	do
		if [[ ! -n "${LINE}" ]]
		then
			COUNTRY='-'
		else
			if [[ "${LINE:0:2}" == '##' ]]
			then
				COUNTRY="${LINE:3}"
			else
				LINE="$(cut -d '/' -f3 <<< "${LINE}")"
				echo -n "'${LINE}' '${COUNTRY}'"
				if [[ "$(awk -F '.' '{print $NF}' <<< "${LINE}")" == "$(tr '[:upper:]' '[:lower:]' <<< "${SET_COUNTRY}")" ]] ||
					[[ "${LINE}" == 'mirrors.kernel.org' ]]
				then
					echo " 'on'"
				else
					echo " 'off'"
				fi
			fi
		fi
	done)"

	RETURN="$(dialog_checklist "${TITLE}" "${HELP_TXT}" "${ITEMS}" '--no-cancel')"

	echo "${RETURN}"
	msg_log "$(gettext 'Выход из диалога'): \"${FUNCNAME} return='${RETURN}'\"" 'noecho'
}

base_dialog_country()
{
	msg_log "$(gettext 'Запуск диалога'): \"${FUNCNAME}$(for ((TEMP=1; TEMP<=${#}; TEMP++)); do echo -n " \$${TEMP}='$(eval "echo \"\${${TEMP}}\"")'"; done)\"" 'noecho'

	local RETURN

	local P_COUNTRY="${1}"

	local TITLE="${TXT_BASE_MAIN}"
	local HELP_TXT="\n$(gettext 'Выберите домен вашей страны')\n"
	HELP_TXT+="$(gettext 'По умолчанию'):"

	local DEFAULT_ITEM="${P_COUNTRY}"
	[[ ! "${DEFAULT_ITEM}" ]] && DEFAULT_ITEM="${DEFAULT_COUNTRY}"

	HELP_TXT+=" \Zb\Z7\"${DEFAULT_ITEM}\"\Zn\n"

	local ITEMS="$(sed "s/'/\`/g" "${DBDIR}domains.db" | awk -F '\t' '{print sq$1sq" "sq$2sq}' sq=\')"

	RETURN="$(dialog_menu "${TITLE}" "${DEFAULT_ITEM}" "${HELP_TXT}" "${ITEMS}" "--cancel-label '${TXT_MAIN_MENU}'")"

	echo "${RETURN}"
	msg_log "$(gettext 'Выход из диалога'): \"${FUNCNAME} return='${RETURN}'\"" 'noecho'
}

base_dialog_timezone()
{
	msg_log "$(gettext 'Запуск диалога'): \"${FUNCNAME}$(for ((TEMP=1; TEMP<=${#}; TEMP++)); do echo -n " \$${TEMP}='$(eval "echo \"\${${TEMP}}\"")'"; done)\"" 'noecho'

	local RETURN

	local P_COUNTRY="${1}"

	local TITLE="${TXT_BASE_MAIN}"
	local HELP_TXT="$(gettext 'Домен'): \Zb\Z2\"${P_COUNTRY}\"\Zn\n"
	HELP_TXT+="\n$(gettext 'Выберите часовой пояс')\n"
	HELP_TXT+="$(gettext 'По умолчанию'):"

	local DEFAULT_ITEM="$(awk -F '\t' "/^${P_COUNTRY}/{print \$3}" "${DBDIR}domains.db" | sed "s/'/\`/g")"
	local ITEMS="$(sed "s/'/\`/g" "${DBDIR}timezones.db" | awk -F '\t' '{print sq$2sq" "sq$1" "$5sq}' sq=\')"

	if [[ "${DEFAULT_ITEM}" ]]
	then
		HELP_TXT+=" \Zb\Z7\"${DEFAULT_ITEM}\"\Zn\n"
	else
		HELP_TXT+=" \Zb\Z1$(gettext 'В базе domains.db нет часового пояса по умолчанию для домена') \"${P_COUNTRY}\"!!!\Zn\n"
		DEFAULT_ITEM="$(awk -F '\t' "/^${P_COUNTRY}/{print \$2}" "${DBDIR}timezones.db" | sed "s/'/\`/g" | head -n '1')"
		POST_LOCALIZE=1
	fi

	RETURN="$(dialog_menu "${TITLE}" "${DEFAULT_ITEM}" "${HELP_TXT}" "${ITEMS}")"

	echo "${RETURN}"
	msg_log "$(gettext 'Выход из диалога'): \"${FUNCNAME} return='${RETURN}'\"" 'noecho'
}

base_dialog_localtime()
{
	msg_log "$(gettext 'Запуск диалога'): \"${FUNCNAME}$(for ((TEMP=1; TEMP<=${#}; TEMP++)); do echo -n " \$${TEMP}='$(eval "echo \"\${${TEMP}}\"")'"; done)\"" 'noecho'

	local RETURN

	local P_TIMEZONE="${1}"
	local P_COUNTRY="${2}"

	local TITLE="${TXT_BASE_MAIN}"
	local HELP_TXT="$(gettext 'Домен'): \Zb\Z2\"${P_COUNTRY}\"\Zn\n"
	HELP_TXT+="$(gettext 'Часовой пояс'): \Zb\Z2\"${P_TIMEZONE}\"\Zn\n"
	HELP_TXT+="\n$(gettext 'Выберите тип аппаратных часов')\n"
	HELP_TXT+="$(gettext 'По умолчанию'):"

	local DEFAULT_ITEM='UTC'
	local ITEMS="'UTC' '$(gettext 'Всемирное координированное время')'"
	ITEMS+=" 'LOCAL' '$(gettext 'Местное время') \Zb\Z1$(gettext '(КАТЕГОРИЧЕСКИ НЕ РЕКОМЕНДУЕТСЯ)')\Zn'"

	HELP_TXT+=" \Zb\Z7\"${DEFAULT_ITEM}\"\Zn\n"

	RETURN="$(dialog_menu "${TITLE}" "${DEFAULT_ITEM}" "${HELP_TXT}" "${ITEMS}")"

	echo "${RETURN}"
	msg_log "$(gettext 'Выход из диалога'): \"${FUNCNAME} return='${RETURN}'\"" 'noecho'
}

base_dialog_local()
{
	msg_log "$(gettext 'Запуск диалога'): \"${FUNCNAME}$(for ((TEMP=1; TEMP<=${#}; TEMP++)); do echo -n " \$${TEMP}='$(eval "echo \"\${${TEMP}}\"")'"; done)\"" 'noecho'

	local RETURN

	local P_TIMEZONE="${1}"
	local P_COUNTRY="${2}"

	local TITLE="${TXT_BASE_MAIN}"
	local HELP_TXT="$(gettext 'Домен'): \Zb\Z2\"${P_COUNTRY}\"\Zn\n"
	HELP_TXT+="$(gettext 'Часовой пояс'): \Zb\Z2\"${P_TIMEZONE}\"\Zn\n"
	HELP_TXT+="\n$(gettext 'Выберите локаль')\n"
	HELP_TXT+="$(gettext 'По умолчанию'):"

	local DEFAULT_ITEM="$(awk -F '\t' "/^[A-Z]{2}\t$(sed 's/\//\\\//g' <<< "${P_TIMEZONE}")/{print \$3}" "${DBDIR}timezones.db" | sed "s/'/\`/g")"
	local ITEMS="$(sed "s/'/\`/g" "${DBDIR}locales.db" | awk -F '\t' '{print sq$2sq" "sq$1sq}' sq=\')"

	if [[ "${DEFAULT_ITEM}" ]]
	then
		HELP_TXT+=" \Zb\Z7\"${DEFAULT_ITEM}\"\Zn\n"
	else
		HELP_TXT+=" \Zb\Z1$(gettext 'В базе timezones.db нет локали по умолчанию для часового пояса') \"${P_TIMEZONE}\"!!!\Zn\n"
		DEFAULT_ITEM="$(awk -F '\t' "/^${P_COUNTRY}/{print \$2}" "${DBDIR}locales.db" | sed "s/'/\`/g" | head -n '1')"
		POST_LOCALIZE=1
	fi

	RETURN="$(dialog_menu "${TITLE}" "${DEFAULT_ITEM}" "${HELP_TXT}" "${ITEMS}")"

	echo "${RETURN}"
	msg_log "$(gettext 'Выход из диалога'): \"${FUNCNAME} return='${RETURN}'\"" 'noecho'
}

base_dialog_keymap()
{
	msg_log "$(gettext 'Запуск диалога'): \"${FUNCNAME}$(for ((TEMP=1; TEMP<=${#}; TEMP++)); do echo -n " \$${TEMP}='$(eval "echo \"\${${TEMP}}\"")'"; done)\"" 'noecho'

	local RETURN

	local P_LOCAL="${1}"
	local P_COUNTRY="${2}"

	local TITLE="${TXT_BASE_MAIN}"
	local HELP_TXT="$(gettext 'Домен'): \Zb\Z2\"${P_COUNTRY}\"\Zn\n"
	HELP_TXT+="$(gettext 'Локаль'): \Zb\Z2\"${P_LOCAL}\"\Zn\n"
	HELP_TXT+="\n$(gettext 'Выберите раскладку клавиатуры')\n"
	HELP_TXT+="$(gettext 'По умолчанию'):"

	local DEFAULT_ITEM="$(awk -F '\t' "/^[A-Z]{2}\t$(sed 's/\//\\\//g' <<< "${P_LOCAL}")/{print \$3}" "${DBDIR}locales.db" | sed "s/'/\`/g")"
	local ITEMS="$(sed "s/'/\`/g" "${DBDIR}keymaps.db" | awk -F '\t' '{print sq$2sq" "sq$1sq}' sq=\')"

	if [[ "${DEFAULT_ITEM}" ]]
	then
		HELP_TXT+=" \Zb\Z7\"${DEFAULT_ITEM}\"\Zn\n"
	else
		HELP_TXT+=" \Zb\Z1$(gettext 'В базе locales.db нет раскладки по умолчанию для локали') \"${P_LOCAL}\"!!!\Zn\n"
		DEFAULT_ITEM="$(awk -F '\t' "/^${P_COUNTRY}/{print \$3}" "${DBDIR}locales.db" | sed "s/'/\`/g" | head -n '1')"
		POST_LOCALIZE=1
	fi

	RETURN="$(dialog_menu "${TITLE}" "${DEFAULT_ITEM}" "${HELP_TXT}" "${ITEMS}")"

	echo "${RETURN}"
	msg_log "$(gettext 'Выход из диалога'): \"${FUNCNAME} return='${RETURN}'\"" 'noecho'
}

base_dialog_keymap_toggle()
{
	msg_log "$(gettext 'Запуск диалога'): \"${FUNCNAME}$(for ((TEMP=1; TEMP<=${#}; TEMP++)); do echo -n " \$${TEMP}='$(eval "echo \"\${${TEMP}}\"")'"; done)\"" 'noecho'

	local RETURN

	local P_LOCAL="${1}"
	local P_COUNTRY="${2}"

	local TITLE="${TXT_BASE_MAIN}"
	local HELP_TXT="$(gettext 'Домен'): \Zb\Z2\"${P_COUNTRY}\"\Zn\n"
	HELP_TXT+="$(gettext 'Локаль'): \Zb\Z2\"${P_LOCAL}\"\Zn\n"
	HELP_TXT+="\n$(gettext 'Выберите дополнительную раскладку клавиатуры')\n"
	HELP_TXT+="$(gettext 'По умолчанию'):"

	local DEFAULT_ITEM='none'
	local ITEMS="'${DEFAULT_ITEM}' '${DEFAULT_ITEM}'"
	ITEMS+=" $(sed "s/'/\`/g" "${DBDIR}keymaps.db" | awk -F '\t' '{print sq$2sq" "sq$1sq}' sq=\')"

	HELP_TXT+=" \Zb\Z7\"${DEFAULT_ITEM}\"\Zn\n"

	RETURN="$(dialog_menu "${TITLE}" "${DEFAULT_ITEM}" "${HELP_TXT}" "${ITEMS}")"

	echo "${RETURN}"
	msg_log "$(gettext 'Выход из диалога'): \"${FUNCNAME} return='${RETURN}'\"" 'noecho'
}

base_dialog_font()
{
	msg_log "$(gettext 'Запуск диалога'): \"${FUNCNAME}$(for ((TEMP=1; TEMP<=${#}; TEMP++)); do echo -n " \$${TEMP}='$(eval "echo \"\${${TEMP}}\"")'"; done)\"" 'noecho'

	local RETURN

	local P_LOCAL="${1}"
	local P_COUNTRY="${2}"

	local TITLE="${TXT_BASE_MAIN}"
	local HELP_TXT="$(gettext 'Домен'): \Zb\Z2\"${P_COUNTRY}\"\Zn\n"
	HELP_TXT+="$(gettext 'Локаль'): \Zb\Z2\"${P_LOCAL}\"\Zn\n"
	HELP_TXT+="\n$(gettext 'Выберите шрифт')\n"
	HELP_TXT+="$(gettext 'По умолчанию'):"

	local DEFAULT_ITEM="$(awk -F '\t' "/^[A-Z]{2}\t$(sed 's/\//\\\//g' <<< "${LOCAL}")/{print \$4}" "${DBDIR}locales.db" | sed "s/'/\`/g")"
	local ITEMS="$(sed "s/'/\`/g" "${DBDIR}fonts.db" | awk -F '\t' '{print sq$2sq" "sq$1sq}' sq=\')"

	if [[ "${DEFAULT_ITEM}" ]]
	then
		HELP_TXT+=" \Zb\Z7\"${DEFAULT_ITEM}\"\Zn\n"
	else
		HELP_TXT+=" \Zb\Z1$(gettext 'В базе locales.db нет шрифта по умолчанию для локали') \"${P_LOCAL}\"!!!\Zn\n"
		DEFAULT_ITEM="$(awk -F '\t' "/^${COUNTRY}/{print \$4}" "${DBDIR}locales.db" | sed "s/'/\`/g" | head -n '1')"
		POST_LOCALIZE=1
	fi

	RETURN="$(dialog_menu "${TITLE}" "${DEFAULT_ITEM}" "${HELP_TXT}" "${ITEMS}")"

	echo "${RETURN}"
	msg_log "$(gettext 'Выход из диалога'): \"${FUNCNAME} return='${RETURN}'\"" 'noecho'
}

base_dialog_font_map()
{
	msg_log "$(gettext 'Запуск диалога'): \"${FUNCNAME}$(for ((TEMP=1; TEMP<=${#}; TEMP++)); do echo -n " \$${TEMP}='$(eval "echo \"\${${TEMP}}\"")'"; done)\"" 'noecho'

	local RETURN

	local P_FONT="${1}"

	local TITLE="${TXT_BASE_MAIN}"
	local HELP_TXT="$(gettext 'Шрифт'): \Zb\Z2\"${P_FONT}\"\Zn\n"
	HELP_TXT+="\n$(gettext 'Выберите карту шрифта')\n"
	HELP_TXT+="$(gettext 'По умолчанию'):"

#  local DEFAULT_ITEM="$(awk -F '\t' "/^(psf|psfu)\t$(sed 's/\//\\\//g' <<< "${P_FONT}")/{print \$3}" "${DBDIR}fonts.db" | sed "s/'/\`/g")"
	local DEFAULT_ITEM='none'
	local ITEMS="'${DEFAULT_ITEM}' '${DEFAULT_ITEM}'"
	ITEMS+=" $(sed "s/'/\`/g" "${DBDIR}font_maps.db" | awk -F '\t' '{print sq$1sq" "sq"-"sq}' sq=\')"

	if [[ "${DEFAULT_ITEM}" ]]
	then
		HELP_TXT+=" \Zb\Z7\"${DEFAULT_ITEM}\"\Zn\n"
	else
		HELP_TXT+=" \Zb\Z1$(gettext 'В базе fonts.db нет карты шрифта по умолчанию для шрифта') \"${P_FONT}\"!!!\Zn\n"
		DEFAULT_ITEM='none'
		POST_LOCALIZE=1
	fi

	RETURN="$(dialog_menu "${TITLE}" "${DEFAULT_ITEM}" "${HELP_TXT}" "${ITEMS}")"

	echo "${RETURN}"
	msg_log "$(gettext 'Выход из диалога'): \"${FUNCNAME} return='${RETURN}'\"" 'noecho'
}

base_dialog_font_unimap()
{
	msg_log "$(gettext 'Запуск диалога'): \"${FUNCNAME}$(for ((TEMP=1; TEMP<=${#}; TEMP++)); do echo -n " \$${TEMP}='$(eval "echo \"\${${TEMP}}\"")'"; done)\"" 'noecho'

	local RETURN

	local P_FONT="${1}"

	local TITLE="${TXT_BASE_MAIN}"
	local HELP_TXT="$(gettext 'Шрифт'): \Zb\Z2\"${P_FONT}\"\Zn\n"
	HELP_TXT+="\n$(gettext 'Выберите unicode карту шрифта')\n"
	HELP_TXT+="$(gettext 'По умолчанию'):"

#  local DEFAULT_ITEM="$(awk -F '\t' "/^(psf|psfu)\t$(sed 's/\//\\\//g' <<< "${P_FONT}")/{print \$4}" "${DBDIR}fonts.db" | sed "s/'/\`/g")"
	local DEFAULT_ITEM='none'
	local ITEMS="'${DEFAULT_ITEM}' '${DEFAULT_ITEM}'"
	ITEMS+=" $(sed "s/'/\`/g" "${DBDIR}font_unimaps.db" | awk -F '\t' '{print sq$1sq" "sq"-"sq}' sq=\')"

	if [[ "${DEFAULT_ITEM}" ]]
	then
		HELP_TXT+=" \Zb\Z7\"${DEFAULT_ITEM}\"\Zn\n"
	else
		HELP_TXT+=" \Zb\Z1$(gettext 'В базе fonts.db нет unicode карты шрифта по умолчанию для шрифта') \"${P_FONT}\"!!!\Zn\n"
		DEFAULT_ITEM='none'
		POST_LOCALIZE=1
	fi

	RETURN="$(dialog_menu "${TITLE}" "${DEFAULT_ITEM}" "${HELP_TXT}" "${ITEMS}")"

	echo "${RETURN}"
	msg_log "$(gettext 'Выход из диалога'): \"${FUNCNAME} return='${RETURN}'\"" 'noecho'
}

base_dialog_hostname()
{
	msg_log "$(gettext 'Запуск диалога'): \"${FUNCNAME}$(for ((TEMP=1; TEMP<=${#}; TEMP++)); do echo -n " \$${TEMP}='$(eval "echo \"\${${TEMP}}\"")'"; done)\"" 'noecho'

	local RETURN

	local P_COUNTRY="${1}"

	local TITLE="${TXT_BASE_MAIN}"
	local HELP_TXT="$(gettext 'Домен'): \Zb\Z2\"${P_COUNTRY}\"\Zn\n"
	HELP_TXT+="\n$(gettext 'Введите имя компьютера') \Zb\Z2\"<hostname.domain.org>\"\Zn\n"
	HELP_TXT+="$(gettext 'По умолчанию'):"

	local TEXT="hostname.$(tr '[:upper:]' '[:lower:]' <<< "${P_COUNTRY}")"

	HELP_TXT+=" \Zb\Z7\"${TEXT}\"\Zn\n"

	RETURN="$(dialog_inputbox "${TITLE}" "${HELP_TXT}" "${TEXT}")"

	echo "${RETURN}"
	msg_log "$(gettext 'Выход из диалога'): \"${FUNCNAME} return='${RETURN}'\"" 'noecho'
}

# Устанавливаем и настраиваем базовую систему
base_install()
{
#===============================================================================
# Тестируем зеркала и выбираем 6 самых быстрых
#===============================================================================
	[[ ! -f /etc/pacman.d/mirrorlist.bak ]] && cp -Pb /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
	cp -Pb /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.new
	sed -i '
# Раскомментируем все строки начинающиеся с 
/^#Server/{
s/#//;
};
# Удаляем оставшиеся закомментированные строки
/^#/{
d;
};
' /etc/pacman.d/mirrorlist.new

	msg_log "$(gettext 'Выбираю лучшие зеркала')"
	msg_info "$(gettext 'Пожалуйста, подождите')..."
	msg_log "rankmirrors -n 6 /etc/pacman.d/mirrorlist.new > /etc/pacman.d/mirrorlist"
	rankmirrors -n 6 /etc/pacman.d/mirrorlist.new > /etc/pacman.d/mirrorlist
	rm /etc/pacman.d/mirrorlist.new
#-------------------------------------------------------------------------------



#===============================================================================
# Устанавливаем базовую систему
#===============================================================================
# Обновляем базу пакмена
	pacman_install '-Syy' 'nochroot' 'noexit'
	if [[ "${?}" -ne '0' ]]
	then
		dialog_warn \
			"\Zb\Z1$(gettext 'Нет подключения к сети или выбранные зеркала сейчас не доступны')\Zn"
		return 1
	fi

# Устанавливаем базовые пакеты
	#core
	pacman_install "-S base" 'nochroot'

	SERVICES+=" 'cronie.service' '-' 'on'"
	SERVICES+=" 'dmeventd.service' '-' 'off'"
	SERVICES+=" 'nscd.service' '-' 'off'"
	SERVICES+=" 'ftpd.service' '-' 'off'"
	SERVICES+=" 'lvm-monitoring.service' '-' 'off'"
	SERVICES+=" 'lvmetad.service' '-' 'off'"
	SERVICES+=" 'mdadm.service' '-' 'off'"
	SERVICES+=" 'uuidd.service' '-' 'off'"

	cat "${DBDIR}modules/aai-donate.txt" > "${NS_PATH}/aai-donate.txt"

# Копируем список уже выбранных быстрых зеркал в новую систему
	cp -PbS .orig '/etc/pacman.d/mirrorlist' "${NS_PATH}/etc/pacman.d/"

	msg_log "$(gettext 'Добавляю репозиторий multilib')"
	sed -i '
# Добавляем репозиторий multilib
/^\[multilib\]/,+1{
s/^/#/;
};
0,/^#\[multilib\]/{
//{
	n;n;
	a [multilib]
	a Include = /etc/pacman.d/mirrorlist
};
};
# Включаем color
/^Color$/s/^/#/;
0,/^#Color/{
//{
	a Color
};
};
' "${NS_PATH}/etc/pacman.conf"
#-------------------------------------------------------------------------------



#===============================================================================
# Устанавливаем git
#===============================================================================
	#extra
	pacman_install "-S git" 'nochroot'
#	pacman_install "-S tk" 'nochroot'

# Создаем git репозиторий /etc/
	chroot_run bash -c "'cd /etc; git init; git config --global user.email root@${SET_HOSTNAME}; git config --global user.name root'"
#Добавляем исключения
	msg_log "$(gettext 'Настраиваю') /etc/.gitignore"
	cat "${DBDIR}modules/etc/.gitignore" > "${NS_PATH}/etc/.gitignore"
#-------------------------------------------------------------------------------

	git_commit

	base_netctl

	base_netutils

	base_ntp


#===============================================================================
# Настраиваем locale
#===============================================================================
	msg_log "$(gettext 'Настраиваю') /etc/locale.conf"
	echo "LANG=$(awk '{print $1}' <<< "${SET_LOCAL}")" > "${NS_PATH}/etc/locale.conf"
	echo 'LC_COLLATE=C' >> "${NS_PATH}/etc/locale.conf"
#  chroot_run localectl set-locale "LANG=${LANG}" "LC_COLLATE=C"

	msg_log "$(gettext 'Настраиваю') /etc/locale.gen"
	sed -i '
/^#/!d;
' "${NS_PATH}/etc/locale.gen"
	echo "${SET_LOCAL}" >> "${NS_PATH}/etc/locale.gen"
	echo "en_US.UTF-8 UTF-8" >> "${NS_PATH}/etc/locale.gen"
#	echo "en_US ISO-8859-1" >> "${NS_PATH}/etc/locale.gen"
	chroot_run locale-gen
#-------------------------------------------------------------------------------



#===============================================================================
# Настраиваем консоль
#===============================================================================
	msg_log "$(gettext 'Настраиваю') /etc/vconsole.conf"
	echo "KEYMAP=${SET_KEYMAP}" > "${NS_PATH}/etc/vconsole.conf"
	[[ ! "${SET_KEYMAP_TOGGLE}" ]] && echo -n '# ' >> "${NS_PATH}/etc/vconsole.conf"
	echo "KEYMAP_TOGGLE=${SET_KEYMAP_TOGGLE}" >> "${NS_PATH}/etc/vconsole.conf"
	echo "FONT=${SET_FONT}" >> "${NS_PATH}/etc/vconsole.conf"
	[[ ! "${SET_FONT_MAP}" ]] && echo -n '# ' >> "${NS_PATH}/etc/vconsole.conf"
	echo "FONT_MAP=${SET_FONT_MAP}" >> "${NS_PATH}/etc/vconsole.conf"
	[[ ! "${SET_FONT_UNIMAPMAP}" ]] && echo -n '# ' >> "${NS_PATH}/etc/vconsole.conf"
	echo "FONT_UNIMAPMAP=${SET_FONT_UNIMAPMAP}" >> "${NS_PATH}/etc/vconsole.conf"

# 	chroot_run localectl --no-convert set-keymap "${SET_KEYMAP}" "${SET_KEYMAP_TOGGLE}"
#-------------------------------------------------------------------------------



#===============================================================================
# Настраиваем hostname
#===============================================================================
	local HOSTNAME="$(awk -F '.' '{print $1}' <<< "${SET_HOSTNAME}")"

# Создаем /etc/hostname и добавляем имя хоста
	msg_log "$(gettext 'Настраиваю') /etc/hostname"
	echo "${HOSTNAME}" > "${NS_PATH}/etc/hostname"
# 	chroot_run hostnamectl set-hostname "${HOSTNAME}"

# Создаем /etc/machine-info и добавляем имя хоста
	msg_log "$(gettext 'Настраиваю') /etc/machine-info"
	echo "PRETTY_HOSTNAME='${HOSTNAME}'" > "${NS_PATH}/etc/machine-info"
	echo "#ICON_NAME=" >> "${NS_PATH}/etc/machine-info"
	echo "#CHASSIS=" >> "${NS_PATH}/etc/machine-info"

# Добавляем в /etc/hosts имя хоста
#	msg_log "$(gettext 'Настраиваю') /etc/hosts"
#	echo -e "127.0.0.1\t${SET_HOSTNAME}\t${HOSTNAME}" >> "${NS_PATH}/etc/hosts"
#-------------------------------------------------------------------------------



#===============================================================================
# Настраиваем fstab
#===============================================================================
	msg_log "$(gettext 'Настраиваю') /etc/fstab"
	echo '#' > "${NS_PATH}/etc/fstab"
	echo '# /etc/fstab: static file system information' >> "${NS_PATH}/etc/fstab"
	echo '#' >> "${NS_PATH}/etc/fstab"
	echo '# <file system>	<dir>	<type>	<options>	<dump>	<pass>' >> "${NS_PATH}/etc/fstab"
	echo '' >> "${NS_PATH}/etc/fstab"
	echo "$(part_mount_set_fstab_str '/' 'SET_DEV_ROOT' '1' '1')" >> "${NS_PATH}/etc/fstab"
	echo "$(part_mount_set_fstab_str '/boot' 'SET_DEV_BOOT' '1' '2')" >> "${NS_PATH}/etc/fstab"
	echo "$(part_mount_set_fstab_str '/home' 'SET_DEV_HOME' '1' '2')" >> "${NS_PATH}/etc/fstab"
	echo "$(part_mount_set_fstab_str 'none' 'SET_DEV_SWAP' '0' '0')" >> "${NS_PATH}/etc/fstab"
#-------------------------------------------------------------------------------



#===============================================================================
# Настраиваем подключение к сети
#===============================================================================
	if [[ "${RUN_NET}" ]]
	then
		case "${SET_NET_TYPE}" in
			'DHCP')
				net_dhcp_set '1'
				;;
			'STATIC')
				net_static_set '1'
				;;
			'VPN')
				net_vpn_set '1'
				;;
			'WIFI')
				net_wifi_set '1'
				;;
		esac
	fi
#-------------------------------------------------------------------------------



#===============================================================================
# Копируем resolv.conf в новую систему
#===============================================================================
	msg_log "$(gettext 'Настраиваю') /etc/resolv.conf"
	cat '/etc/resolv.conf' > "${NS_PATH}/etc/resolv.conf"
#-------------------------------------------------------------------------------



#===============================================================================
# Настраиваем localtime
#===============================================================================
	msg_log "$(gettext 'Настраиваю') /etc/localtime"
	ln -srf "${NS_PATH}/usr/share/zoneinfo/${SET_TIMEZONE}" "${NS_PATH}/etc/localtime"
# 	chroot_run timedatectl set-timezone "${SET_TIMEZONE}"
	ntpd -q -g -u ntp:ntp

	local LOCALTIME='--utc'
	[[ "${SET_LOCALTIME}" = 'LOCAL' ]] && LOCALTIME='--localtime'
	chroot_run hwclock --systohc ${LOCALTIME}
	hwclock --systohc ${LOCALTIME}

# 	chroot_run timedatectl set-ntp TRUE
#-------------------------------------------------------------------------------


	pacman_install '-Syy'


#===============================================================================
# Создаем ключи для пакмена
#===============================================================================
	chroot_run pacman-key --init
	msg_info "$(gettext 'Пожалуйста, подтвердите добавление ключей.')"
	chroot_run pacman-key --populate archlinux
	git_commit
#-------------------------------------------------------------------------------



#===============================================================================
# Добавляю resume в mkinitcpio.conf если свап выбран
#===============================================================================
	if [[ -n "${SET_DEV_SWAP[0]}" ]]
	then
		msg_log "$(gettext 'Добавляю') resume > /etc/mkinitcpio.conf"
		sed -i '
# Добавляем хук resume
/^HOOKS=/{
	h;
	s/^/#/;
	P;g;
	//{
	s/resume//g;s/ \{1,\}/ /g;
	s/filesystems/resume filesystems/;
	};
};
' "${NS_PATH}/etc/mkinitcpio.conf"

		git_commit
	fi
#-------------------------------------------------------------------------------



	[[ "${NO_MINI}" ]] && base_mc

	[[ "${NO_MINI}" ]] && base_sudo

	[[ "${NO_MINI}" ]] && base_hd

	base_fs
	base_btrfs

	[[ "${NO_MINI}" ]] && base_utils

	[[ "${NO_MINI}" ]] && base_zsh

	[[ "${NO_MINI}" ]] && base_pkgfile

#-------------------------------------------------------------------------------

	chroot_run mkinitcpio -p linux

	return 0
}

base_netctl()
{
	#core
#	pacman_install "-S netctl" 'nochroot'
	pacman_install "-S dialog" 'nochroot'
	pacman_install "-S wpa_supplicant" 'nochroot'
	pacman_install "-S wpa_actiond" 'nochroot'
	pacman_install "-S dhclient" 'nochroot'
	pacman_install "-S dhcpcd" 'nochroot'
	pacman_install "-S ifenslave" 'nochroot'
	pacman_install "-S bridge-utils" 'nochroot'
	pacman_install "-S ppp" 'nochroot'
	# зависимость для wpa_actiond
#	pacman_install "-S wpa_supplicant" 'nochroot'
	#extra
	pacman_install "-S ifplugd" 'nochroot'

	git_commit

	SET_USER_GRUPS+=',network'
}

base_netutils()
{
	#core
	pacman_install "-S dnsutils" 'nochroot'
	pacman_install "-S pptpclient" 'nochroot'
	pacman_install "-S openvpn" 'nochroot'
	pacman_install "-S rp-pppoe" 'nochroot'
	pacman_install "-S linux-atm" 'nochroot'
	pacman_install "-S b43-fwcutter" 'nochroot'
	pacman_install "-S crda" 'nochroot'
	pacman_install "-S ipw2100-fw" 'nochroot'
	pacman_install "-S ipw2200-fw" 'nochroot'
	pacman_install "-S zd1211-firmware" 'nochroot'
	pacman_install "-S rfkill" 'nochroot'
	pacman_install "-S openssh" 'nochroot'
	pacman_install "-S wireless_tools" 'nochroot'
	pacman_install "-S traceroute" 'nochroot'
	#extra
	pacman_install "-S openconnect" 'nochroot'
	pacman_install "-S dnsmasq" 'nochroot'
	pacman_install "-S ethtool" 'nochroot'
	pacman_install "-S vpnc" 'nochroot'
	pacman_install "-S gnu-netcat" 'nochroot'
	pacman_install "-S nmap" 'nochroot'
	pacman_install "-S speedtouch" 'nochroot'
	pacman_install "-S tcpdump" 'nochroot'
	#community
	pacman_install "-S usb_modeswitch" 'nochroot'
	pacman_install "-S xl2tpd" 'nochroot'
	pacman_install "-S wvdial" 'nochroot'

	git_commit

	SERVICES+=" 'sshd.service' '-' 'off'"
	SERVICES+=" 'sshdgenkeys.service' '-' 'off'"

	SET_USER_GRUPS+=',rfkill'
}

base_ntp()
{
	#extra
	pacman_install "-S ntp" 'nochroot'

	git_commit

	SERVICES+=" 'ntpd.service' '-' 'on'"
	SERVICES+=" 'ntpdate.service' '-' 'off'"
}

base_mc()
{
	#core
	pacman_install "-S gpm"
	#extra
	pacman_install "-S p7zip"
	pacman_install "-S zip"
	pacman_install "-S unrar"
	pacman_install "-S smbclient"
	pacman_install "-S mtools"
	pacman_install "-S cvs"
	pacman_install "-S aspell"
	pacman_install "-S cdrkit"
	pacman_install "-S cdparanoia"
	#community
	pacman_install "-S mc"
	pacman_install "-S unarj"
	pacman_install "-S unace"
	pacman_install "-S python2-pytz"
	pacman_install "-S python2-boto"
	pacman_install "-S cabextract"

	git_commit
}

base_sudo()
{
	#core
	pacman_install "-S sudo"

	git_commit

# Разрешаем использование sudo пользователям в группе wheel
	msg_log "$(gettext 'Настраиваю') /etc/sudoers"
	sed -i '
/^%wheel ALL=(ALL) ALL/s/^/#/;
/^# %wheel ALL=(ALL) ALL$/{
	h;
	s/^# //;
	H;
	g;
};
' "${NS_PATH}/etc/sudoers"

	SET_USER_GRUPS+=',wheel'

	git_commit
}

base_hd()
{
	#core
	pacman_install "-S hdparm"
	#extra
	pacman_install "-S smartmontools"
	pacman_install "-S parted"
	pacman_install "-S gptfdisk"
	pacman_install "-S fsarchiver"
	pacman_install "-S testdisk"
	pacman_install "-S ddrescue"
	#community
	pacman_install "-S partimage"
	pacman_install "-S partclone"
	pacman_install "-S clonezilla"

	git_commit

	SERVICES+=" 'smartd.service'  '-' 'off'"
	SERVICES+=" 'partimaged.service'  '-' 'off'"
}

base_fs()
{
	#core
	pacman_install "-S mkinitcpio-nfs-utils"
	pacman_install "-S nfs-utils"
	pacman_install "-S nilfs-utils"
	pacman_install "-S dmraid"
	#extra
	pacman_install "-S dosfstools"
	pacman_install "-S ntfs-3g"
	pacman_install "-S f2fs-tools"
	#community
	pacman_install "-S nbd"
	pacman_install "-S exfat-utils"

	git_commit

	SERVICES+=" 'blkmapd.service'  '-' 'off'"
	SERVICES+=" 'nfsd.service'  '-' 'off'"
	SERVICES+=" 'rpc-gssd.service'  '-' 'off'"
	SERVICES+=" 'rpc-idmapd.service'  '-' 'off'"
	SERVICES+=" 'rpc-mountd.service'  '-' 'off'"
	SERVICES+=" 'rpc-statd.service'  '-' 'off'"
	SERVICES+=" 'rpc-svcgssd.service'  '-' 'off'"
	SERVICES+=" 'dmraid.service'  '-' 'off'"
	SERVICES+=" 'nbd.service'  '-' 'off'"
}

base_btrfs()
{
	#core
	pacman_install "-S btrfs-progs"

	git_commit

#     msg_log "$(gettext 'Добавляю') btrfs > /etc/mkinitcpio.conf"
#     sed -i '
# # Добавляем хук btrfs
# /^HOOKS=/{
#     h;
#     s/^/#/;
#     P;g;
#     //{
# 	s/btrfs//g;s/ \{1,\}/ /g;
# 	s/filesystems/btrfs filesystems/;
#     };
# };
# ' "${NS_PATH}/etc/mkinitcpio.conf"
# 
#     git_commit
}

base_utils()
{
	#extra
	pacman_install "-S lftp"
	pacman_install "-S irssi"
	pacman_install "-S rsync"
	pacman_install "-S wget"
	#community
	pacman_install "-S darkhttpd"
	pacman_install "-S elinks"
	pacman_install "-S js"
	pacman_install "-S haveged"

	git_commit

	SERVICES+=" 'rsyncd.service'  '-' 'off'"
	SERVICES+=" 'haveged.service'  '-' 'off'"
}

base_zsh()
{
	#extra
	pacman_install "-S zsh"
	pacman_install "-S grml-zsh-config"
	#community
	pacman_install "-S zsh-syntax-highlighting"

	git_commit

	msg_log "$(gettext 'Добавляю') zsh-syntax-highlighting > /etc/skel/.zshrc"
	echo '[ -r /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] && source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh' >> "${NS_PATH}/etc/skel/.zshrc"
	cat "${NS_PATH}/etc/skel/.zshrc" > "${NS_PATH}/root/.zshrc"

# Меняем оболочку по умолчанию для новых пользователей
	chroot_run useradd -D --shell /usr/bin/zsh
# Меняем оболочку по умолчанию для root
	chroot_run usermod --shell /usr/bin/zsh root

	git_commit
}

base_pkgfile()
{
	#community
	pacman_install "-S pkgfile"

	git_commit

# Добавляем определение в каком пакете можно найти не существующую команду
	msg_log "$(gettext 'Добавляю') pkgfile > /etc/skel/.zshrc"
	echo '[ -r /usr/share/doc/pkgfile/command-not-found.zsh ] && source /usr/share/doc/pkgfile/command-not-found.zsh' >> "${NS_PATH}/etc/skel/.zshrc"
	cat "${NS_PATH}/etc/skel/.zshrc" > "${NS_PATH}/root/.zshrc"

# Включаем ежедневное обновление базы по крону
	SERVICES+=" 'pkgfile-update.timer'  '-' 'on'"

# Обновляем базу pkgfile
	chroot_run pkgfile --update

	git_commit
}
