#!/bin/bash
dt=0
if [ $# -ge 1 ]; then
secondval=$2
if [ $# -eq 1 ]; then secondval=0 ; fi
case $1 in
1)
file="/tmp/unica_v9_uat_wf_details"
;;
2)
file="/tmp/unica_v11_prod_1am_wf_details"
period="1AM"
;;
3)
file="/tmp/unica_v11_uat_1am_wf_details"
period="1AM"
;;
4)
file="/tmp/unica_v11_prod_1pm_wf_details"
period="1PM"
;;
5)
file="/tmp/unica_v11_uat_1pm_wf_details"
period="1PM"
;;
6)
file="/tmp/unica_v11_prod_7pm_wf_details"
period="7PM"
;;
7)
file="/tmp/unica_v11_uat_7pm_wf_details"
period="7PM"
esac

table=$(echo "unica_dashbrd.`echo $file | sed 's#/tmp/##g' | cut -d '_' -f1,2,3,5`")
version=`echo $file | sed 's#/tmp/##g' | cut -d '_' -f2`
types=`echo $file | sed 's#/tmp/##g' | cut -d '_' -f3`

#if [ $1 -le 3 ]; then period="1AM"; elif [ $1 -le 5 ]; then period="1PM" ; fi

MYSQL_PWD=root@123 mysql -uroot  -N -s -e "update ${table}_details set status=NULL,starttime=NULL,endtime=NULL,total_time_taken=NULL,remarks=NULL where date(executedate)=curdate()-${dt} and status in ('run_failed','running','inactive','not_started','long_running','not_yet_started');"

IFS=$'\n'; for u in `MYSQL_PWD=root@123 mysql -uroot -N -s -e "select workflow_name from ${table} where period='$period' and status=1"`; do v=`grep -w "$u" $file | tail -1`; if [ ! -z $v ]; then runsuc=`echo $v | grep "Run Succeeded"` || running=`echo $v | grep "Running"`; else starttime=""; endtime="" ; fi 

if [ ! -z $running ]; then
completed_to_running=`MYSQL_PWD=root@123 mysql -uroot -N -s -e "select count(1) from ${table}_details where workflow_name='$u' and date(executedate)=curdate()-${dt} and period='$period' and status!='running'"`
if [ ${completed_to_running} -eq 1 ]; then
MYSQL_PWD=root@123 mysql -uroot -N -s -e "update ${table}_details set status='running',starttime=NULL,endtime=NULL,total_time_taken=NULL where workflow_name='$u' and date(executedate)=curdate()-${dt} and period='$period' and status='completed'" ; fi ; fi


if [ ! -z $runsuc ]; then starttime=`echo $runsuc | awk '{print $4" "$5" "$6" "$7" "$8}'`; endtime=`echo $runsuc | awk '{print $9" "$10" "$11" "$12" "$13}'`; elif [ ! -z $running ]; then starttime=`echo $running | awk '{print $3" "$4" "$5" "$6" "$7}'`; endtime=""; fi

echo $v | grep "Inactive" >/dev/null ; if [ $? -eq 0 ]; then 
starttime=`echo $v | grep "Inactive" | awk '{print $3" "$4" "$5" "$6" "$7}'`
endtime=`echo $v | awk '{print $8" "$9" "$10" "$11" "$12}'`
fi
if [ ! -z $endtime ]; then endtime=`date -d "$endtime" +"%Y-%m-%d %H:%M:%S"`; else endtime="" ;fi

if [ ! -z $starttime ] ; then starttime=`date -d "$starttime" +"%Y-%m-%d %H:%M:%S"`; fi

update=`MYSQL_PWD=root@123 mysql -uroot -N -s -e "select * from ${table}_details where workflow_name='$u' and date(starttime)=curdate()-${dt} and date(endtime)=curdate()-${dt} and date(executedate)=curdate()-${dt}" | wc -l`


if [ $update -eq 0 ]; then 

updateend=`MYSQL_PWD=root@123 mysql -uroot -N -s -e "select * from ${table}_details where workflow_name='$u' and date(starttime)=curdate()-${dt} and date(executedate)=curdate()-${dt}" | wc -l`

if [ $updateend -eq 1 ] && [ ! -z $endtime ] ; then 

MYSQL_PWD=root@123 mysql -uroot -N -s -e "update ${table}_details set endtime='$endtime' where workflow_name='$u' and starttime='$starttime' and date(executedate)=curdate()-${dt}"; fi

update_startend=`MYSQL_PWD=root@123 mysql -uroot -N -s -e "select * from ${table}_details where workflow_name='$u' and starttime is null and date(executedate)=curdate()-${dt}" | wc -l;`

if [ $update_startend -eq 1 ]; then 

if [ ! -z $starttime ] && [ ! -z $endtime ]; then

MYSQL_PWD=root@123 mysql -uroot -N -s -e "update ${table}_details set starttime='$starttime', endtime='$endtime' where workflow_name='$u' and period='$period' and starttime is null and endtime is null and date(executedate)=curdate()-${dt}" 

fi

if [ ! -z $starttime ] && [  -z $endtime ]; then

MYSQL_PWD=root@123 mysql -uroot -N -s -e "update ${table}_details set starttime='$starttime' where workflow_name='$u' and period='$period' and starttime is null and endtime is null and date(executedate)=curdate()-${dt}"; fi

else

today_value=`MYSQL_PWD=root@123 mysql -uroot -N -s -e "select * from ${table}_details where workflow_name='$u' and date(executedate)=curdate()-${dt}" | wc -l`

if [ $today_value -eq 0 ]; then

if [ ! -z $starttime ] && [ ! -z $endtime ]; then

MYSQL_PWD=root@123 mysql -uroot -N -s -e "insert into ${table}_details (workflow_name,period,starttime,endtime,executedate) values ('$u','$period','$starttime','$endtime',curdate()-${dt})"

elif [ ! -z $starttime ] && [ -z $endtime ]; then

MYSQL_PWD=root@123 mysql -uroot -N -s -e "insert into ${table}_details (workflow_name,period,starttime,executedate) values ('$u','$period','$starttime',curdate()-${dt})"

elif [ -z $starttime ] && [ -z $endtime ]; then

MYSQL_PWD=root@123 mysql -uroot -N -s -e "insert into ${table}_details (workflow_name,period,executedate) values ('$u','$period',curdate()-${dt})"

fi;fi;fi;fi
starttime=""
running=""
runsuc=""
notstarted=""
endtime=""

#inactive
#run failed

echo $v | grep -i "Inactive" >/dev/null ; if [ $? -eq 0 ]; then 

starttime=`echo $v | awk '{print $3" "$4" "$5" "$6" "$7}'`; 
endtime=`echo $v | awk '{print $8" "$9" "$10" "$11" "$12}'`; 

if [ ! -z $endtime ]; then endtime=`date -d "$endtime" +"%Y-%m-%d %H:%M:%S"`; else endtime="" ;fi
if [ ! -z $starttime ] ; then starttime=`date -d "$starttime" +"%Y-%m-%d %H:%M:%S"`; else endtime=""; fi


MYSQL_PWD=root@123 mysql -uroot  -N -s -e "update ${table}_details set status='inactive',starttime='${starttime}',endtime='${endtime}',total_time_taken=NULL where workflow_name='$u' and date(executedate)=curdate()-${dt}"; fi

echo $v | grep -i "Run failed" >/dev/null && MYSQL_PWD=root@123 mysql -uroot  -N -s -e "update ${table}_details set status='run_failed',starttime=NULL,endtime=NULL,total_time_taken=NULL where workflow_name='$u' and date(executedate)=curdate()-${dt}"

done

#MYSQL_PWD=root@123 mysql -uroot  -N -s -e "select concat('MYSQL_PWD=root@123 mysql -uroot -N -s -e \"','update ${table}_details set total_time_taken=(','SELECT TIMEDIFF(\'',endtime,'\',','\'',starttime,'\'))',' where workflow_name=\'',workflow_name,'\';\"') from ${table}_details where date(starttime)=curdate()-${dt} and date(endtime)=curdate()-${dt} and total_time_taken is null and date(executedate)=curdate()-${dt};" > /tmp/dhinesh.txt

MYSQL_PWD=root@123 mysql -uroot  -N -s unica_dashbrd -e "select concat('MYSQL_PWD=root@123 mysql -uroot -N -s -e \"','update ${table}_details set total_time_taken=(','SELECT TIMEDIFF(\'',endtime,'\',','\'',starttime,'\'))',' where workflow_name=\'',workflow_name,'\'',' and date(executedate)=curdate()-${dt}',' and period=\'$period\'','\";') from ${table}_details where date(starttime)=curdate() and date(endtime)=curdate()-${dt} and total_time_taken is null and date(executedate)=curdate()-${dt};" | sh

MYSQL_PWD=root@123 mysql -uroot  -N -s -e "update ${table}_details set status='completed' where date(starttime)=curdate()-${dt} and date(endtime)=curdate()-${dt} and date(executedate)=curdate()-${dt} and status is null"
MYSQL_PWD=root@123 mysql -uroot  -N -s -e "update ${table}_details set status='running' where date(starttime)=curdate()-${dt} and endtime is null and date(executedate)=curdate()-${dt}  and status is null;"
MYSQL_PWD=root@123 mysql -uroot  -N -s -e "update ${table}_details set status='not_started' where starttime is null and endtime is null and date(executedate)=curdate()-${dt}  and status is null;"

##Long_Running##
IFS=$'\n'; for unica in `MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "select workflow_name,starttime from ${table}_details where status='running' and date(executedate)=curdate() and period='$period'"`
do 
workflow_name=`echo $unica | awk '{print $1}'`; 
start_time=`echo $unica | awk '{print $2" "$3}'` ; 
today_start=$(date -d "`echo $unica | awk '{print $2" "$3}'`" +"%s"); 
avg_time=`MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "select AVG(TIME_TO_SEC(total_time_taken)) from ${table}_details where workflow_name='$workflow_name' and executedate>=DATE_SUB(NOW(), INTERVAL 7 DAY) and period='$period'" | cut -d '.' -f1` ; 
now_time=`date +"%s"`;  
expected_end_time=`echo ${today_start}+${avg_time} | bc`
avg_time_val=`MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "select SEC_TO_TIME(AVG(TIME_TO_SEC(total_time_taken))) from ${table}_details where workflow_name='$workflow_name' and executedate>=DATE_SUB(NOW(), INTERVAL 7 DAY) and period='$period'"  | cut -d . -f1`
if [ ! $expected_end_time -ge $now_time ] ; then 
MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "update ${table}_details set status='long_running',remarks='$avg_time_val' where date(executedate)=curdate() and period='$period' and workflow_name='$workflow_name'"
fi
done
##Not_yet_started##
IFS=$'\n'; for unica in `MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "select workflow_name,starttime from ${table}_details where status='not_started' and date(executedate)=curdate() and period='$period'"`
do
workflow_name=`echo $unica | awk '{print $1}'`;
avg_time=`MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "select SEC_TO_TIME(AVG(TIME_TO_SEC(starttime))) from ${table}_details where workflow_name='$workflow_name' and executedate>=DATE_SUB(NOW(), INTERVAL 7 DAY) and period='$period'" | cut -d '.' -f1` ;
now_time=`date +"%s"`;
actual_start_time=`date -d "$avg_time" +"%s"`
if [ ! $actual_start_time -ge $now_time ] ; then
MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "update ${table}_details set status='not_yet_started',remarks='$avg_time' where date(executedate)=curdate() and period='$period' and workflow_name='$workflow_name'"
fi

done

count=`MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "SELECT COUNT(1) FROM last_updated_time where period='$period' AND unica_type='$types' and version='$version' and date(informatica_time)=curdate()"`
cntupdate=`MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "SELECT COUNT(1) FROM last_updated_time where period='$period' AND unica_type='$types' and version='$version' and date(last_update_time)=curdate() and status='completed'"`
if [ $count -ge 1 ] ; then
if [ $cntupdate -eq 0 ]; then
MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "update last_updated_time set last_update_time=now() where period='$period' AND unica_type='$types' and version='$version' and date(informatica_time)=curdate() and informatica_status='completed'"; fi
#else
#MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "insert into last_updated_time (version,unica_type,period,last_update_time) values ('$version','$types','$period',now())"
fi 
if [ $secondval -eq 1 ] && [ $count -ge 1 ] ; then 
if [ $cntupdate -eq 0 ] ; then 
maxtime=`MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "select max(endtime) from ${table}_details where date(executedate)=curdate() and period='$period'"`
MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "update last_updated_time set last_update_time='$maxtime',status='completed' where period='$period' AND unica_type='$types' and version='$version' and date(last_update_time)=curdate() and date(informatica_time)=curdate() and informatica_status='completed'" 
#else 
#MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "update last_updated_time set last_update_time=now(),status='completed' where period='$period' AND unica_type='$types' and version='$version' and date(last_update_time)=curdate()"
fi ; fi

else  echo "sh $0 [1-7]"; fi
