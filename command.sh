#!/bin/sh
set -e
gateway=$(ip r | sed -n -E 's|default via ([^ ]+) .*|\1|p')
if [ -n "${DNS}" ]; then
  ip route add "${DNS}" via "${gateway}"
  echo "nameserver ${DNS}" >"/etc/resolv.conf"
fi
if [ -z "${ADDRESS}" ]; then echo "The ADDRESS environment variable must be set!" >&2; exit 1; fi
if [ -z "${ID}" ]; then echo "The ID environment variable must be set!" >&2; exit 1; fi
if [ -z "${PUBLIC_KEY}" ]; then echo "The PUBLIC_KEY environment variable must be set!" >&2; exit 1; fi
if [ "${NETWORK}" = "xhttp" ]; then
  cat >"/etc/xray.json" <<-EOF
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
                    "encryption": "none"
                  }
                ]
              }
            ]
          },
          "streamSettings": {
						"network": "xhttp",
            "security": "reality",
            "realitySettings": {
              "fingerprint": "chrome",
              "serverName": "${SNI}",
              "publicKey": "${PUBLIC_KEY}"
            }
          }
        }
      ]
    }
	EOF
elif [ "${NETWORK}" = "tcp" ]; then
  cat >"/etc/xray.json" <<-EOF
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
              "publicKey": "${PUBLIC_KEY}"
            }
          }
        }
      ]
    }
	EOF
else
  echo 'The NETWORK environment variable must be set to "tcp" or "xhttp"!' >&2
  exit 1
fi

ip route add "${ADDRESS}" via "${gateway}"
ip tuntap add dev tun0 mode tun
ip addr add 10.0.0.1/24 dev tun0
ip link set tun0 up
ip route del default
ip route add default dev tun0

exec xray run -config "/etc/xray.json" &
  exec tun2socks -loglevel warn -device tun0 -proxy socks5://127.0.0.1:1080