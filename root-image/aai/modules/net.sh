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

#Отключаем подключенные сетевые интерфейсы
#systemctl stop 'dhcpcd.service'
# for IFACE in /sys/class/net/*
# do
#   IFACE="${IFACE/\/sys\/class\/net\//}"
#   [[ "${IFACE}" == 'lo' ]] && continue
#   ip link set "${IFACE}" down
# done


# Добавляем функцию модуля в главное меню, пробел в конце обязательно!
MAIN_CASE+=('net')

#===============================================================================
# Сигнальная переменная успешного завершения функции модуля,
# может потребоваться для других модулей, для проверки зависимости
RUN_NET=
TXT_NET_MAIN="$(gettext 'Сеть')"

# Переменные по умолчанию
DEFAULT_NAMESERVERS=('8.8.8.8' '8.8.4.4')

SET_NET_IFACE=
SET_NET_TYPE=

SET_STATIC_IP=
SET_STATIC_NETMASK=
SET_STATIC_BROADCAST=
SET_STATIC_DNS=
SET_STATIC_GATEWAY=

SET_HTTP_PROXY=
SET_HTTPS_PROXY=
SET_FTP_PROXY=
#===============================================================================

# Выводим строку пункта главного меню
str_net()
{
	local TEMP="\Zb\Z1($(gettext 'ОБЯЗАТЕЛЬНО!!!'))\Zn"

	[[ ! "$(get_ifaces)" ]] && TEMP+=" \Zb\Z1($(gettext 'УСТРОЙСТВА НЕ НАЙДЕНЫ!!!'))\Zn"
	[[ "${RUN_NET}" ]] && TEMP="\Zb\Z2($(gettext 'ВЫПОЛНЕНО'))\Zn"

	echo "${TXT_NET_MAIN} ${TEMP}"
}

# Функция выполнения из главного меню
run_net()
{
	local IFACE
	local TYPE

	while true
	do
		IFACE="$(net_dialog_iface)"
		[[ ! -n "${IFACE}" ]] && return 1
		if [[ "${IFACE}" == 'ok' ]]
		then
			RUN_NET=1
			return 0
		fi

		TYPE="$(net_dialog_type "${IFACE}")"
		case "${TYPE}" in
			'DHCP')
				net_dhcp "${IFACE}" || continue
				RUN_NET=1
				return 0
				;;
			'STATIC')
				net_static "${IFACE}" || continue
				RUN_NET=1
				return 0
				;;
			'VPN')
				net_vpn "${IFACE}" || continue
				RUN_NET=1
				return 0
				;;
			'WIFI')
				net_wifi "${IFACE}" || continue
				RUN_NET=1
				return 0
				;;
		esac
	done
}

net_dialog_iface()
{
	msg_log "$(gettext 'Запуск диалога'): \"${FUNCNAME}$(for ((TEMP=1; TEMP<=${#}; TEMP++)); do echo -n " \$${TEMP}='$(eval "echo \"\${${TEMP}}\"")'"; done)\"" 'noecho'

	local RETURN

	local TITLE="${TXT_NET_MAIN}"
	local HELP_TXT="\n$(gettext 'Выберите сетевой адаптер')\n"

	local DEFAULT_ITEM=''
	local ITEMS="'ok' '$(gettext 'Уже подключено')'"
	ITEMS+=" $(ip l | awk 'BEGIN {temp=""} $1~/[0-9]+:/ && $2!~/lo:/ && temp=="" { temp=sq substr($2, 1, length($2)-1) sq }
$1~/^link\// && temp!="" { print temp " " sq substr($0, 5, length($0)) sq; temp="" }' sq=\' | sort -u)"

	RETURN="$(dialog_menu "${TITLE}" "${DEFAULT_ITEM}" "${HELP_TXT}" "${ITEMS}" "--cancel-label '${TXT_MAIN_MENU}'")"

	echo "${RETURN}"
	msg_log "$(gettext 'Выход из диалога'): \"${FUNCNAME} return='${RETURN}'\"" 'noecho'
}

net_dialog_type()
{
	msg_log "$(gettext 'Запуск диалога'): \"${FUNCNAME}$(for ((TEMP=1; TEMP<=${#}; TEMP++)); do echo -n " \$${TEMP}='$(eval "echo \"\${${TEMP}}\"")'"; done)\"" 'noecho'

	local RETURN

	local P_IFACE="${1}"

	local TITLE="${TXT_NET_MAIN}"
	local HELP_TXT="$(gettext 'Сетевой адаптер'): \Zb\Z2\"${P_IFACE}\"\Zn\n"
	HELP_TXT+="\n$(gettext 'Выберите тип подключения')\n"
#  HELP_TXT+="$(gettext 'Статус:')\n"

	local DEFAULT_ITEM='DHCP'
	local ITEMS="'DHCP' '$(gettext 'DHCP')'"
	ITEMS+=" 'STATIC' '$(gettext 'Статичный IP')'"
	ITEMS+=" 'VPN' '$(gettext 'VPN') \Zb\Z3($(gettext 'Пока не поддерживается'))\Zn'"
	ITEMS+=" 'WIFI' '$(gettext 'WIFI') \Zb\Z3($(gettext 'Пока не поддерживается'))\Zn'"

	RETURN="$(dialog_menu "${TITLE}" "${DEFAULT_ITEM}" "${HELP_TXT}" "${ITEMS}" "--cancel-label '$(gettext 'Назад')'")"

	echo "${RETURN}"
	msg_log "$(gettext 'Выход из диалога'): \"${FUNCNAME} return='${RETURN}'\"" 'noecho'
}

net_off()
{
	local FILE_PROF

	if [[ "${SET_NET_IFACE}" ]]
	then
		case "${SET_NET_TYPE}" in
			'DHCP')
				FILE_PROF="ethernet-dhcp-${SET_NET_IFACE}"
				;;
			'STATIC')
				FILE_PROF="ethernet-static-${SET_NET_IFACE}"
				;;
		esac
		netctl stop "${FILE_PROF}"
		netctl disable "${FILE_PROF}"
		ip link set "${SET_NET_IFACE}" down
	fi
	RUN_NET=
	set_global_var 'SET_NET_IFACE' ''
	set_global_var 'SET_NET_TYPE' ''
}

net_vpn()
{
	local P_IFACE="${1}"

	local TYPE='VPN'

# Устанавливаем локальные переменные и их значения по умолчанию
	local HTTPS_PROXY
	local HTTP_PROXY
	local FTP_PROXY

	dialog_warn \
		"\Zb\Z1\"VPN\" $(gettext 'пока не поддерживается, помогите проекту, допишите данный функционал')\Zn"
	return 1

	HTTP_PROXY="$(net_dialog_proxy_http "${TYPE}" "${P_IFACE}")"

	HTTPS_PROXY="$(net_dialog_proxy_https "${TYPE}" "${P_IFACE}")"

	FTP_PROXY="$(net_dialog_proxy_ftp "${TYPE}" "${P_IFACE}")"
}

net_vpn_set()
{
	local IS_NEW_SYS="${1}"

	local PATH_ROOT
	[[ "${IS_NEW_SYS}" ]] && PATH_ROOT="${NS_PATH}"

	local CHROOTC
	[[ "${IS_NEW_SYS}" ]] && CHROOTC='chroot_run'
}

net_wifi()
{
	local P_IFACE="${1}"

	local TYPE='WIFI'

# Устанавливаем локальные переменные и их значения по умолчанию
	local HTTPS_PROXY
	local HTTP_PROXY
	local FTP_PROXY

	dialog_warn \
		"\Zb\Z1\"WIFI\" $(gettext 'пока не поддерживается, помогите проекту, допишите данный функционал')\Zn"
	return 1

	HTTP_PROXY="$(net_dialog_proxy_http "${TYPE}" "${P_IFACE}")"

	HTTPS_PROXY="$(net_dialog_proxy_https "${TYPE}" "${P_IFACE}")"

	FTP_PROXY="$(net_dialog_proxy_ftp "${TYPE}" "${P_IFACE}")"
}

net_wifi_set()
{
	local IS_NEW_SYS="${1}"

	local PATH_ROOT
	[[ "${IS_NEW_SYS}" ]] && PATH_ROOT="${NS_PATH}"

	local CHROOTC
	[[ "${IS_NEW_SYS}" ]] && CHROOTC='chroot_run'
}

net_dhcp()
{
	local P_IFACE="${1}"

	local TYPE='DHCP'

# Устанавливаем локальные переменные и их значения по умолчанию
	local HTTPS_PROXY
	local HTTP_PROXY
	local FTP_PROXY

	HTTP_PROXY="$(net_dialog_proxy_http "${TYPE}" "${P_IFACE}")"

	HTTPS_PROXY="$(net_dialog_proxy_https "${TYPE}" "${P_IFACE}")"

	FTP_PROXY="$(net_dialog_proxy_ftp "${TYPE}" "${P_IFACE}")"

# Проверяем правильность ввода параметров, если не правильно введено,
# то повторяем выбор, если отмена то выход
	dialog_yesno \
		"$(gettext 'Подтвердите свой выбор')" \
		"
\Zb\Z7IFACE=\Zn${P_IFACE}\n
\Zb\Z7TYPE=\Zn${TYPE}\n
\Zb\Z7HTTP_PROXY=\Zn${HTTP_PROXY}\n
\Zb\Z7HTTPS_PROXY=\Zn${HTTPS_PROXY}\n
\Zb\Z7FTP_PROXY=\Zn${FTP_PROXY}\n
" \
		'--defaultno'
	case "${?}" in
		'0') #Yes
# Устанавливаем выбранные переменные в глобальные
			ip link set "${IFACE}" down
			net_off
			set_global_var 'SET_NET_IFACE' "${IFACE}"
			set_global_var 'SET_NET_TYPE' "${TYPE}"
			set_global_var 'SET_HTTPS_PROXY' "${HTTPS_PROXY}"
			set_global_var 'SET_HTTP_PROXY' "${HTTP_PROXY}"
			set_global_var 'SET_FTP_PROXY' "${FTP_PROXY}"

			net_dhcp_set && return 0
			;;
	esac
	return 1
}

net_dhcp_set()
{
	local IS_NEW_SYS="${1}"

	local PATH_ROOT
	[[ "${IS_NEW_SYS}" ]] && PATH_ROOT="${NS_PATH}"

	local CHROOTC
	[[ "${IS_NEW_SYS}" ]] && CHROOTC='chroot_run'

	msg_log "$(gettext 'Настраиваю') /etc/netctl/ethernet-dhcp-${SET_NET_IFACE}"
	cp -Pb "${PATH_ROOT}/etc/netctl/examples/ethernet-dhcp" "${PATH_ROOT}/etc/netctl/ethernet-dhcp-${SET_NET_IFACE}"

	sed -i "
# Меняем Interface
/^Interface=/s/^/#/;
0,/^#Interface=/{
//{
	a Interface='${SET_NET_IFACE}'
};
};
" "${PATH_ROOT}/etc/netctl/ethernet-dhcp-${SET_NET_IFACE}"

	if [[ ! "${IS_NEW_SYS}" ]]
	then
		${CHROOTC} netctl stop "ethernet-dhcp-${SET_NET_IFACE}"
		${CHROOTC} netctl disable "ethernet-dhcp-${SET_NET_IFACE}"
	fi

	${CHROOTC} netctl enable "ethernet-dhcp-${SET_NET_IFACE}"

	if [[ ! "${IS_NEW_SYS}" ]]
	then
		${CHROOTC} netctl start "ethernet-dhcp-${SET_NET_IFACE}"
		if [[ "${?}" -ne '0' ]]
		then
			dialog_warn \
				"\Zb\Z1$(gettext 'Нет подключения к сети или неправильные параметры')\Zn"
			return 1
		fi
	fi

	net_set_proxy 'https' "${PATH_ROOT}"
	net_set_proxy 'http' "${PATH_ROOT}"
	net_set_proxy 'ftp' "${PATH_ROOT}"
}

net_static()
{
	local P_IFACE="${1}"

	local TYPE='STATIC'

	local IP
	local NETMASK
	local BROADCAST
	local DNS
	local GATEWAY

	local HTTPS_PROXY
	local HTTP_PROXY
	local FTP_PROXY

	local TEMP

	TEMP="$(net_static_dialog_ip "${TYPE}" "${P_IFACE}")"
	[[ ! -n "${TEMP}" ]] && return 1
	IP="${TEMP}"

	TEMP="$(net_static_dialog_netmask "${TYPE}" "${P_IFACE}")"
	[[ ! -n "${TEMP}" ]] && return 1
	NETMASK="${TEMP}"

	TEMP="$(net_static_dialog_broadcast "${IP}" "${TYPE}" "${P_IFACE}")"
	[[ ! -n "${TEMP}" ]] && return 1
	BROADCAST="${TEMP}"

	TEMP="$(net_static_dialog_dns "${IP}" "${TYPE}" "${P_IFACE}")"
	[[ ! -n "${TEMP}" ]] && return 1
	DNS="${TEMP}"

	TEMP="$(net_static_dialog_gateway "${IP}" "${TYPE}" "${P_IFACE}")"
	[[ ! -n "${TEMP}" ]] && return 1
	GATEWAY="${TEMP}"

	HTTP_PROXY="$(net_dialog_proxy_http "${TYPE}" "${P_IFACE}")"

	HTTPS_PROXY="$(net_dialog_proxy_https "${TYPE}" "${P_IFACE}")"

	FTP_PROXY="$(net_dialog_proxy_ftp "${TYPE}" "${P_IFACE}")"

# Проверяем правильность ввода параметров, если не правильно введено,
# то повторяем выбор, если отмена то выход
	dialog_yesno \
		"$(gettext 'Подтвердите свой выбор')" \
		"
\Zb\Z7IFACE=\Zn${P_IFACE}\n
\Zb\Z7TYPE=\Zn${TYPE}\n
\Zb\Z7IP=\Zn${IP}\n
\Zb\Z7NETMASK=\Zn${NETMASK}\n
\Zb\Z7BROADCAST=\Zn${BROADCAST}\n
\Zb\Z7DNS=\Zn${DNS}\n
\Zb\Z7GATEWAY=\Zn${GATEWAY}\n
\Zb\Z7HTTP_PROXY=\Zn${HTTP_PROXY}\n
\Zb\Z7HTTPS_PROXY=\Zn${HTTPS_PROXY}\n
\Zb\Z7FTP_PROXY=\Zn${FTP_PROXY}\n
" \
		'--defaultno'

	case "${?}" in
		'0') #Yes
# Устанавливаем выбранные переменные в глобальные
			ip link set "${IFACE}" down
			net_off
			set_global_var 'SET_NET_IFACE' "${IFACE}"
			set_global_var 'SET_NET_TYPE' "${TYPE}"
			set_global_var 'SET_STATIC_IP' "${IP}"
			set_global_var 'SET_STATIC_NETMASK' "${NETMASK}"
			set_global_var 'SET_STATIC_BROADCAST' "${BROADCAST}"
			set_global_var 'SET_STATIC_DNS' "${DNS}"
			set_global_var 'SET_STATIC_GATEWAY' "${GATEWAY}"
			set_global_var 'SET_HTTPS_PROXY' "${HTTPS_PROXY}"
			set_global_var 'SET_HTTP_PROXY' "${HTTP_PROXY}"
			set_global_var 'SET_FTP_PROXY' "${FTP_PROXY}"

			net_static_set && return 0
			;;
	esac
	return 1
}

net_static_dialog_ip()
{
	msg_log "$(gettext 'Запуск диалога'): \"${FUNCNAME}$(for ((TEMP=1; TEMP<=${#}; TEMP++)); do echo -n " \$${TEMP}='$(eval "echo \"\${${TEMP}}\"")'"; done)\"" 'noecho'

	local RETURN

	local P_TYPE="${1}"
	local P_IFACE="${2}"

	local TITLE="${TXT_NET_MAIN}"
	local HELP_TXT="$(gettext 'Сетевой адаптер'): \Zb\Z2\"${P_IFACE}\"\Zn\n"
	HELP_TXT+="$(gettext 'Тип подключения'): \Zb\Z2\"${P_TYPE}\"\Zn\n"
	HELP_TXT+="\n$(gettext 'Введите IP адрес') (IP address)\n"

	local TEXT='192.168.0.2'

	RETURN="$(dialog_inputbox "${TITLE}" "${HELP_TXT}" "${TEXT}")"

	echo "${RETURN}"
	msg_log "$(gettext 'Выход из диалога'): \"${FUNCNAME} return='${RETURN}'\"" 'noecho'
}

net_static_dialog_netmask()
{
	msg_log "$(gettext 'Запуск диалога'): \"${FUNCNAME}$(for ((TEMP=1; TEMP<=${#}; TEMP++)); do echo -n " \$${TEMP}='$(eval "echo \"\${${TEMP}}\"")'"; done)\"" 'noecho'

	local RETURN

	local P_TYPE="${1}"
	local P_IFACE="${2}"

	local TITLE="${TXT_NET_MAIN}"
	local HELP_TXT="$(gettext 'Сетевой адаптер'): \Zb\Z2\"${P_IFACE}\"\Zn\n"
	HELP_TXT+="$(gettext 'Тип подключения'): \Zb\Z2\"${P_TYPE}\"\Zn\n"
	HELP_TXT+="\n$(gettext 'Введите маску подсети') (netmask)\n"

	local TEXT='255.255.255.0'

	RETURN="$(dialog_inputbox "${TITLE}" "${HELP_TXT}" "${TEXT}")"

	echo "${RETURN}"
	msg_log "$(gettext 'Выход из диалога'): \"${FUNCNAME} return='${RETURN}'\"" 'noecho'
}

net_static_dialog_broadcast()
{
	msg_log "$(gettext 'Запуск диалога'): \"${FUNCNAME}$(for ((TEMP=1; TEMP<=${#}; TEMP++)); do echo -n " \$${TEMP}='$(eval "echo \"\${${TEMP}}\"")'"; done)\"" 'noecho'

	local RETURN

	local P_IP="${1}"
	local P_TYPE="${2}"
	local P_IFACE="${3}"

	local TITLE="${TXT_NET_MAIN}"
	local HELP_TXT="$(gettext 'Сетевой адаптер'): \Zb\Z2\"${P_IFACE}\"\Zn\n"
	HELP_TXT+="$(gettext 'Тип подключения'): \Zb\Z2\"${P_TYPE}\"\Zn\n"
	HELP_TXT+="\n$(gettext 'Введите широковещательный канал') (broadcast)\n"

	local TEXT="$(sed 's/\.[^.]*$/\.255/' <<< "${P_IP}")"

	RETURN="$(dialog_inputbox "${TITLE}" "${HELP_TXT}" "${TEXT}")"

	echo "${RETURN}"
	msg_log "$(gettext 'Выход из диалога'): \"${FUNCNAME} return='${RETURN}'\"" 'noecho'
}

net_static_dialog_dns()
{
	msg_log "$(gettext 'Запуск диалога'): \"${FUNCNAME}$(for ((TEMP=1; TEMP<=${#}; TEMP++)); do echo -n " \$${TEMP}='$(eval "echo \"\${${TEMP}}\"")'"; done)\"" 'noecho'

	local RETURN

	local P_IP="${1}"
	local P_TYPE="${2}"
	local P_IFACE="${3}"

	local TITLE="${TXT_NET_MAIN}"
	local HELP_TXT="$(gettext 'Сетевой адаптер'): \Zb\Z2\"${P_IFACE}\"\Zn\n"
	HELP_TXT+="$(gettext 'Тип подключения'): \Zb\Z2\"${P_TYPE}\"\Zn\n"
	HELP_TXT+="\n$(gettext 'Введите DNS сервер') (dns)\n"

	local TEXT="$(sed 's/\.[^.]*$/\.1/' <<< "${P_IP}")"

	RETURN="$(dialog_inputbox "${TITLE}" "${HELP_TXT}" "${TEXT}")"

	echo "${RETURN}"
	msg_log "$(gettext 'Выход из диалога'): \"${FUNCNAME} return='${RETURN}'\"" 'noecho'
}

net_static_dialog_gateway()
{
	msg_log "$(gettext 'Запуск диалога'): \"${FUNCNAME}$(for ((TEMP=1; TEMP<=${#}; TEMP++)); do echo -n " \$${TEMP}='$(eval "echo \"\${${TEMP}}\"")'"; done)\"" 'noecho'

	local RETURN

	local P_IP="${1}"
	local P_TYPE="${2}"
	local P_IFACE="${3}"

	local TITLE="${TXT_NET_MAIN}"
	local HELP_TXT="$(gettext 'Сетевой адаптер'): \Zb\Z2\"${P_IFACE}\"\Zn\n"
	HELP_TXT+="$(gettext 'Тип подключения'): \Zb\Z2\"${P_TYPE}\"\Zn\n"
	HELP_TXT+="\n$(gettext 'Введите шлюз') (gateway)\n"

	local TEXT="$(sed 's/\.[^.]*$/\.1/' <<< "${P_IP}")"

	RETURN="$(dialog_inputbox "${TITLE}" "${HELP_TXT}" "${TEXT}")"

	echo "${RETURN}"
	msg_log "$(gettext 'Выход из диалога'): \"${FUNCNAME} return='${RETURN}'\"" 'noecho'
}

net_static_set()
{
	local IS_NEW_SYS="${1}"

	local PATH_ROOT
	[[ "${IS_NEW_SYS}" ]] && PATH_ROOT="${NS_PATH}"

	local CHROOTC
	[[ "${IS_NEW_SYS}" ]] && CHROOTC='chroot_run'

	local DNS="'${SET_STATIC_DNS}'"
	msg_log "$(gettext 'Настраиваю') /etc/resolv.conf"
	echo "nameserver ${SET_STATIC_DNS}" > "${PATH_ROOT}/etc/resolv.conf"

	local TEMP
	for TEMP in ${DEFAULT_NAMESERVERS[@]}
	do
		echo "nameserver ${TEMP}" >> "${PATH_ROOT}/etc/resolv.conf"
		DNS+=" '${TEMP}'"
	done

	msg_log "$(gettext 'Настраиваю') /etc/netctl/ethernet-static-${SET_NET_IFACE}"
	cp -Pb "${PATH_ROOT}/etc/netctl/examples/ethernet-static" "${PATH_ROOT}/etc/netctl/ethernet-static-${SET_NET_IFACE}"
	sed -i "
# Меняем Interface
/^Interface=/s/^/#/;
0,/^#Interface=/{
//{
	a Interface=${SET_NET_IFACE}
};
};
# Меняем Address
/^Address=/s/^/#/;
0,/^#Address=/{
//{
	a Address=('${SET_STATIC_IP}/${SET_STATIC_NETMASK}')
};
};
# Меняем Gateway
/^Gateway=/s/^/#/;
0,/^#Gateway=/{
//{
	a Gateway='${SET_STATIC_GATEWAY}'
};
};
# Меняем DNS
/^DNS=/s/^/#/;
0,/^#DNS=/{
//{
	a DNS=(${DNS})
};
};
#      SET_STATIC_BROADCAST
" "${PATH_ROOT}/etc/netctl/ethernet-static-${SET_NET_IFACE}"

	if [[ ! "${IS_NEW_SYS}" ]]
	then
		${CHROOTC} netctl stop "ethernet-static-${SET_NET_IFACE}"
		${CHROOTC} netctl disable "ethernet-static-${SET_NET_IFACE}"
	fi

	${CHROOTC} netctl enable "ethernet-static-${SET_NET_IFACE}"

	if [[ ! "${IS_NEW_SYS}" ]]
	then
		${CHROOTC} netctl start "ethernet-static-${SET_NET_IFACE}"
		if [[ "${?}" -ne '0' ]]
		then
			dialog_warn \
				"\Zb\Z1$(gettext 'Нет подключения к сети или неправильные параметры')\Zn"
			return 1
		fi
	fi

	net_set_proxy 'https' "${PATH_ROOT}"
	net_set_proxy 'http' "${PATH_ROOT}"
	net_set_proxy 'ftp' "${PATH_ROOT}"
}

net_dialog_proxy_http()
{
	msg_log "$(gettext 'Запуск диалога'): \"${FUNCNAME}$(for ((TEMP=1; TEMP<=${#}; TEMP++)); do echo -n " \$${TEMP}='$(eval "echo \"\${${TEMP}}\"")'"; done)\"" 'noecho'

	local RETURN

	local P_TYPE="${1}"
	local P_IFACE="${2}"

	local TITLE="${TXT_NET_MAIN}"
	local HELP_TXT="$(gettext 'Сетевой адаптер'): \Zb\Z2\"${P_IFACE}\"\Zn\n"
	HELP_TXT+="$(gettext 'Тип подключения'): \Zb\Z2\"${P_TYPE}\"\Zn\n"
	HELP_TXT+="\n$(gettext 'Введите http прокси сервер') (http_proxy)\n"
	HELP_TXT+='\Zb\Z7http://user:password@server:port/\Zn\n'

	local TEXT=''

	RETURN="$(dialog_inputbox "${TITLE}" "${HELP_TXT}" "${TEXT}" '--no-cancel')"

	echo "${RETURN}"
	msg_log "$(gettext 'Выход из диалога'): \"${FUNCNAME} return='${RETURN}'\"" 'noecho'
}

net_dialog_proxy_https()
{
	msg_log "$(gettext 'Запуск диалога'): \"${FUNCNAME}$(for ((TEMP=1; TEMP<=${#}; TEMP++)); do echo -n " \$${TEMP}='$(eval "echo \"\${${TEMP}}\"")'"; done)\"" 'noecho'

	local RETURN

	local P_TYPE="${1}"
	local P_IFACE="${2}"

	local TITLE="${TXT_NET_MAIN}"
	local HELP_TXT="$(gettext 'Сетевой адаптер'): \Zb\Z2\"${P_IFACE}\"\Zn\n"
	HELP_TXT+="$(gettext 'Тип подключения'): \Zb\Z2\"${P_TYPE}\"\Zn\n"
	HELP_TXT+="\n$(gettext 'Введите https прокси сервер') (https_proxy)\n"
	HELP_TXT+='\Zb\Z7https://user:password@server:port/\Zn\n'

	local TEXT=''

	RETURN="$(dialog_inputbox "${TITLE}" "${HELP_TXT}" "${TEXT}" '--no-cancel')"

	echo "${RETURN}"
	msg_log "$(gettext 'Выход из диалога'): \"${FUNCNAME} return='${RETURN}'\"" 'noecho'
}

net_dialog_proxy_ftp()
{
	msg_log "$(gettext 'Запуск диалога'): \"${FUNCNAME}$(for ((TEMP=1; TEMP<=${#}; TEMP++)); do echo -n " \$${TEMP}='$(eval "echo \"\${${TEMP}}\"")'"; done)\"" 'noecho'

	local RETURN

	local P_TYPE="${1}"
	local P_IFACE="${2}"

	local TITLE="${TXT_NET_MAIN}"
	local HELP_TXT="$(gettext 'Сетевой адаптер'): \Zb\Z2\"${P_IFACE}\"\Zn\n"
	HELP_TXT+="$(gettext 'Тип подключения'): \Zb\Z2\"${P_TYPE}\"\Zn\n"
	HELP_TXT+="\n$(gettext 'Введите ftp прокси сервер') (ftp_proxy)\n"
	HELP_TXT+='\Zb\Z7ftp://user:password@server:port/\Zn\n'

	local TEXT=''

	RETURN="$(dialog_inputbox "${TITLE}" "${HELP_TXT}" "${TEXT}" '--no-cancel')"

	echo "${RETURN}"
	msg_log "$(gettext 'Выход из диалога'): \"${FUNCNAME} return='${RETURN}'\"" 'noecho'
}

net_set_proxy()
{
	local P_TYPE="${1}"
	local P_PATH_ROOT="${2}"

	eval "local PROXY=\${SET_$(tr '[:lower:]' '[:upper:]' <<< "${P_TYPE}")_PROXY}"

	if [[ -n "${PROXY}" ]]
	then
		eval "export ${P_TYPE}_proxy='${PROXY}'"
		msg_log "$(gettext 'Настраиваю') /etc/profile.d/${P_TYPE}_proxy.sh"
		echo "export ${P_TYPE}_proxy='${PROXY}'" > "${P_PATH_ROOT}/etc/profile.d/${P_TYPE}_proxy.sh"
		chmod +x "${P_PATH_ROOT}/etc/profile.d/${P_TYPE}_proxy.sh"
	fi
}

get_ifaces()
{
	local IFACE
	for IFACE in /sys/class/net/*
	do
		IFACE="${IFACE/\/sys\/class\/net\//}"
		[[ "${IFACE}" == 'lo' ]] && continue
		echo "${IFACE}"
	done
}
