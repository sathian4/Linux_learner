#! /bin/bash
echo '"#IPADDRESS#"' >/tmp/$HOSTNAME.txt
/sbin/ifconfig | grep -i inet | grep -v inet6 >>/tmp/$HOSTNAME.txt
echo '"#NETSTAT#' >>/tmp/$HOSTNAME.txt
/bin/netstat -tulpn | grep -i listen >>/tmp/$HOSTNAME.txt
echo '"#DISK USAGE"' >>/tmp/$HOSTNAME.txt
df -hT >>/tmp/$HOSTNAME.txt
echo '"#FDISK#'>>/tmp/$HOSTNAME.txt
sudo /sbin/fdisk -l >>/tmp/$HOSTNAME.txt
echo '"#fstab entry#"' >>/tmp/$HOSTNAME.txt
cat /etc/fstab >>/tmp/$HOSTNAME.txt
echo '"#OS VERSION"' >>/tmp/$HOSTNAME.txt
cat /etc/redhat-release >>/tmp/$HOSTNAME.txt





