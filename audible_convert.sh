#!/usr/bin/env bash

# DeDRMs all audiobooks downloaded with audible_dl.sh
# Imports all *.pdf files, as well as generated *.m4b files, into Calibre
# Moves all files to ./aax & ./m4b

# set -e: exit script immediately upon error
# set -u: treat unset variables as an error
# set -o pipefail: cause a pipeline to fail, if any command within it fails
set -euo pipefail

# shellcheck source=/dev/null
[[ -f ${HOME}/.SECRETS ]] && . "${HOME}"/.SECRETS

# shellcheck source=/dev/null
[[ -f ${HOME}/bin/COLORS ]] && . "${HOME}"/bin/COLORS

BOOKS="/Users/tom/data/books/audible"
CALIBRE="/Users/tom/tmp/calibre_auto_upload"
# shellcheck disable=SC2034
VERSION_CONTROL=numbered

CP="cp"
MV="mv"
if [[ "$(uname)" = Darwin ]] ; then
    CP="gcp"
    MV="gmv"
fi

cd ${BOOKS} || exit 1

mkdir -p "$BOOKS/{aax,dl,m4b}"
mkdir -p "$CALIBRE"

for f in dl/*.aax; do
    # does filename exist? if not, continue:
    [ -f "$f" ] || continue

    echo
    if [ -f "${f%.*}.m4b" ] ; then
        echo "${BLUE}Skipping $f...${RESET}"
        continue
    fi

    echo "${CYAN}Converting $f...${RESET}"
    echo
    ffmpeg -activation_bytes "${AUDIBLE_ACTIVATION_BYTES}" -i "$f" -codec copy "${f%.*}.m4b"
    if [ -f "${f%.*}.m4b" ] ; then
        FILE="${f%-*}"
        echo
        echo "${MAGENTA}Copying ${f%.*}.m4b into calibre...${RESET}"
        $CP -b "${f%.*}.m4b" "$CALIBRE"
        [[ -f "${FILE}.pdf" ]] && echo "${MAGENTA}Copying ${FILE}.pdf into calibre...${RESET}" && $CP -b "${FILE}.pdf" "$CALIBRE"

        echo "${CYAN}Moving $f...${RESET}"
        $MV -b "$f" aax
        echo "${CYAN}Moving ${f%.*}.m4b...${RESET}"
        $MV -b "${f%.*}.m4b" m4b

        [[ -f "${FILE}-annotations.json" ]] && echo "${CYAN}Moving ${FILE}-annotations.json...${RESET}" && $MV -b "${FILE}-annotations.json" aax
        [[ -f "${FILE}-chapters.json" ]]    && echo "${CYAN}Moving ${FILE}-chapters.json...${RESET}"    && $MV -b "${FILE}-chapters.json" aax
        [[ -f "${FILE}_(500).jpg" ]]        && echo "${CYAN}Moving ${FILE}_(500).jpg...${RESET}"        && $MV -b "${FILE}_(500).jpg" aax
        [[ -f "${FILE}.pdf" ]]              && echo "${CYAN}Moving ${FILE}.pdf...${RESET}"              && $MV -b "${FILE}.pdf" m4b
    fi
done

for f in dl/*.aaxc; do
    # does filename exist? if not, continue:
    [ -f "$f" ] || continue

    echo
    if [ -f "${f%.*}.m4b" ] ; then
        echo "${BLUE}Skipping $f...${RESET}"
        continue
    fi
    if [ -f "${f%.*}.voucher" ] ; then
        AUDIBLE_KEY=$(jq --raw-output '.["content_license"]["license_response"]["key"]' "${f%.*}.voucher")
        AUDIBLE_IV=$(jq --raw-output '.["content_license"]["license_response"]["iv"]' "${f%.*}.voucher")

        echo "${CYAN}Converting $f...${RESET}"
        echo
        ffmpeg -audible_key "$AUDIBLE_KEY" -audible_iv "$AUDIBLE_IV" -i "$f" -codec copy "${f%.*}.m4b"
        if [ -f "${f%.*}.m4b" ] ; then
            FILE="${f%-*}"
            echo
            echo "${MAGENTA}Copying ${f%.*}.m4b into calibre...${RESET}"
            $CP -b "${f%.*}.m4b" "$CALIBRE"
            [[ -f "${FILE}.pdf" ]] && echo "${MAGENTA}Copying ${FILE}.pdf into calibre...${RESET}" && $CP -b "${FILE}.pdf" "$CALIBRE"

            echo "${CYAN}Moving $f...${RESET}"
            $MV -b "$f" aax
            echo "${CYAN}Moving ${f%.*}.m4b...${RESET}"
            $MV -b "${f%.*}.m4b" m4b
            echo "${CYAN}Moving ${f%.*}.voucher...${RESET}"
            $MV -b "${f%.*}.voucher" aax

            [[ -f "${FILE}-annotations.json" ]] && echo "${CYAN}Moving ${FILE}-annotations.json...${RESET}" && $MV -b "${FILE}-annotations.json" aax
            [[ -f "${FILE}-chapters.json" ]]    && echo "${CYAN}Moving ${FILE}-chapters.json...${RESET}"    && $MV -b "${FILE}-chapters.json" aax
            [[ -f "${FILE}_(500).jpg" ]]        && echo "${CYAN}Moving ${FILE}_(500).jpg...${RESET}"        && $MV -b "${FILE}_(500).jpg" aax
            [[ -f "${FILE}.pdf" ]]              && echo "${CYAN}Moving ${FILE}.pdf...${RESET}"              && $MV -b "${FILE}.pdf" m4b
        fi
    else
        echo
        echo "${RED}${f%.*}.voucher does not exist!${RESET}"
        echo
        exit 99
    fi
done

echo
echo "${YELLOW}Delete any backups shown below:${RESET}"
echo

find "$BOOKS" -name '*~' -print
find "$CALIBRE" -name '*~' -print
