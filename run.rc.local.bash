#!/bin/bash

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

old_ip=$(cat /etc/tsuru/tsuru.conf | grep ^host | sed "s/host: http:\/\///" | sed "s/:8080//")
if [[ "$old_ip" == "" ]]; then
    error "Couldn't find old_ip"
    exit 1
fi
new_ip=$(public_ip)
sed "s/$old_ip/$new_ip/g" /etc/tsuru/tsuru.conf > tsuru-new.conf | grep $new_ip tsuru-new.conf && sudo mv tsuru-new.conf /etc/tsuru/tsuru.conf
if [[ $? -gt 0 ]]; then
    error "Cannot change public ip in /etc/tsuru/tsuru.conf, please do it manually."
    exit 1
fi
sed "s/$old_ip/$new_ip/g" /etc/gandalf.conf > gandalf-new.conf | grep $new_ip gandalf-new.conf && sudo mv gandalf-new.conf /etc/gandalf.conf
if [[ $? -gt 0 ]]; then
    error "Cannot change public ip in /etc/gandalf.conf, please do it manually."
    exit 1
fi
EOF
)

echo "$RC_LOCAL_FILE" | sudo tee /etc/rc.local > /dev/null
