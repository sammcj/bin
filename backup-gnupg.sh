#!/usr/bin/env sh

# set -e: exit script immediately upon error
# set -u: treat unset variables as an error
set -eu

KEY=gnupg
KEY_BACKUPDIR=/Volumes/zz_backups/${KEY}
FILENAME=$(date +%Y%m%d-%H%M%S).tgz.gpg

cd || exit

# shellcheck disable=SC2174
if ! [ -d ${KEY_BACKUPDIR} ] ; then mkdir -pm 0700 ${KEY_BACKUPDIR} ; fi

tar --exclude .gnupg/random_seed -czvf - .gnupg | gpg --cipher-algo aes256 -co "$KEY_BACKUPDIR/$FILENAME"

# decrypt with:
#gpg -o - xxx.tgz.gpg | tar xzvf -
