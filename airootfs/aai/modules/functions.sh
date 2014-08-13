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

set_global_var()
{
	local P_NAME="${1}"
	local P_VALUE="${2}"

	eval "${P_NAME}='${P_VALUE}'"

	echo "${P_NAME}='${P_VALUE}'" >> "${VAR_FILE}"
}

get_part_txt()
{
# https://github.com/karelzak/util-linux/blob/cbebd20d26b8d06e28e67a07050967668af7ce08/include/pt-mbr-partnames.h
# http://git.kernel.org/cgit/utils/util-linux/util-linux.git/tree/include/pt-mbr-partnames.h
# https://github.com/karelzak/util-linux/blob/cbebd20d26b8d06e28e67a07050967668af7ce08/libfdisk/src/gpt.c
# http://git.kernel.org/cgit/utils/util-linux/util-linux.git/tree/libfdisk/src/gpt.c
	case "${1}" in
		'0x00' | '0x0')
			echo 'Empty'
			;;
		'0x01' | '0x1')
			echo 'FAT12'
			;;
		'0x02' | '0x2')
			echo 'XENIX root'
			;;
		'0x03' | '0x3')
			echo 'XENIX usr'
			;;
		'0x04' | '0x4')
			echo 'FAT16 <32M'
			;;
		'0x05' | '0x5')
			echo 'Extended' 					# DOS 3.3+ extended partition
			;;
		'0x06' | '0x6')
			echo 'FAT16'						# DOS 16-bit >=32M
			;;
		'0x07' | '0x7')
			echo 'HPFS/NTFS/exFAT'				# OS/2 IFS, eg, HPFS or NTFS or QNX
			;;
		'0x08' | '0x8')
			echo 'AIX'							# AIX boot (AIX -- PS/2 port) or SplitDrive
			;;
		'0x09' | '0x9')
			echo 'AIX bootable'					# AIX data or Coherent
			;;
		'0x0a' | '0xa')
			echo 'OS/2 Boot Manager'			# OS/2 Boot Manager
			;;
		'0x0b' | '0xb')
			echo 'W95 FAT32'
			;;
		'0x0c' | '0xc')
			echo 'W95 FAT32 (LBA)'				#LBA really is `Extended Int 13h'
			;;
		'0x0e' | '0xe')
			echo 'W95 FAT16 (LBA)'
			;;
		'0x0f' | '0xf')
			echo 'W95 Ext`d (LBA)'
			;;
		'0x10')
			echo 'OPUS'
			;;
		'0x11')
			echo 'Hidden FAT12'
			;;
		'0x12')
			echo 'Compaq diagnostics'
			;;
		'0x14')
			echo 'Hidden FAT16 <32M'
			;;
		'0x16')
			echo 'Hidden FAT16'
			;;
		'0x17')
			echo 'Hidden HPFS/NTFS'
			;;
		'0x18')
			echo 'AST SmartSleep'
			;;
		'0x1b')
			echo 'Hidden W95 FAT32'
			;;
		'0x1c')
			echo 'Hidden W95 FAT32 (LBA)'
			;;
		'0x1e')
			echo 'Hidden W95 FAT16 (LBA)'
			;;
		'0x24')
			echo 'NEC DOS'
			;;
		'0x27')
			echo 'Hidden NTFS WinRE'
			;;
		'0x39')
			echo 'Plan 9'
			;;
		'0x3c')
			echo 'PartitionMagic recovery'
			;;
		'0x40')
			echo 'Venix 80286'
			;;
		'0x41')
			echo 'PPC PReP Boot'
			;;
		'0x42')
			echo 'SFS'
			;;
		'0x4d')
			echo 'QNX4.x'
			;;
		'0x4e')
			echo 'QNX4.x 2nd part'
			;;
		'0x4f')
			echo 'QNX4.x 3rd part'
			;;
		'0x50')
			echo 'OnTrack DM'
			;;
		'0x51')
			echo 'OnTrack DM6 Aux1'				# (or Novell)
			;;
		'0x52')
			echo 'CP/M'							# CP/M or Microport SysV/AT
			;;
		'0x53')
			echo 'OnTrack DM6 Aux3'
			;;
		'0x54')
			echo 'OnTrackDM6'
			;;
		'0x55')
			echo 'EZ-Drive'
			;;
		'0x56')
			echo 'Golden Bow'
			;;
		'0x5c')
			echo 'Priam Edisk'
			;;
		'0x61')
			echo 'SpeedStor'
			;;
		'0x63')
			echo 'GNU HURD or SysV'
			;;
		'0x64')
			echo 'Novell Netware 286'
			;;
		'0x65')
			echo 'Novell Netware 386'
			;;
		'0x70')
			echo 'DiskSecure Multi-Boot'
			;;
		'0x75')
			echo 'PC/IX'
			;;
		'0x80')
			echo 'Old Minix'					# Minix 1.4a and earlier
			;;
		'0x81')
			echo 'Minix / old Linux'			# Minix 1.4b and later
			;;
		'0x82')
			echo 'Linux swap / Solaris'
			;;
		'0x83')
			echo 'Linux'
			;;
		'0x84')
			echo 'OS/2 hidden C: drive'
			;;
		'0x85')
			echo 'Linux extended'
			;;
		'0x86')
			echo 'NTFS volume set'
			;;
		'0x87')
			echo 'NTFS volume set'
			;;
		'0x88')
			echo 'Linux plaintext'
			;;
		'0x8e')
			echo 'Linux LVM'
			;;
		'0x93')
			echo 'Amoeba'
			;;
		'0x94')
			echo 'Amoeba BBT'					# (bad block table)
			;;
		'0x9f')
			echo 'BSD/OS'						# BSDI
			;;
		'0xa0')
			echo 'IBM Thinkpad hibernation'
			;;
		'0xa5')
			echo 'FreeBSD'						# various BSD flavours
			;;
		'0xa6')
			echo 'OpenBSD'
			;;
		'0xa7')
			echo 'NeXTSTEP'
			;;
		'0xa8')
			echo 'Darwin UFS'
			;;
		'0xa9')
			echo 'NetBSD'
			;;
		'0xab')
			echo 'Darwin boot'
			;;
		'0xaf')
			echo 'HFS / HFS+'
			;;
		'0xb7')
			echo 'BSDI fs'
			;;
		'0xb8')
			echo 'BSDI swap'
			;;
		'0xbb')
			echo 'Boot Wizard hidden'
			;;
		'0xbe')
			echo 'Solaris boot'
			;;
		'0xbf')
			echo 'Solaris'
			;;
		'0xc1')
			echo 'DRDOS/sec (FAT-12)'
			;;
		'0xc4')
			echo 'DRDOS/sec (FAT-16 < 32M)'
			;;
		'0xc6')
			echo 'DRDOS/sec (FAT-16)'
			;;
		'0xc7')
			echo 'Syrinx'
			;;
		'0xda')
			echo 'Non-FS data'
			;;
		'0xdb')
			echo 'CP/M / CTOS / ...'			# CP/M or Concurrent CP/M or Concurrent DOS or CTOS
			;;
		'0xde')
			echo 'Dell Utility'					# Dell PowerEdge Server utilities
			;;
		'0xdf')
			echo 'BootIt'						# BootIt EMBRM
			;;
		'0xe1')
			echo 'DOS access'					# DOS access or SpeedStor 12-bit FAT extended partition
			;;
		'0xe3')
			echo 'DOS R/O'						# DOS R/O or SpeedStor
			;;
		'0xe4')
			echo 'SpeedStor'					# SpeedStor 16-bit FAT extended partition < 1024 cyl.
			;;
		'0xeb')
			echo 'BeOS fs'
			;;
		'0xee')
			echo 'GPT'							# Intel EFI GUID Partition Table
			;;
		'0xef')
			echo 'EFI (FAT-12/16/32)'			# Intel EFI System Partition
			;;
		'0xf0')
			echo 'Linux/PA-RISC boot'			# Linux/PA-RISC boot loader
			;;
		'0xf1')
			echo 'SpeedStor'
			;;
		'0xf4')
			echo 'SpeedStor'					# SpeedStor large partition
			;;
		'0xf2')
			echo 'DOS secondary'				# DOS 3.3+ secondary
			;;
		'0xfb')
			echo 'VMware VMFS'
			;;
		'0xfc')
			echo 'VMware VMKCORE'				# VMware kernel dump partition
			;;
		'0xfd')
			echo 'Linux raid autodetect'		# New (2.2.x) raid partition with autodetect using persistent superblock
			;;
		'0xfe')
			echo 'LANstep'						# SpeedStor >1024 cyl. or LANstep
			;;
		'0xff')
			echo 'BBT'							# Xenix Bad Block Table
			;;
		# Start with the "unused entry," which should normally appear only
		# on empty partition table entries....
		'00000000-0000-0000-0000-000000000000')
			echo 'Unused entry'
			;;

		# DOS/Windows partition types, which confusingly Linux also uses in GPT
		'ebd0a0a2-b9e5-4433-87c0-68b6b72699c7')
			echo 'Microsoft basic data'			# FAT-12
			;;
		'ebd0a0a2-b9e5-4433-87c0-68b6b72699c7')
			echo 'Microsoft basic data'			# FAT-16 < 32M
			;;
		'ebd0a0a2-b9e5-4433-87c0-68b6b72699c7')
			echo 'Microsoft basic data'			# FAT-16
			;;
		'ebd0a0a2-b9e5-4433-87c0-68b6b72699c7')
			echo 'Microsoft basic data'			# NTFS (or HPFS)
			;;
		'ebd0a0a2-b9e5-4433-87c0-68b6b72699c7')
			echo 'Microsoft basic data'			# FAT-32
			;;
		'ebd0a0a2-b9e5-4433-87c0-68b6b72699c7')
			echo 'Microsoft basic data'			# FAT-32 LBA
			;;
		'e3c9e316-0b5c-4db8-817d-f92df00215ae')
			echo 'Microsoft reserved'
			;;
		'ebd0a0a2-b9e5-4433-87c0-68b6b72699c7')
			echo 'Microsoft basic data'			# FAT-16 LBA
			;;
		'ebd0a0a2-b9e5-4433-87c0-68b6b72699c7')
			echo 'Microsoft basic data'			# Hidden FAT-12
			;;
		'ebd0a0a2-b9e5-4433-87c0-68b6b72699c7')
			echo 'Microsoft basic data'			# Hidden FAT-16 < 32M
			;;
		'ebd0a0a2-b9e5-4433-87c0-68b6b72699c7')
			echo 'Microsoft basic data'			# Hidden FAT-16
			;;
		'ebd0a0a2-b9e5-4433-87c0-68b6b72699c7')
			echo 'Microsoft basic data'			# Hidden NTFS (or HPFS)
			;;
		'ebd0a0a2-b9e5-4433-87c0-68b6b72699c7')
			echo 'Microsoft basic data'			# Hidden FAT-32
			;;
		'ebd0a0a2-b9e5-4433-87c0-68b6b72699c7')
			echo 'Microsoft basic data'			# Hidden FAT-32 LBA
			;;
		'ebd0a0a2-b9e5-4433-87c0-68b6b72699c7')
			echo 'Microsoft basic data'			# Hidden FAT-16 LBA
			;;
		'de94bba4-06d1-4d40-a16a-bfd50179d6ac')
			echo 'Windows RE'
			;;
		'af9b60a0-1431-4f62-bc68-3311714a69ad')
			echo 'Windows LDM data'				# Logical disk manager
			;;
		'5808c8aa-7e8f-42e0-85d2-e1e90434cfb3')
			echo 'Windows LDM metadata'			# Logical disk manager
			;;

		# An oddball IBM filesystem....
		'37affc90-ef7d-4e96-91c3-2d7ae055b174')
			echo 'IBM GPFS'						# General Parallel File System (GPFS)
			;;

		# ChromeOS-specific partition types...
		# Values taken from vboot_reference/firmware/lib/cgptlib/include/gpt.h in
		# ChromeOS source code, retrieved 12/23/2010. They're also at
		# http://www.chromium.org/chromium-os/chromiumos-design-docs/disk-format.
		# These have no MBR equivalents, AFAIK, so I'm using 0x7Fxx values, since they're close
		# to the Linux values.
		'fe3a2a5d-4f32-41a7-b725-accc3285a309')
			echo 'ChromeOS kernel'
			;;
		'3cb8e202-3b7e-47dd-8a3c-7ff2a13cfcec')
			echo 'ChromeOS root'
			;;
		'2e0a753d-9e48-43b0-8337-b15192cb1b5e')
			echo 'ChromeOS reserved'
			;;

		# Linux-specific partition types....
		'0657fd6d-a4ab-43c4-84e5-0933c84b4f4f')
			echo 'Linux swap'					# Linux swap (or Solaris)
			;;
		'0fc63daf-8483-4772-8e79-3d69d8477de4')
			echo 'Linux filesystem'				# Linux native
			;;
		'8da63339-0007-60c0-c436-083ac8230908')
			echo 'Linux reserved'
			;;
		'e6d6d379-f507-44c2-a23c-238f2a3df928')
			echo 'Linux LVM'
			;;

		# FreeBSD partition types....
		# Note: Rather than extract FreeBSD disklabel data, convert FreeBSD
		# partitions in-place, and let FreeBSD sort out the details....
		'516e7cb4-6ecf-11d6-8ff8-00022d09712b')
			echo 'FreeBSD disklabel'
			;;
		'83bd6b9d-7f41-11dc-be0b-001560b84f0f')
			echo 'FreeBSD boot'
			;;
		'516e7cb5-6ecf-11d6-8ff8-00022d09712b')
			echo 'FreeBSD swap'
			;;
		'516e7cb6-6ecf-11d6-8ff8-00022d09712b')
			echo 'FreeBSD UFS'
			;;
		'516e7cba-6ecf-11d6-8ff8-00022d09712b')
			echo 'FreeBSD ZFS'
			;;
		'516e7cb8-6ecf-11d6-8ff8-00022d09712b')
			echo 'FreeBSD Vinum/RAID'
			;;

		# A MacOS partition type, separated from others by NetBSD partition types...
		'55465300-0000-11aa-aa11-00306543ecac')
			echo 'Apple UFS'					# Mac OS X
			;;

		# NetBSD partition types. Note that the main entry sets it up as a
		# FreeBSD disklabel. I'm not 100% certain this is the correct behavior.
		'516e7cb4-6ecf-11d6-8ff8-00022d09712b')
			echo 'FreeBSD disklabel'			# NetBSD disklabel
			;;
		'49f48d32-b10e-11dc-b99b-0019d1879648')
			echo 'NetBSD swap'
			;;
		'49f48d5a-b10e-11dc-b99b-0019d1879648')
			echo 'NetBSD FFS'
			;;
		'49f48d82-b10e-11dc-b99b-0019d1879648')
			echo 'NetBSD LFS'
			;;
		'2db519c4-b10f-11dc-b99b-0019d1879648')
			echo 'NetBSD concatenated'
			;;
		'2db519ec-b10f-11dc-b99b-0019d1879648')
			echo 'NetBSD encrypted'
			;;
		'49f48daa-b10e-11dc-b99b-0019d1879648')
			echo 'NetBSD RAID'
			;;

		# Mac OS partition types (See also 0xa800, above)....
		'426f6f74-0000-11aa-aa11-00306543ecac')
			echo 'Apple boot'
			;;
		'48465300-0000-11aa-aa11-00306543ecac')
			echo 'Apple HFS/HFS+'
			;;
		'52414944-0000-11aa-aa11-00306543ecac')
			echo 'Apple RAID'
			;;
		'52414944-5f4f-11aa-aa11-00306543ecac')
			echo 'Apple RAID offline'
			;;
		'4c616265-6c00-11aa-aa11-00306543ecac')
			echo 'Apple label'
			;;
		'5265636f-7665-11aa-aa11-00306543ecac')
			echo 'AppleTV recovery'
			;;
		'53746f72-6167-11aa-aa11-00306543ecac')
			echo 'Apple Core Storage'
			;;

		# Solaris partition types (one of which is shared with MacOS)
		'6a82cb45-1dd2-11b2-99a6-080020736631')
			echo 'Solaris boot'
			;;
		'6a85cf4d-1dd2-11b2-99a6-080020736631')
			echo 'Solaris root'
			;;
		'6a898cc3-1dd2-11b2-99a6-080020736631')
			echo 'Solaris /usr & Mac ZFS'		# Solaris/MacOS
			;;
		'6a87c46f-1dd2-11b2-99a6-080020736631')
			echo 'Solaris swap'
			;;
		'6a8b642b-1dd2-11b2-99a6-080020736631')
			echo 'Solaris backup'
			;;
		'6a8ef2e9-1dd2-11b2-99a6-080020736631')
			echo 'Solaris /var'
			;;
		'6a90ba39-1dd2-11b2-99a6-080020736631')
			echo 'Solaris /home'
			;;
		'6a9283a5-1dd2-11b2-99a6-080020736631')
			echo 'Solaris alternate sector'
			;;
		'6a945a3b-1dd2-11b2-99a6-080020736631')
			echo 'Solaris Reserved 1'
			;;
		'6a9630d1-1dd2-11b2-99a6-080020736631')
			echo 'Solaris Reserved 2'
			;;
		'6a980767-1dd2-11b2-99a6-080020736631')
			echo 'Solaris Reserved 3'
			;;
		'6a96237f-1dd2-11b2-99a6-080020736631')
			echo 'Solaris Reserved 4'
			;;
		'6a8d2ac7-1dd2-11b2-99a6-080020736631')
			echo 'Solaris Reserved 5'
			;;

		# I can find no MBR equivalents for these, but they're on the
		# Wikipedia page for GPT, so here we go....
		'75894c1e-3aeb-11d3-b7c1-7b03a0000000')
			echo 'HP-UX data'
			;;
		'e2a1e728-32e3-11d6-a682-7b03a0000000')
			echo 'HP-UX service'
			;;

		# EFI system and related partitions
		'c12a7328-f81f-11d2-ba4b-00a0c93ec93b')
			echo 'EFI System'					# Parted identifies these as having the "boot flag" set
			;;
		'024dee41-33e7-11d3-9d69-0008c781f39f')
			echo 'MBR partition scheme'			# Used to nest MBR in GPT
			;;
		'21686148-6449-6e6f-744e-656564454649')
			echo 'BIOS boot partition'			# Boot loader
			;;

		# A straggler Linux partition type....
		'a19d880f-05fc-4d3b-a006-743f0f84911e')
			echo 'Linux RAID'
			;;
		*)
		# Note: DO NOT use the 0xffff code; that's reserved to indicate an
		# unknown GUID type code.
			echo "${1}"
			;;
	esac
}

get_part_param()
{
	sed -n "/^${1}=/{s/^${1}=//; p}" | sed "s/'//g"
}

get_part_info()
{
	local TEMP

	local NAME
	local MOUNTPOINT
	local RM
	local SIZE
	local ROTA
	local TRAN

	local ID_PART_ENTRY_TYPE
	local PART_TABLE_TYPE_NAME

	local ID_PART_ENTRY_NAME
	local ID_FS_LABEL

	lsblk -ndaro NAME,MOUNTPOINT,RM,SIZE,ROTA,TRAN "${1}" | tr ' ' '\r' |
	while IFS=$'\r' read -r NAME MOUNTPOINT RM SIZE ROTA TRAN
	do
		[[ -n "${NAME}" ]] && echo -e "NAME='${NAME}'"
		[[ -n "${MOUNTPOINT}" ]] && echo -e "MOUNTPOINT='${MOUNTPOINT}'"
		[[ -n "${RM}" ]] && echo -e "RM='${RM}'"
		[[ -n "${SIZE}" ]] && echo -e "SIZE='${SIZE}'"
		[[ -n "${ROTA}" ]] && echo -e "ROTA='${ROTA}'"
		[[ -n "${TRAN}" ]] && echo -e "TRAN='${TRAN}'"

		TEMP="$(udevadm info --query=property -x --name="${NAME}")"
		TEMP="$(echo -e "${TEMP}" | sed '
s/ \{1,\}/ /g;
s/^[ \t]*//;
s/[ \t]*$//;
')"

		ID_PART_ENTRY_TYPE="$(get_part_param 'ID_PART_ENTRY_TYPE' <<< "${TEMP}")"
		PART_TABLE_TYPE_NAME="$(get_part_txt "${ID_PART_ENTRY_TYPE}")"
		[[ -n "${PART_TABLE_TYPE_NAME}" ]] && echo "PART_TABLE_TYPE_NAME='${PART_TABLE_TYPE_NAME}'"

#		ID_FS_LABEL="$(get_part_param 'ID_FS_LABEL' <<< "${TEMP}")"
#		if [[ ! -n "${ID_FS_LABEL}" ]]
#		then
#			ID_PART_ENTRY_NAME="$(get_part_param 'ID_PART_ENTRY_NAME' <<< "${TEMP}")"
#			ID_FS_LABEL="${ID_PART_ENTRY_NAME}"
#			[[ -n "${ID_FS_LABEL}" ]] && echo "ID_FS_LABEL='${ID_PART_ENTRY_NAME}'"
#		fi

		echo "${TEMP}"
	done
}
