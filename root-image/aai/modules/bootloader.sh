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
MAIN_CASE+=('bootloader')

#===============================================================================
# Сигнальная переменная успешного завершения функции модуля,
# может потребоваться для других модулей, для установки кода завершения
RUN_BOOTLOADER=
TXT_BOOTLOADER_MAIN="$(gettext 'Загрузчик')"

# Выбранный загрузчик
SET_BOOTLOADER=
# Разрешение в консоли по умолчанию
DEF_CONSOLE_V_XxYxD='0x317_1024x768x16'
#===============================================================================

# Выводим строку пункта главного меню
str_bootloader()
{
	local TEMP="\Zb\Z1($(gettext 'ОБЯЗАТЕЛЬНО!!!'))\Zn"

	[[ "${RUN_BOOTLOADER}" ]] && TEMP="\Zb\Z2($(gettext 'ВЫПОЛНЕНО'))\Zn"
	echo "${TXT_BOOTLOADER_MAIN} ${TEMP}"
}

# Функция выполнения из главного меню
run_bootloader()
{
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

		if [[ "${SET_BOOTLOADER}" ]]
		then
			dialog_warn \
				"\Zb\Z1$(gettext 'Пункт') \"${TXT_BOOTLOADER_MAIN}\" $(gettext 'уже выполнен')\Zn \Zb\Z2\"${SET_BOOTLOADER}\"\Zn"
			return 1
		fi

# Проверяем выполнен ли base_plus
		if [[ "${NO_MINI}" ]] && [[ ! "${RUN_BASE_PLUS}" ]]
		then
			dialog_warn \
				"\Zb\Z1$(gettext 'Пункт') \"${TXT_BASE_PLUS_MAIN}\" $(gettext 'не выполнен')\Zn\n$(gettext 'Тема загрузчика не будет установлена')"
		fi
	fi

	local DEF_MENU='grub_bios'

	while true
	do
		DEF_MENU="$(bootloader_dialog_menu "${DEF_MENU}")"
		case "${DEF_MENU}" in
			'none')
				set_global_var 'SET_BOOTLOADER' ''
				RUN_BOOTLOADER=1
				return 0
				;;
			'grub_bios')
				bootloader_grub_bios || continue
				set_global_var 'SET_BOOTLOADER' "${DEF_MENU}"
				RUN_BOOTLOADER=1
				return 0
				;;
			'grub_efi')
				bootloader_grub_efi || continue
#	set_global_var 'SET_BOOTLOADER' "${DEF_MENU}"
#	RUN_BOOTLOADER=1
				return 0
				;;
			'syslinux')
				bootloader_syslinux || continue
#	set_global_var 'SET_BOOTLOADER' "${DEF_MENU}"
#	RUN_BOOTLOADER=1
				return 0
				;;
			'lilo')
				bootloader_lilo || continue
#	set_global_var 'SET_BOOTLOADER' "${DEF_MENU}"
#	RUN_BOOTLOADER=1
				return 0
				;;
			*)
				return 1
				;;
		esac
	done
}

bootloader_dialog_menu()
{
	msg_log "$(gettext 'Запуск диалога'): \"${FUNCNAME}$(for ((TEMP=1; TEMP<=${#}; TEMP++)); do echo -n " \$${TEMP}='$(eval "echo \"\${${TEMP}}\"")'"; done)\"" 'noecho'

	local RETURN

	local P_DEF_MENU="${1}"

	local TITLE="${TXT_BOOTLOADER_MAIN}"
	local HELP_TXT="\n$(gettext 'Выберите загрузчик')\n"
	HELP_TXT+="$(gettext 'По умолчанию'):"

	local DEFAULT_ITEM="${P_DEF_MENU}"
#  local ITEMS="'none' '$(gettext 'Не устанавливать загрузчик')'"
	local ITEMS="'grub_bios' 'GRUB BIOS'"
	ITEMS+=" 'grub_efi' 'GRUB EFI \Zb\Z3($(gettext 'Пока не поддерживается'))\Zn'"
	ITEMS+=" 'syslinux' 'SYSLINUX \Zb\Z3($(gettext 'Пока не поддерживается'))\Zn'"
	ITEMS+=" 'lilo' 'LILO \Zb\Z3($(gettext 'Пока не поддерживается'))\Zn'"

	HELP_TXT+=" \Zb\Z7\"${DEFAULT_ITEM}\"\Zn\n"

	RETURN="$(dialog_menu "${TITLE}" "${DEFAULT_ITEM}" "${HELP_TXT}" "${ITEMS}" "--cancel-label '${TXT_MAIN_MENU}'")"

	echo "${RETURN}"
	msg_log "$(gettext 'Выход из диалога'): \"${FUNCNAME} return='${RETURN}'\"" 'noecho'
}

bootloader_dialog_console()
{
	msg_log "$(gettext 'Запуск диалога'): \"${FUNCNAME}$(for ((TEMP=1; TEMP<=${#}; TEMP++)); do echo -n " \$${TEMP}='$(eval "echo \"\${${TEMP}}\"")'"; done)\"" 'noecho'

	local RETURN

	local TITLE="${TXT_BOOTLOADER_MAIN}"
	local HELP_TXT="\n$(gettext 'Выберите разрешение экрана для консоли')\n"
	HELP_TXT+="$(gettext 'По умолчанию'):"

	local DEFAULT_ITEM="${DEF_CONSOLE_V_XxYxD}"
#  local ITEMS="$(hwinfo --vbe | grep ' Mode ' |  awk -F ' ' '{print sq $2 "_" $3 "x" $5 sq " " sq $0 sq}' sq=\' | sed 's/:_/_/g')"
	local ITEMS="
'0x301_640x480x8' '-' '0x303_800x600x8' '-' '0x305_1024x768x8' '-' '0x307_1280x1024x8' '-'
'0x311_640x480x16' '-' '0x314_800x600x16' '-' '0x317_1024x768x16' '-' '0x31A_1280x1024x16' '-'
'0x312_640x480x24' '-' '0x315_800x600x24' '-' '0x318_1024x768x24' '-' '0x31B_1280x1024x24' '-'
"
	HELP_TXT+=" \Zb\Z7\"${DEFAULT_ITEM}\"\Zn\n"

	RETURN="$(dialog_menu "${TITLE}" "${DEFAULT_ITEM}" "${HELP_TXT}" "${ITEMS}")"

	echo "${RETURN}"
	msg_log "$(gettext 'Выход из диалога'): \"${FUNCNAME} return='${RETURN}'\"" 'noecho'
}

bootloader_dialog_dev_part()
{
	msg_log "$(gettext 'Запуск диалога'): \"${FUNCNAME}$(for ((TEMP=1; TEMP<=${#}; TEMP++)); do echo -n " \$${TEMP}='$(eval "echo \"\${${TEMP}}\"")'"; done)\"" 'noecho'

	local RETURN

	local TITLE="${TXT_BOOTLOADER_MAIN}"
	local HELP_TXT="$(gettext 'Символом * помечены загрузочные разделы')\n"
	HELP_TXT+="\n$(gettext 'Выберите раздел для установки загрузчика')\n"
	HELP_TXT+="$(gettext 'По умолчанию'):"

	local DEV="${SET_DEV_BOOT[0]}"
	[[ ! -n "${DEV}" ]] && DEV="${SET_DEV_ROOT[0]}"

	local DEFAULT_ITEM="${DEV:0:8}"

	local ITEMS="$(get_parts | sed '1,1d' | awk '
$1 ~ /\/dev\/[hs]d[a-z]/{
if ($7 != "0x82" && $7 != "0x5")
	print sq $1 sq " " sq $2 " " $6 "\t" $4 " " $5 "\t" $8 sq
}' sq=\')"

	if [[ ! -n "${ITEMS}" ]]
	then
		dialog_warn \
			"\Zb\Z1$(gettext 'Разделов не найдено!!!')\Zn"
		return 1
	fi

	HELP_TXT+=" \Zb\Z7\"${DEFAULT_ITEM}\"\Zn\n"

	RETURN="$(dialog_menu "${TITLE}" "${DEFAULT_ITEM}" "${HELP_TXT}" "${ITEMS}")"

	echo "${RETURN}"
	msg_log "$(gettext 'Выход из диалога'): \"${FUNCNAME} return='${RETURN}'\"" 'noecho'
}

bootloader_grub_bios()
{
	local CONSOLE_V_XxYxD
	local PART
	local PACS
	local FILE_TXT

	local TEMP
	local TEMP1
#===============================================================================
# Устанавливаем grub
#===============================================================================
	#core
	PACS='grub'
	#extra
	PACS+=' memtest86+'
	#community
	PACS+=' os-prober'
	pacman_install "-S ${PACS}" '1'
	git_commit

	while true
	do
		PART="$(bootloader_dialog_dev_part)"
		[[ ! -n "${PART}" ]] && return 1

		chroot_run grub-install --force "${PART}"

		if [[ "${?}" != '0' ]]
		then
			dialog_warn \
				"\Zb\Z1$(gettext 'Grub не установлен на раздел')\Zn\n${PART}"
			continue
		fi

		mkdir -p "${NS_PATH}/boot/grub/locale"
		cp "${NS_PATH}/usr/share/locale/en@quot/LC_MESSAGES/grub.mo" "${NS_PATH}/boot/grub/locale/en.mo"

		break
	done

# @todo Закомментировано потому что темы могут не поддерживать выбранные режимы
#  TEMP="$(bootloader_dialog_console)"
#  [[ ! -n "${TEMP}" ]] && return 1
#  CONSOLE_V_XxYxD="${TEMP}"
	CONSOLE_V_XxYxD="${DEF_CONSOLE_V_XxYxD}"

# Добавляем параметр resume если выбран свап
	if [[ "${SET_DEV_SWAP[0]}" ]]
	then
		FILE_TXT='GRUB_CMDLINE_LINUX+=\" '
		if [[ "$(grep '^/dev/' <<< "${SET_DEV_SWAP[0]}")" ]]
		then
			FILE_TXT+="resume=UUID=$(blkid -c /dev/null "${SET_DEV_SWAP[0]}" | grep ' UUID="' | sed -r 's/.* UUID="//; s/" .*//')"
		else
			TEMP="$(filefrag -v "${NS_PATH}${SET_DEV_SWAP[0]}" | sed -n '4p' | awk '{print $3}')"
			FILE_TXT+="resume=UUID=$(blkid -c /dev/null "${SET_DEV_ROOT[0]}" | grep ' UUID="' | sed -r 's/.* UUID="//; s/" .*//') "
			FILE_TXT+="resume_offset=${TEMP/:/}"
		fi
		FILE_TXT+='\"'
	fi
#fastboot splash=verbose
	msg_log "$(gettext 'Настраиваю') /etc/default/grub"
	TEMP="${CONSOLE_V_XxYxD#*_}"
	TEMP1="${TEMP#*x}"
	TEMP1="${TEMP1#*x}"
	TEMP="${TEMP%x*}"
#Настройка яркости экрана : GRUB_CMDLINE_LINUX_DEFAULT=acpi_backlight=vendor
	sed -i "
# Добавляем параметр nomodeset
#/^GRUB_CMDLINE_LINUX+=\" *nomodeset/s/^/#/;
#0,/^GRUB_CMDLINE_LINUX=/{
#  //{
#    a GRUB_CMDLINE_LINUX+=\" nomodeset\"
#  };
#};
# Добавляем параметр zcache2
/^GRUB_CMDLINE_LINUX+=\" *zcache2/s/^/#/;
0,/^GRUB_CMDLINE_LINUX=/{
//{
	a GRUB_CMDLINE_LINUX+=\" zcache2\"
};
};
# Добавляем параметр video и vga
/^GRUB_CMDLINE_LINUX+=\" *video/s/^/#/;
0,/^GRUB_CMDLINE_LINUX=/{
//{
	a GRUB_CMDLINE_LINUX+=\" video=${TEMP}-${TEMP1} vga=${CONSOLE_V_XxYxD%_*} acpi_backlight=vendor\"
};
};
# Добавляем параметр resume
/^GRUB_CMDLINE_LINUX+=\" *resume/s/^/#/;
0,/^GRUB_CMDLINE_LINUX=/{
//{
	a ${FILE_TXT}
};
};
# Добавляем сохранение последнего выбора в меню
/^GRUB_DEFAULT=/s/^/#/;
0,/^#GRUB_DEFAULT=/{
//{
	a GRUB_DEFAULT=saved
};
};
/^GRUB_SAVEDEFAULT=/s/^/#/;
0,/^#GRUB_SAVEDEFAULT=/{
//{
	a GRUB_SAVEDEFAULT=\"true\"
};
};
# Добавляем разрешение консоли
/^GRUB_GFXMODE=/s/^/#/;
0,/^#GRUB_GFXMODE=/{
//{
	a GRUB_GFXMODE=${CONSOLE_V_XxYxD#*_}
};
};
" "${NS_PATH}/etc/default/grub"
#echo "vga=${CONSOLE_V_XxYxD%_*}"
	if [[ "${RUN_BASE_PLUS}" ]]
	then
		#aur
		PACS='grub2-theme-archxion'
		pacman_install "-S ${PACS}" '2'
		git_commit

#    cp -Pbr "${NS_PATH}/usr/share/grub/themes/Archxion" "${NS_PATH}/boot/grub/themes/Archxion"
		msg_log "$(gettext 'Настраиваю') /usr/local/bin/update-grub"
		mkdir -p "${NS_PATH}/usr/local/bin"
		cat "${DBDIR}modules/usr/local/bin/update-grub" > "${NS_PATH}/usr/local/bin/update-grub"
		chmod +x "${NS_PATH}/usr/local/bin/update-grub"

		msg_log "$(gettext 'Настраиваю') /etc/default/grub"
		sed -i "
# Добавляем скин
/^GRUB_THEME=/s/^/#/;
0,/^#GRUB_THEME=/{
//{
	a GRUB_THEME=\"/boot/grub/themes/Archxion/theme.txt\"
};
};
" "${NS_PATH}/etc/default/grub"
	fi

	msg_info "$(gettext 'Пожалуйста, подождите')..."
	chroot_run grub-mkconfig -o /boot/grub/grub.cfg
	git_commit
#-------------------------------------------------------------------------------
}

# Устанавливаем grub-efi
bootloader_grub_efi()
{
	local CONSOLE_V_XxYxD
	local PACS

	dialog_warn \
		"\Zb\Z1\"GRUB EFI\" $(gettext 'пока не поддерживается, помогите проекту, допишите данный функционал')\Zn"
	return 1


# @todo Закомментировано потому что темы могут не поддерживать выбранные режимы
#  TEMP="$(bootloader_dialog_console)"
#  [[ ! -n "${TEMP}" ]] && return 1
#  CONSOLE_V_XxYxD="${TEMP}"
	CONSOLE_V_XxYxD="${DEF_CONSOLE_V_XxYxD}"

	#core
	PACS='grub dosfstools efibootmgr gummiboot'
	#extra
	PACS+=' refind-efi prebootloader memtest86+'
	#community
	PACS+=' os-prober'
	pacman_install "-S ${PACS}" '1'
	git_commit

	if [[ "${RUN_BASE_PLUS}" ]]
	then
		#aur
		PACS='grub2-theme-archxion'
		pacman_install "-S ${PACS}" '2'
		git_commit

#    cp -Pbr "${NS_PATH}/usr/share/grub/themes/Archxion" "${NS_PATH}/boot/grub/themes/Archxion"
		msg_log "$(gettext 'Настраиваю') /usr/local/bin/update-grub"
		mkdir -p "${NS_PATH}/usr/local/bin"
		cat "${DBDIR}modules/usr/local/bin/update-grub" > "${NS_PATH}/usr/local/bin/update-grub"
		chmod +x "${NS_PATH}/usr/local/bin/update-grub"

# mkdir -p /boot/efi
# mount -t vfat /dev/sdXY /boot/efi
# modprobe dm-mod
# grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=arch_grub --recheck --debug
# mkdir -p /boot/grub/locale
# cp /usr/share/locale/en@quot/LC_MESSAGES/grub.mo /boot/grub/locale/en.mo

		msg_log "$(gettext 'Настраиваю') /etc/default/grub"
		sed -i "
# Добавляем скин
/^GRUB_THEME=/s/^/#/;
0,/^#GRUB_THEME=/{
//{
	a GRUB_THEME=\"/boot/grub/themes/Archxion/theme.txt\"
};
};
" "${NS_PATH}/etc/default/grub"
	fi

	msg_info "$(gettext 'Пожалуйста, подождите')..."
	chroot_run grub-mkconfig -o /boot/grub/grub.cfg
	git_commit
#-------------------------------------------------------------------------------
}

# Устанавливаем syslinux
bootloader_syslinux()
{
	local CONSOLE_V_XxYxD
	local PACS

	dialog_warn \
		"\Zb\Z1\"SYSLINUX\" $(gettext 'пока не поддерживается, помогите проекту, допишите данный функционал')\Zn"
	return 1

# @todo Закомментировано потому что темы могут не поддерживать выбранные режимы
#  TEMP="$(bootloader_dialog_console)"
#  [[ ! -n "${TEMP}" ]] && return 1
#  CONSOLE_V_XxYxD="${TEMP}"
	CONSOLE_V_XxYxD="${DEF_CONSOLE_V_XxYxD}"

	#core
	PACS='syslinux'
	#extra
	PACS+=' mksyslinux'
	pacman_install "-S ${PACS}" '1'
	git_commit

# Настраиваем syslinux
#  "${NS_PATH}/boot/syslinux/syslinux.cfg"
#  chroot_run syslinux-install_update -i -a -m
}

# Устанавливаем lilo
bootloader_lilo()
{
	local CONSOLE_V_XxYxD
	local PACS

	dialog_warn \
		"\Zb\Z1\"LILO\" $(gettext 'пока не поддерживается, помогите проекту, допишите данный функционал')\Zn"
	return 1

# @todo Закомментировано потому что темы могут не поддерживать выбранные режимы
#  TEMP="$(bootloader_dialog_console)"
#  [[ ! -n "${TEMP}" ]] && return 1
#  CONSOLE_V_XxYxD="${TEMP}"
	CONSOLE_V_XxYxD="${DEF_CONSOLE_V_XxYxD}"

	#core
	PACS='lilo'
	pacman_install "-S ${PACS}" '1'
	git_commit

# Настраиваем lilo
#  "${NS_PATH}/etc/lilo.conf"
#  chroot_run lilo
}
