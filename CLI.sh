#!/bin/bash
rm -rf /etc/net/ifaces/ens19
 
echo "nameserver 77.88.8.8" >> /etc/resolv.conf
mkdir /etc/net/ifaces/ens19
cat <<EOF > /etc/net/ifaces/ens19/options
TYPE=eth
DISABLED=no
NM_CONTROLLED=no
BOOTPROTO=static
IPV4_CONFIG=yes
IPV6_CONFIG=yes
EOF
 
sed -i 's/CONFIG_IPV6=no/CONFIG_IPV6=yes/g' /etc/net/ifaces/default/options
mkdir /etc/net/ifaces/ens19
mkdir /etc/net/ifaces/ens20
cp /etc/net/ifaces/ens19/options /etc/net/ifaces/ens20/options

echo 33.33.33.33/24 > /etc/net/ifaces/ens19/ipv4address
echo 44.44.44.1/24 > /etc/net/ifaces/ens20/ipv4address
echo 2001:33::33/64 > /etc/net/ifaces/ens19/ipv6address
echo 2001:44::1/64 > /etc/net/ifaces/ens20/ipv6address
echo default via 33.33.33.1 > /etc/net/ifaces/ens19/ipv4route
echo default via 2001:33::1 > /etc/net/ifaces/ens19/ipv6route  
echo default via 44.44.44.1 > /etc/net/ifaces/ens20/ipv4route
echo default via 2001:44::1 > /etc/net/ifaces/ens20/ipv6route

sed -i '10a\net.ipv6.conf.all.forwarding = 1' /etc/net/sysctl.conf
sed -i 's/net.ipv4.ip_forward = 0/net.ipv4.ip_forward = 1/g' /etc/net/sysctl.conf
 
systemctl restart network
 
resolvconf -u
echo "nameserver 77.88.8.8" >> /etc/resolv.conf
apt-get update

useradd admin -m -c "Admin" -U
passwd admin
