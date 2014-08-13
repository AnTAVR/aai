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
MAIN_CASE+=('part')

#===============================================================================
# Сигнальная переменная успешного завершения функции модуля,
# может потребоваться для других модулей, для проверки зависимости
RUN_PART=
TXT_PART_MAIN="$(gettext 'Разделы')"

#  dev opt
SET_DEV_ROOT=('' "")
SET_DEV_BOOT=('' '')
SET_DEV_HOME=('' '')
SET_DEV_SWAP=('' '')
#===============================================================================

# Выводим строку пункта главного меню
str_part()
{
	local TEMP="\Zb\Z1($(gettext 'ОБЯЗАТЕЛЬНО!!!'))\Zn"

	[[ "${RUN_PART}" ]] && TEMP="\Zb\Z2($(gettext 'ВЫПОЛНЕНО'))\Zn"
	echo "${TXT_PART_MAIN} ${TEMP}"
}

# Функция выполнения из главного меню
run_part()
{
	local DEF_MENU='part'

	while true
	do
		DEF_MENU="$(part_dialog_def_menu "${DEF_MENU}")"
		case "${DEF_MENU}" in
			'part')
				part_part
				DEF_MENU='mount'
				;;
			'autopart')
				part_autopart || continue
				[[ "${RUN_PART}" ]] && return 0
				;;
			'raidlvm')
				part_raidlvm || continue
				DEF_MENU='mount'
				;;
			'mount')
				part_mount
				[[ "${RUN_PART}" ]] && return 0
				;;
			*)
				[[ "${RUN_PART}" ]] && return 0
				return 1
				;;
		esac
	done
}

part_dialog_def_menu()
{
	msg_log "$(gettext 'Запуск диалога'): \"${FUNCNAME}$(for ((TEMP=1; TEMP<=${#}; TEMP++)); do echo -n " \$${TEMP}='$(eval "echo \"\${${TEMP}}\"")'"; done)\"" 'noecho'

	local RETURN

	local P_DEF_MENU="${1}"

	local TEMP

	local TITLE="${TXT_PART_MAIN}"
	local HELP_TXT="\n$(gettext 'Выберите действие')\n"

	local DEFAULT_ITEM="${P_DEF_MENU}"
	local ITEMS="'autopart' '$(gettext 'Авто разметка и монтирование') \Zb\Z3($(gettext 'Пока не поддерживается'))\Zn'"
	ITEMS+=" 'raidlvm' '$(gettext 'RAID LVM') \Zb\Z3($(gettext 'Пока не поддерживается'))\Zn'"
	ITEMS+=" 'part' '$(gettext 'Разметка диска')'"

	TEMP="\Zb\Z1($(gettext 'ОБЯЗАТЕЛЬНО!!!'))\Zn"
	[[ "${RUN_PART}" ]] && TEMP="\Zb\Z2($(gettext 'ВЫПОЛНЕНО'))\Zn"

	ITEMS+=" 'mount' '$(gettext 'Монтирование разделов') ${TEMP}'"

	RETURN="$(dialog_menu "${TITLE}" "${DEFAULT_ITEM}" "${HELP_TXT}" "${ITEMS}" "--cancel-label '${TXT_MAIN_MENU}'")"

	echo "${RETURN}"
	msg_log "$(gettext 'Выход из диалога'): \"${FUNCNAME} return='${RETURN}'\"" 'noecho'
}

part_raidlvm()
{
	dialog_warn \
		"\Zb\Z1\"RAID LVM\" $(gettext 'пока не поддерживается, помогите проекту, допишите данный функционал')\Zn"
	return 1
}

part_autopart()
{
	dialog_warn \
		"\Zb\Z1\"$(gettext 'Авто разметка и монтирование')\" $(gettext 'пока не поддерживается, помогите проекту, допишите данный функционал')\Zn"
	return 1
}


# Функция разметки диска
part_part()
{
	local FDISK='fdisk'
	local DEV

	local TEMP

	while true
	do
		DEV="$(part_part_dialog_dev "${DEV}")"
		[[ ! -n "${DEV}" ]] && return 1

		TEMP="$(part_part_dialog_fdisk "${FDISK}")"
		[[ ! -n "${TEMP}" ]] && continue
		FDISK="${TEMP}"

		msg_log "${FDISK} ${DEV}"

		${FDISK} "${DEV}"
		partprobe "${DEV}"
	done
}

part_part_dialog_fdisk()
{
	msg_log "$(gettext 'Запуск диалога'): \"${FUNCNAME}$(for ((TEMP=1; TEMP<=${#}; TEMP++)); do echo -n " \$${TEMP}='$(eval "echo \"\${${TEMP}}\"")'"; done)\"" 'noecho'

	local P_FDISK="${1}"

	local TITLE="${TXT_PART_MAIN}"
	local HELP_TXT="\n$(gettext 'Выберите программу для разметки')\n"

	local DEFAULT_ITEM="${P_FDISK}"
	local ITEMS="'cfdisk' 'MBR'"
	ITEMS+=" 'fdisk' 'MBR & GPT \Zb\Z3($(gettext 'Рекомендуется'))\Zn'"
	ITEMS+=" 'sfdisk' 'MBR'"
	ITEMS+=" 'parted' '-'"
	ITEMS+=" 'cgdisk' 'GPT'"
	ITEMS+=" 'gdisk' 'GPT'"
	ITEMS+=" 'sgdisk' 'GPT'"

	RETURN="$(dialog_menu "${TITLE}" "${DEFAULT_ITEM}" "${HELP_TXT}" "${ITEMS}")"

	echo "${RETURN}"
	msg_log "$(gettext 'Выход из диалога'): \"${FUNCNAME} return='${RETURN}'\"" 'noecho'
}

part_part_dialog_dev()
{
	msg_log "$(gettext 'Запуск диалога'): \"${FUNCNAME}$(for ((TEMP=1; TEMP<=${#}; TEMP++)); do echo -n " \$${TEMP}='$(eval "echo \"\${${TEMP}}\"")'"; done)\"" 'noecho'

	local RETURN

	local P_DEV="${1}"

	local TITLE="${TXT_PART_MAIN}"
	local HELP_TXT="\Zb\Z7/boot\Zn - 32MB-500MB \Zb\Z6(100MB)\Zn, $(gettext 'код') \Zb\Z683 Linux\Zn \Zb\Z3($(gettext 'Рекомендуется'))\Zn\n"
	HELP_TXT+="  FLASH DRIVE \Zb\Z6(32MB)\Zn, $(gettext 'код') \Zb\Z607 HPFS/NTFS/exFAT\Zn | $(gettext 'код') \Zb\Z60B W95 FAT32\Zn\n"
	HELP_TXT+="  $(gettext 'Нужно сделать загрузочным!!!')\n"
	HELP_TXT+="\Zb\Z7/ (root)\Zn - 4GB-32GB \Zb\Z6(20GB)\Zn, $(gettext 'код') \Zb\Z683 Linux\Zn \Zb\Z1($(gettext 'ОБЯЗАТЕЛЬНО!!!'))\Zn\n"
	HELP_TXT+="\Zb\Z7/home\Zn - \Zb\Z6($(gettext 'все остальное место'))\Zn, $(gettext 'код') \Zb\Z683 Linux\Zn \Zb\Z3($(gettext 'Рекомендуется'))\Zn\n"
	HELP_TXT+="  $(gettext '10G на одного пользователя и 5G на бэкапы и кеш системы')\n"
	HELP_TXT+="  $(gettext 'Если установка на FLASH DRIVE, то можно не использовать отдельный раздел')\n"
	HELP_TXT+="\Zb\Z7swap\Zn - RAM*2 \Zb\Z6($(free -m | awk '/Mem:/{ print $2*2 }')MB)\Zn, $(gettext 'код') \Zb\Z682 Linux swap / Solaris\Zn\n"
	HELP_TXT+="  $(gettext 'Можно не создавать, а потом сделать swap в файл, если') \Zb\Z6/ (root) ext4\Zn\n"
	HELP_TXT+="\n$(gettext 'Выберите устройство для разметки')\n"

	local DEFAULT_ITEM="${P_DEV}"

	local NAME

	ITEMS="$(lsblk -nro NAME | tr ' ' '\r' |
	while IFS=$'\r' read -r NAME
	do
		local TEMP="$(get_part_info "/dev/${NAME}")"

		local DEVTYPE="$(get_part_param 'DEVTYPE' <<< "${TEMP}")"
		local ID_TYPE="$(get_part_param 'ID_TYPE' <<< "${TEMP}")"
		if [[ "${DEVTYPE}" == 'disk' ]] && [[ "${ID_TYPE}" == 'disk' ]]
		then
			local DEVNAME="$(get_part_param 'DEVNAME' <<< "${TEMP}")"
			local ID_BUS="$(get_part_param 'ID_BUS' <<< "${TEMP}")"
			local ID_PART_TABLE_TYPE="$(get_part_param 'ID_PART_TABLE_TYPE' <<< "${TEMP}")"
			local SIZE="$(get_part_param 'SIZE' <<< "${TEMP}")"
			local ID_SERIAL="$(get_part_param 'ID_SERIAL' <<< "${TEMP}")"

			echo -e "'${DEVNAME}' '${ID_BUS} ${ID_PART_TABLE_TYPE} ${SIZE} ${ID_SERIAL}'"
		fi
	done)"

	RETURN="$(dialog_menu "${TITLE}" "${DEFAULT_ITEM}" "${HELP_TXT}" "${ITEMS}" "--cancel-label '$(gettext 'Назад')'")"

	echo "${RETURN}"
	msg_log "$(gettext 'Выход из диалога'): \"${FUNCNAME} return='${RETURN}'\"" 'noecho'
}

# Функция монтирования разделов
part_mount()
{
	local POINT

	while true
	do
# Диалог выбора точки монтирования
		POINT="$(part_mount_dialog_point "${POINT}")"

		case "${POINT}" in
			'unmount')
				part_unmount
				continue
				;;
			'/ (root)')
				part_mount_root || continue
				;;
			'swap')
				part_mount_swap || continue
				;;
			'/boot')
				part_mount_boot || continue
				;;
			'/home')
				part_mount_home || continue
				;;
			*)
				return 1
				;;
		esac
	done
}

part_mount_dialog_point()
{
	msg_log "$(gettext 'Запуск диалога'): \"${FUNCNAME}$(for ((TEMP=1; TEMP<=${#}; TEMP++)); do echo -n " \$${TEMP}='$(eval "echo \"\${${TEMP}}\"")'"; done)\"" 'noecho'

	local RETURN

	local P_POINT="${1}"

	local TITLE="${TXT_PART_MAIN}"
	local HELP_TXT="\n$(gettext 'Выберите точку монтирования')\n"

	local DEFAULT_ITEM="${P_POINT}"
	local ITEMS="'unmount' '$(gettext 'Размонтировать')'"

	local TEMP

	TEMP="\Zb\Z1($(gettext 'ОБЯЗАТЕЛЬНО!!!'))\Zn"
	[[ -n "${SET_DEV_ROOT[0]}" ]] && TEMP="\Zb\Z2($(gettext 'ВЫПОЛНЕНО'))\Zn"
	ITEMS+=" '/ (root)' '\"${SET_DEV_ROOT[0]}\" \"$(mount | grep "^${SET_DEV_ROOT[0]} " | awk '{print $5}')\" ${TEMP}'"

	TEMP="\Zb\Z3($(gettext 'Рекомендуется'))\Zn"
	[[ -n "${SET_DEV_BOOT[0]}" ]] && TEMP="\Zb\Z2($(gettext 'ВЫПОЛНЕНО'))\Zn"
	ITEMS+=" '/boot' '\"${SET_DEV_BOOT[0]}\" \"$(mount | grep "^${SET_DEV_BOOT[0]} " | awk '{print $5}')\" ${TEMP}'"

	TEMP="\Zb\Z3($(gettext 'Рекомендуется'))\Zn"
	[[ -n "${SET_DEV_HOME[0]}" ]] && TEMP="\Zb\Z2($(gettext 'ВЫПОЛНЕНО'))\Zn"
	ITEMS+=" '/home' '\"${SET_DEV_HOME[0]}\" \"$(mount | grep "^${SET_DEV_HOME[0]} " | awk '{print $5}')\" ${TEMP}'"

	TEMP="\Zb\Z3($(gettext 'Рекомендуется'))\Zn"
	[[ -n "${SET_DEV_SWAP[0]}" ]] && TEMP="\Zb\Z2($(gettext 'ВЫПОЛНЕНО'))\Zn"
	ITEMS+=" 'swap' '\"${SET_DEV_SWAP[0]}\" \"$(swapon --show | grep "^${SET_DEV_SWAP[0]} " | awk '{print $2}')\" ${TEMP}'"

	RETURN="$(dialog_menu "${TITLE}" "${DEFAULT_ITEM}" "${HELP_TXT}" "${ITEMS}" "--cancel-label '${TXT_MAIN_MENU}'")"

	echo "${RETURN}"
	msg_log "$(gettext 'Выход из диалога'): \"${FUNCNAME} return='${RETURN}'\"" 'noecho'
}

part_mount_boot()
{
	local POINT='/boot'

	local PART
	local OPT

	local TEMP

	part_mount_test "${POINT}" 'SET_DEV_BOOT' || return 1

	PART="$(part_mount_dialog_dev_part "${POINT}")"
	[[ ! -n "${PART}" ]] && return 1

	dialog_yesno \
		"${TXT_PART_MAIN}" \
		"$(gettext 'Форматировать раздел')\n \Zb\Z6${PART}\Zn ?" \
		'--defaultno'

	case "${?}" in
		'0') #Yes
			part_format "${PART}" "${POINT}" || return 1
			;;
# 	'1') #No
# 	    ;;
		'255') #ESC
			return 1
			;;
	esac

	part_mount_test_fs "${PART}" || return 1

	TEMP="$(part_mount_dialog_dev_opt "${PART}" "${POINT}")"
	case "${?}" in
		'0') #Yes
			OPT="${TEMP}"
			;;
		'1') #No
			return 1
			;;
		'255') #ESC
			return 1
			;;
	esac

	SET_DEV_BOOT[0]="${PART}"
	SET_DEV_BOOT[1]="${OPT}"

	part_mount_all "${POINT}" 'SET_DEV_BOOT'
}


# Функция форматирования разделов
part_format()
{
	local P_PART="${1}"
	local P_POINT="${2}"

# Устанавливаем локальные переменные и их значения по умолчанию
	local MKF
	local MKF_OPT

	local TEMP

	while true
	do
		MKF="$(part_format_dialog_mkf "${P_PART}" "${P_POINT}")"
		[[ ! -n "${MKF}" ]] && return 1

		TEMP="$(part_format_dialog_mkf_opt "${MKF}" "${P_POINT}" "${P_PART}")"
		case "${?}" in
			'0') #Yes
				MKF_OPT="${TEMP}"
				;;
			'1') #No
				continue
				;;
			'255') #ESC
				return 1
				;;
		esac

# Проверяем правильность ввода параметров, если не правильно введено,
# то повторяем выбор, если отмена то выход
		dialog_yesno \
			"${TXT_PART_MAIN}" \
			"$(gettext 'Подтвердите свой выбор')\n\n
\Zb\Z7${MKF} ${MKF_OPT} ${P_PART}\Zn\n
\Zb\Z1$(gettext 'Изменение происходит сразу! Будьте внимательны!!!')\Zn" \
			'--defaultno'

		case "${?}" in
			'0') #Yes
				umount "${P_PART}" 2> /dev/null
				msg_log "${MKF} ${MKF_OPT} ${P_PART}"
				${MKF} ${MKF_OPT} "${P_PART}" 2>&1
				partprobe "${P_PART}"
				return 0
				;;
		esac
	done
}

part_format_dialog_mkf()
{
	msg_log "$(gettext 'Запуск диалога'): \"${FUNCNAME}$(for ((TEMP=1; TEMP<=${#}; TEMP++)); do echo -n " \$${TEMP}='$(eval "echo \"\${${TEMP}}\"")'"; done)\"" 'noecho'

	local RETURN

	local P_PART="${1}"
	local P_POINT="${2}"

	local TITLE="${TXT_PART_MAIN}"
	local HELP_TXT="$(gettext 'Точка монтирования'): \Zb\Z2\"${P_POINT}\"\Zn\n"
	HELP_TXT+="$(gettext 'Раздел'): \Zb\Z2\"${P_PART}\"\Zn\n"
	HELP_TXT+="\n$(gettext 'Выберите файловую систему')\n"
	HELP_TXT+="$(gettext 'По умолчанию'):"

	local DEFAULT_ITEM='mkfs.ext4'
#  local ITEMS="$(ls -1 '/usr/bin' '/sbin'| grep 'mkfs.' | sort -u | awk -F '.' '{print sq $0 sq " " sq "-" sq}' sq=\')"
	local ITEMS="'mkfs.ext4' '-'"
	ITEMS+=" 'mkfs.ext2' '-'"
	ITEMS+=" 'mkfs.ext3' '-'"
#  ITEMS+=" 'mkfs.ext4dev' '-'"
	ITEMS+=" 'mkfs.f2fs' '-'"
	ITEMS+=" 'mkfs.btrfs' '-'"
	ITEMS+=" 'mkfs.reiserfs' '-'"
	ITEMS+=" 'mkfs.jfs' '-'"
	ITEMS+=" 'mkfs.xfs' '-'"
	ITEMS+=" 'mkfs.nilfs2' '-'"
#  ITEMS+=" 'mkfs.ntfs' '-'"
#  ITEMS+=" 'mkfs.exfat' '-'"
	ITEMS+=" 'mkfs.vfat' '-'"
#  ITEMS+=" 'mkfs.msdos' '-'"
	ITEMS+=" 'mkswap' '-'"

	case "$(fdisk -l | awk "/^$(sed 's/\//\\\//g' <<< "${P_PART}")/ {if (\$2 == \"*\") { print \$6 } else { print \$5 }}")" in
		'7')
			DEFAULT_ITEM='mkfs.ntfs'
			is_ssd "${P_PART}" && DEFAULT_ITEM='mkfs.exfat'
			;;
		'b')
			DEFAULT_ITEM='mkfs.vfat'
			;;
		'83')
			DEFAULT_ITEM='mkfs.ext4'
			;;
		'82')
			DEFAULT_ITEM='mkswap'
			;;
	esac

	HELP_TXT+=" \Zb\Z7\"${DEFAULT_ITEM}\"\Zn\n"

	RETURN="$(dialog_menu "${TITLE}" "${DEFAULT_ITEM}" "${HELP_TXT}" "${ITEMS}")"

	echo "${RETURN}"
	msg_log "$(gettext 'Выход из диалога'): \"${FUNCNAME} return='${RETURN}'\"" 'noecho'
}

part_format_dialog_mkf_opt()
{
	msg_log "$(gettext 'Запуск диалога'): \"${FUNCNAME}$(for ((TEMP=1; TEMP<=${#}; TEMP++)); do echo -n " \$${TEMP}='$(eval "echo \"\${${TEMP}}\"")'"; done)\"" 'noecho'

	local RETURN

	local P_MKF="${1}"
	local P_POINT="${2}"
	local P_PART="${3}"

	local TITLE="${TXT_PART_MAIN}"
	local HELP_TXT="$(gettext 'Точка монтирования'): \Zb\Z2\"${P_POINT}\"\Zn\n"
	HELP_TXT+="$(gettext 'Раздел'): \Zb\Z2\"${P_PART}\"\Zn\n"
	HELP_TXT+="$(gettext 'Файловая система'): \Zb\Z2\"${P_MKF}\"\Zn\n"
	HELP_TXT+="\n$(gettext 'Введите дополнительные опции форматирования')\n"
	HELP_TXT+="$(gettext 'По умолчанию'):"

	local TEXT

	local FLASH
	is_ssd "${P_PART}" && FLASH='Flash'

	local LABEL
	case "${P_POINT}" in
		'/ (root)')
			LABEL="${FLASH}Root"
			;;
		'/boot')
			LABEL="${FLASH}Boot"
			;;
		'/home')
			LABEL="${FLASH}Home"
			;;
		'swap')
			LABEL="${FLASH}Swap"
			;;
	esac

	case "${P_MKF}" in
		'mkfs.ntfs')
			TEXT="-C -L ${LABEL}"
			;;
		'mkfs.exfat' | 'mkfs.vfat' | 'mkfs.msdos')
			TEXT="-n ${LABEL}"
			;;
		'mkfs.reiserfs' | 'mkfs.f2fs')
			TEXT="-l ${LABEL}"
			;;
		'mkfs.ext4' | 'mkfs.ext4dev')
			[[ "${FLASH}" ]] && FLASH=' -E discard'
			case "${P_POINT}" in
				'/ (root)')
					TEXT="-m 1 -L ${LABEL}${FLASH}"
					;;
				'/home')
					TEXT="-m 0 -L ${LABEL}${FLASH}"
					;;
				'/boot')
					TEXT="-m 0 -O ^has_journal -L ${LABEL}${FLASH}"
					;;
			esac
			;;
		'mkfs.btrfs' | 'mkfs.xfs')
			TEXT="-f -L ${LABEL}"
			;;
		'mkswap' | 'mkfs.ext2' | 'mkfs.ext3' | 'mkfs.jfs' | 'mkfs.nilfs2')
			TEXT="-L ${LABEL}"
			;;
	esac

	HELP_TXT+=" \Zb\Z7\"${TEXT}\"\Zn\n"
#  HELP_TXT+="\n$(sed ':a; /$/N; s/\n/\\n/; ta' <<< "$(${P_MKF} 2>&1)" | sed "s/'/\"/" | sed '/^$/d')\n"

	RETURN="$(dialog_inputbox "${TITLE}" "${HELP_TXT}" "${TEXT}")"

	echo "${RETURN}"
	msg_log "$(gettext 'Выход из диалога'): \"${FUNCNAME} return='${RETURN}'\"" 'noecho'
}

part_mount_home()
{
	local POINT='/home'

	local PART
	local OPT

	local TEMP

	part_mount_test "${POINT}" 'SET_DEV_HOME' || return 1

	PART="$(part_mount_dialog_dev_part "${POINT}")"
	[[ ! -n "${PART}" ]] && return 1

	dialog_yesno \
		"${TXT_PART_MAIN}" \
		"$(gettext 'Форматировать раздел')\n \Zb\Z6${PART}\Zn ?" \
		'--defaultno'

	case "${?}" in
		'0') #Yes
			part_format "${PART}" "${POINT}" || return 1
			;;
#    '1') #No
#      ;;
		'255') #ESC
			return 1
			;;
	esac

	part_mount_test_fs "${PART}" || return 1

	TEMP="$(part_mount_dialog_dev_opt "${PART}" "${POINT}")"
	case "${?}" in
		'0') #Yes
			OPT="${TEMP}"
			;;
		'1') #No
			return 1
			;;
		'255') #ESC
			return 1
			;;
	esac

	SET_DEV_HOME[0]="${PART}"
	SET_DEV_HOME[1]="${OPT}"

	part_mount_all "${POINT}" 'SET_DEV_HOME'
}

part_mount_root()
{
	local POINT='/ (root)'
	local PART
	local OPT

	local TEMP

	if [[ -n "${SET_DEV_ROOT[0]}" ]]
	then
		dialog_warn \
			"\Zb\Z1$(gettext 'Раздел для') \"${POINT}\" $(gettext 'уже выбран и премонтирован!!!')\Zn"
		return 1
	fi

	PART="$(part_mount_dialog_dev_part "${POINT}")"
	[[ ! -n "${PART}" ]] && return 1

	dialog_yesno \
		"${TXT_PART_MAIN}" \
		"$(gettext 'Форматировать раздел')\n \Zb\Z6${PART}\Zn ?" \
		'--defaultno'

	case "${?}" in
		'0') #Yes
			part_format "${PART}" "${POINT}" || return 1
			;;
#    '1') #No
#      ;;
		'255') #ESC
			return 1
			;;
	esac

	part_mount_test_fs "${PART}" || return 1

	TEMP="$(part_mount_dialog_dev_opt "${PART}" "${POINT}")"
	case "${?}" in
		'0') #Yes
			OPT="${TEMP}"
			;;
		'1') #No
			return 1
			;;
		'255') #ESC
			return 1
			;;
	esac

	SET_DEV_ROOT[0]="${PART}"
	SET_DEV_ROOT[1]="${OPT}"

	mkdir -p "${NS_PATH}/"
	local MOUNT_OPT
	[[ -n "${SET_DEV_ROOT[1]}" ]] && MOUNT_OPT="-o ${SET_DEV_ROOT[1]}"
	msg_log "mount ${MOUNT_OPT} ${SET_DEV_ROOT[0]} /"
	mount ${MOUNT_OPT} "${SET_DEV_ROOT[0]}" "${NS_PATH}/"

	RUN_PART=1
}

part_mount_test_fs()
{
	local P_PART="${1}"

	if [[ ! -n "$(blkid -c /dev/null "${P_PART}" | sed -n '/ TYPE=/{s/.* TYPE="//; s/".*//; p}')" ]]
	then
		dialog_warn \
			"\Zb\Z1$(gettext 'Раздел не отформатирован')\Zn"
		return 1
	fi
	return 0
}

part_mount_dialog_dev_part()
{
	msg_log "$(gettext 'Запуск диалога'): \"${FUNCNAME}$(for ((TEMP=1; TEMP<=${#}; TEMP++)); do echo -n " \$${TEMP}='$(eval "echo \"\${${TEMP}}\"")'"; done)\"" 'noecho'

	local RETURN

	local P_POINT="${1}"

	local TITLE="${TXT_PART_MAIN}"
	local HELP_TXT="$(gettext 'Точка монтирования'): \Zb\Z2\"${P_POINT}\"\Zn\n"
	HELP_TXT+="$(gettext 'Символом * помечены загрузочные разделы')\n"
	HELP_TXT+="\n$(gettext 'Выберите раздел для монтирования')\n"

	local DEFAULT_ITEM=' '

	local NAME

	local ITEMS="$(lsblk -nro NAME | tr ' ' '\r' |
	while IFS=$'\r' read -r NAME
	do
		local TEMP="$(get_part_info "/dev/${NAME}")"

		local MOUNTPOINT="$(get_part_param 'MOUNTPOINT' <<< "${TEMP}")"
		if [[ ! -n "${MOUNTPOINT}" ]]
		then
			local ID_PART_ENTRY_TYPE="$(get_part_param 'ID_PART_ENTRY_TYPE' <<< "${TEMP}")"
			if [[ -n "${ID_PART_ENTRY_TYPE}" ]]
			then
				case "${ID_PART_ENTRY_TYPE}" in
					# список типов разделов которые нельзя использовать
					'0x00' | '0x0' | '0x05' | '0x5' | '0x82')
						;;
					*)
						local DEVNAME="$(get_part_param 'DEVNAME' <<< "${TEMP}")"
						local ID_FS_TYPE="$(get_part_param 'ID_FS_TYPE' <<< "${TEMP}")"
						local PART_TABLE_TYPE_NAME="$(get_part_param 'PART_TABLE_TYPE_NAME' <<< "${TEMP}")"
						local SIZE="$(get_part_param 'SIZE' <<< "${TEMP}")"
						local ID_FS_LABEL="$(get_part_param 'ID_FS_LABEL' <<< "${TEMP}")"

						local ID_PART_ENTRY_FLAGS="$(get_part_param 'ID_PART_ENTRY_FLAGS' <<< "${TEMP}")"

						local BOOTM=
						[[ "${ID_PART_ENTRY_FLAGS}" == '0x8000000000000000' ]] || [[ "${ID_PART_ENTRY_FLAGS}" == '0x80' ]] && BOOTM='* '

						echo -e "'${DEVNAME}' '${BOOTM}\"${PART_TABLE_TYPE_NAME}\" ${SIZE} ${ID_FS_TYPE} \"${ID_FS_LABEL}\"'"
						;;
				esac
			fi
		fi

	done)"

	if [[ ! -n "${ITEMS}" ]]
	then
		dialog_warn \
			"\Zb\Z1$(gettext 'Свободных разделов не найдено!!!')\Zn"
		return 1
	fi

	RETURN="$(dialog_menu "${TITLE}" "${DEFAULT_ITEM}" "${HELP_TXT}" "${ITEMS}")"

	echo "${RETURN}"
	msg_log "$(gettext 'Выход из диалога'): \"${FUNCNAME} return='${RETURN}'\"" 'noecho'
}

part_mount_dialog_dev_opt()
{
	msg_log "$(gettext 'Запуск диалога'): \"${FUNCNAME}$(for ((TEMP=1; TEMP<=${#}; TEMP++)); do echo -n " \$${TEMP}='$(eval "echo \"\${${TEMP}}\"")'"; done)\"" 'noecho'

	local RETURN

	local P_PART="${1}"
	local P_POINT="${2}"

	local TYPE="$(blkid -c /dev/null "${P_PART}" | sed -n '/ TYPE=/{s/.* TYPE="//; s/".*//; p}')"

	local TITLE="${TXT_PART_MAIN}"
	local HELP_TXT="$(gettext 'Точка монтирования'): \Zb\Z2\"${P_POINT}\"\Zn\n"
	HELP_TXT+="$(gettext 'Раздел'): \Zb\Z2\"${P_PART}\"\Zn\n"
	HELP_TXT+="$(gettext 'Файловая система'): \Zb\Z2\"${TYPE}\"\Zn\n"
	HELP_TXT+="\n$(gettext 'Введите дополнительные опции монтирования')\n"
	HELP_TXT+="$(gettext 'По умолчанию'):"

	local TEXT='defaults,noauto,x-systemd.automount'

	case "${TYPE}" in
		'ext4' | 'ext4dev')
			is_ssd "${P_PART}" && TEXT+=',discard'
			;;
		'btrfs')
			TEXT+=',compress=lzo'
			is_ssd "${P_PART}" && TEXT+=',discard,ssd'
			;;
	esac

	HELP_TXT+=" \Zb\Z7\"${TEXT}\"\Zn\n"

	RETURN="$(dialog_inputbox "${TITLE}" "${HELP_TXT}" "${TEXT}")"

	echo "${RETURN}"
	msg_log "$(gettext 'Выход из диалога'): \"${FUNCNAME} return='${RETURN}'\"" 'noecho'
}


part_mount_all()
{
	local P_POINT="${1}"
	local P_P="${2}"

	local SET_DEV
	eval "SET_DEV[0]=\${${P_P}[0]}"
	eval "SET_DEV[1]=\${${P_P}[1]}"

	mkdir -p "${NS_PATH}${P_POINT}"
	chmod 755 "${NS_PATH}${P_POINT}"
	[[ -n "${SET_DEV[1]}" ]] && SET_DEV[1]="-o ${SET_DEV[1]}"
	msg_log "mount ${SET_DEV[1]} ${SET_DEV[0]} ${P_POINT}"
	mount ${SET_DEV[1]} "${SET_DEV[0]}" "${NS_PATH}${P_POINT}"
	[[ "${?}" == '0' ]] && return 0
	eval "${P_P}[0]=''"
	eval "${P_P}[1]=''"
	return 1
}

part_mount_swap()
{
	local POINT='swap'

	local PART
	local OPT

	local TEMP

	part_mount_test "${POINT}" 'SET_DEV_SWAP' || return 1

# Диалог выбора раздела, для монтирования
	case "$(part_mount_dialog_swap_type "${POINT}")" in
		'dev')
			PART="$(part_mount_dialog_swap_dev "${POINT}")"
			[[ ! -n "${PART}" ]] && return 1

			dialog_yesno \
				"${TXT_PART_MAIN}" \
				"$(gettext 'Форматировать раздел')\n \Zb\Z6${PART}\Zn ?" \
				'--defaultno'

			case "${?}" in
				'0') #Yes
					part_format "${PART}" "${POINT}" || return 1
					;;
#   	'1') #No
#     	  ;;
				'255') #ESC
					return 1
					;;
			esac

			part_mount_test_fs "${PART}" || return 1

			OPT='defaults'

			SET_DEV_SWAP[0]="${PART}"
			SET_DEV_SWAP[1]="${OPT}"

			msg_log " swapon ${SET_DEV_SWAP[0]}"
			swapon "${SET_DEV_SWAP[0]}"
			;;
		'file')
			OPT="$(part_mount_dialog_swap_file "${POINT}")"
			[[ ! -n "${OPT}" ]] && return 1
			OPT="${OPT}"
			PART='/swapfile'

			SET_DEV_SWAP[0]="${PART}"
			SET_DEV_SWAP[1]="${OPT}"

			msg_log "$(gettext 'Создается') /swapfile"
			fallocate -l "${SET_DEV_SWAP[1]}M" "${NS_PATH}${SET_DEV_SWAP[0]}"
			msg_log "dd if='/dev/zero' of=${NS_PATH}${SET_DEV_SWAP[0]} bs='1M' count=${SET_DEV_SWAP[1]}"
# 			msg_log "dd if='/dev/urandom' of=${NS_PATH}${SET_DEV_SWAP[0]} bs='1M' count=${SET_DEV_SWAP[1]}"
			msg_info "$(gettext 'Пожалуйста, подождите')..."
			dd if='/dev/zero' of="${NS_PATH}${SET_DEV_SWAP[0]}" bs='1M' count="${SET_DEV_SWAP[1]}"
# 			dd if='/dev/urandom' of="${NS_PATH}${SET_DEV_SWAP[0]}" bs='1M' count="${SET_DEV_SWAP[1]}"
			mkswap -L SwapFile "${NS_PATH}${SET_DEV_SWAP[0]}"
			msg_log " swapon ${NS_PATH}${SET_DEV_SWAP[0]}"
			swapon "${NS_PATH}${SET_DEV_SWAP[0]}"
			;;
		*)
			return 1
			;;
	esac
}

part_mount_dialog_swap_type()
{
	msg_log "$(gettext 'Запуск диалога'): \"${FUNCNAME}$(for ((TEMP=1; TEMP<=${#}; TEMP++)); do echo -n " \$${TEMP}='$(eval "echo \"\${${TEMP}}\"")'"; done)\"" 'noecho'

	local RETURN

	local P_POINT="${1}"

	local TYPE="$(blkid -c /dev/null "${SET_DEV_ROOT[0]}" | sed -n '/ TYPE=/{s/.* TYPE="//; s/".*//; p}')"

	local TITLE="${TXT_PART_MAIN}"
	local HELP_TXT="$(gettext 'Точка монтирования'): \Zb\Z2\"${P_POINT}\"\Zn\n"
	HELP_TXT+="\n$(gettext 'Выберите тип')\n"

	local DEFAULT_ITEM='1'
	local ITEMS="'dev' '$(gettext 'Раздел')'"
	ITEMS+=" 'file' '$(gettext 'Файл')'"

	case "${TYPE}" in
		'ext2' | 'ext3' | 'ext4')
			RETURN=
			;;
		*)
			echo 'dev'
			return
			;;
	esac

	RETURN="$(dialog_menu "${TITLE}" "${DEFAULT_ITEM}" "${HELP_TXT}" "${ITEMS}")"

	echo "${RETURN}"
	msg_log "$(gettext 'Выход из диалога'): \"${FUNCNAME} return='${RETURN}'\"" 'noecho'
}

part_mount_dialog_swap_dev()
{
	msg_log "$(gettext 'Запуск диалога'): \"${FUNCNAME}$(for ((TEMP=1; TEMP<=${#}; TEMP++)); do echo -n " \$${TEMP}='$(eval "echo \"\${${TEMP}}\"")'"; done)\"" 'noecho'

	local RETURN

	local P_POINT="${1}"

	local TITLE="${TXT_PART_MAIN}"
	local HELP_TXT="$(gettext 'Точка монтирования'): \Zb\Z2\"${P_POINT}\"\Zn\n"
	HELP_TXT+="\n$(gettext 'Выберите раздел для монтирования')\n"

	local DEFAULT_ITEM=' '

	local NAME

	local ITEMS="$(lsblk -nro NAME | tr ' ' '\r' |
	while IFS=$'\r' read -r NAME
	do
		local TEMP="$(get_part_info "/dev/${NAME}")"

		local MOUNTPOINT="$(get_part_param 'MOUNTPOINT' <<< "${TEMP}")"
		if [[ ! -n "${MOUNTPOINT}" ]]
		then
			local ID_PART_ENTRY_TYPE="$(get_part_param 'ID_PART_ENTRY_TYPE' <<< "${TEMP}")"
			if [[ -n "${ID_PART_ENTRY_TYPE}" ]]
			then
				case "${ID_PART_ENTRY_TYPE}" in
					# типы свап разделов
					'0x82' | '0657fd6d-a4ab-43c4-84e5-0933c84b4f4f')
						local DEVNAME="$(get_part_param 'DEVNAME' <<< "${TEMP}")"

						local PART_TABLE_TYPE_NAME="$(get_part_param 'PART_TABLE_TYPE_NAME' <<< "${TEMP}")"
						local SIZE="$(get_part_param 'SIZE' <<< "${TEMP}")"
						local ID_FS_LABEL="$(get_part_param 'ID_FS_LABEL' <<< "${TEMP}")"

						echo -e "'${DEVNAME}' '\"${PART_TABLE_TYPE_NAME}\" ${SIZE} \"${ID_FS_LABEL}\"'"
						;;
				esac
			fi
		fi

	done)"

	if [[ ! -n "${ITEMS}" ]]
	then
		dialog_warn \
			"\Zb\Z1$(gettext 'Свободных разделов не найдено!!!')\Zn"
		return 1
	fi

	RETURN="$(dialog_menu "${TITLE}" "${DEFAULT_ITEM}" "${HELP_TXT}" "${ITEMS}")"

	echo "${RETURN}"
	msg_log "$(gettext 'Выход из диалога'): \"${FUNCNAME} return='${RETURN}'\"" 'noecho'
}

part_mount_dialog_swap_file()
{
	msg_log "$(gettext 'Запуск диалога'): \"${FUNCNAME}$(for ((TEMP=1; TEMP<=${#}; TEMP++)); do echo -n " \$${TEMP}='$(eval "echo \"\${${TEMP}}\"")'"; done)\"" 'noecho'

	local RETURN

	local P_POINT="${1}"

	local TITLE="${TXT_PART_MAIN}"
	local HELP_TXT="$(gettext 'Точка монтирования'): \Zb\Z2\"${P_POINT}\"\Zn\n"
	HELP_TXT+="\n$(gettext 'Введите размер swap файла (размер в MB!!!)')\n"
	HELP_TXT+="$(gettext 'По умолчанию'):"

	local TEXT="$(($(free -m | grep 'Mem:' | awk '{ print $2 }') * 2))"

	HELP_TXT+=" \Zb\Z7\"${TEXT}\"\Zn\n"

	RETURN="$(dialog_inputbox "${TITLE}" "${HELP_TXT}" "${TEXT}")"

	echo "${RETURN}"
	msg_log "$(gettext 'Выход из диалога'): \"${FUNCNAME} return='${RETURN}'\"" 'noecho'
}

part_mount_test()
{
	local P_POINT="${1}"
	local P_P="${2}"

	local SET_DEV
	eval "SET_DEV[0]=\${${P_P}[0]}"

	if [[ ! -n "${SET_DEV_ROOT[0]}" ]]
	then
		dialog_warn \
			"\Zb\Z1$(gettext 'Раздел "/ (root)" не премонтирован!!!')\Zn"
		return 1
	fi
	if [[ -n "${SET_DEV[0]}" ]]
	then
		dialog_warn \
			"\Zb\Z1$(gettext 'Раздел для') \"${P_POINT}\" $(gettext 'уже премонтирован!!!')\Zn"
		return 1
	fi
	return 0
}

part_mount_set_fstab_str()
{
	local P_POINT="${1}"
	local P_P="${2}"
	local P_DUMP="${3}"
	local P_PASS="${4}"

	local UUID
	local TYPE
	local SET_DEV
	eval "SET_DEV[0]=\${${P_P}[0]}"
	eval "SET_DEV[1]=\${${P_P}[1]}"

	[[ ! -n "${SET_DEV[0]}" ]] && return 1

	if [[ "$(grep '^/dev/' <<< "${SET_DEV[0]}")" ]]
	then
		UUID="$(blkid -c /dev/null "${SET_DEV[0]}")"
		TYPE="$(sed -n '/ TYPE=/{s/.* TYPE="//; s/".*//; p}' <<< "${UUID}")"
		UUID="$(sed -n '/ UUID=/{s/.* UUID="//; s/".*//; p}' <<< "${UUID}")"

		msg_log "UUID=${UUID}	${P_POINT}	${TYPE}	${SET_DEV[1]}	${P_DUMP}	${P_PASS}" '1'
		echo -e "UUID=${UUID}\t${P_POINT}\t${TYPE}\t${SET_DEV[1]}\t${P_DUMP}\t${P_PASS}"
	else
		msg_log "${SET_DEV[0]}	${P_POINT}	swap	defaults	${P_DUMP}	${P_PASS}" '1'
		echo -e "${SET_DEV[0]}\t${P_POINT}\tswap\tdefaults\t${P_DUMP}\t${P_PASS}"
	fi
}

part_unmount()
{
	if [[ "${RUN_PART}" ]]
	then
# Размонтируем
		if [[ -n "${SET_DEV_SWAP[0]}" ]]
		then
			msg_log "swapoff ${SET_DEV_SWAP[0]}"
			if [[ "$(grep '^/dev/' <<< "${SET_DEV_SWAP[0]}")" ]]
			then
				swapoff "${SET_DEV_SWAP[0]}"
			else
				swapoff "${NS_PATH}${SET_DEV_SWAP[0]}"
			fi
		fi

		if [[ -n "${SET_DEV_HOME[0]}" ]]
		then
			msg_log "umount ${SET_DEV_HOME[0]}"
			umount "${SET_DEV_HOME[0]}"
		fi
		if [[ -n "${SET_DEV_BOOT[0]}" ]]
		then
			msg_log "umount ${SET_DEV_BOOT[0]}"
			umount "${SET_DEV_BOOT[0]}"
		fi

#    cat "${LOG_FILE}" > "${NS_PATH}${LOG_FILE}"
		msg_log "umount ${SET_DEV_ROOT[0]}"
		umount "${SET_DEV_ROOT[0]}"
		msg_log "rmdir ${NS_PATH}/"
		rmdir "${NS_PATH}/"
	fi

	SET_DEV_SWAP=('' '')

	SET_DEV_BOOT=('' '')
	SET_DEV_HOME=('' '')

	SET_DEV_ROOT=('' '')

	RUN_PART=
}

is_ssd()
{
	local SDX="${1}"

	SDX="${SDX/\/dev\//}"
	SDX="${SDX:0:3}"

	[[ "$(cat "/sys/block/${SDX}/queue/rotational")" == '0' ]] && return 0
	[[ "$(cat "/sys/block/${SDX}/removable")" == '1' ]] && return 0
#  [[ "$(udevadm info --query=property --name="${SDX}" | grep 'ID_BUS=' | sed 's/ID_BUS=//')" == 'usb' ]] && return 0

	return 1
}

#chroot /mnt/newSystem nano /etc/fstab
#/usbUsr.sfs   /usr   squashfs   ro   0 0
#chroot /mnt/newSystem mksquashfs /usr /usbUsr.sfs -b 1M -comp xz
