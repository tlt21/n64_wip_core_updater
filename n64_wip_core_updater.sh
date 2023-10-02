#!/bin/bash
# Copyright (c) 2023

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# You can download the latest version of this tool from:
# https://github.com/tlt21/n64_wip_core_updater

download_file() {
    local DOWNLOAD_PATH="${1}"
    local DOWNLOAD_URL="${2}"
    for (( COUNTER=0; COUNTER<=60; COUNTER+=1 )); do
        if [ ${COUNTER} -ge 1 ] ; then
            sleep 1s
        fi
        set +e
        curl ${CURL_SSL:-} --fail --location -o "${DOWNLOAD_PATH}" "${DOWNLOAD_URL}" &> /dev/null
        local CMD_RET=$?
        set -e

        case ${CMD_RET} in
            0)
                export CURL_SSL="${CURL_SSL:-}"
                return
                ;;
            60|77|35|51|58|59|82|83)
                if [ -f /etc/ssl/certs/cacert.pem ] ; then
                    export CURL_SSL="--cacert /etc/ssl/certs/cacert.pem"
                    continue
                fi

                set +e
                dialog --keep-window --title "Bad Certificates" --defaultno \
                    --yesno "CA certificates need to be fixed, do you want me to fix them?\n\nNOTE: This operation will delete files at /etc/ssl/certs" \
                    7 65
                local DIALOG_RET=$?
                set -e

                if [[ "${DIALOG_RET}" == "0" ]] ; then
                    local RO_ROOT="false"
                    if mount | grep "on / .*[(,]ro[,$]" -q ; then
                        RO_ROOT="true"
                    fi
                    [ "${RO_ROOT}" == "true" ] && mount / -o remount,rw
                    rm /etc/ssl/certs/* 2> /dev/null || true
                    echo
                    echo "Installing cacert.pem from https://curl.se"
                    curl --insecure --location -o /etc/ssl/certs/cacert.pem "https://curl.se/ca/cacert.pem"
                    sync
                    [ "${RO_ROOT}" == "true" ] && mount / -o remount,ro
                    echo
                    export CURL_SSL="--cacert /etc/ssl/certs/cacert.pem"
                    continue
                fi

                set +e
                dialog --keep-window --title "Insecure Connection" --defaultno \
                    --yesno "Would you like to run this tool using an insecure connection?\n\nNOTE: You should fix the certificates instead." \
                    7 67
                DIALOG_RET=$?
                set -e

                if [[ "${DIALOG_RET}" == "0" ]] ; then
                    echo
                    echo "WARNING! Connection is insecure."
                    export CURL_SSL="--insecure"
                    sleep 5s
                    echo
                    continue
                fi

                echo "No secure connection is possible without fixing the certificates."
                exit 1
                ;;
            *)
                echo "No Internet connection, please try again later."
                exit 1
                ;;
        esac
    done

    echo "Internet connection failed, please try again later."
    exit 1
}


download_file_as_string() {
    local DOWNLOAD_URL="${1}"
    for (( COUNTER=0; COUNTER<=60; COUNTER+=1 )); do
        if [ ${COUNTER} -ge 1 ] ; then
            sleep 1s
        fi
        set +e
        local content
        content=$(curl ${CURL_SSL:-} --fail --location -s "${DOWNLOAD_URL}")
        local CMD_RET=$?
        set -e

        case ${CMD_RET} in
            0)
                export CURL_SSL="${CURL_SSL:-}"
                echo "${content}"
                return
                ;;
            60|77|35|51|58|59|82|83)
                if [ -f /etc/ssl/certs/cacert.pem ] ; then
                    export CURL_SSL="--cacert /etc/ssl/certs/cacert.pem"
                    continue
                fi

                set +e
                dialog --keep-window --title "Bad Certificates" --defaultno \
                    --yesno "CA certificates need to be fixed, do you want me to fix them?\n\nNOTE: This operation will delete files at /etc/ssl/certs" \
                    7 65
                local DIALOG_RET=$?
                set -e

                if [[ "${DIALOG_RET}" == "0" ]] ; then
                    local RO_ROOT="false"
                    if mount | grep "on / .*[(,]ro[,$]" -q ; then
                        RO_ROOT="true"
                    fi
                    [ "${RO_ROOT}" == "true" ] && mount / -o remount,rw
                    rm /etc/ssl/certs/* 2> /dev/null || true
                    echo
                    echo "Installing cacert.pem from https://curl.se"
                    curl --insecure --location -o /etc/ssl/certs/cacert.pem "https://curl.se/ca/cacert.pem"
                    sync
                    [ "${RO_ROOT}" == "true" ] && mount / -o remount,ro
                    echo
                    export CURL_SSL="--cacert /etc/ssl/certs/cacert.pem"
                    continue
                fi

                set +e
                dialog --keep-window --title "Insecure Connection" --defaultno \
                    --yesno "Would you like to run this tool using an insecure connection?\n\nNOTE: You should fix the certificates instead." \
                    7 67
                DIALOG_RET=$?
                set -e

                if [[ "${DIALOG_RET}" == "0" ]] ; then
                    echo
                    echo "WARNING! Connection is insecure."
                    export CURL_SSL="--insecure"
                    sleep 5s
                    echo
                    continue
                fi

                echo "No secure connection is possible without fixing the certificates."
                exit 1
                ;;
            *)
                echo "No Internet connection, please try again later."
                exit 1
                ;;
        esac
    done

    echo "Internet connection failed, please try again later."
    exit 1
}


# Download the latest release using the download_file function
download_dir="/media/fat/Scripts"
filename="N64.rbf"
download_url="https://api.github.com/repos/RobertPeip/Mister64/releases/latest"

echo "Getting Latest release URL"
url=$(download_file_as_string "$download_url" | jq -r '.assets[0].browser_download_url')
echo $url

echo "Downloading the latest release..."
download_file "$download_dir/$filename" "$url"

# Move the downloaded file to the desired folder, overwriting if it already exists
echo "Moving the downloaded file to the destination folder..."
mv -f "$download_dir/$filename" "/media/fat/_Console/$filename"

echo "Latest release downloaded and moved to the destination folder."
