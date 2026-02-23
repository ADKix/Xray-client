# Xray client in a tiny [Docker image](https://hub.docker.com/repository/docker/adkix/xray-client) based on Alpine Linux.

### It uses [Xray-core](https://github.com/XTLS/Xray-core) and [tun2socks](https://github.com/xjasonlyu/tun2socks).

Supported protocols:
- VLESS Reality

Supported architectures:
- linux/arm64/v8
- linux/arm/v7
- linux/386
- linux/amd64

Note: pinging hosts through the container does not work due to tunnel limitations.

#### It is recommended to use it in conjunction with [ADKix/Xray-server](https://github.com/ADKix/Xray-server)!

------------
### Examples:
* [RouterOS](#routeros-example)
* [GNU/Linux](#linux-example)
------------

### RouterOS example:
##### (tested on MikroTik hAP ax³ with ROS 7.21.3 using internal storage with tmpfs in RAM)

Enable container mode (only once):
```
/system/package enable container
/system/package apply-changes
/system/device-mode update container=yes
```

Creating a container and a network interface for it, providing internet access, changing the MSS:
```
/interface/veth add address=172.16.0.2/24 gateway=172.16.0.1 name=veth1
/ip/address add address=172.16.0.1/24 interface=veth1
/ip/firewall/nat add action=masquerade chain=srcnat out-interface=veth1
/ip/firewall/mangle add action=change-mss chain=forward new-mss=1360 out-interface=veth1 passthrough=yes protocol=tcp tcp-flags=syn tcp-mss=1420-65535
/container/envs add key=ADDRESS value="<server IP address>" list=xray-client
/container/envs add key=PORT value=<port number on the server [optional, default "443"]> list=xray-client
/container/envs add key=ID value="<ID>" list=xray-client
/container/envs add key=PUBLIC_KEY value="<public key>" list=xray-client
/container/envs add key=SHORT_ID value="<short ID>" list=xray-client
/container/envs add key=SNI value="<SNI [optional, default "google.com"]>" list=xray-client
/container/config set registry-url=registry-1.docker.io
/container add remote-image=adkix/xray-client root-dir=xray-client/ tmpfs=/tmp:64M:0777 interface=veth1 envlist=xray-client start-on-boot=yes
/container start 0
```

View logs:
```
/container/log print where container="xray-client"
```

Adding a route via a container:
```
/ip/route add dst-address=<destination IP address> gateway=172.16.0.2
```

Test (get public IP address via routed "ifconfig.me"):
```
# Enable fetch mode (only once):
/system/device-mode update fetch=yes
# Get public IP:
/tool fetch url="https://ifconfig.me/ip" output=user
# Get IP addresses of the domain "ifconfig.me" and the container; add a route to the domain via the container:
:local ip [:resolve "ifconfig.me"]; :local gateway [/container shell 0 cmd="hostname -i" as-value]; /ip/route add dst-address=$ip gateway=$gateway comment="ifconfig.me"
# Get public IP (it should now match the server's public IP address):
/tool fetch url="https://ifconfig.me/ip" output=user
# Delete a route:
/ip/route remove numbers=[/ip/route find comment="ifconfig.me"]
```

### Linux example:
##### (using docker-compose)

Create a "docker-compose.yml" file with the following contents:
```
services:
  client:
    image: "adkix/xray-client"
    environment:
      - ADDRESS=<server IP address>
      - PORT=<port number on the server [optional, default "443"]>
      - ID=<ID>
      - PUBLIC_KEY=<public key>
      - SHORT_ID=<short ID>
      - SNI=<SNI [optional, default "google.com"]>
    devices:
      - /dev/net/tun
    cap_add:
      - NET_ADMIN
    restart: unless-stopped
```

Creating a container and a network interface for it:
```
docker-compose up -d
```

View logs:
```
docker-compose logs
```

Adding a route via a container:
```
gateway="$(docker-compose exec "client" hostname -i)"
ip route add "<destination IP address>" via "${gateway}"
```

Test (get public IP address via routed "ifconfig.me"):
```
wget -q "ifconfig.me/ip" -O-  # get public IP
ip="$(ping -c 1 "ifconfig.me" | sed -n '1p' | awk -F'[()]' '{print $2}')"  # IP address of the domain "ifconfig.me"
gateway="$(docker-compose exec "client" hostname -i | tr -d '\r')"  # IP address of the container
ip route add "${ip}" via "${gateway}"  # add a route to the domain via the container
wget -q "ifconfig.me/ip" -O-  # get public IP (it should now match the server's public IP address)
ip route del "${ip}"  # delete a route
```
