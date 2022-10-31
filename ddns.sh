#!/usr/bin/env bash
# shellcheck disable=all

# set -e: exit script immediately upon error
# set -u: treat unset variables as an error
# set -o pipefail: cause a pipeline to fail, if any command within it fails
set -eu -o pipefail

PATH=$PATH:/usr/local/bin
FILE="$HOME/Dropbox/lastip"

DIRNAME="$(dirname $FILE)"
if ! [ -d ${DIRNAME} ] ; then
    mkdir -pm 0700 ${DIRNAME}
    touch ${FILE}
fi

LASTIP=$(cat "$FILE")
WAN="$(dig +short myip.opendns.com @resolver1.opendns.com)"

if [[ "$LASTIP" != "$WAN" ]]; then
    echo "IP changed from $LASTIP to $WAN"
    echo "$WAN" > "$FILE"

    if [[ "$HOSTNAME" == "unraid" ]]; then
        [[ -f /root/.boto ]] && . /root/.boto
        CLI53="docker run --rm -e AWS_ACCESS_KEY_ID=${aws_access_key_id} -e AWS_SECRET_ACCESS_KEY=${aws_secret_access_key} tomhoover/docker-cli53"
        # ${CLI53} rrcreate --replace --ttl 300 t0m.us @ A $WAN     # previous command (for python cli53)
        # ${CLI53} rrcreate --replace t0m.us '@ 300 A' ${WAN}       # won't work--space must be inside single quote to work
        # ${CLI53} rrcreate --replace t0m.us 'www 300 A '${WAN}     # changed www to CNAME
        ${CLI53} rrcreate --replace t0m.us '@ 300 A '${WAN}
    else
        [ "$(which cli53)" ] || brew install cli53
        CLI53="cli53"
        ${CLI53} rrcreate --replace t0m.us ${HOSTNAME}' 300 A '${WAN}
    fi
fi

# https://github.com/barnybug/cli53
