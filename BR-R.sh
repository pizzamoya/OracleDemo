#!/bin/bash
rm -rf /etc/net/ifaces/enp0s3
 
echo "nameserver 77.88.8.8" >> /etc/resolv.conf
mkdir /etc/net/ifaces/enp0s3
cat <<EOF > /etc/net/ifaces/enp0s3/options
TYPE=eth
DISABLED=no
NM_CONTROLLED=no
BOOTPROTO=static
IPV4_CONFIG=yes
IPV6_CONFIG=yes
EOF
 
sed -i 's/CONFIG_IPV6=no/CONFIG_IPV6=yes/g' /etc/net/ifaces/default/options
mkdir /etc/net/ifaces/enp0s3
mkdir /etc/net/ifaces/enp0s8
 
cp /etc/net/ifaces/enp0s3/options /etc/net/ifaces/enp0s8/options
 
echo 22.22.22.22/24 > /etc/net/ifaces/enp0s3/ipv4address
echo 192.168.200.14/28 > /etc/net/ifaces/enp0s8/ipv4address
echo 2001:22::22/64 > /etc/net/ifaces/enp0s3/ipv6address
echo 2000:200::f/122 > /etc/net/ifaces/enp0s8/ipv6address
echo default via 22.22.22.1 > /etc/net/ifaces/enp0s3/ipv4route
echo default via 2001:22::1 > /etc/net/ifaces/enp0s3/ipv6route  
 
sed -i '10a\net.ipv6.conf.all.forwarding = 1' /etc/net/sysctl.conf
sed -i 's/net.ipv4.ip_forward = 0/net.ipv4.ip_forward = 1/g' /etc/net/sysctl.conf
 
systemctl restart network
 
resolvconf -u
echo "nameserver 77.88.8.8" >> /etc/resolv.conf
apt-get update && apt-get install -y firewalld
systemctl enable --now firewalld
firewall-cmd --permanent --zone=public --add-interface=enp0s3
firewall-cmd --permanent --zone=trusted --add-interface=enp0s8
firewall-cmd --permanent --zone=public --add-masquerade
firewall-cmd --reload
systemctl restart firewalld
 
mkdir /etc/net/ifaces/tun1
cat <<EOF > /etc/net/ifaces/tun1/options
TYPE=iptun
TUNTYPE=gre
TUNLOCAL=22.22.22.22
TUNREMOTE=11.11.11.11
TUNOPTIONS='ttl 64'
HOST=enp0s3
EOF
 
echo 172.16.100.2/24 > /etc/net/ifaces/tun1/ipv4address
echo 2001:100::2/64 > /etc/net/ifaces/tun1/ipv6address
 
systemctl restart network
modprobe gre
 
resolvconf -u
echo "nameserver 77.88.8.8" >> /etc/resolv.conf
 
apt-get update && apt-get install -y frr
 
sed -i 's/ospfd=no/ospfd=yes/g' /etc/frr/daemons
sed -i 's/ospf6d=no/ospf6d=yes/g' /etc/frr/daemons
systemctl enable --now frr
 
systemctl restart frr
 
resolvconf -u
echo "nameserver 77.88.8.8" >> /etc/resolv.conf
 
useradd branch-admin -m -c "Branch admin" -U
passwd branch-admin

useradd network-admin -m -c "Network admin" -U
passwd network-admin

chmod +x /root/OracleDemo/backup.sh
sh /root/OracleDemo/backup.sh
ls /opt/
