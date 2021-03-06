#!/bin/bash -e

if [[ ! -f /var/cache/virtualbox_4.3_installed ]]; then
    echo "deb http://download.virtualbox.org/virtualbox/debian trusty contrib" | sudo tee -a /etc/apt/sources.list
    wget -q http://download.virtualbox.org/virtualbox/debian/oracle_vbox.asc -O- | sudo apt-key add -

    sudo apt-get update
    sudo apt-get install -y --force-yes linux-headers-$(uname -r)
    sudo apt-get install -y --force-yes build-essential
    sudo apt-get install -y --force-yes virtualbox-4.3
    sudo apt-get install -y --force-yes dkms

    wget http://download.virtualbox.org/virtualbox/4.3.10/Oracle_VM_VirtualBox_Extension_Pack-4.3.10-93012.vbox-extpack
    sudo VBoxManage extpack install Oracle_VM_VirtualBox_Extension_Pack-4.3.10-93012.vbox-extpack

    sudo apt-get install -y --force-yes unzip git
    wget https://releases.hashicorp.com/packer/0.8.6/packer_0.8.6_linux_amd64.zip
    unzip packer_0.8.6_linux_amd64.zip
    sudo cp packer* /usr/local/bin/
    sudo touch /var/cache/virtualbox_4.3_installed
fi
