#!/usr/bin/env bash

# shellcheck source=/dev/null
[[ -f ${HOME}/.SECRETS ]] && . "${HOME}"/.SECRETS

# vultr-cli os list
# ID	NAME				ARCH	FAMILY
# 124	Windows 2012 R2 Standard x64	x64	windows
# 159	Custom				x64	iso
# 164	Snapshot			x64	snapshot
# 167	CentOS 7 x64			x64	centos
# 180	Backup				x64	backup
# 186	Application			x64	application
# 240	Windows 2016 Standard x64	x64	windows
# 270	Ubuntu 18.04 LTS x64		x64	ubuntu
# 327	FreeBSD 12 x64			x64	freebsd
# 352	Debian 10 x64 (buster)		x64	debian
# 371	Windows 2019 Standard x64	x64	windows
# 381	CentOS 7 SELinux x64		x64	centos
# 387	Ubuntu 20.04 LTS x64		x64	ubuntu
# 391	Fedora CoreOS Stable		x64	fedora-coreos
# 401	CentOS 8 Stream x64		x64	centos
# 424	Fedora CoreOS Next		x64	fedora-coreos
# 425	Fedora CoreOS Testing		x64	fedora-coreos
# 447	FreeBSD 13 x64			x64	freebsd
# 448	Rocky Linux x64			x64	rockylinux
# 452	AlmaLinux x64			x64	almalinux
# 477	Debian 11 x64 (bullseye)	x64	debian
# 501	Windows 2022 Standard x64	x64	windows
# 521	Windows Core 2022 Standard x64	x64	windows
# 522	Windows Core 2016 Standard x64	x64	windows
# 523	Windows Core 2019 Standard x64	x64	windows
# 535	Arch Linux x64			x64	archlinux
# 542	CentOS 9 Stream x64		x64	centos
# 1743	Ubuntu 22.04 LTS x64		x64	ubuntu
# 1744	Fedora 36 x64			x64	fedora
# 1797	OpenBSD 7.1 x64			x64	openbsd
# 1868	AlmaLinux 9 x64			x64	almalinux
# 1869	Rocky Linux 9 x64		x64	rockylinux
# 1929	Fedora 37 x64			x64	fedora
# 1946	Ubuntu 22.10 x64		x64	ubuntu
# 1968	OpenBSD 7.2 x64			x64	openbsd

read -rsn 1 -p "(A)rch, (D)ebian 11, (F)edora 37, or (U)buntu 22.04 " choice;

case $choice in
    a|A)
        # 535	Arch Linux x64			x64	archlinux
        ID=535
        NAME=arch
        ;;
    d|D)
        # 477	Debian 11 x64 (bullseye)	x64	debian
        ID=477
        NAME=debian
        ;;
    f|F)
        # 1929	Fedora 37 x64			x64	fedora
        ID=1929
        NAME=fedora
        ;;
    u|U)
        # 1743	Ubuntu 22.04 LTS x64		x64	ubuntu
        ID=1743
        NAME=ubuntu
        ;;
    *)
        exit
        ;;
esac

~/bin/update-vultr-hosts.sh
for x in {0..99}; do grep -q "${NAME}${x} " ~/.ssh/vultr_config || break; done
vultr-cli instance create \
    --host="${NAME}${x}" \
    --ipv6=true \
    --label="${NAME}${x}" \
    --os=${ID} \
    --plan=vhp-1c-1gb-amd \
    --region=dfw \
    --ssh-keys=68ce220c-d2c8-4dfb-b989-f3c7d57f04c8 \

sleep 10
~/bin/update-vultr-hosts.sh
cat ~/.ssh/vultr_config
