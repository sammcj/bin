#!/bin/sh
# requires https://github.com/StevenBlack/hosts

cd ~/src/github.com/stevenblack/hosts/ || exit
cp ~/.config/hosts/* .
#./makeHosts
python3 updateHostsFile.py -a -o alternates/tch -e porn
cat blacklist >> alternates/tch/hosts
git checkout hosts
git checkout readmeData.json

if [ ! "$1" = "runfromcron" ] ; then
    scp ~/src/github.com/stevenblack/hosts/alternates/tch/hosts manuel:/tmp
    echo "enter sudo password for manuel"
    ssh -t manuel 'sudo mv /tmp/hosts /etc && sudo chown root /etc/hosts'
    ssh manuel 'ls -l /etc/hosts'
fi
