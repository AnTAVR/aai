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
MAIN_CASE+=('pkgs')

#===============================================================================
# Сигнальная переменная успешного завершения функции модуля,
# может потребоваться для других модулей, для установки кода завершения
RUN_PKGS=
TXT_PKGS_MAIN="$(gettext 'Дополнительное ПО')"

APPS=''

#===============================================================================

# Выводим строку пункта главного меню
str_pkgs()
{
	local TEMP

	[[ "${RUN_PKGS}" ]] && TEMP="\Zb\Z2($(gettext 'ВЫПОЛНЕНО'))\Zn"
	echo "${TXT_PKGS_MAIN} ${TEMP}"
}

# Функция выполнения из главного меню
run_pkgs()
{
	local TEMP

	local APP

	if [[ "${NO_DEBUG}" ]]
	then
# Проверяем выполнен ли base_plus
		[[ ! "${RUN_BASE_PLUS}" ]] && TEMP+=" $(str_base_plus)\n"
# Проверяем выполнен ли de пункт меню
		[[ ! "${RUN_DE}" ]] && TEMP+=" $(str_de)\n"

		if [[ "${TEMP}" ]]
		then
			dialog_warn \
				"\Zb\Z1$(gettext 'Не выполнены обязательные пункты меню')\Zn\n${TEMP}"
			return 1
		fi
	fi

	TEMP="$(pkgs_dialog_app)"
	for APP in ${TEMP}
	do
		pkgs_${APP}
		RUN_PKGS=1
	done
}

pkgs_dialog_app()
{
	msg_log "$(gettext 'Запуск диалога'): \"${FUNCNAME}$(for ((TEMP=1; TEMP<=${#}; TEMP++)); do echo -n " \$${TEMP}='$(eval "echo \"\${${TEMP}}\"")'"; done)\"" 'noecho'

	local RETURN

	local TITLE="${TXT_PKGS_MAIN}"
	local HELP_TXT="\n$(gettext 'Выберите дополнительное ПО')\n"

	local ITEMS="${APPS}"

	RETURN="$(dialog_checklist "${TITLE}" "${HELP_TXT}" "${ITEMS}" "--cancel-label '${TXT_MAIN_MENU}'")"

	echo "${RETURN}"
	msg_log "$(gettext 'Выход из диалога'): \"${FUNCNAME} return='${RETURN}'\"" 'noecho'
}

pkgs_appset()
{
	#aur
	pacman_install "-S appset-qt" '2'
	pacman_install "-S packer" '2'

	git_commit

	chroot_run systemctl appset-helper.service

	git_commit
}
APPS+=" 'appset' '$(gettext 'Графический менеджер пакетов') (AUR)' 'off'"

pkgs_dolphin()
{
	#extra
	pacman_install "-S kdebase-dolphin" '1'
	pacman_install "-S kdesdk-dolphin-plugins" '1'
	pacman_install "-S kdemultimedia-ffmpegthumbs" '1'
	pacman_install "-S kdeutils-ark" '1'
	pacman_install "-S kdebase-konsole" '1'
	pacman_install "-S kdebase-kdialog" '1'
	pacman_install "-S kdeutils-kwallet" '1'
	#aur
#	pacman_install "-S kde-servicemenus-rootactions" '2' # отключил потому что подвисает, и xauth зомбируется так что лучше использовать kdesu!
	#extra
	pacman_install "-S kde-l10n-${SET_LOCAL%_*}" '2'

	git_commit
}
APPS+=" 'dolphin' '$(gettext 'Файловый менеджер')' 'on'"

pkgs_kate()
{
	#extra
	pacman_install "-S kdesdk-kate" '1'
	pacman_install "-S kdebase-konsole" '1'
	#extra
	pacman_install "-S kde-l10n-${SET_LOCAL%_*}" '2'

	git_commit
}
APPS+=" 'kate' '$(gettext 'Хороший текстовый редактор')' 'on'"

pkgs_geany()
{
	#community
	pacman_install "-S geany" '1'
	pacman_install "-S geany-plugins" '1'

	git_commit
}
APPS+=" 'geany' '$(gettext 'Текстовый редактор')' 'off'"

pkgs_sublime()
{
	#aur
	pacman_install "-S sublime-text" '2'

	git_commit
}
APPS+=" 'sublime' '$(gettext 'Отличный текстовый редактор!!!') (AUR)' 'off'"

pkgs_vim()
{
	#extra
	pacman_install "-S vim" '1'
	#community
	pacman_install "-S vim-plugins" '1'
	#community
	pacman_install "-S vim-spell-${SET_LOCAL%_*}" '2'

	git_commit
}
APPS+=" 'vim' '$(gettext 'Консольный текстовый редактор')' 'off'"

pkgs_acestream()
{
	#aur
	pacman_install "-S acestream-player" '2'
	pacman_install "-S acestream-mozilla-plugin" '2'

	git_commit
}
APPS+=" 'acestream' '$(gettext 'Медиа-платформа нового поколения') (AUR)' 'off'"

pkgs_smplayer()
{
	#extra
	pacman_install "-S smplayer" '1'
	pacman_install "-S smplayer-themes" '1'
	#community
	pacman_install "-S smtube" '1'

	git_commit
}
APPS+=" 'smplayer' '$(gettext 'Видео плеер')' 'on'"

pkgs_bino()
{
	#aur
	pacman_install "-S bino" '2'

	git_commit
}
APPS+=" 'bino' '$(gettext '3D Видео плеер') (AUR)' 'off'"

pkgs_audacious()
{
	#extra
	pacman_install "-S audacious" '1'
	pacman_install "-S rhythmbox" '1'

	git_commit
}
APPS+=" 'audacious' '$(gettext 'Аудио плеер')' 'on'"

pkgs_tvtime()
{
	#community
	pacman_install "-S tvtime" '1'
	#aur
	pacman_install "-S alevt" '2'
	pacman_install "-S kradio" '2'

	git_commit
}
APPS+=" 'tvtime' '$(gettext 'ТВ и РАДИО тюнер, Телетекст') (+AUR)' 'off'"

pkgs_k3b()
{
	#extra
	pacman_install "-S k3b" '1'
	pacman_install "-S dvd+rw-tools" '1'
	pacman_install "-S vcdimager" '1'
	pacman_install "-S transcode" '1'
	pacman_install "-S emovix" '1'
	pacman_install "-S cdrdao" '1'
	pacman_install "-S cdparanoia" '1'
	#community
	pacman_install "-S nrg2iso" '1'

	git_commit
}
APPS+=" 'k3b' '$(gettext 'Запись CD')' 'on'"

pkgs_avidemux()
{
	#extra
	pacman_install "-S avidemux-qt" '1'
	pacman_install "-S mkvtoolnix-gtk" '1'
	pacman_install "-S mencoder" '1'
	#community
	pacman_install "-S mediainfo-gui" '1'

	git_commit
}
APPS+=" 'avidemux' '$(gettext 'Конвертер видео')' 'off'"

pkgs_openshot()
{
	#community
	pacman_install "-S openshot" '1'

	git_commit
}
APPS+=" 'openshot' '$(gettext 'Редактор видео')' 'off'"

pkgs_soundkonverter()
{
	#extra
	pacman_install "-S cdrkit" '1'
	pacman_install "-S faac" '1'
	pacman_install "-S faad2" '1'
	pacman_install "-S ffmpeg" '1'
	pacman_install "-S flac" '1'
	pacman_install "-S lame" '1'
	pacman_install "-S mplayer" '1'
	pacman_install "-S speex" '1'
	pacman_install "-S vorbis-tools" '1'
	pacman_install "-S wavpack" '1'
	pacman_install "-S fluidsynth" '1'
	#community
	pacman_install "-S rubyripper" '1'
	pacman_install "-S ruby-gtk2" '1'
	pacman_install "-S soundkonverter" '1'
	pacman_install "-S mac" '1'
	pacman_install "-S mp3gain" '1'
	pacman_install "-S twolame" '1'
	pacman_install "-S vorbisgain" '1'
	pacman_install "-S opus-tools" '1'
	#aur
	pacman_install "-S split2flac-git" '2'
	pacman_install "-S isomaster" '2'
	pacman_install "-S fluidr3" '2' # для fluidsynth

	git_commit
}
APPS+=" 'soundkonverter' '$(gettext 'Конвертер аудио') (+AUR)' 'off'"

pkgs_snapshot()
{
	#extra
	pacman_install "-S kdegraphics-ksnapshot" '1'
	#extra
	pacman_install "-S kde-l10n-${SET_LOCAL%_*}" '2'

	git_commit
}
APPS+=" 'snapshot' '$(gettext 'Снимки экрана')' 'on'"

pkgs_xvidcap()
{
	#aur
	pacman_install "-S xvidcap" '2'

	git_commit
}
APPS+=" 'xvidcap' '$(gettext 'Запись видео с экрана') (AUR)' 'off'"

pkgs_okular()
{
	#extra
	pacman_install "-S kdegraphics-okular" '1'
	pacman_install "-S kdegraphics-mobipocket" '1'
	pacman_install "-S kdegraphics-gwenview" '1'
	pacman_install "-S kipi-plugins" '1'
	#extra
	pacman_install "-S kde-l10n-${SET_LOCAL%_*}" '2'

	git_commit
}
APPS+=" 'okular' '$(gettext 'Просмотр документов')' 'on'"

pkgs_hardinfo()
{
	#community
	pacman_install "-S hardinfo" '1'

	git_commit
}
APPS+=" 'hardinfo' '$(gettext 'Информация о системе')' 'on'"

pkgs_diffuse()
{
	#community
	pacman_install "-S diffuse" '1'
	pacman_install "-S qgit" '1'

	git_commit
}
APPS+=" 'diffuse' '$(gettext 'Работа с git репозиторием')' 'on'"

pkgs_smartgithg()
{
	#aur
	pacman_install "-S smartgithg" '2'

	git_commit
}
APPS+=" 'smartgithg' '$(gettext 'GUI клиент Git, Mercurial и Subversion') (AUR)' 'off'"

pkgs_gparted()
{
	#extra
	pacman_install "-S gparted" '1'

	git_commit
}
APPS+=" 'gparted' '$(gettext 'Работа с разделами')' 'on'"

pkgs_tesseract()
{
	#community
	pacman_install "-S tesseract" '1'
	pacman_install "-S tesseract-data" '1'
	pacman_install "-S cuneiform" '1'
	pacman_install "-S ocrfeeder" '1'
	pacman_install "-S yagf" '1'
# 	#aur
# 	pacman_install "-S tesseract-gui" '2'

	git_commit
}
APPS+=" 'tesseract' '$(gettext 'Система распознавания текста')' 'off'"

pkgs_libreoffice()
{
	#extra
	pacman_install "-S jdk7-openjdk" '1'
	pacman_install "-S libreoffice" '1'
	pacman_install "-S libreoffice-extensions" '1'
	#extra
	pacman_install "-S libreoffice-${SET_LOCAL%_*}" '2'

	git_commit
}
APPS+=" 'libreoffice' '$(gettext 'Офисные программы')' 'on'"

pkgs_gimp()
{
	#extra
	pacman_install "-S gimp" '1'
	pacman_install "-S gimp-help-${SET_LOCAL%_*}" '2'
	#community
	pacman_install "-S gimp-ufraw" '1'
	pacman_install "-S gimp-plugin-fblur" '1'
	pacman_install "-S gimp-plugin-gmic" '1'
	pacman_install "-S gimp-plugin-lqr" '1'
	pacman_install "-S gimp-plugin-mathmap" '1'
	pacman_install "-S gimp-plugin-wavelet-decompose" '1'
	pacman_install "-S gimp-plugin-wavelet-denoise" '1'
	pacman_install "-S gimp-refocus" '1'

	git_commit
}
APPS+=" 'gimp' '$(gettext 'Графический редактор')' 'on'"

pkgs_inkscape()
{
	#extra
	pacman_install "-S inkscape" '1'

	git_commit
}
APPS+=" 'inkscape' '$(gettext 'Векторный редактор')' 'on'"

pkgs_xmind()
{
	#aur
	pacman_install "-S xmind" '2'

	git_commit
}
APPS+=" 'xmind' '$(gettext 'Редактор интеллект-карт и диаграмм') (AUR)' 'off'"

pkgs_firefox()
{
	#extra
	pacman_install "-S flashplugin" '1'
	pacman_install "-S icedtea-web-java7" '1'
	#community
	pacman_install "-S gecko-mediaplayer" '1'
	#extra
	pacman_install "-S firefox" '1'
	pacman_install "-S firefox-i18n-${SET_LOCAL%_*}" '2'

	git_commit
# http://adblockplus.org/ru/
# https://addons.mozilla.org/ru/firefox/addon/adblock-plus-pop-up-addon/
# http://www.binaryturf.com/free-software/colorfultabs-for-firefox/
# https://addons.mozilla.org/en-US/firefox/addon/cookies-manager-plus/
# https://addons.mozilla.org/ru/firefox/addon/css-usage/
# https://addons.mozilla.org/ru/firefox/addon/abpcustomization/
# https://addons.mozilla.org/ru/firefox/addon/default-fullzoom-level/
# http://developercompanion.com/
# https://addons.mozilla.org/ru/firefox/addon/video-downloadhelper/
# https://addons.mozilla.org/ru/firefox/addon/download-statusbar/
# https://addons.mozilla.org/ru/firefox/addon/elemhidehelper/
# https://addons.mozilla.org/ru/firefox/addon/firebug/
# https://addons.mozilla.org/ru/firefox/addon/fireftp/
# https://addons.mozilla.org/ru/firefox/addon/foxyproxy-standard/
# http://groups.google.com/group/quick-translator/browse_thread/thread/a03e58bd9ea45775
# https://addons.mozilla.org/ru/firefox/addon/imacros-for-firefox/
# https://addons.mozilla.org/ru/firefox/addon/validator/
# https://addons.mozilla.org/ru/firefox/addon/kde-wallet-password-integratio/
# https://addons.mozilla.org/ru/firefox/addon/total-validator/
# https://addons.mozilla.org/ru/firefox/addon/simple-markup-validator/
# https://addons.mozilla.org/ru/firefox/addon/showip/
# http://seleniumhq.org/download/
# https://addons.mozilla.org/ru/firefox/addon/oxygen-kde-patched/
}
APPS+=" 'firefox' '$(gettext 'Интернет браузер (Mozilla)')' 'on'"

pkgs_thunderbird()
{
	#extra
	pacman_install "-S thunderbird" '1'
	#extra
	pacman_install "-S thunderbird-i18n-${SET_LOCAL%_*}" '2'

	git_commit
}
APPS+=" 'thunderbird' '$(gettext 'Почтовая программа (Mozilla)')' 'off'"

pkgs_opera()
{
	#extra
	pacman_install "-S flashplugin" '1'
	pacman_install "-S icedtea-web-java7" '1'
	#community
	pacman_install "-S gecko-mediaplayer" '1'
	#community
	pacman_install "-S opera" '1'

	git_commit
}
APPS+=" 'opera' '$(gettext 'Интернет браузер')' 'off'"

pkgs_claws()
{
	#extra
	pacman_install "-S claws-mail" '1'
	pacman_install "-S claws-mail-themes" '1'
	pacman_install "-S spamassassin" '1'
	pacman_install "-S razor" '1'
	#community
	pacman_install "-S dspam" '1'
	pacman_install "-S p3scan" '1'

	git_commit

	chroot_run /usr/bin/vendor_perl/sa-update
	chroot_run /usr/bin/vendor_perl/sa-compile

	cat "${DBDIR}modules/usr/local/bin/sa-run" > "${NS_PATH}/usr/local/bin/sa-run"
	chmod +x "${NS_PATH}/usr/local/bin/sa-run"

	git_commit

# iptables -t nat -A PREROUTING -p tcp --dport pop3 -j REDIRECT --to 8110

# *nat
# :PREROUTING ACCEPT [0:0]
# :INPUT ACCEPT [0:0]
# :OUTPUT ACCEPT [0:0]
# :POSTROUTING ACCEPT [0:0]
# -A PREROUTING -p tcp -m tcp --dport 110 -j REDIRECT --to-ports 8110
# COMMIT

# ~/.claws-mail/accountrc
# spam: %as{execute "spamassassin -R --local -e < %F" execute "sa-learn --spam %F" move "#mh/Mail/spam!!!" mark_as_spam}
# nospam: %as{execute "spamassassin -W --local -e < %F" execute "sa-learn --ham %F" copy "#mh/Mail/spamNO" mark_as_ham}

# ~/.claws-mail/matcherrc
# [filtering]
# enabled rulename "sa-run" test "!(sa-run %F)" move "#mh/Mail/spam"

# ~/.claws-mail/toolbar_msgview.xml
# ~/.claws-mail/toolbar_main.xml
# <toolbar>
# 	<separator/>
# 	<item file="spam_btn" text="spam" action="A_CLAWS_ACTIONS"/>
# 	<item file="ham_btn" text="nospam" action="A_CLAWS_ACTIONS"/>
# </toolbar>


}
APPS+=" 'claws' '$(gettext 'EMAIL клиент')' 'on'"

pkgs_filezilla()
{
	#extra
	pacman_install "-S filezilla" '1'

	git_commit
}
APPS+=" 'filezilla' '$(gettext 'FTP клиент')' 'on'"

pkgs_linuxdcpp()
{
	#community
	pacman_install "-S linuxdcpp" '1'

	git_commit
}
APPS+=" 'linuxdcpp' '$(gettext 'DC++ клиент')' 'off'"

#Хороший торрент клиент но при работе вылетает (((
# kernel: qbittorrent[5140]: segfault at 680000003f ip 00007f963956ad63 sp 00007f962c55ba00 error 4 in libc-2.17.so[7f96394ef000+1a4000]
pkgs_qbittorrent()
{
	#aur
	pacman_install "-S qbittorrent" '2'

	git_commit
}
APPS+=" 'qbittorrent' '$(gettext 'TORRENT клиент') (AUR)' 'off'"

pkgs_pidgin()
{
	#extra
	pacman_install "-S pidgin" '1'
	#community
	pacman_install "-S pidgin-encryption" '1'
	pacman_install "-S pidgin-libnotify" '1'
	pacman_install "-S pidgin-toobars" '1'
	#aur
	pacman_install "-S pidgin-bot-sentry" '2'

	git_commit
}
APPS+=" 'pidgin' '$(gettext 'ICQ, QIP и т.п.') (+AUR)' 'on'"

pkgs_kvirc()
{
	#community
	pacman_install "-S kvirc" '1'

	git_commit
}
APPS+=" 'kvirc' '$(gettext 'IRC')' 'off'"

pkgs_skype()
{
	#community
	pacman_install "-S skype-call-recorder" '1'
	#multilib
	pacman_install "-S skype" '1'
#	pacman_install "-S lib32-libcanberra-pulse" '2'
#	pacman_install "-S lib32-libcanberra" '2'
#	pacman_install "-S lib32-libpulse" '2'

	git_commit
}
APPS+=" 'skype' '$(gettext 'Skype IP-телефония')' 'on'"

pkgs_ekiga()
{
	#extra
	pacman_install "-S ekiga" '1'

	git_commit
}
APPS+=" 'ekiga' '$(gettext 'Ekiga IP-телефония')' 'off'"

pkgs_truecrypt()
{
	#extra
	pacman_install "-S truecrypt" '1'

	git_commit
}
APPS+=" 'truecrypt' '$(gettext 'TrueCrypt шифрование на лету')' 'on'"

pkgs_cryptkeeper()
{
	#community
	pacman_install "-S gpg-crypter" '1'
	#aur
	pacman_install "-S cryptkeeper" '2'

	git_commit
}
APPS+=" 'cryptkeeper' '$(gettext 'GUI для шифрования папок') (+AUR)' 'on'"

pkgs_keepassx()
{
	#community
	pacman_install "-S keepassx" '1'
	#aur
#     pacman_install "-S keepass" '2'
# Локализация закоментированна потому что можно вручную скачать файл с сайта.
# А установка задает вопросы!
#     pacman_install "-S keepass-${SET_LOCAL%_*}" '2'

	git_commit
}
APPS+=" 'keepassx' '$(gettext 'программа для хранения паролей')' 'on'"

pkgs_mmex()
{
	#aur
	pacman_install "-S mmex" '2'

	git_commit
}
APPS+=" 'mmex' '$(gettext 'Менеджер личных финансов') (AUR)' 'off'"

pkgs_teamviewer()
{
	#aur
	pacman_install "-S teamviewer" '2'

	git_commit
}
APPS+=" 'teamviewer' '$(gettext 'Удаленный доступ и поддержка через Интернет') (AUR)' 'off'"

pkgs_clamav()
{
	#extra
	pacman_install "-S clamav" '1'

	git_commit

	msg_log "$(gettext 'Настраиваю') /etc/clamav/clamd.conf"
	sed -i "
/^Example/s/^/#/;
" "${NS_PATH}/etc/clamav/clamd.conf"
	msg_log "$(gettext 'Настраиваю') /etc/clamav/freshclam.conf"
	sed -i "
/^Example/s/^/#/;
" "${NS_PATH}/etc/clamav/freshclam.conf"

# Включаем ежедневное обновление базы по крону
	cat "${DBDIR}modules/etc/cron.daily/freshclam" > "${NS_PATH}/etc/cron.daily/freshclam"
	chmod +x "${NS_PATH}/etc/cron.daily/freshclam"

	msg_info "$(gettext 'Пожалуйста, подождите')..."
	chroot_run freshclam

	git_commit
}
APPS+=" 'clamav' '$(gettext 'Антивирус')' 'off'"

pkgs_stardict()
{
	#community
	pacman_install "-S stardict" '1'
	pacman_install "-S goldendict" '1'

	git_commit
}
APPS+=" 'stardict' '$(gettext 'Словарь')' 'off'"

pkgs_mixxx()
{
	#community
	pacman_install "-S mixxx" '1'

	git_commit
}
APPS+=" 'mixxx' '$(gettext 'DJ система')' 'off'"

pkgs_ardour()
{
	#extra
	pacman_install "-S ardour" '1'
	pacman_install "-S qjackctl" '1'
	#community
	pacman_install "-S calf" '1'

	git_commit
}
APPS+=" 'ardour' '$(gettext 'Аудио станция')' 'off'"

pkgs_hydrogen()
{
	#extra
	pacman_install "-S hydrogen" '1'
	#aur
	pacman_install "-S hydrogen-drumkits" '2'
	
	git_commit
}
APPS+=" 'hydrogen' '$(gettext 'Драм-машина +drumkits') (+AUR)' 'off'"

# pkgs_rosegarden()
# {
# 	#extra
# 	pacman_install "-S rosegarden" '1'

# 	git_commit
# }
# APPS+=" 'rosegarden' '$(gettext 'MIDI-секвенсер')' 'off'"

pkgs_myrulib()
{
	#aur
	pacman_install "-S myrulib" '2'

	git_commit
}
APPS+=" 'myrulib' '$(gettext 'Домашняя библиотека') (AUR)' 'off'"

pkgs_blender()
{
	#community
	pacman_install "-S blender" '1'

	git_commit
}
APPS+=" 'blender' '$(gettext '3D моделирование')' 'off'"

pkgs_sweethome3d()
{
	#aur
	pacman_install "-S sweethome3d" '2'

	git_commit
}
APPS+=" 'sweethome3d' '$(gettext '3D дизайн интерьера') (AUR)' 'off'"

pkgs_virtualbox()
{
	#community
	pacman_install "-S virtualbox" '1'
	pacman_install "-S virtualbox-host-modules" '1'
	pacman_install "-S virtualbox-guest-iso" '1'
	[[ "${SET_LTS}" ]] && pacman_install "-S virtualbox-host-modules-lts" '1'
	#aur
#	pacman_install "-S virtualbox-ext-oracle" '2'

	git_commit

	msg_log "$(gettext 'Настраиваю') /etc/modules-load.d/vbox.conf"
	cat "${DBDIR}modules/etc/modules-load.d/vbox.conf" > "${NS_PATH}/etc/modules-load.d/vbox.conf"

	SET_USER_GRUPS+=',vboxusers'

	git_commit
}
APPS+=" 'virtualbox' '$(gettext 'Виртуальная машина') (+AUR)' 'off'"

pkgs_ettercap()
{
	#community
	pacman_install "-S ettercap-gtk" '1'
	#aur
	pacman_install "-S netdiscover" '2'
	pacman_install "-S hydra" '2'
	pacman_install "-S nikto" '2'

	git_commit

	chroot_run nikto -update

	git_commit
}
APPS+=" 'ettercap' '$(gettext 'Анализ безопасности сети') (+AUR)' 'off'"

pkgs_wireshark()
{
	#extra
	pacman_install "-S wireshark-gtk" '1'

	SET_USER_GRUPS+=',wireshark'

	git_commit
}
APPS+=" 'wireshark' '$(gettext 'Анализатор трафика для сетей Ethernet')' 'off'"

pkgs_eric()
{
	#extra
	pacman_install "-S eric" '1'
	#aur
	pacman_install "-S eric5-i18n" '2'

	git_commit
}
APPS+=" 'eric' '$(gettext 'Python редактор') (+AUR)' 'off'"

pkgs_netbeans()
{
	#community
	pacman_install "-S netbeans" '1'

	git_commit
}
APPS+=" 'netbeans' '$(gettext 'Java, PHP, C, C++ редактор')' 'off'"

pkgs_kpatience()
{
	#extra
	pacman_install "-S kdegames-kpatience" '1'
	pacman_install "-S kde-l10n-${SET_LOCAL%_*}" '2'

	git_commit
}
APPS+=" 'kpatience' '$(gettext 'Игра. Пасьянсы')' 'on'"

pkgs_urbanterror()
{
	#community
	pacman_install "-S urbanterror" '1'

	git_commit
}
APPS+=" 'urbanterror' '$(gettext 'Игра. 3D Шутер от первого лица')' 'off'"

pkgs_spring()
{
	#community
	pacman_install "-S springlobby" '1'
	pacman_install "-S spring" '1'

	git_commit
}
APPS+=" 'spring' '$(gettext 'Игра. 3D Стратегия')' 'off'"

pkgs_ufoai()
{
	#community
	pacman_install "-S ufoai" '1'

	git_commit
}
APPS+=" 'ufoai' '$(gettext 'Игра. Смесь ролевой игры и стратегии')' 'off'"

pkgs_0ad()
{
	#community
	pacman_install "-S 0ad" '1'

	git_commit
}
APPS+=" '0ad' '$(gettext 'Игра. 3D Стратегия')' 'off'"

pkgs_warsow()
{
	#community
	pacman_install "-S warsow" '1'

	git_commit
}
APPS+=" 'warsow' '$(gettext 'Игра. Киберспортивная игра')' 'off'"

pkgs_minetest()
{
	#community
	pacman_install "-S minetest" '1'

	git_commit
}
APPS+=" 'minetest' '$(gettext 'Игра. Аналог Minecraft')' 'off'"

pkgs_neverball()
{
	#community
	pacman_install "-S neverball" '1'

	git_commit
}
APPS+=" 'neverball' '$(gettext 'Игра. Neverball')' 'off'"

pkgs_xboard()
{
	#community
	pacman_install "-S xboard" '1'

	git_commit
}
APPS+=" 'xboard' '$(gettext 'Игра. Шахматы')' 'on'"
