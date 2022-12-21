#!/usr/bin/env bash
# shellcheck disable=SC2001
# shellcheck disable=SC2016

# set -e: exit script immediately upon error
# set -u: treat unset variables as an error
# set -o pipefail: cause a pipeline to fail, if any command within it fails
# set -eu -o pipefail
set -u -o pipefail

# . $HOME/.keychain/$(hostname)-sh

[[ -f ${HOME}/.SECRETS ]] && . "${HOME}"/.SECRETS

cd "$HOME"/data/software/gh-backup || exit

DATETIME=$(date "+%Y%m%d-%H%M%S")
mv gh-backup.txt "$DATETIME--gh-backup.txt"

echo " ---------------------"
echo "| get tomhoover repos |"
echo " ---------------------"

pages=$(curl -Iu tomhoover:"$GH_BACKUP_GITHUB_API_TOKEN" https://api.github.com/users/tomhoover/repos | sed -nr 's/^[Ll]ink:.*page=([0-9]+).*/\1/p')

for page in $(seq 1 "$pages"); do
    curl -u tomhoover:"$GH_BACKUP_GITHUB_API_TOKEN" "https://api.github.com/users/tomhoover/repos?page=$page" | jq -r '.[].html_url' |
    while read -r rp; do
      # git clone $rp
      echo "$rp" | sed 's|^.*github.com/||' >> gh-backup.tmp
    done
done

# echo "----------" >> gh-backup.tmp

echo " -------------------"
echo "| get starred repos |"
echo " -------------------"

pages=$(curl -Iu tomhoover:"$GH_BACKUP_GITHUB_API_TOKEN" https://api.github.com/users/tomhoover/starred | sed -nr 's/^[Ll]ink:.*page=([0-9]+).*/\1/p')

for page in $(seq 1 "$pages"); do
    curl -u tomhoover:"$GH_BACKUP_GITHUB_API_TOKEN" "https://api.github.com/users/tomhoover/starred?page=$page" | jq -r '.[].html_url' |
    while read -r rp; do
      echo "$rp" | sed 's|^.*github.com/|starred/|' | \
          grep -v 'youtube-dl2/youtube-dl' | \
          grep -v 'voisine/breadwallet-ios' | \
          grep -v 'infochimps-away/infochimps.github.com' \
          >> gh-backup.tmp
    done
done

sort -u gh-backup.tmp > gh-backup.txt && rm gh-backup.tmp

# cd /Users/tom/data/software/gh-backup/starred && for i in */*; do mr -c .mrconfig register $i; done && mr up
# cd /Users/tom/data/software/gh-backup/tomhoover && for i in *; do mr -c .mrconfig register $i; done && mr up

cd /Users/tom/data/software/gh-backup && echo "" > .mrconfig && echo "# ----- $DATETIME -----" > .mrconfig
cd /Users/tom/data/software/gh-backup && for i in starred/*/*; do mr -c .mrconfig register "$i"; done
cd /Users/tom/data/software/gh-backup && for i in tomhoover/*; do mr -c .mrconfig register "$i"; done && gsed -i'' -e '/^skip/d' -e '/^checkout.*/a skip = ([ "$1" = update ] && ! hours_since "$1" 12)' .mrconfig

cd /Users/tom/data/software/gh-backup/starred && echo "" > .mrconfig && echo "# ----- $DATETIME -----" > .mrconfig
cd /Users/tom/data/software/gh-backup/starred && for i in */*; do mr -c .mrconfig register "$i"; done && gsed -i'' -e '/^skip/d' -e '/^checkout.*/a skip = ([ "$1" = update ] && ! hours_since "$1" 12)' .mrconfig

cd /Users/tom/data/software/gh-backup/tomhoover && echo "" > .mrconfig && echo "# ----- $DATETIME -----" > .mrconfig
cd /Users/tom/data/software/gh-backup/tomhoover && for i in *; do mr -c .mrconfig register "$i"; done && gsed -i'' -e '/^skip/d' -e '/^checkout.*/a skip = ([ "$1" = update ] && ! hours_since "$1" 12)' .mrconfig

# sed -e '/^\[\$HOME/! s/^\[/[\$HOME\//g' -e 's/^\[/~[/g' .mrconfig |tr '\n' '^' |tr '~' '\n' |sort |tr -s '^' |tr '^' '\n' > sorted.mrconfig
