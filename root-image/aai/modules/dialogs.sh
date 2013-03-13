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


# Временный файл для dialog
TEMPFILE="$(mktemp)"
# Удалять при выходе из скрипта
#trap "rm -f '${TEMPFILE}' && part_unmount" EXIT

# dialog по умолчанию, если запускается в Xorg то использовать Xdialog
# при отладке не используется
DIALOG='dialog --clear --colors'


dialog_menu()
{
    local TITLE="${1}"
    local DEFAULT_ITEM="${2}"
    local MENU="${3}"
    local ITEMS="${4}"
    local PARAMS="${5}"

    local TEMP="${DIALOG}
${PARAMS}
--backtitle '${AAI_VER}'
--title '${TITLE}'
--default-item '${DEFAULT_ITEM}'
--menu '${MENU}' 0 0 0
${ITEMS}"

    eval "$(tr '\n' ' ' <<< "${TEMP}")"
}

dialog_inputbox()
{
    local TITLE="${1}"
    local INPUTBOX="${2}"
    local TEXT="${3}"
    local PARAMS="${4}"

    local TEMP="${DIALOG}
${PARAMS}
--backtitle '${AAI_VER}'
--title '${TITLE}'
--inputbox '${INPUTBOX}' 0 0
'${TEXT}'"

    eval "$(tr '\n' ' ' <<< "${TEMP}")"
}

dialog_passwordbox()
{
    local TITLE="${1}"
    local PASSWORDBOX="${2}"
    local PARAMS="${3}"

    local TEMP="${DIALOG}
${PARAMS}
--backtitle '${AAI_VER}'
--title '${TITLE}'
--passwordbox '${PASSWORDBOX}' 0 0"

    eval "$(tr '\n' ' ' <<< "${TEMP}")"
}

dialog_yesno()
{
    local TITLE="${1}"
    local TEXT="${2}"
    local PARAMS="${3}"

    local TEMP="${DIALOG}
${PARAMS}
--backtitle '${AAI_VER}'
--title '${TITLE}'
--yesno '${TEXT}' 0 0"

    eval "$(tr '\n' ' ' <<< "${TEMP}")"
}

dialog_programbox()
{
    local TITLE="${1}"
    local TEXT="${2}"
    local PARAMS="${3}"

    local TEMP="${DIALOG}
${PARAMS}
--backtitle '${AAI_VER}'
--title '${TITLE}'
--programbox '${TEXT}' 30 80"

    eval "$(tr '\n' ' ' <<< "${TEMP}")"
}

dialog_msgbox()
{
    local TITLE="${1}"
    local TEXT="${2}"
    local PARAMS="${3}"

    local TEMP="${DIALOG}
${PARAMS}
--backtitle '${AAI_VER}'
--title '${TITLE}'
--msgbox '${TEXT}' 0 0"

    eval "$(tr '\n' ' ' <<< "${TEMP}")"
}

dialog_warn()
{
    local TEXT="${1}"

    dialog_msgbox "$(gettext 'Внимание!!!')" "${TEXT}"
}

dialog_textbox()
{
    local TITLE="${1}"
    local TEXT="${2}"
    local PARAMS="${3}"

    local TEMP="${DIALOG}
${PARAMS}
--backtitle '${AAI_VER}'
--title '${TITLE}'
--textbox '${TEXT}' 0 0"

    eval "$(tr '\n' ' ' <<< "${TEMP}")"
}

dialog_checklist()
{
    local TITLE="${1}"
    local CHECKLIST="${2}"
    local ITEMS="${3}"
    local PARAMS="${4}"

    local TEMP="${DIALOG}
${PARAMS}
--backtitle '${AAI_VER}'
--title '${TITLE}'
--checklist '${CHECKLIST}' 0 0 0
${ITEMS}"

    eval "$(tr '\n' ' ' <<< "${TEMP}")"
}

