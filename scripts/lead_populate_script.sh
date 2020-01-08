#!/bin/bash


dt=`date +"%Y-%m-%d %H:%M:%S"`
tnw=`date +"%H"`
tnw=5
dst_path="/home/sakthi/unica_dash/lead_count_files/"
tend=$(($tnw+3))

cd $dst_path

IFS=$'\n'; for lead_dtls in `MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "select lead_group_name,'@',file_name,'@',server_name,'@',ipaddress,'@',crontime from lead_count_server_dtls where status=1"`; do 

lead_group_name=$(echo $lead_dtls | cut -d '@' -f1 | sed 's#\t##g')
file_path=$(echo $lead_dtls | cut -d '@' -f2| sed 's#\t##g')
file_name=$(basename `echo $lead_dtls | cut -d '@' -f2 | sed 's#\t##g'`)
server_name=$(echo $lead_dtls | cut -d '@' -f3 | sed 's#\t##g')
ipaddress=$(echo $lead_dtls | cut -d '@' -f4 | sed 's#\t##g')
full_path="${dst_path}${file_name}"
crontime=$(echo $lead_dtls | cut -d '@' -f5 | sed 's#\t##g')

if [ $crontime -ge $tnw ] && [ $crontime -le $tend ]; then 
if [ -f  $dst_path${file_name} ] ; then 
file_date=`stat $dst_path/${file_name} | grep Modify | awk '{print $2}'`
fi
actual_date=`date +"%Y-%m-%d"`
lead_updated_status=`MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "select count(1) from lead_update_status where date(executedate)=curdate() and status='completed' and lead_group_name='$lead_group_name'"`

if [ $lead_updated_status -eq 0 ]; then
 
if [ ! "$file_date" == "$actual_date" ] || [ ! -s $dst_path${file_name} ]; then 
#echo "rsync -azr lamatri@171.23.0.13 \"rsync -azr lamatri@${ipaddress}:${file_path} $dst_path\""
echo "ssh lamatri@172.23.0.13 \"rsync -azr lamatri@${ipaddress}:${file_path} /tmp/ && rsync -azr /tmp/\\\`basename ${file_path}\\\` sakthi@192.168.0.60:/tmp/\""
else
IFS=$'\n' 
for lcn in `cat $full_path | grep ":"`
do 
lead_name=`echo $lcn | grep ":" | sed 's# - ##g'| awk -F ':' '{print $1}'`
lead_cnt=`echo $lcn | grep ":" | sed 's# - ##g'| awk -F ':' '{print $2}'`


already_update=`MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "select count(1) from daily_lead_count where date(executedate)=curdate() and lead_group_name='$lead_group_name' and lead_name='$lead_name'"`

null_value=`MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "select count(1) from daily_lead_count where date(executedate)=curdate() and lead_group_name='$lead_group_name' and lead_name='$lead_name' and lead_count is NULL"`

if [ $null_value -eq 1 ]; then 
MYSQL_PWD=root@123 mysql -uroot unica_dashbrd -N -s -e "update daily_lead_count set lead_count=${lead_cnt},executedate='${dt}' where lead_group_name='$lead_group_name' and lead_name='$lead_name' and date(executedate)=curdate();"
elif [ $already_update -eq 0 ]; then
MYSQL_PWD=root@123 mysql -uroot unica_dashbrd -N -s -e "insert into daily_lead_count (lead_group_name,lead_name,lead_count,executedate) values ('$lead_group_name','$lead_name','$lead_cnt','$dt');"
fi
done
MYSQL_PWD=root@123 mysql -uroot unica_dashbrd -N -s -e "insert into lead_update_status (lead_group_name,executedate,status) values('$lead_group_name','$dt','completed')"
fi
else echo "already completed for $lead_group_name"; fi
fi
done

MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "update daily_lead_count set status='completed' where date(executedate)=curdate() and lead_count is not NULL;"


