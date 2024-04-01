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
mkdir /etc/net/ifaces/enp0s9
 
cp /etc/net/ifaces/enp0s3/options /etc/net/ifaces/enp0s8/options
cp /etc/net/ifaces/enp0s8/options /etc/net/ifaces/enp0s9/options
 
echo 11.11.11.11/24 > /etc/net/ifaces/enp0s3/ipv4address
echo 192.168.100.62/26 > /etc/net/ifaces/enp0s8/ipv4address
echo 44.44.44.44/24 > /etc/net/ifaces/enp0s9/ipv4address
echo 2001:11::11/64 > /etc/net/ifaces/enp0s3/ipv6address
echo 2000:100::3f/122 > /etc/net/ifaces/enp0s8/ipv6address
echo 2001:44::44/64 > /etc/net/ifaces/enp0s9/ipv6address
echo default via 11.11.11.1 > /etc/net/ifaces/enp0s3/ipv4route
echo default via 2001:11::1 > /etc/net/ifaces/enp0s3/ipv6route  
 
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
TUNLOCAL=11.11.11.11
TUNREMOTE=22.22.22.22
TUNOPTIONS='ttl 64'
HOST=enp0s3
EOF
 
echo 172.16.100.1/24 > /etc/net/ifaces/tun1/ipv4address
echo 2001:100::1/64 > /etc/net/ifaces/tun1/ipv6address
 
systemctl restart network
modprobe gre
 
resolvconf -u
echo "nameserver 77.88.8.8" >> /etc/resolv.conf
 
apt-get update && apt-get install -y frr
 
sed -i 's/ospfd=no/ospfd=yes/g' /etc/frr/daemons
sed -i 's/ospf6d=no/ospf6d=yes/g' /etc/frr/daemons
systemctl enable --now frr
 
cat <<EOF >> /etc/frr/frr.conf
!
interface tun1
 ipv6 ospf6 area 0
 no ip ospf passive
exit
!
interface enp0s8
 ipv6 ospf6 area 0
exit
!
router ospf
 passive-interface default
 network 172.16.100.0/24 area 0
 network 192.168.100.0/26 area 0
exit
!
router ospf6
 ospf6 router-id 11.11.11.11
exit
!
EOF
systemctl restart frr
 
resolvconf -u
echo "nameserver 77.88.8.8" >> /etc/resolv.conf
 
apt-get update && apt-get install -y dhcp-server
 
sed -i 's/DHCPDARGS=/DHCPDARGS=enp0s8/g' /etc/sysconfig/dhcpd
sed -i 's/DHCPDARGS=/DHCPDARGS=enp0s8/g' /etc/sysconfig/dhcpd6
 
cp /etc/dhcp/dhcpd.conf.example /etc/dhcp/dhcpd.conf
 
cat <<EOF > /etc/dhcp/dhcpd.conf
# dhcpd.conf
 
default-lease-time 6000;
max-lease-time 72000;
 
authoritative;
 
subnet 192.168.100.0 netmask 255.255.255.192 {
  range 192.168.100.5 192.168.100.61;
  option routers 192.168.100.62;
}
 
#host hq-srv {
# hardware ethernet "mac-address hq-srv";
#  fixed-address 192.168.100.1;
#}
EOF
systemctl enable --now dhcpd
 
cp /etc/dhcp/dhcpd6.conf.sample /etc/dhcp/dhcpd6.conf
 
cat <<EOF > /etc/dhcp/dhcpd6.conf
# Server configuration file example for DHCPv6
default-lease-time 2592000;
preferred-lifetime 604000;
option dhcp-renewal-time 36000;
option dhcp-rebinding-time 72000;
 
allow leasequery;
 
option dhcp6.preference 255;
 
option dhcp6.info-refresh-time 21600;
 
subnet6 2000:100::/122 {
	range6 2000:100::2 2000:100::3f;
}
 
#host hq-srv {
#	host-identifier option
#		dhcp6.client-id <DUID>;
#	fixed-address 2000:100::1;
#	fixed-prefix6 2000:100::/122;
#}
EOF
systemctl enable --now dhcpd6
 
resolvconf -u
echo "nameserver 77.88.8.8" >> /etc/resolv.conf
 
apt-get update && apt-get install -y radvd
 
echo net.ipv6.conf.enp0s8.accept_ra = 2 >> /etc/net/sysctl.conf 
systemcrtl restart network
 
cat <<EOF  > /etc/radvd.conf
# NOTE: there is no such thing as a working "by-default" configuration file.
#       At least the prefix needs to be specified.  Please consult the radvd.conf(5)
#       man page and/or /usr/share/doc/radvd-*/radvd.conf.example for help.
#
#
interface enp0s8
{
	AdvSendAdvert on;
	AdvManagedFlag on;
	AdvOtherConfigFlag on;
	prefix 2000:100::/122
	{
		AdvOnLink on;
		AdvAutonomous on;
		AdvRouterAddr on;
	};
];
EOF
 
systemctl restart dhcpd6
systemctl enable --now radvd
 
useradd admin -m -c "Admin" -U
passwd admin
 
useradd network-admin -m -c "Network admin" -U
passwd network-admin
 
apt-get install -y iperf3
systemctl enable --now iperf3
 
iperf3 -c 11.11.11.1 --get-server-output > /root/iperf3_logfile.txt
 
chmod +x /root/OracleDemo/backup.sh
sh /root/backup.sh
 
firewall-cmd --permanent --zone=public --add-forward-port=port=22:proto=tcp:toport=2222:toaddr=192.168.100.5
firewall-cmd --permanent --zone=public --add-forward-port=port=22:proto=tcp:toport=2222:toaddr=2000:100::2
firewall-cmd --reload
