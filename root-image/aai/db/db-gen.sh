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

#
# domains.db
# <domain>\t<country>\t<default_timezone>
#
# timezones.db
# <domain>\t<timezone>\t<default_locale>\t<coordinates>\t<comment>
#
# locales.db
# <domain>\t<locale>\t<default_keymap>\t<default_font>
#
# keymaps.db
# <architecture>\t<keymap>\t<xlayout>\t<xmodel>\t<xvariant>\t<xoptions>
#
# fonts.db
# <unicode>\t<font>\t<font_map>\t<font_unimap>
#
# font_maps.db
# <font_map>
#
# font_unimaps.db
# <font_unimap>
#
TEMPFILE="$(mktemp)"
trap "rm -f '${TEMPFILE}'" INT QUIT TERM EXIT


LOCALSEC=(
	'de_BE' 'fr_BE' 'li_BE' 'wa_BE'
	'fr_CA' 'ik_CA' 'iu_CA' 'shs_CA'
	'fr_CH' 'it_CH' 'wae_CH' 'bo_CN' 'ug_CN'
	'el_CY'
	'fy_DE' 'hsb_DE' 'nds_DE'
	'so_DJ'
	'en_DK'
	'ber_DZ'
	'byn_ER' 'gez_ER' 'ti_ER' 'tig_ER'
	'an_ES' 'ast_ES' 'ca_ES' 'eu_ES' 'gl_ES'
	'aa_ET' 'gez_ET' 'om_ET' 'sid_ET' 'so_ET' 'ti_ET' 'wal_ET'
	'sv_FI'
	'br_FR' 'ca_FR' 'oc_FR'
	'cy_GB' 'gd_GB' 'gv_GB' 'kw_GB'
	'yue_HK' 'zh_HK'
	'ca_IT' 'fur_IT' 'lij_IT' 'sc_IT'
	'ar_IN' 'as_IN' 'bho_IN' 'bn_IN' 'bo_IN' 'brx_IN' 'en_IN' 'gu_IN' 'hne_IN' 'kn_IN'
	'kok_IN' 'ks_IN' 'mag_IN' 'mai_IN' 'ml_IN' 'mr_IN' 'or_IN' 'pa_IN' 'sa_IN' 'sd_IN'
	'ta_IN' 'te_IN' 'ur_IN'
	'iw_IL'
	'ga_IE'
	'om_KE' 'sw_KE'
	'ta_LK'
	'de_LU' 'fr_LU'
	'ber_MA'
	'sq_MK'
	'ha_NG' 'ig_NG' 'yo_NG'
	'fy_NL' 'li_NL' 'nds_NL'
	'se_NO' 'nn_NO'
	'mi_NZ'
	'tl_PH' 'en_PH'
	'pa_PK'
	'csb_PL'
	'cv_RU' 'mhr_RU' 'os_RU' 'tt_RU'
	'zh_SG'
	'wo_SN'
	'ku_TR'
	'ru_UA' 'crh_UA'
	'es_US' 'unm_US' 'yi_US'
	'af_ZA' 'nr_ZA' 'nso_ZA' 'ss_ZA' 'st_ZA' 'tn_ZA' 'ts_ZA' 've_ZA' 'xh_ZA' 'zu_ZA'
	'bem_ZM'
)

# Цвет и вид текста сообщений
BLDRED='\e[1;31m' # Red
BLDGRN='\e[1;32m' # Green
BLDYLW='\e[1;33m' # Yellow
BLDBLU='\e[1;34m' # Blue
BLDWHT='\e[1;37m' # White
TXTRST='\e[0m'    # Text Reset

SHARE_DIR=

LOCALSEC_DB="$(mktemp)"
# Удалять при выходе
trap "rm -f '${LOCALSEC_DB}'" INT QUIT TERM EXIT

for I in ${LOCALSEC[*]}
do
	echo ${I}
done \
| sort -u > "${LOCALSEC_DB}"


parse_locale()
{
	local P_LOCALE="${1}"

	local LANGUAGE="$(echo "${P_LOCALE}" | cut -d ' ' -f '1')"
	local CHARSET="$(echo "${P_LOCALE}" | cut -d ' ' -f '2')"

	local CODESET="$(echo "${LANGUAGE}" | cut -d '.' -f '2')"
	local LANGUAGE="$(echo "${LANGUAGE}" | cut -d '.' -f '1')"

	local TERRITORY="$(echo "${LANGUAGE}" | cut -d '_' -f '2')"
	TERRITORY="$(echo "${TERRITORY}" | cut -d '@' -f '1')"
	local LANGUAGE="$(echo "${LANGUAGE}" | cut -d '_' -f '1')"

	local MODYFIER="$(echo "${CODESET}" | cut -d '@' -f '2')"
	local CODESET="$(echo "${CODESET}" | cut -d '@' -f '1')"

	[[ "${MODYFIER}" = "${CODESET}" ]] && MODYFIER=
	[[ "${CODESET}" = "${LANGUAGE}_${TERRITORY}" ]] && CODESET=

	echo "${LANGUAGE}:${TERRITORY}:${CODESET}:${MODYFIER}:${CHARSET}"
}

sort_db_file()
{
	local P_DBFILE="${1}"

	cat "${P_DBFILE}" > "${TEMPFILE}"
	cat "${P_DBFILE}.bak" >> "${TEMPFILE}" 2> /dev/null
	cat "${TEMPFILE}" | LC_ALL=C sort -uf > "${P_DBFILE}"
}

#===============================================================================
# font_maps.db (старая база имеет приоритет!!!)
# <font_map>
#===============================================================================
echo_font_map()
{
	local P_DBFILE="${1}"
	local P_FONT_MAP="${2}"

	if [[ ! -f "${P_DBFILE}.bak" ]] || [[ ! "$(grep "^${P_FONT_MAP}$" "${P_DBFILE}.bak")" ]]
	then
		echo -e "${P_FONT_MAP}"
	fi
}

gen_font_maps_db()
{
	local DBFILE='font_maps'

	local FONT_MAP

	echo -e "${BLDYLW}$(gettext 'Добавляем в базу') ${DBFILE}.db $(gettext 'новые карты шрифтов')${TXTRST}" >&2

	DBFILE="${SHARE_DIR}${DBFILE}.db"
	cp -Pb "${DBFILE}" "${DBFILE}.bak" 2> /dev/null

	find '/usr/share/kbd/consoletrans/' -iname '*.trans' \
	| awk -F '/' '{print $NF}' \
	| sed 's/\.trans$//g' \
	| while read FONT_MAP
	do
		echo_font_map "${DBFILE}" "${FONT_MAP}"
	done > "${DBFILE}"

	sort_db_file "${DBFILE}"
}
#===============================================================================

gen_font_maps_db

#===============================================================================
# font_unimaps.db (старая база имеет приоритет!!!)
# <font_unimap>
#===============================================================================
echo_font_unimap()
{
	local P_DBFILE="${1}"
	local P_FONT_UNIMAP="${2}"

	if [[ ! -f "${P_DBFILE}.bak" ]] || [[ ! "$(grep "^${P_FONT_UNIMAP}$" "${P_DBFILE}.bak")" ]]
	then
		echo -e "${P_FONT_UNIMAP}"
	fi
}

gen_font_unimaps_db()
{
	local DBFILE='font_unimaps'

	local FONT_UNIMAP

	echo -e "${BLDYLW}$(gettext 'Добавляем в базу') ${DBFILE}.db $(gettext 'новые карты шрифтов unicode')${TXTRST}" >&2

	DBFILE="${SHARE_DIR}${DBFILE}.db"
	cp -Pb "${DBFILE}" "${DBFILE}.bak" 2> /dev/null

	find '/usr/share/kbd/unimaps/' -iname '*.uni' \
	| awk -F '/' '{print $NF}' \
	| sed 's/\.uni$//g' \
	| while read FONT_UNIMAP
	do
		echo_font_unimap "${DBFILE}" "${FONT_UNIMAP}"
	done > "${DBFILE}"

	sort_db_file "${DBFILE}"
}
#===============================================================================

gen_font_unimaps_db

#===============================================================================
# fonts.db (старая база имеет приоритет!!!)
# <unicode>\t<font>\t<font_map>\t<font_unimap>
#===============================================================================
get_font_map()
{
	local P_UNICODE="${1}"
	local P_FONT="${2}"

	local FONT_MAP

	echo "${FONT_MAP}"
}

get_font_unimap()
{
	local P_UNICODE="${1}"
	local P_FONT="${2}"

	local FONT_UNIMAP

	echo "${FONT_UNIMAP}"
}

echo_font()
{
	local P_DBFILE="${1}"
	local P_UNICODE="${2}"
	local P_FONT="${3}"

	local FONT_MAP
	local FONT_UNIMAP

	if [[ ! -f "${P_DBFILE}.bak" ]] || [[ ! "$(grep "^${P_UNICODE}[[:space:]]${P_FONT}[[:space:]]" "${P_DBFILE}.bak")" ]]
	then
		FONT_MAP="$(get_font_map "${P_UNICODE}" "${P_FONT}")"
		FONT_UNIMAP="$(get_font_unimap "${P_UNICODE}" "${P_FONT}")"

		echo -e "${P_UNICODE}\t${P_FONT}\t${FONT_MAP}\t${FONT_UNIMAP}"
	fi
}

gen_fonts_db()
{
	local DBFILE='fonts'

	local UNICODE
	local FONT

	echo -e "${BLDYLW}$(gettext 'Добавляем в базу') ${DBFILE}.db $(gettext 'новые шрифты')${TXTRST}" >&2

	DBFILE="${SHARE_DIR}${DBFILE}.db"
	cp -Pb "${DBFILE}" "${DBFILE}.bak" 2> /dev/null

	find '/usr/share/kbd/consolefonts/' -iname '*.psfu.gz' -or  -iname '*.psf.gz' \
	| awk -F '/' '{print $NF}' \
	| sed 's/\.gz$//g;s/\.psfu$/:psfu/g;s/\.psf$/:psf/g' \
	| while read FONT
	do
		UNICODE="$(echo "${FONT}" | cut -d ':' -f '2')"
		FONT="$(echo "${FONT}" | cut -d ':' -f '1')"

		echo_font "${DBFILE}" "${UNICODE}" "${FONT}"
	done > "${DBFILE}"

	sort_db_file "${DBFILE}"
}
#===============================================================================

gen_fonts_db

#===============================================================================
# keymaps.db (старая база имеет приоритет!!!)
# <architecture>\t<keymap>\t<xlayout>\t<xmodel>\t<xvariant>\t<xoptions>
#===============================================================================
get_xlayout()
{
	local P_ARCHITECTURE="${1}"
	local P_KEYMAP="${2}"

	local XLAYOUT
	local XMODEL
	local XVARIANT
	local XOPTIONS

	XLAYOUT="$(grep "^${P_KEYMAP}[[:space:]]" '/usr/share/systemd/kbd-model-map')"
	if [[ "${XLAYOUT}" ]]
	then
		XMODEL="$(echo "${XLAYOUT}" | awk '{print $3}')"
		XVARIANT="$(echo "${XLAYOUT}" | awk '{print $4}')"
		XOPTIONS="$(echo "${XLAYOUT}" | awk '{print $5}')"
		XLAYOUT="$(echo "${XLAYOUT}" | awk '{print $2}')"

		XOPTIONS="$(echo "${XOPTIONS}" | sed 's/grp:shifts_toggle/grp:alt_shift_toggle/')"
		[[ "$(echo "${XLAYOUT}" | grep ',us')" ]] && XLAYOUT="$(echo "us,${XLAYOUT}" | sed 's/,us//')"
#	[[ "${XVARIANT}" = '-' ]] && XVARIANT=
	fi

	echo -e "${XLAYOUT}\t${XMODEL}\t${XVARIANT}\t${XOPTIONS}"
}

echo_keymap()
{
	local P_DBFILE="${1}"
	local P_ARCHITECTURE="${2}"
	local P_KEYMAP="${3}"

	local XLAYOUT

	if [[ ! -f "${P_DBFILE}.bak" ]] || [[ ! "$(grep "^${P_ARCHITECTURE}[[:space:]]${P_KEYMAP}[[:space:]]" "${P_DBFILE}.bak")" ]]
	then
		XLAYOUT="$(get_xlayout "${P_ARCHITECTURE}" "${P_KEYMAP}")"

		echo -e "${P_ARCHITECTURE}\t${P_KEYMAP}\t${XLAYOUT}"
	fi
}

gen_keymaps_db()
{
	local DBFILE='keymaps'

	local ARCHITECTURE
	local KEYMAP

	echo -e "${BLDYLW}$(gettext 'Добавляем в базу') ${DBFILE}.db $(gettext 'новые раскладки')${TXTRST}" >&2

	DBFILE="${SHARE_DIR}${DBFILE}.db"
	cp -Pb "${DBFILE}" "${DBFILE}.bak" 2> /dev/null

	find '/usr/share/kbd/keymaps/' -iname '*.map.gz' \
	| sed 's/^\/usr\/share\/kbd\/keymaps\///g;s/\(.*\)\//\1:/' \
	| sed 's/\.map\.gz$//g' \
	| while read KEYMAP
	do
		ARCHITECTURE="$(echo "${KEYMAP}" | cut -d ':' -f '1')"
		KEYMAP="$(echo "${KEYMAP}" | cut -d ':' -f '2')"

		echo_keymap "${DBFILE}" "${ARCHITECTURE}" "${KEYMAP}"
	done > "${DBFILE}"

	sort_db_file "${DBFILE}"
}
#===============================================================================

gen_keymaps_db

#===============================================================================
# domains.db (старая база имеет приоритет!!!)
# <domain>\t<country>\t<default_timezone>
#===============================================================================
get_country()
{
	local P_DOMAIN="${1}"

	local COUNTRY="$(grep -v '^#' '/usr/share/zoneinfo/iso3166.tab' | grep "^${P_DOMAIN}[[:space:]]" | cut -f '2' | head -n '1')"

	echo "${COUNTRY}"
}

get_timezone()
{
	local P_DOMAIN="${1}"

	local TIMEZONE="$(grep "^${P_DOMAIN}[[:space:]]" '/usr/share/zoneinfo/zone.tab' | cut -f '3')"

	if (( $(echo "${TIMEZONE}" | wc -l) < 2 ))
	then
		echo "${TIMEZONE}"
		return
	fi
#    echo "${TIMEZONE}"
}

echo_domain()
{
	local P_DBFILE="${1}"
	local P_DOMAIN="${2}"

	local COUNTRY
	local TIMEZONE

	if [[ ! -f "${P_DBFILE}.bak" ]] || [[ ! "$(grep "^${P_DOMAIN}[[:space:]]" "${P_DBFILE}.bak")" ]]
	then
		COUNTRY="$(get_country "${P_DOMAIN}")"
		TIMEZONE="$(get_timezone "${P_DOMAIN}")"

		echo -e "${P_DOMAIN}\t${COUNTRY}\t${TIMEZONE}"
	fi
}

gen_domains_db()
{
	local DBFILE='domains'

	local DOMAIN

	echo -e "${BLDYLW}$(gettext 'Добавляем в базу') ${DBFILE}.db $(gettext 'новые домены')${TXTRST}" >&2

	DBFILE="${SHARE_DIR}${DBFILE}.db"
	cp -Pb "${DBFILE}" "${DBFILE}.bak" 2> /dev/null

	grep -v '^#' '/usr/share/zoneinfo/iso3166.tab' \
	| awk -F "\t" '{print $1}' > "${TEMPFILE}"

	grep '^[A-Z]' '/usr/share/zoneinfo/zone.tab' \
	| awk -F "\t" '{print $1}' >> "${TEMPFILE}"

	grep '^#[a-z]' '/etc/locale.gen' \
	| tr -d '#' \
	| awk '{print $1}' \
	| awk -F '.' '{print $1}' \
	| awk -F '@' '{print $1}' \
	| awk -F '_' '{print $2}' >> "${TEMPFILE}"

	cat "${TEMPFILE}" \
	| sort -u \
	| while read DOMAIN
	do
		echo_domain "${DBFILE}" "${DOMAIN}"
	done > "${DBFILE}"

	sort_db_file "${DBFILE}"
}
#===============================================================================

gen_domains_db

#===============================================================================
# timezones.db (старая база имеет приоритет!!!)
# <domain>\t<timezone>\t<default_locale>\t<coordinates>\t<comment>
#===============================================================================
get_locale_def()
{
	local P_CHARSET="${1}"

	local LOCALE

	while read LOCALE
	do
		if [[ "${1}" ]]
		then
			[[ "$(echo "${LOCALE}" | grep "${P_CHARSET}")" ]] && echo "${LOCALE}" && break
		else
			echo "${LOCALE}" && break
		fi
	done
}

get_locale()
{
	local P_DOMAIN="${1}"
	local P_TIMEZONE="${2}"

	local LOCALE
	local LOCALES="$(grep '^#[a-z]' '/etc/locale.gen' | tr -d '#' \
	| grep -e "_${P_DOMAIN}[ |.|\n|@]" | grep -v -f "${LOCALSEC_DB}")"

	[[ ! "${LOCALE}" ]] && LOCALE="$(echo "${LOCALES}" | get_locale_def 'UTF-8')"
	[[ ! "${LOCALE}" ]] && LOCALE="$(echo "${LOCALES}" | get_locale_def 'KOI8')"
	[[ ! "${LOCALE}" ]] && LOCALE="$(echo "${LOCALES}" | get_locale_def 'ISO')"
	[[ ! "${LOCALE}" ]] && LOCALE="$(echo "${LOCALES}" | get_locale_def)"

	echo "${LOCALE}" | head -n '1'
}
# @todo Не работает, нужно доделать!
get_coordinates()
{
	local P_DOMAIN="${1}"
	local P_TIMEZONE="${2}"

	local COORDINATES="$(grep "^${P_DOMAIN}[[:space:]]" '/usr/share/zoneinfo/zone.tab' | grep "[[:space:]]${P_TIMEZONE}[[:space:]]")"
	local COMMENT="$(echo "${COORDINATES}" | cut -f '4')"
	COORDINATES="$(echo "${COORDINATES}" | cut -f '2')"

	echo -e "${COORDINATES}\t${COMMENT}"
}

echo_timezone()
{
	local P_DBFILE="${1}"
	local P_DOMAIN="${2}"
	local P_TIMEZONE="${3}"

	local LOCALE
	local COORDINATES

	if [[ ! -f "${P_DBFILE}.bak" ]] || [[ ! "$(grep "^${P_DOMAIN}[[:space:]]${P_TIMEZONE}[[:space:]]" "${P_DBFILE}.bak")" ]]
	then
		LOCALE="$(get_locale "${P_DOMAIN}" "${P_TIMEZONE}")"
		COORDINATES="$(get_coordinates "${P_DOMAIN}" "${P_TIMEZONE}")"

		echo -e "${P_DOMAIN}\t${P_TIMEZONE}\t${LOCALE}\t${COORDINATES}"
	fi
}

gen_timezones_db()
{
	local DBFILE='timezones'

	local DOMAIN
	local TIMEZONE
	local TIMEZONES

	echo -e "${BLDYLW}$(gettext 'Добавляем в базу') ${DBFILE}.db $(gettext 'новые временные зоны')${TXTRST}" >&2

	DBFILE="${SHARE_DIR}${DBFILE}.db"
	cp -Pb "${DBFILE}" "${DBFILE}.bak" 2> /dev/null

	cut -f '1' "${SHARE_DIR}domains.db" \
	| while read DOMAIN
	do
		TIMEZONE=

		TIMEZONES="$(grep "^${DOMAIN}[[:space:]]" '/usr/share/zoneinfo/zone.tab' | cut -f '3')"
		if [[ "${TIMEZONES}" ]]
		then
			echo "${TIMEZONES}" \
			| while read TIMEZONE
			do
				echo_timezone "${DBFILE}" "${DOMAIN}" "${TIMEZONE}"
			done
		else
			echo_timezone "${DBFILE}" "${DOMAIN}" "${TIMEZONE}"
		fi
	done > "${DBFILE}"

	sort_db_file "${DBFILE}"
}
#===============================================================================

gen_timezones_db

#===============================================================================
# locales.db (старая база имеет приоритет!!!)
# <domain>\t<locale>\t<default_keymap>\t<default_font>
#===============================================================================
get_font()
{
	local P_LOCALE="${2}"

	local FONT

	echo "${FONT}"
}

get_keymap()
{
	local P_LOCALE="$(parse_locale "${1}")"

	local KEYMAP
	local TERRITORY="$(echo "${P_LOCALE}" | cut -d ':' -f '2' | tr '[:upper:]' '[:lower:]')"
	local LANGUAGE="$(echo "${P_LOCALE}" | cut -d ':' -f '1')"
	local ISO="$(echo "${P_LOCALE}" | cut -d ':' -f '5')"

	if [[ "$(echo "${ISO}" | cut -d '-' -f '1')" = 'ISO' ]]
	then
		ISO="$(echo "${ISO}" | cut -d '-' -f '2,3')"
	else
		ISO=
	fi

	[[ ! "${TERRITORY}" ]] && [[ ! "${LANGUAGE}" ]] && echo "${KEYMAP}" && return

	[[ "${TERRITORY}" == 'en' ]] && echo 'us' && return
	KEYMAP="$(localectl list-keymaps | grep "^${TERRITORY}$" | head -n '1')"
	[[ "${KEYMAP}" ]] && echo "${KEYMAP}" && return

	KEYMAP="$(localectl list-keymaps | grep "^${TERRITORY}-latin-$(echo "${ISO}" | cut -d '-' -f '2')" | head -n '1')"
	[[ "${KEYMAP}" ]] && echo "${KEYMAP}" && return

	KEYMAP="$(localectl list-keymaps | grep "^${TERRITORY}-latin" | head -n '1')"
	[[ "${KEYMAP}" ]] && echo "${KEYMAP}" && return

	[[ "${LANGUAGE}" == 'en' ]] && echo 'us' && return
	KEYMAP="$(localectl list-keymaps | grep "^${LANGUAGE}$" | head -n '1')"
	[[ "${KEYMAP}" ]] && echo "${KEYMAP}" && return

	KEYMAP="$(localectl list-keymaps | grep "^${LANGUAGE}-latin-$(echo "${ISO}" | cut -d '-' -f '2')" | head -n '1')"
	[[ "${KEYMAP}" ]] && echo "${KEYMAP}" && return

	KEYMAP="$(localectl list-keymaps | grep "^${LANGUAGE}-latin" | head -n '1')"
	[[ "${KEYMAP}" ]] && echo "${KEYMAP}" && return

}

echo_locale()
{
	local P_DBFILE="${1}"
	local P_DOMAIN="${2}"
	local P_LOCALE="${3}"

	local FONT
	local KEYMAP

	if [[ ! -f "${P_DBFILE}.bak" ]] || [[ ! "$(grep "^${P_DOMAIN}[[:space:]]${P_LOCALE}[[:space:]]" "${P_DBFILE}.bak")" ]]
	then
		FONT="$(get_font "${P_LOCALE}")"
		KEYMAP="$(get_keymap "${P_LOCALE}")"

		echo -e "${P_DOMAIN}\t${P_LOCALE}\t${KEYMAP}\t${FONT}"
	fi
}

gen_locales_db()
{
	local DBFILE='locales'

	local DOMAIN
	local LOCALE
	local LOCALES

	echo -e "${BLDYLW}$(gettext 'Добавляем в базу') ${DBFILE}.db $(gettext 'новые локали')${TXTRST}" >&2

	DBFILE="${SHARE_DIR}${DBFILE}.db"
	cp -Pb "${DBFILE}" "${DBFILE}.bak" 2> /dev/null

	cut -f '1' "${SHARE_DIR}domains.db" \
	| while read DOMAIN
	do
		LOCALE=

		LOCALES="$(grep '^#[a-z]' '/etc/locale.gen' | tr -d '#' | grep -e "_${DOMAIN}[ |.|\n|@]")"
		if [[ "${LOCALES}" ]]
		then
			echo "${LOCALES}" \
			| while read LOCALE
			do
				echo_locale "${DBFILE}" "${DOMAIN}" "${LOCALE}"
			done
		else
			echo_locale "${DBFILE}" "${DOMAIN}" "${LOCALE}"
		fi
	done > "${DBFILE}"

	sort_db_file "${DBFILE}"
}
#===============================================================================

gen_locales_db
