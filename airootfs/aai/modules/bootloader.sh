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
MAIN_CASE+=('bootloader')

#===============================================================================
# Сигнальная переменная успешного завершения функции модуля,
# может потребоваться для других модулей, для установки кода завершения
RUN_BOOTLOADER=
TXT_BOOTLOADER_MAIN="$(gettext 'Загрузчик')"

# Выбранный загрузчик
SET_BOOTLOADER=
# Разрешение в консоли по умолчанию
DEF_CONSOLE_V_XxYxD='0x0317_1024x768x16'
#===============================================================================

# Выводим строку пункта главного меню
str_bootloader()
{
	local TEMP="\Zb\Z3($(gettext 'Рекомендуется'))\Zn"

	[[ "${RUN_BOOTLOADER}" ]] && TEMP="\Zb\Z2($(gettext 'ВЫПОЛНЕНО'))\Zn"
	echo "${TXT_BOOTLOADER_MAIN} (~45M) ${TEMP}"
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

	local DEF_MENU=

	while true
	do
		DEF_MENU="$(bootloader_dialog_menu)"
		case "${DEF_MENU}" in
			'none')
				set_global_var 'SET_BOOTLOADER' ''
				RUN_BOOTLOADER=1
				return 0
				;;
			'grub')
				bootloader_grub || continue
				set_global_var 'SET_BOOTLOADER' "${DEF_MENU}"
				RUN_BOOTLOADER=1
				return 0
				;;
			'syslinux')
				bootloader_syslinux || continue
				set_global_var 'SET_BOOTLOADER' "${DEF_MENU}"
				RUN_BOOTLOADER=1
				return 0
				;;
 			'lilo')
 				bootloader_lilo || continue
				set_global_var 'SET_BOOTLOADER' "${DEF_MENU}"
				RUN_BOOTLOADER=1
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

	local TITLE="${TXT_BOOTLOADER_MAIN}"
	local HELP_TXT="\n$(gettext 'Выберите загрузчик')\n"
	HELP_TXT+="$(gettext 'По умолчанию'):"

	local DEFAULT_ITEM='grub'

	local ITEMS= # "'none' '$(gettext 'Не устанавливать загрузчик')'"
	ITEMS+=" 'grub' 'GRUB ${BIOS_SYS}'"
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
#	HELP_TXT+=" \Zb\Z3($(gettext 'Некоторые разрешения могут не поддерживаться !!!'))\Zn\n"
	HELP_TXT+="$(gettext 'По умолчанию'):"

	local DEFAULT_ITEM="${DEF_CONSOLE_V_XxYxD}"
	local ITEMS="$(hwinfo --vbe | grep ' Mode ' |  awk -F ' ' '{print sq $2 "_" $3 "x" $5 sq " " sq $0 sq}' sq=\' | sed 's/:_/_/g')"
	[[ ! -n "${ITEMS}" ]] && ITEMS="
'0x0301_640x480x8' '-' '0x0303_800x600x8' '-' '0x0305_1024x768x8' '-' '0x0307_1280x1024x8' '-'
'0x0311_640x480x16' '-' '0x0314_800x600x16' '-' '0x0317_1024x768x16' '-' '0x031A_1280x1024x16' '-'
'0x0312_640x480x24' '-' '0x0315_800x600x24' '-' '0x0318_1024x768x24' '-' '0x031B_1280x1024x24' '-'
"
	HELP_TXT+=" \Zb\Z7\"${DEFAULT_ITEM}\"\Zn\n"

	RETURN="$(dialog_menu "${TITLE}" "${DEFAULT_ITEM}" "${HELP_TXT}" "${ITEMS}")"

	echo "${RETURN}"
	msg_log "$(gettext 'Выход из диалога'): \"${FUNCNAME} return='${RETURN}'\"" 'noecho'
}

bootloader_dev_part()
{
	local NAME

	lsblk -nro NAME | tr ' ' '\r' |
	while IFS=$'\r' read -r NAME
	do
		local PART_INFO="$(get_part_info "/dev/${NAME}")"

		local ID_PART_ENTRY_TYPE="$(get_part_param 'ID_PART_ENTRY_TYPE' <<< "${PART_INFO}")"
		local ID_TYPE="$(get_part_param 'ID_TYPE' <<< "${PART_INFO}")"

		if [[ "${ID_TYPE}" == 'disk' ]] && [[ "${ID_PART_ENTRY_TYPE}" != "0x82" ]] && [[ "${ID_PART_ENTRY_TYPE}" != "0x5" ]]
		then
			local DEVNAME="$(get_part_param 'DEVNAME' <<< "${PART_INFO}")"

			local PART_TABLE_TYPE_NAME="$(get_part_param 'PART_TABLE_TYPE_NAME' <<< "${PART_INFO}")"
			local SIZE="$(get_part_param 'SIZE' <<< "${PART_INFO}")"

			local ID_FS_TYPE="$(get_part_param 'ID_FS_TYPE' <<< "${PART_INFO}")"
			local ID_FS_LABEL="$(get_part_param 'ID_FS_LABEL' <<< "${PART_INFO}")"

			local BOOT_BIOS="$(get_part_param 'BOOT_BIOS' <<< "${PART_INFO}")"
			local BOOT_EFI="$(get_part_param 'BOOT_EFI' <<< "${PART_INFO}")"

			echo -e "'${DEVNAME}' '${BOOT_BIOS}${BOOT_EFI} \"${PART_TABLE_TYPE_NAME}\" ${SIZE} ${ID_FS_TYPE} \"${ID_FS_LABEL}\"'"
		fi
	done
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

	local ITEMS="$(bootloader_dev_part)"

	if [[ ! -n "${ITEMS}" ]]
	then
		dialog_warn \
			"\Zb\Z1$(gettext 'Разделы не найдены!!!')\Zn"
		return 1
	fi

	HELP_TXT+=" \Zb\Z7\"${DEFAULT_ITEM}\"\Zn\n"

	RETURN="$(dialog_menu "${TITLE}" "${DEFAULT_ITEM}" "${HELP_TXT}" "${ITEMS}")"

	echo "${RETURN}"
	msg_log "$(gettext 'Выход из диалога'): \"${FUNCNAME} return='${RETURN}'\"" 'noecho'
}

bootloader_grub()
{
	local CONSOLE_V_XxYxD
	local PART
	local FILE_TXT

	local TEMP
	local TEMP1
#===============================================================================
# Устанавливаем grub
#===============================================================================
	#core
	pacman_install '-S grub'
	pacman_install '-S efibootmgr'
	#extra
	pacman_install '-S memtest86+'
	#community
	pacman_install '-S os-prober'

	git_commit

# @todo Закомментировано потому что темы могут не поддерживать выбранные режимы
	TEMP="$(bootloader_dialog_console)"
	[[ ! -n "${TEMP}" ]] && return 1
	CONSOLE_V_XxYxD="${TEMP}"
#	CONSOLE_V_XxYxD="${DEF_CONSOLE_V_XxYxD}"

	PART="$(bootloader_dialog_dev_part)"
	[[ ! -n "${PART}" ]] && return 1


#	local TARGET='i386-pc'
#	if [[ "${BIOS_SYS}" == 'EFI' ]]
#	then
#		TARGET='i386-efi'
#		[[ "${UNAME}" == 'x86_64' ]] && TARGET='x86_64-efi'
#	fi

#	chroot_run grub-install --target="${TARGET}" --force "${PART}"
	chroot_run grub-install --force "${PART}"
	if [[ "${?}" != '0' ]]
	then
		dialog_warn \
			"\Zb\Z1$(gettext 'Из за возникших ошибок GRUB BIOS не был установлен на раздел')\Zn\n${PART}"
		return 1
	fi

	if [[ "${BIOS_SYS}" == 'EFI' ]]
	then
		mkdir -p "${NS_PATH}/boot/efi/EFI/boot"
		TARGET='ia32'
		[[ "${UNAME}" == 'x86_64' ]] && TARGET='x64'
		cp -b "${NS_PATH}/boot/efi/EFI/arch/grub${TARGET}.efi" "${NS_PATH}/boot/efi/EFI/boot/boot${TARGET}.efi"
	fi

	mkdir -p "${NS_PATH}/boot/grub/locale"
	cp "${NS_PATH}/usr/share/locale/en@quot/LC_MESSAGES/grub.mo" "${NS_PATH}/boot/grub/locale/en.mo"

# Добавляем параметр resume если выбран свап
	if [[ -n "${SET_DEV_SWAP[0]}" ]]
	then
		FILE_TXT='GRUB_CMDLINE_LINUX+=\"'
		FILE_TXT+=" resume=UUID=${SET_DEV_SWAP[3]}"
		[[ "${SET_DEV_SWAP[0]}" == "${SWAPFILE}" ]] && FILE_TXT+=" resume_offset=${SET_DEV_SWAP[2]}"
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
/^GRUB_CMDLINE_LINUX+=\" *nomodeset/s/^/#/;
0,/^GRUB_CMDLINE_LINUX=/{
//{
  a GRUB_CMDLINE_LINUX+=\" nomodeset\"
};
};
# Добавляем параметр zswap.enabled=1
/^GRUB_CMDLINE_LINUX+=\" *zswap/s/^/#/;
0,/^GRUB_CMDLINE_LINUX=/{
//{
	a GRUB_CMDLINE_LINUX+=\" zswap.enabled=1\"
};
};
# Добавляем параметр video и vga
# /^GRUB_CMDLINE_LINUX+=\" *video/s/^/#/;
# 0,/^GRUB_CMDLINE_LINUX=/{
# //{
# 	a GRUB_CMDLINE_LINUX+=\" video=${TEMP}-${TEMP1} vga=${CONSOLE_V_XxYxD%_*}\"
# };
# };
# Добавляем параметр acpi_backlight
/^GRUB_CMDLINE_LINUX+=\" *acpi_backlight/s/^/#/;
0,/^GRUB_CMDLINE_LINUX=/{
//{
	a GRUB_CMDLINE_LINUX+=\" acpi_backlight=vendor acpi_osi=Linux\"
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

	git_commit

# исправляет ошибку в грубе
#echo 'GRUB_DISABLE_SUBMENU=y' >> "${NS_PATH}/etc/default/grub"

#echo "vga=${CONSOLE_V_XxYxD%_*}"
	if [[ "${RUN_BASE_PLUS}" ]]
	then
		msg_log "$(gettext 'Настраиваю') /usr/local/bin/update-grub"
		mkdir -p "${NS_PATH}/usr/local/bin"
		cat "${DBDIR}modules/usr/local/bin/update-grub" > "${NS_PATH}/usr/local/bin/update-grub"
		chmod +x "${NS_PATH}/usr/local/bin/update-grub"

		git_commit

		dialog_yesno \
			"${TXT_BOOTLOADER_MAIN}" \
			"$(gettext 'Установить тему для grub?')"

		case "${?}" in
			'0') #Yes
				#aur
				pacman_install '-S grub2-theme-archxion' 'yaourt'

				git_commit

#				cp -Pbr "${NS_PATH}/usr/share/grub/themes/Archxion" "${NS_PATH}/boot/grub/themes/Archxion"
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

				git_commit
				;;
		esac

	fi

	msg_info "$(gettext 'Пожалуйста, подождите')..."
	chroot_run grub-mkconfig -o /boot/grub/grub.cfg

	git_commit

	return 0
#-------------------------------------------------------------------------------
}

# Устанавливаем syslinux
bootloader_syslinux()
{
	local CONSOLE_V_XxYxD

	dialog_warn \
		"\Zb\Z1\"SYSLINUX\" $(gettext 'пока не поддерживается, помогите проекту, допишите данный функционал')\Zn"
	return 1

# @todo Закомментировано потому что темы могут не поддерживать выбранные режимы
#  TEMP="$(bootloader_dialog_console)"
#  [[ ! -n "${TEMP}" ]] && return 1
#  CONSOLE_V_XxYxD="${TEMP}"
	CONSOLE_V_XxYxD="${DEF_CONSOLE_V_XxYxD}"

	#core
	pacman_install '-S syslinux'
	#extra
	pacman_install '-S mksyslinux'

	git_commit

# Настраиваем syslinux
#  "${NS_PATH}/boot/syslinux/syslinux.cfg"
#  chroot_run syslinux-install_update -i -a -m
}

# Устанавливаем lilo
bootloader_lilo()
{
	local CONSOLE_V_XxYxD

	dialog_warn \
		"\Zb\Z1\"LILO\" $(gettext 'пока не поддерживается, помогите проекту, допишите данный функционал')\Zn"
	return 1

# @todo Закомментировано потому что темы могут не поддерживать выбранные режимы
#  TEMP="$(bootloader_dialog_console)"
#  [[ ! -n "${TEMP}" ]] && return 1
#  CONSOLE_V_XxYxD="${TEMP}"
	CONSOLE_V_XxYxD="${DEF_CONSOLE_V_XxYxD}"

	#core
	pacman_install '-S lilo'

	git_commit

# Настраиваем lilo
#  "${NS_PATH}/etc/lilo.conf"
#  chroot_run lilo
}
