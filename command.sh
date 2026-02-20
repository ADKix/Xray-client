#!/bin/sh
set -e
if [ -z "${ADDRESS}" ]; then echo "The ADDRESS environment variable must be set!" >&2; exit 1; fi
if [ -z "${ID}" ]; then echo "The ID environment variable must be set!" >&2; exit 1; fi
if [ -z "${PUBLIC_KEY}" ]; then echo "The PUBLIC_KEY environment variable must be set!" >&2; exit 1; fi
if [ -z "${SHORT_ID}" ]; then echo "The SHORT_ID environment variable must be set!" >&2; exit 1; fi
gateway=$(ip r | sed -n -E 's|default via ([^ ]+) .*|\1|p')
if [ -n "${DNS}" ]; then
  ip route add "${DNS}" via "${gateway}"
  echo "nameserver ${DNS}" >"/etc/resolv.conf"
fi
ip route add "${ADDRESS}" via "${gateway}"
ip tuntap add dev tun0 mode tun
ip addr add 10.0.0.1/24 dev tun0
ip link set tun0 up
ip route del default
ip route add default dev tun0
cat >"/etc/xray.json" <<EOF
{
  "log": {
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "listen": "0.0.0.0",
      "port": 1080,
      "protocol": "socks",
      "settings": {
        "udp": true
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "vless",
      "settings": {
        "vnext": [
          {
            "address": "${ADDRESS}",
            "port": ${PORT},
            "users": [
              {
                "id": "${ID}",
                "encryption": "none",
                "flow": "xtls-rprx-vision"
              }
            ]
          }
        ]
      },
      "streamSettings": {
        "network": "tcp",
        "security": "reality",
        "realitySettings": {
          "fingerprint": "chrome",
          "serverName": "${SNI}",
          "publicKey": "${PUBLIC_KEY}",
          "shortId": "${SHORT_ID}"
        }
      }
    }
  ]
}
EOF
exec xray run -config "/etc/xray.json" &
  exec tun2socks -loglevel warn -device tun0 -proxy socks5://127.0.0.1:1080