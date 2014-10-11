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

SWAPFILE='/swapfile'
# dev opt ID_FS_TYPE ID_FS_UUID
declare -a SET_DEV_ROOT=()
declare -a SET_DEV_BOOT=()
declare -a SET_DEV_EFI=()
declare -a SET_DEV_HOME=()
# dev opt ID_FS_TYPE ID_FS_UUID | file size offset ID_FS_UUID
declare -a SET_DEV_SWAP=()
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
		DEV="$(part_part_dialog_dev)"
		[[ ! -n "${DEV}" ]] && return 1

		TEMP="$(part_part_dialog_fdisk "${FDISK}" "${DEV}")"
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
	local P_DEV="${2}"

	local TITLE="${TXT_PART_MAIN}"

	local HELP_TXT+="$(gettext 'Устройство'): \Zb\Z2\"${P_DEV}\"\Zn\n\n"

	HELP_TXT="\Z1$(gettext 'C BIOS рекомендуется использовать MBR тип разметки!!!')\Zn\n"

	[[ "$BIOS_SYS" == 'EFI' ]] && HELP_TXT="\Z1$(gettext 'C EFI рекомендуется использовать GPT тип разметки!!!')\Zn\n"
	HELP_TXT+="\n$(gettext 'Выберите программу для разметки')\n"
	HELP_TXT+="$(gettext 'По умолчанию'):"

	local DEFAULT_ITEM="${P_FDISK}"

	local ITEMS="'cfdisk' 'MBR'"
	ITEMS+=" 'fdisk' 'MBR & GPT \Zb\Z3($(gettext 'Рекомендуется'))\Zn'"
	ITEMS+=" 'sfdisk' 'MBR'"
	ITEMS+=" 'parted' '-'"
	ITEMS+=" 'cgdisk' 'GPT'"
	ITEMS+=" 'gdisk' 'GPT'"
	ITEMS+=" 'sgdisk' 'GPT'"

	HELP_TXT+=" \Zb\Z7\"${DEFAULT_ITEM}\"\Zn\n"

	RETURN="$(dialog_menu "${TITLE}" "${DEFAULT_ITEM}" "${HELP_TXT}" "${ITEMS}")"

	echo "${RETURN}"
	msg_log "$(gettext 'Выход из диалога'): \"${FUNCNAME} return='${RETURN}'\"" 'noecho'
}

part_part_dialog_dev()
{
	msg_log "$(gettext 'Запуск диалога'): \"${FUNCNAME}$(for ((TEMP=1; TEMP<=${#}; TEMP++)); do echo -n " \$${TEMP}='$(eval "echo \"\${${TEMP}}\"")'"; done)\"" 'noecho'

	local RETURN

	local TITLE="${TXT_PART_MAIN}"
	local HELP_TXT=

	if [[ "$BIOS_SYS" == 'EFI' ]]
	then
		HELP_TXT+="\Zb\Z7/boot/efi\Zn - 128M-512M \Zb\Z2(128M)\Zn, $(gettext 'тип') \Zb\Z61 - EFI System\Zn \Zb\Z1($(gettext 'ОБЯЗАТЕЛЬНО!!!'))\Zn\n"
		HELP_TXT+="  FLASH DRIVE \Zb\Z2(32M)\Zn\n"

		HELP_TXT+="\Zb\Z7/boot\Zn - 32M-512M \Zb\Z2(96M)\Zn, $(gettext 'тип') \Zb\Z615 - Linux filesystem\Zn \Zb\Z3($(gettext 'Рекомендуется'))\Zn\n"
		HELP_TXT+="  FLASH DRIVE \Zb\Z2(32M)\Zn\n"
		if [[ "${UNAME}" = 'x86_64' ]]
		then
			HELP_TXT+="\Zb\Z7/ (root)\Zn - 4G-32G \Zb\Z2(20G)\Zn, $(gettext 'тип') \Zb\Z618 - Linux root (x86-64)\Zn \Zb\Z1($(gettext 'ОБЯЗАТЕЛЬНО!!!'))\Zn\n"
		else
			HELP_TXT+="\Zb\Z7/ (root)\Zn - 4G-32G \Zb\Z2(20G)\Zn, $(gettext 'тип') \Zb\Z617 - Linux root (x86)\Zn \Zb\Z1($(gettext 'ОБЯЗАТЕЛЬНО!!!'))\Zn\n"
		fi

		HELP_TXT+="\Zb\Z7/home\Zn - \Zb\Z2($(gettext 'все остальное место'))\Zn, $(gettext 'тип') \Zb\Z620 - Linux home\Zn \Zb\Z3($(gettext 'Рекомендуется'))\Zn\n"
		HELP_TXT+="  $(gettext '10G на одного пользователя и 5G на бэкапы и кеш системы')\n"
		HELP_TXT+="  $(gettext 'Если установка на FLASH DRIVE, то можно не использовать отдельный раздел')\n"

		HELP_TXT+="\Zb\Z7swap\Zn - RAM*2 \Zb\Z2($(free -m | awk '/Mem:/{ print $2*2 }')M)\Zn, $(gettext 'тип') \Zb\Z614 - Linux swap\Zn\n"
		HELP_TXT+="  $(gettext 'Можно потом сделать swap в файл, если фс') \Zb\Z6/ (root) ext4\Zn\n"
	else
		HELP_TXT+="\Zb\Z7/boot\Zn - 32M-512M \Zb\Z2(96M)\Zn, $(gettext 'тип') \Zb\Z683 - Linux\Zn \Zb\Z3($(gettext 'Рекомендуется'))\Zn\n"
		HELP_TXT+="  FLASH DRIVE \Zb\Z2(32M)\Zn, $(gettext 'тип') \Zb\Z607 - HPFS/NTFS/exFAT\Zn | \Zb\Z60B - W95 FAT32\Zn\n"
		HELP_TXT+="  $(gettext 'Нужно сделать загрузочным!!!')\n"

		HELP_TXT+="\Zb\Z7/ (root)\Zn - 4G-32G \Zb\Z2(20G)\Zn, $(gettext 'тип') \Zb\Z683 - Linux\Zn \Zb\Z1($(gettext 'ОБЯЗАТЕЛЬНО!!!'))\Zn\n"

		HELP_TXT+="\Zb\Z7/home\Zn - \Zb\Z2($(gettext 'все остальное место'))\Zn, $(gettext 'тип') \Zb\Z683 - Linux\Zn \Zb\Z3($(gettext 'Рекомендуется'))\Zn\n"
		HELP_TXT+="  $(gettext '10G на одного пользователя и 5G на бэкапы и кеш системы')\n"
		HELP_TXT+="  $(gettext 'Если установка на FLASH DRIVE, то можно не использовать отдельный раздел')\n"

		HELP_TXT+="\Zb\Z7swap\Zn - RAM*2 \Zb\Z2($(free -m | awk '/Mem:/{ print $2*2 }')M)\Zn, $(gettext 'тип') \Zb\Z682 - Linux swap / Solaris\Zn\n"
		HELP_TXT+="  $(gettext 'Можно потом сделать swap в файл, если фс') \Zb\Z6/ (root) ext2 | ext3 | ext4\Zn\n"
	fi

	HELP_TXT+="\n$(gettext 'Выберите устройство для разметки')\n"

	ITEMS="$(part_part_dev)"

	RETURN="$(dialog_menu "${TITLE}" "${DEFAULT_ITEM}" "${HELP_TXT}" "${ITEMS}" "--cancel-label '$(gettext 'Назад')'")"

	echo "${RETURN}"
	msg_log "$(gettext 'Выход из диалога'): \"${FUNCNAME} return='${RETURN}'\"" 'noecho'
}

part_part_dev()
{
	local NAME

	lsblk -nro NAME | tr ' ' '\r' |
	while IFS=$'\r' read -r NAME
	do
		local PART_INFO="$(get_part_info "/dev/${NAME}")"

		local DEVTYPE="$(get_part_param 'DEVTYPE' <<< "${PART_INFO}")"
		local ID_TYPE="$(get_part_param 'ID_TYPE' <<< "${PART_INFO}")"

		if [[ "${DEVTYPE}" == 'disk' ]] && [[ "${ID_TYPE}" == 'disk' ]]
		then
			local DEVNAME="$(get_part_param 'DEVNAME' <<< "${PART_INFO}")"

			local ID_PART_TABLE_TYPE="$(get_part_param 'ID_PART_TABLE_TYPE' <<< "${PART_INFO}")"
			local SIZE="$(get_part_param 'SIZE' <<< "${PART_INFO}")"
			local ID_BUS="$(get_part_param 'ID_BUS' <<< "${PART_INFO}")"
			local ID_SERIAL="$(get_part_param 'ID_SERIAL' <<< "${PART_INFO}")"

			echo -e "'${DEVNAME}' '${ID_BUS} ${ID_PART_TABLE_TYPE} ${SIZE} ${ID_SERIAL}'"
		fi
	done
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
				part_unmount 'noexit'

				SET_DEV_SWAP=()
				SET_DEV_EFI=()
				SET_DEV_BOOT=()
				SET_DEV_HOME=()
				SET_DEV_ROOT=()
				RUN_PART=

				continue
				;;
			'/')
				part_mount_point '/' 'SET_DEV_ROOT' || continue
				;;
			'/boot')
				part_mount_point '/boot' 'SET_DEV_BOOT' || continue
				;;
			'/boot/efi')
				part_mount_point '/boot/efi' 'SET_DEV_EFI' || continue
				;;
			'/home')
				part_mount_point '/home' 'SET_DEV_HOME' || continue
				;;
			'swap')
				part_mount_swap || continue
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
	ITEMS+=" '/' '(root) \"${SET_DEV_ROOT[0]}\" \"${SET_DEV_ROOT[2]}\" ${TEMP}'"

	TEMP=
	[[ -n "${SET_DEV_BOOT[0]}" ]] && TEMP="\Zb\Z2($(gettext 'ВЫПОЛНЕНО'))\Zn"
	ITEMS+=" '/boot' '\"${SET_DEV_BOOT[0]}\" \"${SET_DEV_BOOT[2]}\" ${TEMP}'"

	if [[ "$BIOS_SYS" == 'EFI' ]]
	then
		TEMP="\Zb\Z1($(gettext 'ОБЯЗАТЕЛЬНО!!!'))\Zn"
		[[ -n "${SET_DEV_EFI[0]}" ]] && TEMP="\Zb\Z2($(gettext 'ВЫПОЛНЕНО'))\Zn"
		ITEMS+=" '/boot/efi' '\"${SET_DEV_EFI[0]}\" \"${SET_DEV_EFI[2]}\" ${TEMP}'"
	fi

	TEMP="\Zb\Z3($(gettext 'Рекомендуется'))\Zn"
	[[ -n "${SET_DEV_HOME[0]}" ]] && TEMP="\Zb\Z2($(gettext 'ВЫПОЛНЕНО'))\Zn"
	ITEMS+=" '/home' '\"${SET_DEV_HOME[0]}\" \"${SET_DEV_HOME[2]}\" ${TEMP}'"

	TEMP=
	[[ -n "${SET_DEV_SWAP[0]}" ]] && TEMP="\Zb\Z2($(gettext 'ВЫПОЛНЕНО'))\Zn"
	if [[ "${SET_DEV_SWAP[0]}" == "${SWAPFILE}" ]]
	then
		ITEMS+=" 'swap' '\"${SET_DEV_SWAP[0]}\" \"${SET_DEV_SWAP[1]}M\" ${TEMP}'"
	else
		ITEMS+=" 'swap' '\"${SET_DEV_SWAP[0]}\" \"${SET_DEV_SWAP[2]}\" ${TEMP}'"
	fi

	RETURN="$(dialog_menu "${TITLE}" "${DEFAULT_ITEM}" "${HELP_TXT}" "${ITEMS}" "--cancel-label '${TXT_MAIN_MENU}'")"

	echo "${RETURN}"
	msg_log "$(gettext 'Выход из диалога'): \"${FUNCNAME} return='${RETURN}'\"" 'noecho'
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

	local PART_INFO
	local ID_FS_TYPE

	dialog_yesno \
		"${TXT_PART_MAIN}" \
		"$(gettext 'Форматировать раздел')\n \Zb\Z6${P_PART}\Zn ?" \
		'--defaultno'

	case "${?}" in
		'0') #Yes
			PART_INFO="$(get_part_info "${P_PART}")"
			local PART_TABLE_TYPE_NAME="$(get_part_param 'PART_TABLE_TYPE_NAME' <<< "${PART_INFO}")"
			local ID_PART_ENTRY_TYPE="$(get_part_param 'ID_PART_ENTRY_TYPE' <<< "${PART_INFO}")"
			local IS_SSD="$(get_part_param 'IS_SSD' <<< "${PART_INFO}")"

			while true
			do
				MKF="$(part_format_dialog_mkf "${P_PART}" "${P_POINT}" "${PART_TABLE_TYPE_NAME}" "${ID_PART_ENTRY_TYPE}" "${IS_SSD}")"
				[[ ! -n "${MKF}" ]] && return 1

				TEMP="$(part_format_dialog_mkf_opt "${MKF}" "${P_POINT}" "${P_PART}" "${IS_SSD}")"
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
						sleep 2s
						break
						;;
					'1') #No
						continue
						;;
					'255') #ESC
						return 1
						;;
				esac
			done
			;;
#		'1') #No
#			;;
		'255') #ESC
			return 1
			;;
	esac

	PART_INFO="$(get_part_info "${P_PART}")"
	ID_FS_TYPE="$(get_part_param 'ID_FS_TYPE' <<< "${PART_INFO}")"

	if [[ ! -n "${ID_FS_TYPE}" ]]
	then
		dialog_warn \
			"\Zb\Z1$(gettext 'Раздел не отформатирован')\Zn"
		return 1
	fi
	return 0
}

part_format_dialog_mkf()
{
	msg_log "$(gettext 'Запуск диалога'): \"${FUNCNAME}$(for ((TEMP=1; TEMP<=${#}; TEMP++)); do echo -n " \$${TEMP}='$(eval "echo \"\${${TEMP}}\"")'"; done)\"" 'noecho'

	local RETURN

	local P_PART="${1}"
	local P_POINT="${2}"
	local P_PART_TABLE_TYPE_NAME="${3}"
	local P_ID_PART_ENTRY_TYPE="${4}"
	local P_IS_SSD="${5}"

	local TITLE="${TXT_PART_MAIN}"
	local HELP_TXT="$(gettext 'Точка монтирования'): \Zb\Z2\"${P_POINT}\"\Zn\n"
	HELP_TXT+="$(gettext 'Раздел'): \Zb\Z2\"${P_PART}\"\Zn\n"
	HELP_TXT+="$(gettext 'Тип'): \Zb\Z2\"${P_PART_TABLE_TYPE_NAME}\"\Zn\n"
	HELP_TXT+="\n$(gettext 'Выберите файловую систему')\n"
	HELP_TXT+="$(gettext 'По умолчанию'):"

	local DEFAULT_ITEM='mkfs.ext4'
#  local ITEMS="$(ls -1 '/usr/bin' '/sbin'| grep 'mkfs.' | sort -u | awk -F '.' '{print sq $0 sq " " sq "-" sq}' sq=\')"
	local ITEMS="'mkfs.ext4' '-'"
	ITEMS+=" 'mkfs.ext2' '-'"
	ITEMS+=" 'mkfs.ext3' '-'"
#	ITEMS+=" 'mkfs.ext4dev' '-'"
	ITEMS+=" 'mkfs.f2fs' '-'"
	ITEMS+=" 'mkfs.btrfs' '-'"
	ITEMS+=" 'mkfs.reiserfs' '-'"
	ITEMS+=" 'mkfs.jfs' '-'"
	ITEMS+=" 'mkfs.xfs' '-'"
	ITEMS+=" 'mkfs.nilfs2' '-'"
	ITEMS+=" 'mkfs.ntfs' '-'"
	ITEMS+=" 'mkfs.exfat' '-'"
	ITEMS+=" 'mkfs.vfat' '-'"
#	ITEMS+=" 'mkfs.fat' '-'"
#	ITEMS+=" 'mkfs.msdos' '-'"
	ITEMS+=" 'mkfs.minix' '-'"
#	ITEMS+=" 'mkfs.bfs' '-'"
#	ITEMS+=" 'mkfs.cramfs' '-'"
	ITEMS+=" 'mkswap' '-'"

	case "${P_ID_PART_ENTRY_TYPE}" in
		'0x01' | '0x1') # FAT12
			DEFAULT_ITEM='mkfs.vfat'
			;;
		'0x04' | '0x4') # FAT16 <32M
			DEFAULT_ITEM='mkfs.vfat'
			;;
		'0x06' | '0x6') # FAT16 >=32M
			DEFAULT_ITEM='mkfs.vfat'
			;;
		'0x07' | '0x7') # HPFS/NTFS/exFAT
			DEFAULT_ITEM='mkfs.ntfs'
			[[ "${P_IS_SSD}" == '1' ]] && DEFAULT_ITEM='mkfs.exfat'
			;;
		'0x0b' | '0xb') # W95 FAT32
			DEFAULT_ITEM='mkfs.vfat'
			;;
		'0x81') # Minix / old Linux
			DEFAULT_ITEM='mkfs.minix'
			;;
		'0x82') # Linux swap / Solaris
			DEFAULT_ITEM='mkswap'
			;;
		'0x83') # Linux
			DEFAULT_ITEM='mkfs.ext4'
			case "${P_POINT}" in
				'/boot')
					DEFAULT_ITEM='mkfs.ext2'
					;;
			esac
			;;
		'0xef') # EFI (FAT-12/16/32)
			DEFAULT_ITEM='mkfs.vfat'
			;;
		'0xee') # GPT
			DEFAULT_ITEM='none'
			;;
		'0x05' | '0x5') # Extended
			DEFAULT_ITEM='none'
			;;
		'024dee41-33e7-11d3-9d69-0008c781f39f') # MBR partition scheme
			DEFAULT_ITEM='none'
			;;
		'21686148-6449-6e6f-744e-656564454649') # BIOS boot
			DEFAULT_ITEM='none'
			;;
		'c12a7328-f81f-11d2-ba4b-00a0c93ec93b') # EFI System
			DEFAULT_ITEM='mkfs.vfat'
			;;
		'ebd0a0a2-b9e5-4433-87c0-68b6b72699c7') # Microsoft basic data
			DEFAULT_ITEM='mkfs.ntfs'
			;;
		'0657fd6d-a4ab-43c4-84e5-0933c84b4f4f') # Linux swap (or Solaris)
			DEFAULT_ITEM='mkswap'
			;;
		'0fc63daf-8483-4772-8e79-3d69d8477de4') # Linux filesystem
			DEFAULT_ITEM='mkfs.ext4'
			case "${P_POINT}" in
				'/boot')
					DEFAULT_ITEM='mkfs.ext2'
					;;
			esac
			;;
		'933ac7e1-2eb4-4f13-b844-0e14e2aef915') # Linux home
			DEFAULT_ITEM='mkfs.ext4'
			;;
		'3b8f8425-20e0-4f3b-907f-1a25a76f98e8') # Linux server data
			DEFAULT_ITEM='mkfs.ext4'
			;;
		'44479540-f297-41b2-9af7-d131d5f0458a') # Linux root (x86)
			DEFAULT_ITEM='mkfs.ext4'
			;;
		'4f68bce3-e8cd-4db1-96e7-fbcaf984b709') # Linux root (x86-64)
			DEFAULT_ITEM='mkfs.ext4'
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
	local P_IS_SSD="${4}"

	local TITLE="${TXT_PART_MAIN}"
	local HELP_TXT="$(gettext 'Точка монтирования'): \Zb\Z2\"${P_POINT}\"\Zn\n"
	HELP_TXT+="$(gettext 'Раздел'): \Zb\Z2\"${P_PART}\"\Zn\n"
	HELP_TXT+="$(gettext 'Файловая система'): \Zb\Z2\"${P_MKF}\"\Zn\n"
	HELP_TXT+="\n$(gettext 'Введите дополнительные опции форматирования')\n"
	HELP_TXT+="$(gettext 'По умолчанию'):"

	local TEXT

	local FLASH
	[[ "${P_IS_SSD}" == '1' ]] && FLASH='Flash'

	local LABEL
	case "${P_POINT}" in
		'/')
			LABEL="${FLASH}Root"
			;;
		'/boot')
			LABEL="${FLASH}Boot"
			;;
		'/boot/efi')
			LABEL="${FLASH}EFI"
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
		'mkfs.exfat' | 'mkfs.vfat')
			TEXT="-n ${LABEL}"
			;;
		'mkfs.reiserfs' | 'mkfs.f2fs')
			TEXT="-l ${LABEL}"
			;;
		'mkfs.ext4' | 'mkfs.ext4dev')
			FLASH=
			[[ "${P_IS_SSD}" == '1' ]] && FLASH=' -E discard'
			case "${P_POINT}" in
				'/')
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

part_mount_point()
{
	local P_POINT="${1}"
	local P_P="${2}"

	local PART
	local OPT

	local TEMP

	part_mount_test "${P_POINT}" "${P_P}" || return 1

	PART="$(part_mount_dialog_dev_part "${P_POINT}")"
	[[ ! -n "${PART}" ]] && return 1

	part_format "${PART}" "${P_POINT}" || return 1

	local PART_INFO="$(get_part_info "${PART}")"
	local ID_FS_TYPE="$(get_part_param 'ID_FS_TYPE' <<< "${PART_INFO}")"
	local IS_SSD="$(get_part_param 'IS_SSD' <<< "${PART_INFO}")"
	local ID_FS_UUID="$(get_part_param 'ID_FS_UUID' <<< "${PART_INFO}")"

	TEMP="$(part_mount_dialog_dev_opt "${PART}" "${P_POINT}" "${ID_FS_TYPE}" "${IS_SSD}")"
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

	mkdir -m 755 -p "${NS_PATH}${P_POINT}"

	TEMP=
	[[ -n "${OPT}" ]] && TEMP="-o ${OPT}"

	msg_log "mount ${TEMP} ${PART} ${P_POINT}"
	mount ${TEMP} "${PART}" "${NS_PATH}${P_POINT}"

	if [[ "${?}" != '0' ]]
	then
		dialog_warn \
			"\Zb\Z1$(gettext 'Не удалось примонтировать')\Zn\n${PART} -> ${P_POINT}"
		return 1
	fi

	set_global_var "${P_P}" "${PART}" "${OPT}" "${ID_FS_TYPE}" "${ID_FS_UUID}"

	if [[ "$BIOS_SYS" == 'EFI' ]]
	then
		[[ -n "${SET_DEV_ROOT[0]}" ]] && [[ -n "${SET_DEV_EFI[0]}" ]] && RUN_PART=1
	else
		[[ -n "${SET_DEV_ROOT[0]}" ]] && RUN_PART=1
	fi

	return 0
}

part_mount_test()
{
	local P_POINT="${1}"
	local P_P="${2}"

	local SET_DEV
	eval "SET_DEV[0]=\${${P_P}[0]}"

	if [[ "${P_POINT}" != '/' ]] && [[ ! -n "${SET_DEV_ROOT[0]}" ]]
	then
		dialog_warn \
			"\Zb\Z1$(gettext 'Раздел') \"/\" (root) $(gettext 'не примонтирован!!!')\Zn"
		return 1
	fi

	if [[ "${P_POINT}" == '/boot' ]] && [[ -n "${SET_DEV_EFI[0]}" ]]
	then
		dialog_warn \
			"\Zb\Z1$(gettext 'Невозможно примонтировать') \"${P_POINT}\"!!!\n $(gettext 'Раздел') \"/boot/efi\" $(gettext 'уже примонтирован!!!')\Zn"
		return 1
	fi

	if [[ -n "${SET_DEV[0]}" ]]
	then
		dialog_warn \
			"\Zb\Z1$(gettext 'Раздел для') \"${P_POINT}\" $(gettext 'уже примонтирован!!!')\Zn"
		return 1
	fi
	return 0
}

part_dev_part()
{
	local P_POINT="${1}"

	local NAME

	lsblk -nro NAME | tr ' ' '\r' |
	while IFS=$'\r' read -r NAME
	do
		local PART_INFO="$(get_part_info "/dev/${NAME}")"

		local MOUNTPOINT="$(get_part_param 'MOUNTPOINT' <<< "${PART_INFO}")"
		if [[ ! -n "${MOUNTPOINT}" ]]
		then
			local ID_PART_ENTRY_TYPE="$(get_part_param 'ID_PART_ENTRY_TYPE' <<< "${PART_INFO}")"
			if [[ -n "${ID_PART_ENTRY_TYPE}" ]]
			then
				case "${ID_PART_ENTRY_TYPE}" in
					'0x00' | '0x0' | '0x05' | '0x5') # список типов разделов которые нельзя использовать
						;;
					*)
						local BOOT_BIOS=
						local BOOT_EFI=
						case "${ID_PART_ENTRY_TYPE}" in
							'0x82' | '0657fd6d-a4ab-43c4-84e5-0933c84b4f4f')
								[[ "${P_POINT}" != 'swap' ]] && continue
								;;
							*)
								[[ "${P_POINT}" == 'swap' ]] && continue
								BOOT_BIOS="$(get_part_param 'BOOT_BIOS' <<< "${PART_INFO}")"
								BOOT_EFI="$(get_part_param 'BOOT_EFI' <<< "${PART_INFO}")"

								;;
						esac
						local DEVNAME="$(get_part_param 'DEVNAME' <<< "${PART_INFO}")"
						local ID_FS_TYPE="$(get_part_param 'ID_FS_TYPE' <<< "${PART_INFO}")"
						local PART_TABLE_TYPE_NAME="$(get_part_param 'PART_TABLE_TYPE_NAME' <<< "${PART_INFO}")"
						local SIZE="$(get_part_param 'SIZE' <<< "${PART_INFO}")"
						local ID_FS_LABEL="$(get_part_param 'ID_FS_LABEL' <<< "${PART_INFO}")"

						echo -e "'${DEVNAME}' '${BOOT_BIOS}${BOOT_EFI} \"${PART_TABLE_TYPE_NAME}\" ${SIZE} ${ID_FS_TYPE} \"${ID_FS_LABEL}\"'"
						;;
				esac
			fi
		fi

	done
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

	local ITEMS="$(part_dev_part "${P_POINT}")"

	if [[ ! -n "${ITEMS}" ]]
	then
		dialog_warn \
			"\Zb\Z1$(gettext 'Свободные разделы не найдены!!!')\Zn"
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
	local P_ID_FS_TYPE="${3}"
	local P_IS_SSD="${4}"

	local TITLE="${TXT_PART_MAIN}"
	local HELP_TXT="$(gettext 'Точка монтирования'): \Zb\Z2\"${P_POINT}\"\Zn\n"
	HELP_TXT+="$(gettext 'Раздел'): \Zb\Z2\"${P_PART}\"\Zn\n"
	HELP_TXT+="$(gettext 'Файловая система'): \Zb\Z2\"${P_ID_FS_TYPE}\"\Zn\n"
	HELP_TXT+="\n$(gettext 'Введите дополнительные опции монтирования')\n"
	HELP_TXT+="$(gettext 'По умолчанию'):"

	local TEXT='defaults,noauto,x-systemd.automount'

	case "${P_ID_FS_TYPE}" in
		'ext4' | 'ext4dev')
			[[ "${P_IS_SSD}" == '1' ]] && TEXT+=',discard'
			;;
		'btrfs')
			TEXT+=',compress=lzo'
			[[ "${P_IS_SSD}" == '1' ]] && TEXT+=',discard,ssd'
			;;
	esac

	HELP_TXT+=" \Zb\Z7\"${TEXT}\"\Zn\n"

	RETURN="$(dialog_inputbox "${TITLE}" "${HELP_TXT}" "${TEXT}")"

	echo "${RETURN}"
	msg_log "$(gettext 'Выход из диалога'): \"${FUNCNAME} return='${RETURN}'\"" 'noecho'
}

part_mount_swap()
{
	local POINT='swap'

	local PART

	part_mount_test "${POINT}" 'SET_DEV_SWAP' || return 1

# Диалог выбора раздела, для монтирования
	case "$(part_mount_dialog_swap_type "${POINT}")" in
		'dev')
			PART="$(part_mount_dialog_dev_part "${POINT}")"
			[[ ! -n "${PART}" ]] && return 1

			part_format "${PART}" "${POINT}" || return 1

			local PART_INFO="$(get_part_info "${PART}")"
			local ID_FS_TYPE="$(get_part_param 'ID_FS_TYPE' <<< "${PART_INFO}")"
			local ID_FS_UUID="$(get_part_param 'ID_FS_UUID' <<< "${PART_INFO}")"

			set_global_var 'SET_DEV_SWAP' "${PART}" 'defaults' "${ID_FS_TYPE}" "${ID_FS_UUID}"

			msg_log "swapon ${PART}"
			swapon "${PART}"
			;;
		'file')
			local SIZE="$(part_mount_dialog_swap_file "${POINT}")"
			[[ ! -n "${SIZE}" ]] && return 1

			PART="${SWAPFILE}"

			local FPART="${NS_PATH}${PART}"

			msg_log "$(gettext 'Создается') ${PART}"

			msg_log "fallocate -l '${SIZE}M' '${PART}'"
			fallocate -l "${SIZE}M" "${FPART}"

			msg_info "$(gettext 'Пожалуйста, подождите')..."

			local FROM_SWAP='/dev/zero' # '/dev/urandom'
			msg_log "dd if='${FROM_SWAP}' of='${PART}' bs='1M' count=${SIZE}"
			dd if="${FROM_SWAP}" of="${FPART}" bs='1M' count="${SIZE}"

			mkswap -L SwapFile "${FPART}"

			local OFFSET="$(filefrag -v "${FPART}" | sed -n '4p' | awk '{print $3}')"
			OFFSET="${OFFSET/:/}"

			local PART_INFO="$(get_part_info "${SET_DEV_ROOT[0]}")"
			local ID_FS_UUID="$(get_part_param 'ID_FS_UUID' <<< "${PART_INFO}")"

			set_global_var 'SET_DEV_SWAP' "${PART}" "${SIZE}" "${OFFSET}" "${ID_FS_UUID}"

			msg_log "swapon ${PART}"
			swapon "${FPART}"
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

	local PART_INFO="$(get_part_info "${SET_DEV_ROOT[0]}")"
	local ID_FS_TYPE="$(get_part_param 'ID_FS_TYPE' <<< "${PART_INFO}")"

	local TITLE="${TXT_PART_MAIN}"
	local HELP_TXT="$(gettext 'Точка монтирования'): \Zb\Z2\"${P_POINT}\"\Zn\n"
	HELP_TXT+="\n$(gettext 'Выберите тип')\n"

	local DEFAULT_ITEM='dev'
	local ITEMS="'dev' '$(gettext 'Раздел')'"
	ITEMS+=" 'file' '$(gettext 'Файл')'"

	case "${ID_FS_TYPE}" in
		'ext2' | 'ext3' | 'ext4')
			RETURN="$(dialog_menu "${TITLE}" "${DEFAULT_ITEM}" "${HELP_TXT}" "${ITEMS}")"
			;;
		*)
			dialog_warn \
				"\Zb\Z1$(gettext 'Раздел / (root) не отформатирован в ext2 | ext3 | ext4!!!')\Zn\n
\n$(gettext 'SWAP можно создать только на разделе.')"
			RETURN='dev'
			;;
	esac

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

part_mount_set_fstab_str()
{
	local P_POINT="${1}"
	local P_P="${2}"
	local P_DUMP="${3}"
	local P_PASS="${4}"

	local SET_DEV
	eval "SET_DEV[0]=\${${P_P}[0]}"
	eval "SET_DEV[1]=\${${P_P}[1]}"
	eval "SET_DEV[2]=\${${P_P}[2]}"
	eval "SET_DEV[3]=\${${P_P}[3]}"

	[[ ! -n "${SET_DEV[0]}" ]] && return 1

	if [[ "$(grep '^/dev/' <<< "${SET_DEV[0]}")" ]]
	then
		msg_log "UUID=${SET_DEV[3]}	${P_POINT}	${SET_DEV[2]}	${SET_DEV[1]}	${P_DUMP}	${P_PASS}" '1'
		echo -e "UUID=${SET_DEV[3]}\t${P_POINT}\t${SET_DEV[2]}\t${SET_DEV[1]}\t${P_DUMP}\t${P_PASS}"
	elif [[ "${SET_DEV[0]}" == "${SWAPFILE}" ]]
	then
		msg_log "${SET_DEV[0]}	${P_POINT}	swap	defaults	${P_DUMP}	${P_PASS}" '1'
		echo -e "${SET_DEV[0]}\t${P_POINT}\tswap\tdefaults\t${P_DUMP}\t${P_PASS}"
	else
		return 1
	fi

	return 0
}

part_unmount()
{
	local P_P="${1}"

#	if [[ "${RUN_PART}" ]]
#	then
# Размонтируем
		if [[ -n "${SET_DEV_SWAP[0]}" ]]
		then
			msg_log "swapoff ${SET_DEV_SWAP[0]}"
			if [[ "$(grep '^/dev/' <<< "${SET_DEV_SWAP[0]}")" ]]
			then
				swapoff "${SET_DEV_SWAP[0]}"
			else
				swapoff "${NS_PATH}${SET_DEV_SWAP[0]}"
				[[ -n "${P_P}" ]] && rm "${NS_PATH}${SET_DEV_SWAP[0]}"
			fi
		fi

		if [[ -n "${SET_DEV_HOME[0]}" ]]
		then
			msg_log "umount ${SET_DEV_HOME[0]}"
			umount "${SET_DEV_HOME[0]}"
		fi
		if [[ -n "${SET_DEV_EFI[0]}" ]]
		then
 			msg_log "umount ${SET_DEV_EFI[0]}"
			umount "${SET_DEV_EFI[0]}"
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
#	fi
}

#chroot /mnt/newSystem nano /etc/fstab
#/usbUsr.sfs   /usr   squashfs   ro   0 0
#chroot /mnt/newSystem mksquashfs /usr /usbUsr.sfs -b 1M -comp xz
