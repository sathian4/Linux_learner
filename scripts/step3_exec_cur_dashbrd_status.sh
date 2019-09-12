#!/bin/bash
d=0
#mysql -uroot -proot@123-e 'select * from ${table} where date(starttime)=curdate()-3 or starttime is null;'
if [ -z $3 ];then dt=`date +"%Y-%m-%d" -d "$d day ago"`; else dt=$3; fi

if [ $# -ge 2 ]; then 

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

table=$(echo "unica_dashbrd.`echo $file | sed 's#/tmp/##g' | cut -d '_' -f1,2,3,5,6`")
srctable=$(echo "unica_dashbrd.`echo $file | sed 's#/tmp/##g'| cut -d '_' -f1,2,3,5`")
version=`echo $file | sed 's#/tmp/##g' | cut -d '_' -f2`
types=`echo $file | sed 's#/tmp/##g' | cut -d '_' -f3`

status="$2"

last_update_fun()
{
#echo -e "\n\n"
table_name=`echo $table | cut -d . -f2`
cnt=`MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "SELECT count(1) FROM last_updated_time where period='$period' AND unica_type='$types' and version='$version' and date(last_update_time)='${dt}'"`
if [ $cnt -ge 1 ]; then
echo -e "\n\n\n\n<h3><center>`MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "SELECT concat('Last Update Time - ',last_update_time) FROM last_updated_time where period='$period' AND unica_type='$types' and version='$version' and date(last_update_time)='${dt}'"`</center></h3>\n<center>Server Current Time - `date +"%d-%b-%Y %H:%M:%S"`</center>"
else 
echo -e "\n\n\n\n<h3><center>`MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "SELECT concat('Last Update Time - ',last_update_time) FROM last_updated_time where period='$period' AND unica_type='$types' and version='$version' and last_update_time>DATE_SUB(NOW(), INTERVAL 1 DAY)"`</center></h3>\n<center>Server Current Time - `date +"%d-%b-%Y %H:%M:%S"`</center>"
fi
#MYSQL_PWD=root@123 mysql -uroot -N -s -e "select concat('Last Update Time is ',UPDATE_TIME) from information_schema.TABLES where TABLE_NAME='${table_name}'"
#echo "</center></h5>"
}


if [ $status -eq 1 ]; then

#1=all
#MYSQL_PWD=root@123 mysql -uroot -H -e "select count(1) as Total_Count from ${srctable} where period='${period}' and status=1"
last_update_fun

total_count=`MYSQL_PWD=root@123 mysql -uroot -N -s -e "select count(1) from ${table} where date(executedate)='${dt}' and period='$period'"`

completed=`MYSQL_PWD=root@123 mysql -uroot -N -s -e "select count(1) from ${table} where date(executedate)='${dt}' and period='$period' and status='completed'"`

running=`MYSQL_PWD=root@123 mysql -uroot -N -s -e "select count(1) from ${table} where date(executedate)='${dt}' and period='$period' and status='running'"`

not_started=`MYSQL_PWD=root@123 mysql -uroot -N -s -e "select count(1) from ${table} where date(executedate)='${dt}' and period='$period' and status='not_started'"`

error=`MYSQL_PWD=root@123 mysql -uroot -N -s -e "select count(1) from ${table} where date(executedate)='${dt}' and period='$period' and status in ('inactive','run_failed')"`

not_yet_started=`MYSQL_PWD=root@123 mysql -uroot -N -s -e "select count(1) from ${table} where date(executedate)='${dt}' and period='$period' and status in ('not_yet_started')"`

long_running=`MYSQL_PWD=root@123 mysql -uroot -N -s -e "select count(1) from ${table} where date(executedate)='${dt}' and period='$period' and status in ('long_running')"`


if [ $completed -gt 0 ]; then c="#4CAF50"; else c=""; fi
if [ $running -gt 0 ]; then  ru="#e6e600"; else ru=""; fi
if [ $not_started -gt 0 ]; then n="#ffb3b3" ; else n=""; fi
if [ $error -gt 0 ]; then e="#e60000" ; else e=""; fi
if [ $not_yet_started -gt 0 ]; then nys="#d35400" ; else nys=""; fi
if [ $long_running -gt 0 ]; then lr="#808b96" ; else lr=""; fi


echo "<TABLE BORDER=10><TH bgcolor=#99ffff>Total_Count</TH><TH  bgcolor=${c}>Total_Completed</TH><TH bgcolor=${ru}>Total_Running</TH><TH bgcolor=${n}>Total_Not_Stared</TH><TH bgcolor=${nys}>Total_Not_Yet_Started</TH><TH bgcolor=${lr}>Total_Long_Running</TH><TH bgcolor=${e}>Total_Error</TH></TR><TR><TD border: 2px solid black bgcolor=#99ffff>${total_count}</TD><TD bgcolor=${c}>${completed}</TD><TD bgcolor=${ru}>${running}</TD><TD bgcolor=${n}>${not_started}</TD><TD bgcolor=${nys}>${not_yet_started}</TD><TD bgcolor=${lr}>${long_running}</TD><TD bgcolor=${e}>${error}</TD></TABLE>"

#echo "<TABLE BORDER=1><TH>Total_Count</TH><TH>Total_Completed</TH><TH>Total_Running</TH><TH>Total_Not_Stared</TH><TH>Total_Error</TH></TR><TR><TD>${total_count}</TD><TD>${completed}</TD><TD>${running}</TD><TD>${not_started}</TD><TD>${error}</TD></TABLE>"

for category in `MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "SELECT category FROM ${srctable} where period='$period' group by category;"`; do workflow=$(MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "SELECT workflow_name FROM ${srctable} where category='$category' and period='$period'"); workflow_name=$(echo $workflow | sed "s# #','#g;s#^#('#g;s#\$#')#g") ;

cnt=`MYSQL_PWD=root@123 mysql -uroot -N -s -e "select count(1) from ${table} where date(executedate)='${dt}' and period='$period' and workflow_name in $workflow_name"`

if [ ${cnt} -gt 0 ] ; then 

echo -en " <center><h2>$category --> ${cnt}</h2> </center>" ;

MYSQL_PWD=root@123 mysql -uroot -H -e "select id as ID, workflow_name as 'Workflow Name',period as Period, starttime as 'Start Time', endtime as 'End Time', total_time_taken as 'Total Time Taken', status as Status, executedate as 'Executed Date' from ${table} where date(executedate)='${dt}' and period='$period' and workflow_name in $workflow_name" | sed 's#NULL#--#g'
fi
done


#2=completed
elif [ $status -eq 2 ]; then

last_update_fun
MYSQL_PWD=root@123 mysql -uroot -H -e "select count(1) as Total_Completed_Count from ${table} where status='completed' and date(executedate)='${dt}' and period='$period'"

for category in `MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "SELECT category FROM ${srctable} where period='$period' group by category;"`; do workflow=$(MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "SELECT workflow_name FROM ${srctable} where category='$category' and period='$period'"); workflow_name=$(echo $workflow | sed "s# #','#g;s#^#('#g;s#\$#')#g") ; 

cnt=`MYSQL_PWD=root@123 mysql -uroot -N -s -e "select count(1) from ${table} where status='completed' and date(executedate)='${dt}' and period='$period' and workflow_name in $workflow_name"`

if [ ${cnt} -gt 0 ] ; then 

echo -en " <center><h2>$category --> ${cnt}</h2> </center>" ;

MYSQL_PWD=root@123 mysql -uroot -H -e "select id as ID, workflow_name as 'Workflow Name',period as Period, starttime as 'Start Time', endtime as 'End Time', total_time_taken as 'Total Time Taken', status as Status, executedate as 'Executed Date' from ${table} where status='completed' and date(executedate)='${dt}' and period='$period' and workflow_name in $workflow_name" ;fi ;done


#3=running
elif [ $status -eq 3 ]; then
last_update_fun
MYSQL_PWD=root@123 mysql -uroot -H -e "select count(1) as Total_Running_Count from ${table} where status='running' and date(executedate)='${dt}' and period='$period'"

for category in `MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "SELECT category FROM ${srctable} where period='$period' group by category;"`; do workflow=$(MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "SELECT workflow_name FROM ${srctable} where category='$category' and period='$period'"); workflow_name=$(echo $workflow | sed "s# #','#g;s#^#('#g;s#\$#')#g") ; 

cnt=`MYSQL_PWD=root@123 mysql -uroot -N -s -e "select count(1) from ${table} where status='running' and date(executedate)='${dt}' and period='$period' and  workflow_name in $workflow_name"`

if [ ${cnt} -gt 0 ] ; then 

echo -en " <center><h2>$category --> ${cnt}</h2> </center>" ;

MYSQL_PWD=root@123 mysql -uroot -H -e "select id as ID, workflow_name as 'Workflow Name',period as Period, starttime as 'Start Time', endtime as 'End Time', total_time_taken as 'Total Time Taken', status as Status, executedate as 'Executed Date' from ${table} where status='running' and date(executedate)='${dt}' and period='$period' and  workflow_name in $workflow_name" | sed 's#NULL#--#g'

fi
done


#4=not_started
elif [ $status -eq 4 ]; then
last_update_fun
MYSQL_PWD=root@123 mysql -uroot -H -e "select count(1) as Total_Not_Started_Count from ${table} where starttime is null and endtime is null and date(executedate)='${dt}' and status not in ('run_failed','inactive') and period='$period'"

for category in `MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "SELECT category FROM ${srctable} where period='$period' group by category;"`; do workflow=$(MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "SELECT workflow_name FROM ${srctable} where category='$category' and period='$period'"); workflow_name=$(echo $workflow | sed "s# #','#g;s#^#('#g;s#\$#')#g") 

cnt=`MYSQL_PWD=root@123 mysql -uroot -N -s -e "select count(1) from ${table} where starttime is null and endtime is null and date(executedate)='${dt}' and status not in ('run_failed','inactive') and period='$period' and  workflow_name in $workflow_name"`

if [ ${cnt} -gt 0 ] ; then 

echo -en " <center><h2>$category --> ${cnt}</h2> </center>" ;
MYSQL_PWD=root@123 mysql -uroot -H -e "select id as ID, workflow_name as 'Workflow Name',period as Period, starttime as 'Start Time', endtime as 'End Time', total_time_taken as 'Total Time Taken', status as Status, executedate as 'Executed Date' from ${table} where starttime is null and endtime is null and date(executedate)='${dt}' and status not in ('run_failed','inactive') and period='$period' and  workflow_name in $workflow_name" | sed 's#NULL#--#g'
fi
done

#5=error
elif [ $status -eq 5 ]; then
last_update_fun
MYSQL_PWD=root@123 mysql -uroot -H -e "select count(1) as Total_Error_Count from ${table} where status in ('run_failed','inactive') and date(executedate)='${dt}' and period='$period'"

for category in `MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "SELECT category FROM ${srctable} where period='$period' group by category;"`; do workflow=$(MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "SELECT workflow_name FROM ${srctable} where category='$category' and period='$period'"); workflow_name=$(echo $workflow | sed "s# #','#g;s#^#('#g;s#\$#')#g") ;

cnt=`MYSQL_PWD=root@123 mysql -uroot -N -s -e "select count(1) from ${table} where status in ('run_failed','inactive') and date(executedate)='${dt}' and period='$period' and  workflow_name in $workflow_name"`

if [ ${cnt} -gt 0 ] ; then 

echo -en " <center><br><h2> $category --> ${cnt}</h2> </br> </center>" ;

MYSQL_PWD=root@123 mysql -uroot -H -e "select id as ID, workflow_name as 'Workflow Name',period as Period, starttime as 'Start Time', endtime as 'End Time', total_time_taken as 'Total Time Taken', status as Status, executedate as 'Executed Date' from ${table} where status in ('run_failed','inactive') and date(executedate)='${dt}' and period='$period' and  workflow_name in $workflow_name"

fi
done

##6=long_running
elif [ $status -eq 6 ]; then
last_update_fun
MYSQL_PWD=root@123 mysql -uroot -H -e "select count(1) as Total_Long_Running_Count from ${table} where status='long_running' and date(executedate)='${dt}' and period='$period'"

for category in `MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "SELECT category FROM ${srctable} where period='$period' group by category;"`; do workflow=$(MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "SELECT workflow_name FROM ${srctable} where category='$category' and period='$period'"); workflow_name=$(echo $workflow | sed "s# #','#g;s#^#('#g;s#\$#')#g") ; 

cnt=`MYSQL_PWD=root@123 mysql -uroot -N -s -e "select count(1) from ${table} where status='long_running' and date(executedate)='${dt}' and period='$period' and workflow_name in $workflow_name"`

if [ ${cnt} -gt 0 ] ; then 

echo -en " <center><h2>$category --> ${cnt}</h2> </center>" ;

MYSQL_PWD=root@123 mysql -uroot -H -e "select id as ID, workflow_name as 'Workflow Name',period as Period, starttime as 'Start Time', endtime as 'End Time', total_time_taken as 'Total Time Taken', status as Status, executedate as 'Executed Date', remarks as Avg_Total_Time from ${table} where status='long_running' and date(executedate)='${dt}' and period='$period' and workflow_name in $workflow_name" ;fi ;done | sed 's#NULL#--#g'

##7=not_yet_started
elif [ $status -eq 7 ]; then

last_update_fun
MYSQL_PWD=root@123 mysql -uroot -H -e "select count(1) as Total_Not_Yet_Started_Count from ${table} where status='not_yet_started' and date(executedate)='${dt}' and period='$period'"

for category in `MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "SELECT category FROM ${srctable} where period='$period' group by category;"`; do workflow=$(MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "SELECT workflow_name FROM ${srctable} where category='$category' and period='$period'"); workflow_name=$(echo $workflow | sed "s# #','#g;s#^#('#g;s#\$#')#g") ; 

cnt=`MYSQL_PWD=root@123 mysql -uroot -N -s -e "select count(1) from ${table} where status='not_yet_started' and date(executedate)='${dt}' and period='$period' and workflow_name in $workflow_name"`

if [ ${cnt} -gt 0 ] ; then 

echo -en " <center><h2>$category --> ${cnt}</h2> </center>" ;

MYSQL_PWD=root@123 mysql -uroot -H -e "select id as ID, workflow_name as 'Workflow Name',period as Period, starttime as 'Start Time', endtime as 'End Time', total_time_taken as 'Total Time Taken', status as Status, executedate as 'Executed Date', remarks as Avg_Start_Time from ${table} where status='not_yet_started' and date(executedate)='${dt}' and period='$period' and workflow_name in $workflow_name" ;fi ;done | sed 's#NULL#--#g'


fi

else echo "Please enter the value like \"sh $0 1 1 2019-07-08\""; fi