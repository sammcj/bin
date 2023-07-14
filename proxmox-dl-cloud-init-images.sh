#!/usr/bin/env bash
# Based upon https://www.apalrd.net/posts/2023/pve_cloud/

### TODO:
# https://vectops.com/2020/01/provision-proxmox-vms-with-ansible-quick-and-easy/

RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
# YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
# MAGENTA=$(tput setaf 5)
# CYAN=$(tput setaf 6)
RESET=$(tput sgr0)

function vmid_available() {
        # check if VMID already exists
    if qm list | grep -q "[ ]*${1}"; then
        echo ""
        echo "${RED}VMID $1 already exists${RESET} - exiting..."
        echo ""
        return 1
    else
        echo ""
        echo "${BLUE}Downloading image${RESET}"
        echo ""
        return 0
    fi
}

# Create template
# args:
#  vm_id
#  vm_name
#  file name in the current directory
function create_template() {
    echo "" && echo "${GREEN}Creating template $2 ($1)${RESET}" && echo ""
    	# install qemu-quest-agent
    virt-customize -a "$3" --install qemu-guest-agent
        # Create new VM
    qm create "$1" --name "$2" --ostype l26
        # Set networking to default bridge & set tag to 5
    qm set "$1" --net0 virtio,bridge=vmbr0,tag=5
        # Set display to serial
    qm set "$1" --serial0 socket --vga serial0
        # Set memory, cpu, type defaults
        # If you are in a cluster, you might need to change cpu type
    qm set "$1" --memory 512 --cores 1 --cpu host
        # Set boot device to new file
    qm set "$1" --scsi0 "${storage}":0,import-from="$(pwd)"/"$3",discard=on
        # Set scsi hardware as default boot disk using virtio scsi single
    qm set "$1" --boot order=scsi0 --scsihw virtio-scsi-single
        # Enable Qemu guest agent in case the guest has it available
    qm set "$1" --agent enabled=1,fstrim_cloned_disks=1
        # Add cloud-init device
    qm set "$1" --ide2 "${storage}":cloudinit

        # # from https://forum.proxmox.com/threads/cloud-init-image-only-applies-configuration-on-second-boot.93414/
        # qm set "$1" --efidisk0 "${storage}":0
        # qm set "$1" --bios ovmf
        # qm set "$1" --scsi1 "${storage}":cloudinit

        # Set CI ip config
        # IP6 = auto means SLAAC (a reliable default with no bad effects on non-IPv6 networks)
        # IP = DHCP means what it says, so leave that out entirely on non-IPv4 networks to avoid DHCP delays
    qm set "$1" --ipconfig0 "ip6=auto,ip=dhcp"
        # Import the ssh keyfile
    qm set "$1" --sshkeys "${ssh_keyfile}"
        # If you want to do password-based auth instaed
        # Then use this option and comment out the line above
        # qm set "$1" --cipassword password
        # Add the user
    qm set "$1" --ciuser "${username}"
        # Resize the disk to 8G, a reasonable minimum. You can expand it more later.
        # If the disk is already bigger than 8G, this will fail, and that is okay.
    qm disk resize "$1" scsi0 8G
        # Make it a template
    qm template "$1"

    # Remove file when done
    rm "$3"
}

# apt update -y
# apt install libguestfs-tools -y

# create ssh_keyfile
grep 'tom@' /root/.ssh/authorized_keys > /root/.ssh/authorized_keys.vm
grep ansible /root/.ssh/authorized_keys >> /root/.ssh/authorized_keys.vm
grep terraform /root/.ssh/authorized_keys >> /root/.ssh/authorized_keys.vm
# Path to your ssh authorized_keys file
# Alternatively, use /etc/pve/priv/authorized_keys if you are already authorized
# on the Proxmox system
#  export ssh_keyfile=/root/id_rsa.pub
#  export ssh_keyfile=/etc/pve/priv/authorized_keys
export ssh_keyfile=/root/.ssh/authorized_keys.vm

# Username to create on VM template
export username=tom

# Name of your storage
export storage=ceph_pool


## Debian
# Buster (10)
if vmid_available 100010; then
    wget "https://cloud.debian.org/images/cloud/buster/latest/debian-10-genericcloud-amd64.qcow2" && \
    create_template 100010 "debian-10-template" "debian-10-genericcloud-amd64.qcow2"
fi
# Bullseye (11)
if vmid_available 100011; then
    wget "https://cloud.debian.org/images/cloud/bullseye/latest/debian-11-genericcloud-amd64.qcow2" && \
    create_template 100011 "debian-11-template" "debian-11-genericcloud-amd64.qcow2"
fi
# Bookworm (12)
if vmid_available 100012; then
    wget "https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2" && \
    create_template 100012 "debian-12-template" "debian-12-genericcloud-amd64.qcow2"
fi
# # Trixie (13 dailies - not yet released)
# if vmid_available 100013; then
# wget "https://cloud.debian.org/images/cloud/trixie/daily/latest/debian-13-genericcloud-amd64-daily.qcow2"
# create_template 100013 "temp-debian-13-daily" "debian-13-genericcloud-amd64-daily.qcow2"
# fi

## Ubuntu
# 20.04 LTS (Focal Fossa)
if vmid_available 100020; then
    wget "https://cloud-images.ubuntu.com/releases/focal/release/ubuntu-20.04-server-cloudimg-amd64.img" && \
    create_template 100020 "ubuntu-20-04-lts-template" "ubuntu-20.04-server-cloudimg-amd64.img"
fi
# 22.04 LTS (Jammy Jellyfish)
if vmid_available 100022; then
    wget "https://cloud-images.ubuntu.com/releases/22.04/release/ubuntu-22.04-server-cloudimg-amd64.img" && \
    create_template 100022 "ubuntu-22-04-lts-template" "ubuntu-22.04-server-cloudimg-amd64.img"
fi
# 23.04 (Lunar Lobster)
if vmid_available 100023; then
    wget "https://cloud-images.ubuntu.com/releases/23.04/release/ubuntu-23.04-server-cloudimg-amd64.img" && \
    create_template 100023 "ubuntu-23-04-template" "ubuntu-23.04-server-cloudimg-amd64.img"
fi
# # # 23.10 (Mantic Minotaur) - daily builds
# qm destroy 100029 --destroy-unreferenced-disks 1 --purge 1 && echo "" && echo "${BLUE}Deleted existing Mantic Minotaur daily build...${RESET}" && echo ""
# wget "https://cloud-images.ubuntu.com/mantic/current/mantic-server-cloudimg-amd64.img" && \
# create_template 100029 "ubuntu-23-10-daily-template" "mantic-server-cloudimg-amd64.img"


## Fedora 37
if vmid_available 100037; then
    # Image is compressed, so need to uncompress first
    wget https://download.fedoraproject.org/pub/fedora/linux/releases/37/Cloud/x86_64/images/Fedora-Cloud-Base-37-1.7.x86_64.raw.xz && \
    xz -d -v Fedora-Cloud-Base-37-1.7.x86_64.raw.xz && \
    create_template 100037 "fedora-37-template" "Fedora-Cloud-Base-37-1.7.x86_64.raw"
fi

## Fedora 38
if vmid_available 100038; then
    # Image is compressed, so need to uncompress first
    wget https://download.fedoraproject.org/pub/fedora/linux/releases/38/Cloud/x86_64/images/Fedora-Cloud-Base-38-1.6.x86_64.raw.xz && \
    xz -d -v Fedora-Cloud-Base-38-1.6.x86_64.raw.xz && \
    create_template 100038 "fedora-38-template" "Fedora-Cloud-Base-38-1.6.x86_64.raw"
fi

# ## CentOS Stream
# # Stream 8
# wget https://cloud.centos.org/centos/8-stream/x86_64/images/CentOS-Stream-GenericCloud-8-20220913.0.x86_64.qcow2
# create_template 930 "temp-centos-8-stream" "CentOS-Stream-GenericCloud-8-20220913.0.x86_64.qcow2"
# # Stream 9 (daily) - they don't have a 'latest' link?
# wget https://cloud.centos.org/centos/9-stream/x86_64/images/CentOS-Stream-GenericCloud-9-20230123.0.x86_64.qcow2
# create_template 931 "temp-centos-9-stream-daily" "CentOS-Stream-GenericCloud-9-20230123.0.x86_64.qcow2"
