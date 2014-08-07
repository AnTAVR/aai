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

	local DEF_MENU='lnmpp'

	while true
	do
		DEF_MENU="$(webserver_dialog_menu "${DEF_MENU}")"
		case "${DEF_MENU}" in
			'lnmpp')
				webserver_lnmpp || continue
				[[ ! "$SET_WEBSERVER" ]] && set_global_var 'SET_WEBSERVER' "${DEF_MENU}"
				RUN_WEBSERVER=1
				return 0
				;;
			'lampp')
				webserver_lampp || continue
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
	local ITEMS="'lnmpp' 'nginx mariadb(mysql) php postgresql'"
	ITEMS+=" 'lampp' 'apache mariadb(mysql) php postgresql \Zb\Z3($(gettext 'Пока не поддерживается'))\Zn'"

	HELP_TXT+=" \Zb\Z7\"${DEFAULT_ITEM}\"\Zn\n"

	RETURN="$(dialog_menu "${TITLE}" "${DEFAULT_ITEM}" "${HELP_TXT}" "${ITEMS}" "--cancel-label '${TXT_MAIN_MENU}'")"

	echo "${RETURN}"
	msg_log "$(gettext 'Выход из диалога'): \"${FUNCNAME} return='${RETURN}'\"" 'noecho'
}

webserver_lnmpp()
{
	webserver_nginx
	webserver_php
	webserver_mariadb
	webserver_postgresql
}

webserver_lampp()
{
	dialog_warn \
		"\Zb\Z1\"${TXT_WEBSERVER_MAIN}\" $(gettext 'пока не поддерживается, помогите проекту, допишите данный функционал')\Zn"
	return 1
}

webserver_nginx()
{
	#community
	pacman_install "-S nginx"

	git_commit

	cp -Pb "${DBDIR}modules/etc/nginx/nginx.conf" "${NS_PATH}/etc/nginx/nginx.conf"
	cp -Pb "${DBDIR}modules/etc/nginx/mime.types" "${NS_PATH}/etc/nginx/mime.types"
	cp -Pb "${DBDIR}modules/etc/nginx/uwsgi_params" "${NS_PATH}/etc/nginx/uwsgi_params"
	cat "${DBDIR}modules/etc/nginx/proxy.conf" > "${NS_PATH}/etc/nginx/proxy.conf"

	mkdir -p "${NS_PATH}"/etc/nginx/{sites-available,sites-enabled,templates}

	cp -Pb "${DBDIR}"modules/etc/nginx/templates/* "${NS_PATH}"/etc/nginx/templates/
	cp -Pb "${DBDIR}"modules/etc/nginx/sites-available/* "${NS_PATH}"/etc/nginx/sites-available/

	ln -srf "${NS_PATH}/etc/nginx/sites-available/localhost.conf" "${NS_PATH}/etc/nginx/sites-enabled/localhost.conf"

	mkdir -p "${NS_PATH}"/srv/http/nginx/{public,private,logs,backup}
	cp -Pb "${NS_PATH}"/usr/share/html/* "${NS_PATH}"/srv/http/nginx/public/

	echo '<?php' > "${NS_PATH}"/srv/http/nginx/public/index.php
	echo 'phpinfo();' >> "${NS_PATH}"/srv/http/nginx/public/index.php

	ln -sr "${NS_PATH}/usr/share/webapps/phpMyAdmin" "${NS_PATH}/srv/http/nginx/public/phpmyadmin"
	ln -sr "${NS_PATH}/usr/share/webapps/phppgadmin" "${NS_PATH}/srv/http/nginx/public/phppgadmin"

	chroot_run systemctl enable nginx.service

	git_commit

#	SET_USER_GRUPS+=',http' # System group
}

webserver_php()
{
	#extra
	pacman_install "-S php"
	pacman_install "-S php-sqlite"
	pacman_install "-S php-apc"
	pacman_install "-S php-gd"
	pacman_install "-S php-mcrypt"
	pacman_install "-S php-pear"
	pacman_install "-S php-pspell"
	pacman_install "-S php-snmp"
	pacman_install "-S php-tidy"
	pacman_install "-S php-xsl"
	pacman_install "-S php-intl"
	pacman_install "-S php-fpm"
#	pacman_install "-S php-apache"

	git_commit

	cp -Pb "${DBDIR}modules/etc/php/php.ini" "${NS_PATH}/etc/php/php.ini"

	chroot_run systemctl enable php-fpm.service

	git_commit
}

webserver_mariadb()
{
	#extra
	pacman_install "-S mariadb"
	#community
	pacman_install "-S phpmyadmin"

	git_commit

	chroot_run systemctl enable mysqld.service

	git_commit
# Поменять в /etc/webapps/phpmyadmin/config.inc.php
# $cfg['Servers'][$i]['AllowNoPassword'] = false;
# $cfg['Servers'][$i]['AllowNoPassword'] = true;
}

webserver_postgresql()
{
	#extra
	pacman_install "-S php-pgsql"
	#community
	pacman_install "-S postgresql"
	pacman_install "-S pgadmin3"
#	pacman_install "-S phppgadmin"

	git_commit

	mkdir -p "${NS_PATH}"/var/lib/postgres/data
	chroot_run chown -Rh -c postgres:postgres /var/lib/postgres/data
	chroot_run "bash -c \"su postgres -c 'initdb --locale en_US.UTF-8 -D /var/lib/postgres/data && exit'\""

	chroot_run systemctl enable postgresql.service

	git_commit

# su root
# su - postgres
# createuser -DRSP <username>
# -D Пользователь не может создавать базы данных
# -R Пользователь не может создавать аккаунты
# -S Пользователь не является суперпользователем
# -P Запрашивать пароль при создании
# createdb -O username databasename [-E database_encoding]
}

webserver_apache()
{
	#extra
	pacman_install "-S apache"

	git_commit

	mkdir -p "${NS_PATH}"/etc/httpd/conf/{sites-available,sites-enabled}

	git_commit

#	SET_USER_GRUPS+=',http' # System group
}
