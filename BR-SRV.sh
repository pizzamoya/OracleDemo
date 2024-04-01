#!/bin/bash
rm -rf /etc/net/ifaces/ens18
 
echo "nameserver 77.88.8.8" >> /etc/resolv.conf
mkdir /etc/net/ifaces/ens18
cat <<EOF > /etc/net/ifaces/ens18/options
TYPE=eth
DISABLED=no
NM_CONTROLLED=no
BOOTPROTO=static
IPV4_CONFIG=yes
IPV6_CONFIG=yes
EOF
 
sed -i 's/CONFIG_IPV6=no/CONFIG_IPV6=yes/g' /etc/net/ifaces/default/options
mkdir /etc/net/ifaces/ens18
 

echo 192.168.200.1/28 > /etc/net/ifaces/ens18/ipv4address
echo 2000:200::1/124 > /etc/net/ifaces/ens18/ipv6address
echo default via 192.168.200.14 > /etc/net/ifaces/ens18/ipv4route
echo default via 2000:200::f > /etc/net/ifaces/ens18/ipv6route  
 
sed -i '10a\net.ipv6.conf.all.forwarding = 1' /etc/net/sysctl.conf
sed -i 's/net.ipv4.ip_forward = 0/net.ipv4.ip_forward = 1/g' /etc/net/sysctl.conf
 
systemctl restart network
 
resolvconf -u
echo "nameserver 77.88.8.8" >> /etc/resolv.conf
apt-get update

useradd branch-admin -m -c "Branch admin" -U
passwd branch-admin

useradd network-admin -m -c "Network admin" -U
passwd network-admin
