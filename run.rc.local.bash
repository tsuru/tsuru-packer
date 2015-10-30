#!/bin/bash

# Copyright 2015 tsuru authors. All rights reserved.
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.

RC_LOCAL_FILE=$(cat <<'EOF'
#!/bin/bash -ue

function get_inet_addr() {
    # Return IP address based on ifconfig's output
    /sbin/ifconfig | grep -A1 $1 2> /dev/null | grep "inet addr" | tail -n1 | \
                                     sed "s/[^:]*:\([0-9.]*\).*/\1/"
}

function public_ip {
    # Try to take the public IP using AWS EC2's metadata API:
    local ip=$(curl -s -L -m2 http://169.254.169.254/latest/meta-data/public-ipv4 || true)

    # Try to use DigitalOcean's metadata API as fallback:
    if [[ "$ip" == "" || "$ip" == "not found" ]]; then
        ip=$(curl -s -L -m2 http://169.254.169.254/metadata/v1/interfaces/public/0/ipv4/address || true)
    fi

    # Try via ifconfig
    if [[ "$ip" == "" || "$ip" == "not found" ]]; then
        ip=$(get_inet_addr eth)
    fi
    if [[ "$ip" == "" || "$ip" == "not found" ]]; then
        ip=$(get_inet_addr venet0)
    fi
    if [[ "$ip" == "" || "$ip" == "not found" ]]; then
        ip=$(get_inet_addr wlan)
    fi

    # Try to access an external API to discover public IP
    if [[ "$ip" == "" || "$ip" == "not found" ]]; then
        ip=$(curl -s -L -m2 'https://api.ipify.org' || true)
    fi

    # Damn, it!
    if [[ "$ip" == "" || "$ip" == "not found" ]]; then
        error "Couldn't find a suitable public IP. Please change it manually.."
        exit 1
    fi

    echo "${ip}"
}

function aws_local_ip {
    # Try to take the public IP using AWS EC2's metadata API:
    local ip=$(curl -s -L -m2 http://169.254.169.254/latest/meta-data/local-ipv4 || true)
    echo "${ip}"
}

function private_ip {
    local private_ip=$(aws_local_ip)
    if [[ $private_ip == "" ]]; then
        private_ip=$(public_ip)
    fi
    if [[ $private_ip == "127.0.0.1" ]]; then
        echo "Couldn't find suitable local_ip, please run with --host-ip <external ip>"
        exit 1
    fi
    echo "${private_ip}"
}



old_public_ip=$(cat /etc/tsuru/tsuru.conf | grep ^host | sed "s/host: http:\/\///" | sed "s/:8080//")
old_private_ip=$(cat ~ubuntu/.tsuru_target | awk -F : '{print $1}')
if [[ "$old_private_ip" == "" ]]; then
    old_private_ip=$(cat ~ubuntu/.tsuru/target | awk -F : '{print $1}')
fi

if [[ "$old_public_ip" == "" || "$old_private_ip" == "" ]]; then
    error "Couldn't find old private or public ip"
    exit 1
fi
new_public_ip=$(public_ip)
new_private_ip=$(private_ip)

sed -i "s/$old_public_ip/$new_public_ip/g" /etc/tsuru/tsuru.conf
if [[ $? -gt 0 ]]; then
    error "Cannot change public ip in /etc/tsuru/tsuru.conf, please do it manually."
    exit 1
fi

sed -i "s/$old_public_ip/$new_public_ip/g" /etc/gandalf.conf
if [[ $? -gt 0 ]]; then
    error "Cannot change public ip in /etc/gandalf.conf, please do it manually."
    exit 1
fi

sed -i "s/$old_private_ip/$new_private_ip/g" ~ubuntu/.tsuru_target
sed -i "s/$old_private_ip/$new_private_ip/g" ~ubuntu/.tsuru/target

sed -i "s/$old_private_ip/$new_private_ip/g" ~ubuntu/.tsuru_targets
sed -i "s/$old_private_ip/$new_private_ip/g" ~ubuntu/.tsuru/targets

sed -i "s/$old_private_ip/$new_private_ip/g" ~git/.bash_profile
if [[ $? -gt 0 ]]; then
    error "Cannot change private ip in ~git/.bash_profile, please do it manually."
    exit 1
fi

EOF
)

echo "$RC_LOCAL_FILE" | sudo tee /etc/rc.local > /dev/null
