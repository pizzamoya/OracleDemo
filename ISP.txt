#!/bin/bash
 
mkdir /etc/net/ifaces/enp0s3
cat <<EOF > /etc/net/ifaces/enp0s3/options
TYPE=eth
DISABLED=no
NM_CONTROLLED=no
BOOTPROTO=dhcp
IPV4_CONFIG=yes
EOF
 
sed -i 's/CONFIG_IPV6=no/CONFIG_IPV6=yes/g' /etc/net/ifaces/default/options
mkdir /etc/net/ifaces/enp0s8
mkdir /etc/net/ifaces/enp0s9
mkdir /etc/net/ifaces/enp0s10
 
cp /etc/net/ifaces/enp0s3/options /etc/net/ifaces/enp0s8/options
sed -i '5a\IPV6_CONFIG=yes' /etc/net/ifaces/enp0s8/options
sed -i 's/dhcp/static/' /etc/net/ifaces/enp0s8/options
cp /etc/net/ifaces/enp0s8/options /etc/net/ifaces/enp0s9/options
cp /etc/net/ifaces/enp0s8/options /etc/net/ifaces/enp0s10/options
 
echo 11.11.11.1/24 > /etc/net/ifaces/enp0s8/ipv4address
echo 22.22.22.1/24 > /etc/net/ifaces/enp0s9/ipv4address
echo 33.33.33.1/24 > /etc/net/ifaces/enp0s10/ipv4address
echo 2001:11::1/64 > /etc/net/ifaces/enp0s8/ipv6address
echo 2001:22::1/64 > /etc/net/ifaces/enp0s9/ipv6address
echo 2001:33::1/64 > /etc/net/ifaces/enp0s10/ipv6address
 
sed -i '10a\net.ipv6.conf.all.forwarding = 1' /etc/net/sysctl.conf
sed -i 's/net.ipv4.ip_forward = 0/net.ipv4.ip_forward = 1/g' /etc/net/sysctl.conf
 
resolvconf -u
echo "nameserver 77.88.8.8" >> /etc/resolv.conf
apt-get update && apt-get install -y firewalld
systemctl enable --now firewalld
firewall-cmd --permanent --zone=public --add-interface=enp0s3
firewall-cmd --permanent --zone=trusted --add-interface=enp0s8
firewall-cmd --permanent --zone=trusted --add-interface=enp0s9
firewall-cmd --permanent --zone=trusted --add-interface=enp0s10
firewall-cmd --permanent --zone=public --add-masquerade
firewall-cmd --reload
systemctl restart firewalld
systemctl restart network

apt-get install iperf3
systemctl enable --now iperf3
