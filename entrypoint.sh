#!/bin/sh
set -e
export PATH="${PATH}:/tmp"
if ! command -v xray >/dev/null; then
  7z x -y -bsp0 -bso0 "xray.7z" -o"/tmp"
  chmod +x "/tmp/xray"
fi
if ! command -v tun2socks >/dev/null; then
  7z x -y -bsp0 -bso0 "tun2socks.7z" -o"/tmp"
  chmod +x "/tmp/tun2socks"
fi
exec "$@"