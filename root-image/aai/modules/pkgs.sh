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

    pkgs_dialog_app 2> "${TEMPFILE}"
    TEMP="$(cat "${TEMPFILE}")"
    for APP in ${TEMP}
    do
	pkgs_${APP}
	RUN_PKGS=1
    done
}

pkgs_dialog_app()
{
    local TITLE="${TXT_PKGS_MAIN}"
    local HELP_TXT="\n$(gettext 'Выберите дополнительное ПО')\n"

    local ITEMS="${APPS}"

    dialog_checklist "${TITLE}" "${HELP_TXT}" "${ITEMS}" "--cancel-label '${TXT_MAIN_MENU}'"
}

pkgs_dolphin()
{
    local PACS
    #extra
    PACS='kdebase-dolphin kdegraphics-thumbnailers ruby kdesdk-dolphin-plugins kdemultimedia-ffmpegthumbs'
    PACS+=' kdebase-konsole kdebase-kdialog kdeutils-kwallet'
    pacman_install "-S ${PACS}" '1'
    #aur
    PACS='kde-servicemenus-rootactions'
    pacman_install "-S ${PACS}" '2'
    #extra
    PACS="kde-l10n-${SET_LOCAL%_*}"
    pacman_install "-S ${PACS}" '2'

    git_commit
}
APPS+=" 'dolphin' '$(gettext 'Файловый менеджер') (+AUR)' 'on'"

pkgs_kdeadmin()
{
    local PACS
    #extra
    PACS='kdeadmin kdeadmin-kcron kdeadmin-ksystemlog kdeadmin-kuser kdebase-kdepasswd'
    pacman_install "-S ${PACS}" '1'
    #extra
    PACS="kde-l10n-${SET_LOCAL%_*}"
    pacman_install "-S ${PACS}" '2'

    git_commit
}

pkgs_kdesdk()
{
    local PACS
    #extra
    PACS='kdesdk jre7-openjdk'
    pacman_install "-S ${PACS}" '1'
    #extra
    PACS="kde-l10n-${SET_LOCAL%_*}"
    pacman_install "-S ${PACS}" '2'

    git_commit
}

pkgs_kdepim()
{
    local PACS
    #extra
    PACS='kdepim'
    pacman_install "-S ${PACS}" '1'
    #extra
    PACS="kde-l10n-${SET_LOCAL%_*}"
    pacman_install "-S ${PACS}" '2'

    git_commit
}

pkgs_kdeutils()
{
    local PACS
    #extra
    PACS='kdeutils'
    pacman_install "-S ${PACS}" '1'
    #extra
    PACS="kde-l10n-${SET_LOCAL%_*}"
    pacman_install "-S ${PACS}" '2'

    git_commit
}

pkgs_kdewebdev()
{
    local PACS
    #extra
    PACS='kdewebdev'
    pacman_install "-S ${PACS}" '1'
    #extra
    PACS="kde-l10n-${SET_LOCAL%_*}"
    pacman_install "-S ${PACS}" '2'

    git_commit
}

pkgs_kdegraphics()
{
    local PACS
    #extra
    PACS='kdegraphics'
    pacman_install "-S ${PACS}" '1'
    #extra
    PACS="kde-l10n-${SET_LOCAL%_*}"
    pacman_install "-S ${PACS}" '2'

    git_commit
}

pkgs_kate()
{
    local PACS
    #extra
    PACS=' kdesdk-kate kdebase-konsole kdebindings-python'
    pacman_install "-S ${PACS}" '1'
    #extra
    PACS="kde-l10n-${SET_LOCAL%_*}"
    pacman_install "-S ${PACS}" '2'

    git_commit
}
APPS+=" 'kate' '$(gettext 'Хороший текстовый редактор')' 'on'"

pkgs_geany()
{
    local PACS
    #community
    PACS='geany geany-plugins'
    pacman_install "-S ${PACS}" '1'

    git_commit
}
APPS+=" 'geany' '$(gettext 'Текстовый редактор')' 'off'"

pkgs_vim()
{
    local PACS
    #extra
    PACS='vim'
    #community
    PACS+=' vim-plugins'
    pacman_install "-S ${PACS}" '1'

    PACS="vim-spell-${SET_LOCAL%_*}"
    pacman_install "-S ${PACS}" '2'

    git_commit
}
APPS+=" 'vim' '$(gettext 'Консольный текстовый редактор')' 'off'"

pkgs_smplayer()
{
    local PACS
    #extra
    PACS='smplayer smplayer-themes'
    pacman_install "-S ${PACS}" '1'

    git_commit
}
APPS+=" 'smplayer' '$(gettext 'Видео плеер')' 'on'"

pkgs_bino()
{
    local PACS
    #aur
    PACS='bino'
    pacman_install "-S ${PACS}" '2'

    git_commit
}
APPS+=" 'bino' '$(gettext '3D Видео плеер') (AUR)' 'off'"

pkgs_audacious()
{
    local PACS
    #extra
    PACS='audacious rhythmbox'
    pacman_install "-S ${PACS}" '1'

    git_commit
}
APPS+=" 'audacious' '$(gettext 'Аудио плеер')' 'on'"

pkgs_tvtime()
{
    local PACS
    #community
    PACS='tvtime kradio'
    pacman_install "-S ${PACS}" '1'
    #aur
    PACS='alevt'
    pacman_install "-S ${PACS}" '2'
    git_commit
}
APPS+=" 'tvtime' '$(gettext 'ТВ и РАДИО тюнер') (+AUR)' 'off'"

pkgs_k3b()
{
    local PACS
    #extra
    PACS='k3b dvd+rw-tools vcdimager transcode emovix cdrdao cdparanoia'
    pacman_install "-S ${PACS}" '1'

    git_commit
}
APPS+=" 'k3b' '$(gettext 'Запись CD')' 'on'"

pkgs_avidemux()
{
    local PACS
    #extra
    PACS='avidemux-qt mkvtoolnix-gtk mencoder mediainfo-gui'
    #community
    PACS+=' mediainfo-gui'
    pacman_install "-S ${PACS}" '1'

    git_commit
}
APPS+=" 'avidemux' '$(gettext 'Конвертер видео')' 'off'"

pkgs_openshot()
{
    local PACS
    #community
    PACS='openshot'
    pacman_install "-S ${PACS}" '1'
    git_commit
}
APPS+=" 'openshot' '$(gettext 'Редактор видео')' 'off'"

pkgs_soundkonverter()
{
    local PACS
    #extra
    PACS='cdrkit faac faad2 ffmpeg flac fluidsynth lame mplayer speex timidity++ vorbis-tools wavpack'
    #community
    PACS+=' rubyripper soundkonverter mac mp3gain twolame vorbisgain'
    pacman_install "-S ${PACS}" '1'
    #aur
    PACS='split2flac-git isomaster'
    pacman_install "-S ${PACS}" '2'
    git_commit
}
APPS+=" 'soundkonverter' '$(gettext 'Конвертер аудио') (+AUR)' 'off'"

pkgs_snapshot()
{
    local PACS
    #extra
    PACS='kdegraphics-ksnapshot'
    pacman_install "-S ${PACS}" '1'
    git_commit
}
APPS+=" 'snapshot' '$(gettext 'Снимки экрана')' 'on'"

pkgs_xvidcap()
{
    local PACS
    #aur
    PACS='xvidcap'
    pacman_install "-S ${PACS}" '2'
    git_commit
}
APPS+=" 'xvidcap' '$(gettext 'Запись видео с экрана') (AUR)' 'on'"

pkgs_okular()
{
    local PACS
    #extra
    PACS='kdegraphics-okular kdegraphics-mobipocket kdegraphics-gwenview'
    pacman_install "-S ${PACS}" '1'
    git_commit
}
APPS+=" 'okular' '$(gettext 'Просмотр документов')' 'on'"

pkgs_hardinfo()
{
    local PACS
    #community
    PACS='hardinfo'
    pacman_install "-S ${PACS}" '1'
    git_commit
}
APPS+=" 'hardinfo' '$(gettext 'Информация о системе')' 'on'"

pkgs_diffuse()
{
    local PACS
    #community
    PACS='diffuse qgit'
    pacman_install "-S ${PACS}" '1'
    git_commit
}
APPS+=" 'diffuse' '$(gettext 'Работа с git репозиторием')' 'on'"

pkgs_gparted()
{
    local PACS
    #extra
    PACS='gparted'
    pacman_install "-S ${PACS}" '1'
    git_commit
}
APPS+=" 'gparted' '$(gettext 'Работа с разделами')' 'on'"

pkgs_tesseract()
{
    local PACS
    #community
    PACS='yagf tesseract ocrfeeder tesseract-data'
    pacman_install "-S ${PACS}" '1'
    #aur
    PACS='tesseract-gui'
    pacman_install "-S ${PACS}" '2'
    git_commit
}
APPS+=" 'tesseract' '$(gettext 'Система распознавания текста') (+AUR)' 'off'"

pkgs_libreoffice()
{
    local PACS
    #extra
    PACS='libreoffice libreoffice-extensions jdk7-openjdk'
    pacman_install "-S ${PACS}" '1'
    #extra
    PACS="libreoffice-${SET_LOCAL%_*}"
    pacman_install "-S ${PACS}" '2'
    git_commit
}
APPS+=" 'libreoffice' '$(gettext 'Офисные программы')' 'on'"

pkgs_gimp()
{
    local PACS
    #extra
    PACS='gimp'
    #community
    PACS+=' gimp-ufraw gimp-plugin-fblur gimp-plugin-gmic gimp-plugin-lqr gimp-plugin-mathmap'
    PACS+=' gimp-plugin-wavelet-decompose gimp-plugin-wavelet-denoise gimp-refocus'
    pacman_install "-S ${PACS}" '1'
    #extra
    PACS="gimp-help-${SET_LOCAL%_*}"
    pacman_install "-S ${PACS}" '2'
    git_commit
}
APPS+=" 'gimp' '$(gettext 'Графический редактор')' 'on'"

pkgs_inkscape()
{
    local PACS
    #extra
    PACS='inkscape'
    pacman_install "-S ${PACS}" '1'
    git_commit
}
APPS+=" 'inkscape' '$(gettext 'Векторный редактор')' 'on'"

pkgs_firefox()
{
    local PACS
    #extra
    PACS='firefox flashplugin icedtea-web-java7'
    #community
    PACS+=' gecko-mediaplayer'
    pacman_install "-S ${PACS}" '1'
    #extra
    PACS="firefox-i18n-${SET_LOCAL%_*}"
    pacman_install "-S ${PACS}" '2'
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
}
APPS+=" 'firefox' '$(gettext 'Интернет браузер')' 'on'"

pkgs_opera()
{
    local PACS
    #extra
    PACS='flashplugin icedtea-web-java7'
    #community
    PACS+=' opera gecko-mediaplayer'
    pacman_install "-S ${PACS}" '1'
    git_commit
}
APPS+=" 'opera' '$(gettext 'Интернет браузер')' 'off'"

pkgs_claws()
{
    local PACS
    #extra
    PACS='claws-mail claws-mail-extra-plugins'
    PACS+=' spamassassin razor bogofilter'
    #community
    PACS+=' dspam p3scan'
    pacman_install "-S ${PACS}" '1'
    git_commit
    chroot_run /usr/bin/vendor_perl/sa-update
    git_commit
}
APPS+=" 'claws' '$(gettext 'EMAIL клиент')' 'on'"

pkgs_filezilla()
{
    local PACS
    #extra
    PACS='filezilla'
    pacman_install "-S ${PACS}" '1'
    git_commit
}
APPS+=" 'filezilla' '$(gettext 'FTP клиент')' 'on'"

# pkgs_qbittorrent()
# {
#     local PACS
#     #aur
#     PACS='qbittorrent'
#     pacman_install "-S ${PACS}" '2'
#     git_commit
# }
# APPS+=" 'qbittorrent' '$(gettext 'TORRENT клиент') (AUR)' 'on'"

pkgs_pidgin()
{
    local PACS
    #extra
    PACS='pidgin'
    #community
    PACS+=' pidgin-encryption pidgin-libnotify pidgin-toobars'
    pacman_install "-S ${PACS}" '1'
    #aur
    PACS='pidgin-bot-sentry'
    pacman_install "-S ${PACS}" '2'
    git_commit
}
APPS+=" 'pidgin' '$(gettext 'ICQ, QIP и т.п.') (+AUR)' 'on'"

pkgs_skype()
{
    local PACS
    #extra
    PACS='ekiga'
    #community
    PACS+=' skype-call-recorder'
    #multilib
    PACS+=' skype'
# lib32-libcanberra lib32-libpulse
    pacman_install "-S ${PACS}" '1'
    git_commit
}
APPS+=" 'skype' '$(gettext 'Skype, Ekiga')' 'on'"

pkgs_cryptkeeper()
{
    local PACS
    #community
    PACS='gpg-crypter'
    pacman_install "-S ${PACS}" '1'
    #aur
    PACS='cryptkeeper'
    pacman_install "-S ${PACS}" '2'
    git_commit
}
APPS+=" 'cryptkeeper' '$(gettext 'GUI для шифрования папок') (+AUR)' 'on'"

pkgs_mmex()
{
    local PACS
    #aur
    PACS='mmex'
    pacman_install "-S ${PACS}" '2'
    git_commit
}
APPS+=" 'mmex' '$(gettext 'Менеджер личных финансов') (AUR)' 'off'"

pkgs_clamav()
{
    local PACS
    #extra
    PACS='clamav'
    pacman_install "-S ${PACS}" '1'
    git_commit

    msg_log "$(gettext 'Настраиваю') /etc/clamav/clamd.conf"
    sed -i "
/^Example/s/^/#/;
" "${NS_PATH}/etc/clamav/clamd.conf"
    msg_log "$(gettext 'Настраиваю') /etc/clamav/freshclam.conf"
    sed -i "
/^Example/s/^/#/;
" "${NS_PATH}/etc/clamav/freshclam.conf"
    msg_info "$(gettext 'Пожалуйста, подождите')..."
    chroot_run freshclam
    git_commit
}
APPS+=" 'clamav' '$(gettext 'Антивирус')' 'off'"

pkgs_stardict()
{
    local PACS
    #community
    PACS='stardict'
    pacman_install "-S ${PACS}" '1'
    git_commit
}
APPS+=" 'stardict' '$(gettext 'Словарь')' 'off'"

pkgs_mixxx()
{
    local PACS
    #community
    PACS='mixxx'
    pacman_install "-S ${PACS}" '1'
    git_commit
}
APPS+=" 'mixxx' '$(gettext 'Цифровая DJ система')' 'off'"

pkgs_myrulib()
{
    local PACS
    #aur
    PACS='myrulib'
    pacman_install "-S ${PACS}" '2'
    git_commit
}
APPS+=" 'myrulib' '$(gettext 'Домашняя библиотека') (AUR)' 'off'"

pkgs_blender()
{
    local PACS
    #community
    PACS='blender'
    pacman_install "-S ${PACS}" '1'
    git_commit
}
APPS+=" 'blender' '$(gettext '3D моделирование')' 'off'"

pkgs_sweethome3d()
{
    local PACS
    #aur
    PACS='sweethome3d'
    pacman_install "-S ${PACS}" '2'
    git_commit
}
APPS+=" 'sweethome3d' '$(gettext '3D дизайн интерьера') (AUR)' 'off'"

pkgs_virtualbox()
{
    local PACS
    #community
    PACS='virtualbox virtualbox-host-modules'
    pacman_install "-S ${PACS}" '1'
    #aur
    PACS='virtualbox-ext-oracle'
    pacman_install "-S ${PACS}" '2'
    git_commit
    msg_log "$(gettext 'Настраиваю') /etc/modules-load.d/vbox.conf"
    cat "${DBDIR}modules/etc/modules-load.d/vbox.conf" > "${NS_PATH}/etc/modules-load.d/vbox.conf"
    git_commit
}
APPS+=" 'virtualbox' '$(gettext 'Виртуальная машина') (+AUR)' 'off'"

pkgs_ettercap()
{
    local PACS
    #community
    PACS='ettercap-gtk'
    pacman_install "-S ${PACS}" '1'
    #aur
    PACS='netdiscover hydra nikto'
    pacman_install "-S ${PACS}" '2'
    git_commit
    chroot_run nikto -update
    git_commit
}
APPS+=" 'ettercap' '$(gettext 'Анализ безопасности сети') (+AUR)' 'off'"

pkgs_wireshark()
{
    local PACS
    #extra
    PACS='wireshark-gtk'
    pacman_install "-S ${PACS}" '1'
    git_commit
}
APPS+=" 'wireshark' '$(gettext 'Анализатор трафика для сетей Ethernet')' 'off'"

pkgs_eric()
{
    local PACS
    #extra
    PACS='eric'
    pacman_install "-S ${PACS}" '1'
    #aur
    PACS='eric5-i18n'
    pacman_install "-S ${PACS}" '2'
    git_commit
}
APPS+=" 'eric' '$(gettext 'Python редактор') (+AUR)' 'off'"

pkgs_netbeans()
{
    local PACS
    #community
    PACS='netbeans'
    pacman_install "-S ${PACS}" '1'
    git_commit
}
APPS+=" 'netbeans' '$(gettext 'Java, PHP, C, C++ редактор')' 'off'"

pkgs_kdevelop()
{
    local PACS
    #community
    PACS='kdevelop'
    #community
    PACS+=' qtcreator poedit'
    pacman_install "-S ${PACS}" '1'
    #extra
    PACS="kde-l10n-${SET_LOCAL%_*}"
    pacman_install "-S ${PACS}" '2'
    git_commit
}
APPS+=" 'kdevelop' '$(gettext 'Разработка на C++')' 'off'"

pkgs_kpatience()
{
    local PACS
    #community
    PACS='kdegames-kpatience'
    pacman_install "-S ${PACS}" '1'
    #extra
    PACS="kde-l10n-${SET_LOCAL%_*}"
    pacman_install "-S ${PACS}" '2'
    git_commit
}
APPS+=" 'kpatience' '$(gettext 'Игра. Пасьянсы')' 'on'"

pkgs_urbanterror()
{
    local PACS
    #community
    PACS='urbanterror'
    pacman_install "-S ${PACS}" '1'
    git_commit
}
APPS+=" 'urbanterror' '$(gettext 'Игра. 3D Шутер от первого лица')' 'off'"

pkgs_spring()
{
    local PACS
    #community
    PACS='springlobby spring'
    pacman_install "-S ${PACS}" '1'
    git_commit
}
APPS+=" 'spring' '$(gettext 'Игра. 3D Стратегия')' 'off'"

pkgs_ufoai()
{
    local PACS
    #community
    PACS='ufoai'
    pacman_install "-S ${PACS}" '1'
    git_commit
}
APPS+=" 'ufoai' '$(gettext 'Игра. Смесь ролевой игры и стратегии')' 'off'"

pkgs_0ad()
{
    local PACS
    #community
    PACS='0ad'
    pacman_install "-S ${PACS}" '1'
    git_commit
}
APPS+=" '0ad' '$(gettext 'Игра. 3D Стратегия')' 'off'"


