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
MAIN_CASE+=('xorg')

#===============================================================================
# Сигнальная переменная успешного завершения функции модуля,
# может потребоваться для других модулей, для установки кода завершения
RUN_XORG=
TXT_XORG_MAIN="$(gettext 'Xorg')"

# Выбранный драйвер
SET_VIDEO=
# Разрешение Xorg
SET_XORG_XxYxD=
#===============================================================================

# Выводим строку пункта главного меню
str_xorg()
{
	local TEMP

	[[ "${RUN_XORG}" ]] && TEMP="\Zb\Z2($(gettext 'ВЫПОЛНЕНО'))\Zn"
	echo "${TXT_XORG_MAIN} (~905M+) ${TEMP}"
}

# Функция выполнения из главного меню
run_xorg()
{
	local VIDEO
	local XORG_XxYxD
	local INPUTS
	local APPS

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

		if [[ "${RUN_XORG}" ]]
		then
			dialog_warn \
				"\Zb\Z1$(gettext 'Пункт') \"${TXT_XORG_MAIN}\" $(gettext 'уже выполнен')\Zn"
			return 1
		fi

	fi

	while true
	do
		TEMP="$(xorg_dialog_video "${VIDEO}")"
		[[ ! -n "${TEMP}" ]] && return 1
		VIDEO="${TEMP}"

		TEMP="$(xorg_dialog_xorg "${XORG_XxYxD}")"
		[[ ! -n "${TEMP}" ]] && return 1
		XORG_XxYxD="${TEMP}"

		INPUTS="$(xorg_dialog_inputs)"
		APPS="$(xorg_dialog_apps)"
		
		dialog_yesno \
			"$(gettext 'Подтвердите свой выбор')" \
			"
\Zb\Z7VIDEO=\Zn${VIDEO}\n
\Zb\Z7XORG_XxYxD=\Zn${XORG_XxYxD}\n
\Zb\Z7INPUTS=\Zn${INPUTS}\n
\Zb\Z7APPS=\Zn${APPS}\n
" \
			'--defaultno'
		case "${?}" in
			'0') #Yes
# Устанавливаем выбранные переменные в глобальные
				set_global_var 'SET_VIDEO' "${VIDEO}"
				set_global_var 'SET_XORG_XxYxD' "${XORG_XxYxD}"


				xorg_mesa

				xorg_xorg

				xorg_video

				for PKG in ${INPUTS}
				do
					pacman_install "-S ${PKG}"
				done

				for PKG in ${APPS}
				do
					pacman_install "-S ${PKG}"
				done

				RUN_XORG=1
				return 0
				;;
		esac
	done
}

xorg_dialog_inputs()
{
	msg_log "$(gettext 'Запуск диалога'): \"${FUNCNAME}$(for ((TEMP=1; TEMP<=${#}; TEMP++)); do echo -n " \$${TEMP}='$(eval "echo \"\${${TEMP}}\"")'"; done)\"" 'noecho'

	local RETURN

	local TITLE="${TXT_PKGS_MAIN}"
	local HELP_TXT="\n$(gettext 'Выберите дополнительные драйвера для XORG')\n"

	local ITEMS=
	#extra
	ITEMS+=" 'xf86-input-joystick' '-' 'off'"
	ITEMS+=" 'xf86-input-keyboard' '-' 'off'"
	ITEMS+=" 'xf86-input-mouse' '-' 'off'"
	ITEMS+=" 'xf86-input-synaptics' '-' 'off'"
	ITEMS+=" 'xf86-input-vmmouse' '-' 'off'"
	ITEMS+=" 'xf86-input-void' '-' 'off'"

	RETURN="$(dialog_checklist "${TITLE}" "${HELP_TXT}" "${ITEMS}" "--cancel-label '${TXT_MAIN_MENU}'")"

	echo "${RETURN}"
	msg_log "$(gettext 'Выход из диалога'): \"${FUNCNAME} return='${RETURN}'\"" 'noecho'
}

xorg_dialog_apps()
{
	msg_log "$(gettext 'Запуск диалога'): \"${FUNCNAME}$(for ((TEMP=1; TEMP<=${#}; TEMP++)); do echo -n " \$${TEMP}='$(eval "echo \"\${${TEMP}}\"")'"; done)\"" 'noecho'

	local RETURN

	local TITLE="${TXT_PKGS_MAIN}"
	local HELP_TXT="\n$(gettext 'Выберите дополнительные утилиты для XORG')\n"

	local ITEMS=
	#extra
	ITEMS+=" 'xorg-bdftopcf' '-' 'off'"
	ITEMS+=" 'xorg-luit' '-' 'off'"
	ITEMS+=" 'xorg-mkfontdir' '-' 'off'"
	ITEMS+=" 'xorg-mkfontscale' '-' 'off'"
	ITEMS+=" 'xorg-setxkbmap' '-' 'off'"
	ITEMS+=" 'xorg-smproxy' '-' 'off'"
	ITEMS+=" 'xorg-x11perf' '-' 'off'"
	ITEMS+=" 'xorg-xauth' '-' 'off'"
	ITEMS+=" 'xorg-xcursorgen' '-' 'off'"
	ITEMS+=" 'xorg-xdpyinfo' '-' 'off'"
	ITEMS+=" 'xorg-xdriinfo' '-' 'off'"
	ITEMS+=" 'xorg-xev' '-' 'off'"
	ITEMS+=" 'xorg-xkbcomp' '-' 'off'"
	ITEMS+=" 'xorg-xkbevd' '-' 'off'"
	ITEMS+=" 'xorg-xkbutils' '-' 'off'"
	ITEMS+=" 'xorg-xkill' '-' 'off'"
	ITEMS+=" 'xorg-xlsatoms' '-' 'off'"
	ITEMS+=" 'xorg-xlsclients' '-' 'off'"
	ITEMS+=" 'xorg-xpr' '-' 'off'"
	ITEMS+=" 'xorg-xprop' '-' 'off'"
	ITEMS+=" 'xorg-xvinfo' '-' 'off'"
	ITEMS+=" 'xorg-xwd' '-' 'off'"
	ITEMS+=" 'xorg-xwininfo' '-' 'off'"
	ITEMS+=" 'xorg-xwud' '-' 'off'"

	RETURN="$(dialog_checklist "${TITLE}" "${HELP_TXT}" "${ITEMS}" "--cancel-label '${TXT_MAIN_MENU}'")"

	echo "${RETURN}"
	msg_log "$(gettext 'Выход из диалога'): \"${FUNCNAME} return='${RETURN}'\"" 'noecho'
}

xorg_dialog_video()
{
	msg_log "$(gettext 'Запуск диалога'): \"${FUNCNAME}$(for ((TEMP=1; TEMP<=${#}; TEMP++)); do echo -n " \$${TEMP}='$(eval "echo \"\${${TEMP}}\"")'"; done)\"" 'noecho'

	local RETURN

	local P_VID="${1}"

	local TITLE="${TXT_VIDEO_MAIN}"
	local HELP_TXT="\n$(gettext 'Выберите видео драйвер для установки')\n"
	HELP_TXT+="$(gettext 'По умолчанию'):"

	local DEFAULT_ITEM=$(xorg_video_drv)
	local ITEMS="'nvidia' 'NVIDIA'"
	ITEMS+=" 'nvidia304' 'NVIDIA 304xx'"
	ITEMS+=" 'optimus' 'Bumblebee NVIDIA Optimus'"
#	ITEMS+=" 'nvidia173' 'NVIDIA 173xx \Zb\Z3($(gettext 'Пока не поддерживается'))\Zn'"
#	ITEMS+=" 'nvidia96' 'NVIDIA 96xx \Zb\Z3($(gettext 'Пока не поддерживается'))\Zn'"
	ITEMS+=" 'catalyst' 'ATI Catalyst'"
	ITEMS+=" 'innotek' 'VirtualBox Graphics Adapter'"

	ITEMS+=" 'xf86-video-vesa' 'FREE'"
	ITEMS+=" 'xf86-video-intel' 'FREE Intel'"
	ITEMS+=" 'xf86-video-nouveau' 'FREE Nvidia'"
	ITEMS+=" 'xf86-video-ati' 'FREE 'Ati"

	ITEMS+=" 'xf86-video-ark' 'FREE'"
	ITEMS+=" 'xf86-video-ast' 'FREE'"
	ITEMS+=" 'xf86-video-cirrus' 'FREE'"
	ITEMS+=" 'xf86-video-dummy' 'FREE'"
	ITEMS+=" 'xf86-video-fbdev' 'FREE'"
	ITEMS+=" 'xf86-video-glint' 'FREE'"
	ITEMS+=" 'xf86-video-i128' 'FREE'"
	ITEMS+=" 'xf86-video-mach64' 'FREE'"
	ITEMS+=" 'xf86-video-mga' 'FREE'"
	ITEMS+=" 'xf86-video-modesetting' 'FREE'"
	ITEMS+=" 'xf86-video-neomagic' 'FREE'"
	ITEMS+=" 'xf86-video-nv' 'FREE'"
	ITEMS+=" 'xf86-video-openchrome' 'FREE'"
	ITEMS+=" 'xf86-video-r128' 'FREE'"
	ITEMS+=" 'xf86-video-savage' 'FREE'"
	ITEMS+=" 'xf86-video-siliconmotion' 'FREE'"
	ITEMS+=" 'xf86-video-sis' 'FREE'"
	ITEMS+=" 'xf86-video-tdfx' 'FREE'"
	ITEMS+=" 'xf86-video-trident' 'FREE'"
	ITEMS+=" 'xf86-video-v4l' 'FREE'"
	ITEMS+=" 'xf86-video-vmware' 'FREE'"
	ITEMS+=" 'xf86-video-voodoo' 'FREE'"

	HELP_TXT+=" \Zb\Z7\"${DEFAULT_ITEM}\"\Zn\n"

	RETURN="$(dialog_menu "${TITLE}" "${DEFAULT_ITEM}" "${HELP_TXT}" "${ITEMS}" "--cancel-label '${TXT_MAIN_MENU}'")"

	echo "${RETURN}"
	msg_log "$(gettext 'Выход из диалога'): \"${FUNCNAME} return='${RETURN}'\"" 'noecho'
}

xorg_dialog_xorg()
{
	msg_log "$(gettext 'Запуск диалога'): \"${FUNCNAME}$(for ((TEMP=1; TEMP<=${#}; TEMP++)); do echo -n " \$${TEMP}='$(eval "echo \"\${${TEMP}}\"")'"; done)\"" 'noecho'

	local RETURN

	local TITLE="${TXT_XORG_MAIN}"
	local HELP_TXT="\n$(gettext 'Выберите разрешение экрана для Xorg')\n"
	HELP_TXT+="$(gettext 'По умолчанию'):"

	local DEFAULT_ITEM='1280x1024x24'
	local ITEMS="$(hwinfo --framebuffer | grep ' Mode ' |  awk -F ' ' '{print sq $3 "x" $5 sq " " sq $0 sq}' sq=\')"
	[[ ! -n "${ITEMS}" ]] && ITEMS="
'640x480x8' '-' '800x600x8' '-' '1024x768x8' '-' '1280x1024x8' '-'
'640x480x16' '-' '800x600x16' '-' '1024x768x16' '-' '1280x1024x16' '-'
'640x480x24' '-' '800x600x24' '-' '1024x768x24' '-' '1280x1024x24' '-'
"
	HELP_TXT+=" \Zb\Z7\"${DEFAULT_ITEM}\"\Zn\n"

	RETURN="$(dialog_menu "${TITLE}" "${DEFAULT_ITEM}" "${HELP_TXT}" "${ITEMS}")"

	echo "${RETURN}"
	msg_log "$(gettext 'Выход из диалога'): \"${FUNCNAME} return='${RETURN}'\"" 'noecho'
}

xorg_xorg()
{
#===============================================================================
# Устанавливаем xorg
#===============================================================================
	#extra
#xorg
	pacman_install "-S xorg-server"
#xorg-server-utils
	pacman_install "-S xorg-iceauth"
	pacman_install "-S xorg-sessreg"
	pacman_install "-S xorg-xbacklight"
	pacman_install "-S xorg-xcmsdb"
	pacman_install "-S xorg-xgamma"
	pacman_install "-S xorg-xhost"
	pacman_install "-S xorg-xinput"
	pacman_install "-S xorg-xmodmap"
	pacman_install "-S xorg-xrandr"
	pacman_install "-S xorg-xrdb"
	pacman_install "-S xorg-xrefresh"
	pacman_install "-S xorg-xset"
	pacman_install "-S xorg-xsetroot"
#xorg-fonts
	pacman_install "-S font-misc-ethiopic"
	pacman_install "-S xorg-font-util"
	pacman_install "-S xorg-fonts-encodings"

	pacman_install "-S xorg-xinit"
	pacman_install "-S xdg-user-dirs"
	pacman_install "-S xdg-utils"

 #xorg
#	pacman_install "-S xorg-docs"
	pacman_install "-S xorg-fonts-100dpi"
	pacman_install "-S xorg-fonts-75dpi"

	pacman_install "-S ttf-dejavu"
	pacman_install "-S ttf-freefont"
	pacman_install "-S ttf-linux-libertine"
	pacman_install "-S ttf-bitstream-vera"

	pacman_install "-S xscreensaver"

	#community
	pacman_install "-S ttf-liberation"
	pacman_install "-S ttf-droid"

	pacman_install "-S xcursor-vanilla-dmz"
	#aur
#	pacman_install "-S ttf-ms-fonts" 'yaourt'
#	pacman_install "-S ttf-vista-fonts" 'yaourt'

	#extra
	pacman_install "-S gstreamer0.10-plugins"
	pacman_install "-S phonon-gstreamer"
	pacman_install "-S tk" #для git
	pacman_install "-S fltk" #для alsa-tools
	pacman_install "-S gtk2"
	pacman_install "-S gtk3"
	pacman_install "-S qt4"
#	pacman_install "-S qt5"
	pacman_install "-S wxgtk2.8" #для p7zip

	git_commit

	xorg_xterm

	msg_log "$(gettext 'Добавляю') alias startx > /etc/skel/.zshrc"
	echo 'which startx 2>&1 > /dev/null && alias startx="startx &> ~/.xlog"' >> "${NS_PATH}/etc/skel/.zshrc"
	cat "${NS_PATH}/etc/skel/.zshrc" > "${NS_PATH}/root/.zshrc"
#-------------------------------------------------------------------------------



#===============================================================================
# Настраиваем раскладку в Xorg
#===============================================================================
	mkdir -p "${NS_PATH}/etc/X11/xorg.conf.d/"

	local XOPTIONS="$(grep "[[:space:]]${SET_KEYMAP}[[:space:]]" "${DBDIR}keymaps.db")"
	local XLAYOUT="$(awk '{print $3}' <<< "${XOPTIONS}")"
	local XMODEL="$(awk '{print $4}' <<< "${XOPTIONS}")"
	local XVARIANT="$(awk '{print $5}' <<< "${XOPTIONS}")"
	XOPTIONS="$(awk '{print $6}' <<< "${XOPTIONS}")"

	msg_log "$(gettext 'Настраиваю') /etc/X11/xorg.conf.d/00-keyboard.conf"

	local TEMP_XLAYOUT='#'
	[[ "${XLAYOUT}" ]] && TEMP_XLAYOUT=
	local TEMP_XMODEL='#'
	[[ "${XMODEL}" ]] && TEMP_XMODEL=
	local TEMP_XVARIANT='#'
	[[ "${XVARIANT}" ]] && TEMP_XVARIANT=
	local TEMP_XOPTIONS='#'
	[[ "${XOPTIONS}" ]] && TEMP_XOPTIONS=

	echo "
Section	\"InputClass\"
    Identifier         \"system-keyboard\"
    MatchIsKeyboard    \"on\"
${TEMP_XLAYOUT}    Option             \"XkbLayout\" \"${XLAYOUT}\"
${TEMP_XMODEL}    Option             \"XkbModel\" \"${XMODEL}\"
${TEMP_XVARIANT}    Option             \"XkbVariant\" \"${XVARIANT}\"
${TEMP_XOPTIONS}    Option             \"XkbOptions\" \"${XOPTIONS}\"
EndSection
" > "${NS_PATH}/etc/X11/xorg.conf.d/00-keyboard.conf"
#  chroot_run localectl --no-convert set-x11-keymap "${XLAYOUT}" "${XMODEL}" "${XVARIANT}" "${XOPTIONS}"
#-------------------------------------------------------------------------------
	git_commit
}

xorg_xterm()
{
	pacman_install "-S xterm"

	git_commit

	msg_log "$(gettext 'Настраиваю') /etc/skel/.Xresources"
	echo "
xterm*termName: xterm-256color
xterm*bellIsUrgent: true
xterm*renderFont: true
xterm*borderWidth: 0
xterm*utf8Title: true

xterm*faceName: Monospase
xterm*faceSize: 9
xterm*foreground: lightgray
xterm*cursorColor: green
xterm*background: black
xterm*saveLines: 1000

xterm*rightScrollBar: True
xterm*scrollBar: True
xterm*geometry: 105x35
" >> "${NS_PATH}/etc/skel/.Xresources"

	git_commit
}

xorg_video()
{
	local DRIVER

	case "${SET_VIDEO}" in
		'nvidia')
			pacman_install "-Rdds mesa-libgl" 'noneeded' 'noexit'
			pacman_install "-Rdds lib32-mesa-libgl" 'noneeded' 'noexit'

			#aur
#			pacman_install "-S nvidia-dkms" 'yaourt'
			#extra
			pacman_install "-S nvidia"
			[[ "${SET_LTS}" ]] && pacman_install "-S nvidia-lts"
			pacman_install "-S nvidia-utils"
#			pacman_install "-S opencl-nvidia"
			#multilib
			pacman_install "-S lib32-nvidia-utils" 'yaourt'
#			pacman_install "-S lib32-opencl-nvidia" 'yaourt'

			pacman_install "-Rnsc ati-dri intel-dri nouveau-dri" 'noneeded' 'noexit'
			;;
		'nvidia304')
			pacman_install "-Rdds mesa-libgl" 'noneeded' 'noexit'
			pacman_install "-Rdds lib32-mesa-libgl" 'noneeded' 'noexit'

			#extra
			pacman_install "-S nvidia-304xx"
			[[ "${SET_LTS}" ]] && pacman_install "-S nvidia-304xx-lts"
			pacman_install "-S nvidia-304xx-utils"
#			pacman_install "-S opencl-nvidia-304xx"
			#multilib
			pacman_install "-S lib32-nvidia-304xx-utils" 'yaourt'
#			pacman_install "-S lib32-opencl-nvidia-304xx" 'yaourt'

			pacman_install "-Rnsc ati-dri intel-dri nouveau-dri" 'noneeded' 'noexit'
			;;
		'optimus')
#			pacman_install "-Rdds mesa-libgl" 'noneeded' 'noexit'
#			pacman_install "-Rdds lib32-mesa-libgl" 'noneeded' 'noexit'

			#community
			pacman_install "-S bumblebee"
			#aur
#			pacman_install "-S nvidia-dkms" 'yaourt'
			#extra
			pacman_install "-S nvidia"
			[[ "${SET_LTS}" ]] && pacman_install "-S nvidia-lts"
			pacman_install "-S nvidia-utils"
#			pacman_install "-S opencl-nvidia"
			#multilib
			pacman_install "-S lib32-nvidia-utils" 'yaourt'
#			pacman_install "-S lib32-opencl-nvidia" 'yaourt'

			pacman_install "-Rnsc ati-dri nouveau-dri" 'noneeded' 'noexit'

			#community
			pacman_install "-S virtualgl"
			pacman_install "-S primus"
			#multilib
			pacman_install "-S lib32-virtualgl" 'yaourt'
			pacman_install "-S lib32-primus" 'yaourt'

			git_commit

			chroot_run systemctl enable 'nvidia-enable.service'

			SET_USER_GRUPS+=',bumblebee'
			;;
		'catalyst')
#Key-ID: 653C3094
#[catalyst]
#Server = http://catalyst.wirephire.com/repo/catalyst/$arch
#pacman-key -r Key-ID
#pacman-key --lsign-key Key-ID

			pacman_install "-Rdds mesa-libgl" 'noneeded' 'noexit'
			pacman_install "-Rdds lib32-mesa-libgl" 'noneeded' 'noexit'
			#aur
			pacman_install "-S catalyst-utils" 'yaourt'
			pacman_install "-S catalyst-libgl" 'yaourt'
#			pacman_install "-S opencl-catalyst" 'yaourt'
			pacman_install "-S lib32-catalyst-utils" 'yaourt'
			pacman_install "-S lib32-catalyst-libgl" 'yaourt'
#			pacman_install "-S lib32-opencl-catalyst" 'yaourt'
			pacman_install "-S catalyst-hook" 'yaourt'
			pacman_install "-S acpid"

			git_commit
			DRIVER='fglrx'

			chroot_run systemctl enable atieventsd
			chroot_run systemctl enable catalyst-hook
			chroot_run systemctl enable temp-links-catalyst

#===============================================================================
# Добавляю fglrx в mkinitcpio
#===============================================================================
			msg_log "$(gettext 'Добавляю') fglrx > /etc/mkinitcpio.conf"
			sed -i '
# Добавляем хук fglrx
/^HOOKS=/{
	h;
	s/^/#/;
	P;g;
	//{
	s/fglrx//g;s/ \{1,\}/ /g;
	s/fsck/fsck fglrx/;
	};
};
' "${NS_PATH}/etc/mkinitcpio.conf"

			#aticonfig --initial

			pacman_install "-Rnsc ati-dri intel-dri nouveau-dri" 'noneeded' 'noexit'
			;;
		'innotek')
			#community
			pacman_install "-S virtualbox-guest-modules"
			pacman_install "-S virtualbox-guest-utils"
			[[ "${SET_LTS}" ]] && pacman_install "-S virtualbox-host-modules-lts"
			;;
		'xf86-video-ati')
			pacman_install "-S xf86-video-ati"
			pacman_install "-S lib32-ati-dri" 'yaourt'
			;;
		'xf86-video-intel')
			pacman_install "-S xf86-video-intel"
			pacman_install "-S lib32-intel-dri" 'yaourt'
			;;
		'xf86-video-nouveau')
			pacman_install "-S xf86-video-nouveau"
			pacman_install "-S lib32-nouveau-dri" 'yaourt'
			;;
		*)
			pacman_install "-S ${SET_VIDEO}"
			;;
	esac

	git_commit

#gtf 1280 1024 85 получить соответствующий Modeline
#Section "Monitor"
# 1280x1024 @ 85.00 Hz (GTF) hsync: 91.38 kHz; pclk: 159.36 MHz
#  Modeline "1280x1024_85.00"  159.36  1280 1376 1512 1744  1024 1025 1028 1075  -HSync +Vsync
#EndSection
#Section "Screen"
#        SubSection "Display"
#              Modes     "1280x1024_85.00"
#        EndSubSection
#EndSection


#===============================================================================
# Настраиваем разрешение монитора для Xorg
#===============================================================================
	msg_log "$(gettext 'Настраиваю') /etc/X11/xorg.conf.d/00-monitor.conf"
	local TEMP='#'
	[[ "${DRIVER}" ]] && TEMP=
	echo "
Section \"ServerLayout\"
    Identifier    \"Layout[0]\"
    Screen        0 \"Screen[0]-0\" 0 0
EndSection

Section \"Module\"
EndSection

Section \"Monitor\"
    Identifier    \"Monitor[0]-0\"
    Option        \"VendorName\" \"Unknown\"
    Option        \"DPMS\" \"true\"
EndSection

Section \"Device\"
    Identifier    \"Device[0]-0\"
${TEMP}    Driver        \"${DRIVER}\" #Choose the driver used for this monitor
#    BusID       \"PCI:0:1:0\" #lspci | grep VGA
EndSection

Section \"Screen\"
    Identifier    \"Screen[0]-0\"
    Device        \"Device[0]-0\"
    Monitor       \"Monitor[0]-0\"
    DefaultDepth  ${SET_XORG_XxYxD##*x} #Choose the depth (16||24)
    SubSection \"Display\"
        Viewport    0 0
        Depth       ${SET_XORG_XxYxD##*x} #Choose the depth (16||24)
        Modes       \"${SET_XORG_XxYxD%x*}\" #Choose the resolution
    EndSubSection
EndSection
" > "${NS_PATH}/etc/X11/xorg.conf.d/00-monitor.conf"
	git_commit
}

xorg_mesa()
{
	#extra
	pacman_install "-S mesa-demos"
	pacman_install "-S mesa-libgl"
	#multilib
	pacman_install "-S lib32-mesa-demos" 'yaourt'
	pacman_install "-S lib32-mesa-libgl" 'yaourt'

	git_commit
}

xorg_video_drv()
{
	local VID

	local TEMP=0

	local DISPLAY

	DISPLAY=$(lshw -c display | tr '[:upper:]' '[:lower:]')

	for VID in $(awk '/product:/{print $2}' <<< "${DISPLAY}")
	do
		case "${VID}" in
			'gf108m' | '3rd')
				TEMP=$((TEMP+1))
				;;
		esac
	done

	if [[ "${TEMP}" == '2' ]]
	then
		echo 'optimus'
		return 0
	fi

	TEMP=
	for VID in $(awk '/vendor:/{print $2}' <<< "${DISPLAY}")
	do
		case "${VID}" in
			'nvidia')
				echo 'nvidia'
				return 0
				;;
			'ati')
				echo 'catalyst'
				return 0
				;;
			*)
				[[ ! "${TEMP}" ]] && TEMP="${VID}"
				;;
		esac
	done

	echo "${TEMP}"
	return 1
}
