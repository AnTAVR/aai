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

# Каталог по умолчанию куда будет монтироваться новая система для установки
# @todo Нужно доделать!!!
NS_PATH='/tmp/newsys'


# общие функции
chroot_mount()
{
	msg_log 'chroot_mount'

	if [[ ! -d "${NS_PATH}/tmp" ]]
	then
		mkdir -p "${NS_PATH}/"{dev,run,proc,sys,tmp}
		chmod 1777 "${NS_PATH}/tmp"
	fi

	local I
	for I in dev run proc sys
	do
		mount --bind /${I} "${NS_PATH}/${I}"
	done

	mkdir -p "${NS_PATH}/run/lock"

	trap 'chroot_umount' EXIT HUP INT TERM
}

chroot_umount()
{
	msg_log 'chroot_umount'

	rm -rf "${NS_PATH}"/tmp/*

	local I
	for I in sys proc run dev
	do
		umount "${NS_PATH}/${I}"
	done

	trap - EXIT HUP INT TERM
}

chroot_run()
{
	local P_CMD="${*}"

	local RET

	chroot_mount

	msg_log "${P_CMD}"
	eval chroot ${NS_PATH} ${P_CMD}
	RET=${?}

	chroot_umount
	return ${RET}
}

msg_info()
{
	local P_MSG="${1}"

	echo -e "${BLDGRN}[${SCRNAME}] INFO: ${P_MSG}${TXTRST}"
	echo '' >&2
	echo "[${SCRNAME}] INFO ($(date +%Y-%m-%d-%T,%N)): ${P_MSG}" >&2
}

msg_log()
{
	local P_MSG="${1}"
	local P_NO_ECHO=${2}

	[[ ! ${P_NO_ECHO} ]] && echo -e "${BLDYLW}[${SCRNAME}] LOG: ${P_MSG}${TXTRST}"
	echo '' >&2
	echo "[${SCRNAME}] LOG ($(date +%Y-%m-%d-%T,%N)): ${P_MSG}" >&2
}

msg_error()
{
	local P_MSG="${1}"
	local P_ERROR=${2}
	local P_EXIT=1

	local TEMP='WARNING'

	[[ ${3} ]] && P_EXIT=

	[[ ${P_ERROR} -gt 0 ]] && TEMP='ERROR'

	echo -e "${BLDRED}[${SCRNAME}] ${TEMP} <${P_ERROR}>: ${P_MSG}${TXTRST}"
	echo '' >&2
	echo "[${SCRNAME}] ${TEMP} <${P_ERROR}> ($(date +%Y-%m-%d-%T,%N)): ${P_MSG}" >&2

	[[ ${P_ERROR} -gt 0 ]] && [[ ${P_EXIT} ]] && run_exit ${P_ERROR}
}

pacman_install()
{
	local P_PACS="${1}"
	local P_INCHROOTC="${2}"
	local P_NO_EXIT="${3}"

	local RET

# Создаем нужные папки для pacman и папку для сохранения бекапов и кеша пакетов
	[[ ! -d "${NS_PATH}/var/cache/pacman" ]] && mkdir -p "${NS_PATH}/var/"{cache/pacman/pkg,lib/pacman}

	case "${P_INCHROOTC}" in
		'nochroot')
			chroot_mount
			msg_log "pacman ${P_PACS}"
			pacman \
				--root "${NS_PATH}/" \
				--dbpath "${NS_PATH}/var/lib/pacman/" \
				--cachedir "${NS_PATH}/var/cache/pacman/pkg/" \
				--noconfirm \
				${P_PACS}
			RET=${?}
			chroot_umount
			pacman_install_err "${RET}" "${P_PACS}" "${P_NO_EXIT}"
			;;
		'yaourt')
			chroot_run yaourt --noconfirm --needed ${P_PACS}
			RET=${?}
			msg_error "$(gettext 'Предупреждение yaourt! Смотрите подробнее в') ${LOG_FILE}" ${RET} 1
			rm -rf "${NS_PATH}/tmp/yaourt-tmp-root"
			;;
		'noneeded')
			chroot_run pacman --noconfirm ${P_PACS}
			RET=${?}
			pacman_install_err "${RET}" "${P_PACS}" "${P_NO_EXIT}"
			;;
		*)
			chroot_run pacman --noconfirm --needed ${P_PACS}
			RET=${?}
			pacman_install_err "${RET}" "${P_PACS}" "${P_NO_EXIT}"
			;;
	esac

	return ${RET}
}

pacman_install_err()
{
	local P_RET="${1}"
	local P_PACS="${2}"
	local P_NO_EXIT="${3}"

	local TXT="$(gettext 'Ошибка') #${P_RET} pacman ${P_PACS} ! $(gettext 'Смотрите подробнее в') ${LOG_FILE}"

	if [[ "${P_RET}" != '0' ]]
	then
		
		if [[ ! ${P_NO_EXIT} ]]
		then
			dialog_yesno \
				"pacman" \
				"\Zb\Z1${TXT}\Zn\n\n$(gettext 'Продолжить установку?')" \
				'--defaultno'

			case "${?}" in
				'0') #Yes
					msg_error "${TXT}" ${P_RET} 1
					;;
				*) #No
					msg_info "$(gettext 'Не гневись ВЛАДЫКА. Это не Я...')"
					msg_error "${TXT}" ${P_RET}
					;;
			esac
		else
			msg_log "${TXT}"
		fi
	fi
}

# Сохраняем изменения в git репозиторий /etc/
git_commit()
{
	chroot_run bash -c "'cd /etc; git add -A; git commit -m $(date +%Y-%m-%d-%H%M%S%N)'"
}

get_parts()
{
	local TEMP

	local I386_SYS_TYPES=(
		['0x00']='Empty'
		['0x01']='FAT12'
		['0x02']='XENIX root'
		['0x03']='XENIX usr'
		['0x04']='FAT16 <32M'
		['0x05']='Extended'
		['0x06']='FAT16'
		['0x07']='HPFS/NTFS/exFAT'
		['0x08']='AIX'
		['0x09']='AIX bootable'
		['0x0a']='OS/2 Boot Manager'
		['0x0b']='W95 FAT32'
		['0x0c']='W95 FAT32 (LBA)'
		['0x0e']='W95 FAT16 (LBA)'
		['0x0f']='W95 Ext`d (LBA)'
		['0x10']='OPUS'
		['0x11']='Hidden FAT12'
		['0x12']='Compaq diagnostics'
		['0x14']='Hidden FAT16 <32M'
		['0x16']='Hidden FAT16'
		['0x17']='Hidden HPFS/NTFS'
		['0x18']='AST SmartSleep'
		['0x1b']='Hidden W95 FAT32'
		['0x1c']='Hidden W95 FAT32 (LBA)'
		['0x1e']='Hidden W95 FAT16 (LBA)'
		['0x24']='NEC DOS'
		['0x27']='Hidden NTFS WinRE'
		['0x39']='Plan 9'
		['0x3c']='PartitionMagic recovery'
		['0x40']='Venix 80286'
		['0x41']='PPC PReP Boot'
		['0x42']='SFS'
		['0x4d']='QNX4.x'
		['0x4e']='QNX4.x 2nd part'
		['0x4f']='QNX4.x 3rd part'
		['0x50']='OnTrack DM'
		['0x51']='OnTrack DM6 Aux1'
		['0x52']='CP/M'
		['0x53']='OnTrack DM6 Aux3'
		['0x54']='OnTrackDM6'
		['0x55']='EZ-Drive'
		['0x56']='Golden Bow'
		['0x5c']='Priam Edisk'
		['0x61']='SpeedStor'
		['0x63']='GNU HURD or SysV'
		['0x64']='Novell Netware 286'
		['0x65']='Novell Netware 386'
		['0x70']='DiskSecure Multi-Boot'
		['0x75']='PC/IX'
		['0x80']='Old Minix'
		['0x81']='Minix / old Linux'
		['0x82']='Linux swap / Solaris'
		['0x83']='Linux'
		['0x84']='OS/2 hidden C: drive'
		['0x85']='Linux extended'
		['0x86']='NTFS volume set'
		['0x87']='NTFS volume set'
		['0x88']='Linux plaintext'
		['0x8e']='Linux LVM'
		['0x93']='Amoeba'
		['0x94']='Amoeba BBT'
		['0x9f']='BSD/OS'
		['0xa0']='IBM Thinkpad hibernation'
		['0xa5']='FreeBSD'
		['0xa6']='OpenBSD'
		['0xa7']='NeXTSTEP'
		['0xa8']='Darwin UFS'
		['0xa9']='NetBSD'
		['0xab']='Darwin boot'
		['0xaf']='HFS / HFS+'
		['0xb7']='BSDI fs'
		['0xb8']='BSDI swap'
		['0xbb']='Boot Wizard hidden'
		['0xbe']='Solaris boot'
		['0xbf']='Solaris'
		['0xc1']='DRDOS/sec (FAT-12)'
		['0xc4']='DRDOS/sec (FAT-16 < 32M)'
		['0xc6']='DRDOS/sec (FAT-16)'
		['0xc7']='Syrinx'
		['0xda']='Non-FS data'
		['0xdb']='CP/M / CTOS / ...'
		['0xde']='Dell Utility'
		['0xdf']='BootIt'
		['0xe1']='DOS access'
		['0xe3']='DOS R/O'
		['0xe4']='SpeedStor'
		['0xeb']='BeOS fs'
		['0xee']='GPT'
		['0xef']='EFI (FAT-12/16/32)'
		['0xf0']='Linux/PA-RISC boot'
		['0xf1']='SpeedStor'
		['0xf4']='SpeedStor'
		['0xf2']='DOS secondary'
		['0xfb']='VMware VMFS'
		['0xfc']='VMware VMKCORE'
		['0xfd']='Linux raid autodetect'
		['0xfe']='LANstep'
		['0xff']='BBT'
	)
	echo -e "DEVNAME\tID_PART_ENTRY_FLAGS\tMOUNT\tID_FS_TYPE\tID_FS_LABEL\tBLOCKS\tID_PART_ENTRY_TYPE\tTYPE\tID_SERIAL"
	sed '1,2d' /proc/partitions |
	while read TEMP
	do
		NAME=
		BLOCKS=

		eval "$(awk '{print "BLOCKS=" $3 "; NAME=" $4}' <<< "${TEMP}")"
		TEMP="$(udevadm info --query=property --name="${NAME}")"

		DEVNAME="$(sed -n '/^DEVNAME=/{s/^DEVNAME=//; p}' <<< "${TEMP}")"
		[ ! "${DEVNAME}" ] && DEVNAME='-'

		ID_FS_TYPE="$(sed -n '/^ID_FS_TYPE=/{s/^ID_FS_TYPE=//; p}' <<< "${TEMP}")"
		[ ! "${ID_FS_TYPE}" ] && ID_FS_TYPE='-'

		ID_FS_LABEL="$(sed -n '/^ID_FS_LABEL=/{s/^ID_FS_LABEL=//; p}' <<< "${TEMP}")"
		[ ! "${ID_FS_LABEL}" ] && ID_FS_LABEL='-'

		ID_MODEL="$(sed -n '/^ID_MODEL=/{s/^ID_MODEL=//; p}' <<< "${TEMP}")"
		[ ! "${ID_MODEL}" ] && ID_MODEL='-'

		ID_PART_ENTRY_FLAGS="$(sed -n '/^ID_PART_ENTRY_FLAGS=/{s/^ID_PART_ENTRY_FLAGS=//; p}' <<< "${TEMP}")"
		[ ! "${ID_PART_ENTRY_FLAGS}" ] && ID_PART_ENTRY_FLAGS='-'

		ID_SERIAL="$(sed -n '/^ID_SERIAL=/{s/^ID_SERIAL=//; p}' <<< "${TEMP}")"
		[ ! "${ID_SERIAL}" ] && ID_SERIAL='-'

		ID_PART_ENTRY_TYPE="$(sed -n '/^ID_PART_ENTRY_TYPE=/{s/^ID_PART_ENTRY_TYPE=//; p}' <<< "${TEMP}")"
		if [ ! "${ID_PART_ENTRY_TYPE}" ]
		then
			ID_PART_ENTRY_TYPE='-'
			TYPE='-'
		else
			TYPE="${I386_SYS_TYPES[${ID_PART_ENTRY_TYPE}]}"
		fi

		if [ ! "${TYPE}" ]
		then
			TYPE='-'
		fi

	
		if [ "${ID_PART_ENTRY_TYPE}" == '0x82' ]
		then
			MOUNT="$(swapon -s | grep "^${DEVNAME} ")"
		else
			MOUNT="$(mount | grep "^${DEVNAME} ")"
		fi

		if [ ! "${MOUNT}" ]
		then
			MOUNT='-'
		else
			MOUNT='*'
		fi

		[ "${ID_PART_ENTRY_FLAGS}" == '0x80' ] && ID_PART_ENTRY_FLAGS='*'

		echo -e "${DEVNAME}\t${ID_PART_ENTRY_FLAGS}\t${MOUNT}\t${ID_FS_TYPE}\t${ID_FS_LABEL}\t${BLOCKS}\t${ID_PART_ENTRY_TYPE}\t${TYPE}\t${ID_SERIAL}"
	done
}

set_global_var()
{
	local P_NAME="${1}"
	local P_VALUE="${2}"

	eval "${P_NAME}='${P_VALUE}'"

	echo "${P_NAME}='${P_VALUE}'" >> "${VAR_FILE}"
}
