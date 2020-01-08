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
;;
8)
file="/tmp/unica_v12_uat_1am_wf_details"
period="1AM"
;;
9)
file="/tmp/unica_v12_uat_7pm_wf_details"
period="7PM"
esac

table=$(echo "unica_dashbrd.`echo $file | sed 's#/tmp/##g' | cut -d '_' -f1,2,3,5`")
version=`echo $file | sed 's#/tmp/##g' | cut -d '_' -f2`
types=`echo $file | sed 's#/tmp/##g' | cut -d '_' -f3`
st=`date -d "$period" +"%H"`

MYSQL_PWD=root@123 mysql -uroot  -N -s -e "update ${table}_details set status=NULL,starttime=NULL,endtime=NULL,total_time_taken=NULL,remarks=NULL where date(executedate)=curdate()-${dt} and status in ('run_failed','running','inactive','not_started','long_running','not_yet_started','trigger_not_completed');"

##completed before the execution time will be removed##
completed_before_execution_time="$(MYSQL_PWD=root@123 mysql -uroot unica_dashbrd -N -s -e "select workflow_name,time(starttime) from ${table}_details where date(executedate)=curdate()-${dt} and period='$period' " | cut -d ':' -f1 | awk -vst="$st" '{if ($2 < st) print $1}' | xargs | sed "s# #','#g;s#^#('#g;s#\$#')#g")"

MYSQL_PWD=root@123 mysql -uroot  -N -s -e "update ${table}_details set status=NULL,starttime=NULL,endtime=NULL,total_time_taken=NULL,remarks=NULL where date(executedate)=curdate()-${dt} and period='$period' and workflow_name in ${completed_before_execution_time}"

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
successfull_trigger="`MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "select successfull_trigger from workflow_trigger_dtls where period='$period' and workflow_name='$workflow_name' and version='$version' and type='$types'"`"
if [ -z $successfull_trigger ]; then MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "update ${table}_details set status='not_yet_started',remarks='$avg_time',success_trigger='Refer_Excel' where date(executedate)=curdate() and period='$period' and workflow_name='$workflow_name'" ; fi
successfull_trigger_avail="`MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "select count(1) from ${table}_details where date(executedate)=curdate() and period='$period' and workflow_name='$successfull_trigger'"`"
if [ $successfull_trigger_avail -eq 1 ]; then 
successfull_trigger_status="`MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "select count(1) from ${table}_details where date(executedate)=curdate() and period='$period' and workflow_name='$successfull_trigger' and status='completed'"`"
if [ $successfull_trigger_status -eq 1 ]; then 
MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "update ${table}_details set status='not_yet_started',remarks='$avg_time',success_trigger='$successfull_trigger' where date(executedate)=curdate() and period='$period' and workflow_name='$workflow_name'"
fi;elif [ -z $successfull_trigger ]; then MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "update ${table}_details set status='not_yet_started',remarks='$avg_time',success_trigger='Refer_Excel' where date(executedate)=curdate() and period='$period' and workflow_name='$workflow_name'" ; else MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "update ${table}_details set status='not_yet_started',remarks='$avg_time',success_trigger='$successfull_trigger' where date(executedate)=curdate() and period='$period' and workflow_name='$workflow_name'" ;fi;fi

done

##Started or completed without on-trigger workflow completed##
for workflow_name in `MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "select workflow_name from ${table}_details where status in ('completed','running','long_running','run_failed','inactive') and period='$period' and date(executedate)=curdate();"`; do

suc_trigger="`MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "select successfull_trigger from workflow_trigger_dtls where workflow_name='$workflow_name' and period='$period' and active=1 and type='$types'"`"
echo $suc_trigger suc_trigger
suc_trigger_cnt=`MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "select count(1) from ${table}_details where workflow_name='$suc_trigger' and status not in ('completed','inactive') and date(executedate)=curdate() and period='$period'"`
echo suc_trigger_cnt $suc_trigger_cnt
active_suc_trigger_cnt=`MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "select count(1) from ${table}_details where workflow_name='$suc_trigger' and date(executedate)=curdate() and period='$period'"`
echo active_suc_trigger_cnt $active_suc_trigger_cnt
if [ $suc_trigger_cnt -eq 1 ] && [ $active_suc_trigger_cnt -eq 1 ] ; then 
MYSQL_PWD=root@123 mysql -uroot -vvvv -N -s unica_dashbrd -e "update ${table}_details set status='trigger_not_completed',success_trigger='$suc_trigger' where workflow_name='$workflow_name' and date(executedate)=curdate() and period='$period'"

fi

done


##status=0 issue fixed##
##status=1 long_running##
##status=2 not_yet_started##
##status=3 run_failed##
##status=4 trigger_not_completed##
##long_running alert status update##

for workflow_name_remarks in `MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "select workflow_name,remarks from ${table}_details where status='long_running' and date(executedate)=curdate() and period='$period'"` ; do

workflow_name=`echo $workflow_name_remarks | awk '{print $1}'`
remarks=`echo $workflow_name_remarks | awk '{print $2}'`

severity_cnt=`MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "select count(1) from unica_alert where date(executedate)=curdate() and workflow_name='$workflow_name' and period='$period' and status=1 and version='$version' and unica_type='$types' and alert_now=1"`

if [ $severity_cnt -ge 1 ]; then 

severity=`MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "select severity from unica_alert where date(executedate)=curdate() and workflow_name='$workflow_name' and period='$period' and status=1 and version='$version' and unica_type='$types' and alert_now=1"`

severity=$((${severity}+1))

MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "update unica_alert set severity=$severity,endtime=now() where date(executedate)=curdate() and workflow_name='$workflow_name' and period='$period' and status=1 and version='$version' and unica_type='$types' and alert_now=1"

else 

MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "insert into unica_alert (workflow_name,period,severity,starttime,endtime,status,executedate,remarks,version,unica_type,alert_now) values ('$workflow_name','$period',1,now(),now(),1,curdate(),'$remarks','$version','$types',1)"

fi ;done

##not yet started##

for workflow_name_remarks in `MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "select workflow_name,remarks,success_trigger from ${table}_details where status='not_yet_started' and date(executedate)=curdate() and period='$period'"` ; do

workflow_name=`echo $workflow_name_remarks | awk '{print $1}'`
remarks=`echo $workflow_name_remarks | awk '{print $2" "$3}'`

severity_cnt=`MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "select count(1) from unica_alert where date(executedate)=curdate() and workflow_name='$workflow_name' and period='$period' and status=2 and version='$version' and unica_type='$types' and alert_now=1"`

if [ $severity_cnt -ge 1 ]; then

severity=`MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "select severity from unica_alert where date(executedate)=curdate() and workflow_name='$workflow_name' and period='$period' and status=2 and version='$version' and unica_type='$types' and alert_now=1"`

severity=$((${severity}+1))

MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "update unica_alert set severity=$severity,endtime=now() where date(executedate)=curdate() and workflow_name='$workflow_name' and period='$period' and status=2 and version='$version' and unica_type='$types' and alert_now=1"

else

MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "insert into unica_alert (workflow_name,period,severity,starttime,endtime,status,executedate,remarks,version,unica_type,alert_now) values ('$workflow_name','$period',1,now(),now(),2,curdate(),'$remarks','$version','$types',1)"

fi ;done

##error status update##
for workflow_name in `MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "select workflow_name from ${table}_details where status in ('run_failed') and date(executedate)=curdate() and period='$period'"`; do 

error_status_cnt=`MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "select count(1) from unica_alert where date(executedate)=curdate() and workflow_name='$workflow_name' and period='$period' and status=3 and unica_type='$types' and version='$version' and alert_now=1"`

if [ $error_status_cnt -eq 0 ]; then MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "insert into unica_alert (workflow_name,period,severity,starttime,endtime,status,executedate,unica_type,version,alert_now) values ('$workflow_name','$period',1,now(),now(),3,curdate(),'$types','$version',1);" 
else 
err_severity=`MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "select severity from unica_alert where date(executedate)=curdate() and workflow_name='$workflow_name' and period='$period' and status=3 and version='$version' and unica_type='$types' and alert_now=1"`

err_severity=$((${err_severity}+1))

MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "update unica_alert set severity=$err_severity,endtime=now() where date(executedate)=curdate() and workflow_name='$workflow_name' and period='$period' and status=3 and version='$version' and unica_type='$types' and alert_now=1"

fi

done


##trigger_not_completed##
for workflow_name in `MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "select workflow_name from ${table}_details where status in ('trigger_not_completed') and date(executedate)=curdate() and period='$period'"`; do


trigger_not_completed_status_cnt=`MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "select count(1) from unica_alert where date(executedate)=curdate() and workflow_name='$workflow_name' and period='$period' and status=4 and unica_type='$types' and version='$version' and alert_now=1"`

if [ $trigger_not_completed_status_cnt -eq 0 ]; then MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "insert into unica_alert (workflow_name,period,severity,starttime,endtime,status,executedate,unica_type,version,alert_now) values ('$workflow_name','$period',1,now(),now(),4,curdate(),'$types','$version',1);"

else

trigger_not_completed_severity="`MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "select severity from unica_alert where date(executedate)=curdate() and workflow_name='$workflow_name' and period='$period' and status=4 and version='$version' and unica_type='$types' and alert_now=1"`"

trigger_not_completed_severity=$((${trigger_not_completed_severity}+1))

MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "update unica_alert set severity=$trigger_not_completed_severity,endtime=now() where date(executedate)=curdate() and workflow_name='$workflow_name' and period='$period' and status=4 and version='$version' and unica_type='$types' and alert_now=1"

fi

done



##status update for (long_running, not_yet_started and run_failed) to completed##

where_cond=`MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "select workflow_name from ${table}_details where status not in ('long_running','run_failed','not_yet_started') and date(executedate)=curdate() and period='$period'" | xargs`

where_clause=`echo $where_cond | sed "s# #','#g;s#^#('#g" | sed "s/\$/')/g"`

MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "update unica_alert set alert_now=0 where date(executedate)=curdate() and workflow_name in $where_clause and status in (1,2,3) and version='$version' and unica_type='$types' and alert_now=1"






##unica daily last executed status##
count=`MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "SELECT COUNT(1) FROM last_updated_time where period='$period' AND unica_type='$types' and version='$version' and date(informatica_time)=curdate()"`
cntupdate=`MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "SELECT COUNT(1) FROM last_updated_time where period='$period' AND unica_type='$types' and version='$version' and date(last_update_time)=curdate() and status='completed'"`
if [ $count -ge 1 ] ; then
if [ $cntupdate -eq 0 ]; then
MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "update last_updated_time set last_update_time=now() where period='$period' AND unica_type='$types' and version='$version' and date(informatica_time)=curdate() and informatica_status='completed'"; fi
fi 
if [ $secondval -eq 1 ] && [ $count -ge 1 ] ; then 
if [ $cntupdate -eq 0 ] ; then 
maxtime=`MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "select max(endtime) from ${table}_details where date(executedate)=curdate() and period='$period'"`
MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "update last_updated_time set last_update_time='$maxtime',status='completed' where period='$period' AND unica_type='$types' and version='$version' and date(last_update_time)=curdate() and date(informatica_time)=curdate() and informatica_status='completed'" 
fi ; fi


else  echo "sh $0 [1-7]"; fi
