#!/usr/bin/env bash

MYHOST=$(uname -n | sed 's/\..*//')     # alternative to $(hostname -s), as arch does not install 'hostname' by default

[[ "${MYHOST}" = "ariel" ]] || exit

# set -e: exit script immediately upon error
# set -u: treat unset variables as an error
# set -o pipefail: cause a pipeline to fail, if any command within it fails
set -eu -o pipefail

#BACKUPDIR="${HOME}/backups/getmail"
BACKUPDIR="/Volumes/BackupNAS/getmail"

[ -f "/tmp/getmail.lock" ] && echo "" && echo "WARNING: Lock file exists..." && echo "" && exit
touch /tmp/getmail.lock

cd "${HOME}"/.getmail
rcfiles=""
for file in rc-* ; do
  MAILDIRPATH=$(echo "${file}" | sed -e 's/rc-//' -e 's|:|/|' )
  mkdir -p $BACKUPDIR/"$MAILDIRPATH"/{cur,new,tmp}
  rcfiles="$rcfiles --rcfile $file"
done

#exec /usr/local/bin/getmail $rcfiles $@
/usr/local/bin/getmail "$rcfiles" "$@"
rm /tmp/getmail.lock
