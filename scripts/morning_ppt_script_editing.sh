#!/bin/bash

> /tmp/morning_ppt.txt
curl -s http://192.168.20.220/dashboard/dwh2dashboard.php -o /tmp/morning_ppt.txt
>/tmp/batchid.txt ;> /tmp/pending.txt; a=0;b=0;for bid in  1 2 4 5 10 11 12 13 14 15 16 17 21 22 23 25 26 32 33 61 ; do actcnt=`cat  /tmp/morning_ppt.txt  | sed -n -e "/etlprocess.php?Scriptid=${bid}\//,/<\/tr>/ p" | awk -F '<td class="' '{print $2}' | cut -d '"' -f1 | grep -v "^$" | wc -l`; curcnt=`cat  /tmp/morning_ppt.txt  | sed -n -e "/etlprocess.php?Scriptid=${bid}\//,/<\/tr>/ p" | awk -F '<td class="' '{print $2}' | cut -d '"' -f1 | grep -v "^$" | grep "Finished" | wc -l` ; if [ $actcnt -eq $curcnt ]; then let a++; else let b++; echo $bid >> /tmp/pending.txt; fi; echo $bid >> /tmp/batchid.txt ; done ; echo -e "DWH 2.0 status:\n-------------------"; cat /tmp/batchid.txt | xargs | sed "s# #,#g;s#^#Batch ID : (#g;s#\$#)#g"; echo  "Completed = $a"; if [ -s /tmp/pending.txt ]; then cat /tmp/pending.txt | xargs | sed "s# #,#g;s#^#Pending = $b (#g;s#\$#)#g";else echo "Pending = 0" ;fi


executedate=`date +"%Y-%m-%d"`

MYSQL_PWD=root@123 mysql -uroot -N -s morning_ppt -e "delete from batchid_status where executedate='$executedate';"

for bid in 1 2 4 5 10 11 12 13 14 15 16 17 21 22 23 25 26 32 33 61; do
#for bid in 33; do 
i=1;a=2;b=3;for purpose_id in `cat  /tmp/morning_ppt.txt | sed -n -e "/etlprocess.php?Scriptid=${bid}\//,/<\/tr>/ p" | grep "<td>.</td>" | cut -d '>' -f2 | cut -d '<' -f1` ;do 

batch_name=`cat  /tmp/morning_ppt.txt | sed -n -e "/etlprocess.php?Scriptid=${bid}\//,/<\/tr>/ p" | sed -n -e "/etlprocess.php?Scriptid=${bid}\//,/<td>${purpose_id}<\/td>/ p"| grep "etlprocess.php?Scriptid=${bid}" | cut -d '>' -f4 | cut -d '<' -f1| head -n $i | tail -1`

status=`cat  /tmp/morning_ppt.txt | sed -n -e "/etlprocess.php?Scriptid=${bid}\//,/<\/tr>/ p" | grep '<td class="' | head -n $i | tail -1 | cut -d '"' -f2`

start_time=`cat  /tmp/morning_ppt.txt | sed -n -e "/etlprocess.php?Scriptid=${bid}\//,/<\/tr>/ p" | grep -A1 '<td class="' |  grep -v "\-\-" | head -n $a | tail -1 | cut -d '>' -f2 | cut -d '<' -f1`

if [ -z "$start_time" ]; then status="Not Started"; MYSQL_PWD=root@123 mysql -uroot -N -s morning_ppt -e "insert into batchid_status (batch_id,purpose_id,status,executedate) values ($bid,$purpose_id,'$status','$executedate');" ;fi

if [ "$status" == "Finished" ]; then end_time=`cat  /tmp/morning_ppt.txt | sed -n -e "/etlprocess.php?Scriptid=${bid}\//,/<\/tr>/ p" | grep -A2 '<td class="' |  grep -v "\-\-" | head -n $b | tail -1 | cut -d '>' -f2 | cut -d '<' -f1`; 
start="`date -d "$start_time" +"%s"`"
end="`date -d "$end_time" +"%s"`"
ttime=$(($end - $start))
total_time="(select sec_to_time($ttime))"; 
MYSQL_PWD=root@123 mysql -uroot -N -s morning_ppt -e "insert into batchid_status (batch_id,purpose_id,start_time,end_time,total_time,status,executedate) values ($bid,$purpose_id,'$start_time','$end_time',$total_time,'$status','$executedate');"
elif [ -n "$start_time" ]; then  MYSQL_PWD=root@123 mysql -uroot -N -s morning_ppt -e "insert into batchid_status (batch_id,purpose_id,start_time,status,executedate) values ($bid,$purpose_id,'$start_time','$status','$executedate');"; fi



IFS=$'\n'; for jobrunning in `MYSQL_PWD=root@123 mysql -uroot -N -s morning_ppt -e "select concat('batch_id=',batch_id,' purpose_id=',purpose_id,' start_time=\"',time(start_time),'\"') from batchid_status where date(executedate)=curdate() and status='Finished'"` ; do echo $jobrunning >/tmp/morning_ppt_src; . /tmp/morning_ppt_src; echo $batch_id $purpose_id $start_time; sleep 1s; done

MYSQL_PWD=root@123 mysql -uroot -N -s morning_ppt -e "select avg(time_to_sec(start_time)) from batchid_status where batch_id=1 and purpose_id=1 and start_time>=date_sub(now(), interval 3 day);" | cut -d '.' -f1


##For mysql 1time details population##
#MYSQL_PWD=root@123 mysql -uroot -N -s morning_ppt -e "insert into batchid_details (batch_id,batch_name,purpose_id,alert) values ($bid,'$batch_name',$purpose_id,1);" 
let i++; a=$(($a+2)) ; b=$(($b+3));done;  done
