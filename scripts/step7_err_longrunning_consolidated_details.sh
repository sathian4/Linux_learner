#!/bin/bash
if [ $# -ge 1 ]; then
if [ $# -eq 2 ]; then fromdate="$2"
frm=`date -d "$fromdate" +"%s"`; to=`date +"%s"`;intvl=`echo \(\(${to}-${frm}\)/60/60/24\)+1 | bc`; else intvl=1; fi
#table=`echo "$logfile" | sed 's#/tmp/##g' | cut -d '_' -f1,2,3,5,6`

IFS=$'\n';for i in `MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "select start_time,end_time,Username,ServerIP,Syntax,logfile,period,type,ID from unica_servers where Active_status=1"`;
do echo $i | awk '{print "s="$1"\t""e="$2"\tuser="$3"\tip="$4"\tsyntax="$5"\tlogfile="$6"\tperiod="$7"\ttype="$8"\tid="$9}' > /tmp/source
. /tmp/source ;

types=`echo $logfile | sed 's#/tmp/##g' | cut -d '_' -f3`
version=`echo $logfile | sed 's#/tmp/##g' | cut -d '_' -f2`
table=`echo "$logfile" | sed 's#/tmp/##g' | cut -d '_' -f1,2,3,5,6`

done
stats=$1
log_type=`echo -e "Long_Running_1\nNot_Yet_Started_2\nRun_Failed_3\nInformatica_Unica_Start_Time_4\nTrigger_Not_Completed_5" | grep $1 | sed "s#_$1##g"`
echo -en "\n\n\n\n<center><h3>Total $intvl Days $log_type Report</h3></center>"
case $stats in 
1)
##long_running##

for unicaversion in `MYSQL_PWD=root@123 mysql -uroot  unica_dashbrd -N -s -e "select concat(version,'_',unica_type,'_',period) as Unica from unica_alert where executedate>=DATE_SUB(NOW(), INTERVAL $intvl DAY) and status=1 and severity>=2 and concat(version,'_',unica_type,'_',period) is not NULL group by Unica order by concat(version,'_',unica_type,'_',period)"`; do
echo -en "<center><h2>$unicaversion</h2></center>"
MYSQL_PWD=root@123 mysql -uroot  unica_dashbrd -H -e "select concat(version,'_',unica_type,'_',period) as Unica, workflow_name as Workflow_Name, severity as Severity,starttime as Alert_Start_Time,endtime as Alert_End_Time,executedate as Execute_Date,remarks as Avg_Run_Time FROM unica_alert where executedate>=DATE_SUB(NOW(), INTERVAL $intvl DAY) and severity>=2 and status=1 and concat(version,'_',unica_type,'_',period)='$unicaversion' order by executedate desc"; done
;;

2)
##not_yet_started##
for unicaversion in `MYSQL_PWD=root@123 mysql -uroot  unica_dashbrd -N -s -e "select concat(version,'_',unica_type,'_',period) as Unica from unica_alert where executedate>=DATE_SUB(NOW(), INTERVAL $intvl DAY) and status=2 and severity>=2 and concat(version,'_',unica_type,'_',period) is not NULL group by Unica order by concat(version,'_',unica_type,'_',period)"`; do
echo -en "<center><h2>$unicaversion</h2></center>"
MYSQL_PWD=root@123 mysql -uroot  unica_dashbrd -H -e "select concat(version,'_',unica_type,'_',period) as Unica, workflow_name as Workflow_Name, severity as Severity,starttime as Alert_Start_Time,endtime as Alert_End_Time,executedate as Execute_Date,remarks as 'Avg_Run_Time/Dependent_Workflow' FROM unica_alert where executedate>=DATE_SUB(NOW(), INTERVAL $intvl DAY) and severity>=2 and status=2 and concat(version,'_',unica_type,'_',period)='$unicaversion' order by executedate desc"; done
;;

3)
##run_failed##
for unicaversion in `MYSQL_PWD=root@123 mysql -uroot  unica_dashbrd -N -s -e "select concat(version,'_',unica_type,'_',period) as Unica from unica_alert where executedate>=DATE_SUB(NOW(), INTERVAL $intvl DAY) and status=3 and concat(version,'_',unica_type,'_',period) is not NULL group by Unica order by concat(version,'_',unica_type,'_',period)"`; do
echo -en "<center><h2>$unicaversion</h2></center>"
MYSQL_PWD=root@123 mysql -uroot  unica_dashbrd -H -e "select concat(version,'_',unica_type,'_',period) as Unica, workflow_name as Workflow_Name, severity as Severity,starttime as Alert_Start_Time,endtime as Alert_End_Time,executedate as Execute_Date,remarks as Run_Failed FROM unica_alert where executedate>=DATE_SUB(NOW(), INTERVAL $intvl DAY)  and status=3 and concat(version,'_',unica_type,'_',period)='$unicaversion' order by executedate desc"; done
;;

4)
##informatica_time##
for unicaversion in `MYSQL_PWD=root@123 mysql -uroot  unica_dashbrd -N -s -e "select concat(version,'_',unica_type,'_',period) as Unica from last_updated_time where last_update_time>=DATE_SUB(NOW(), INTERVAL $intvl DAY) group by Unica order by concat(version,'_',unica_type,'_',period)"`; do
echo -en "<center><h2>$unicaversion</h2></center>"
#MYSQL_PWD=root@123 mysql -uroot  unica_dashbrd -H -e "select concat(version,'_',unica_type,'_',period) Unica, informatica_time as Informatica_Completed_Time, last_update_time as Unica_Completed_Time  from last_updated_time where last_update_time>=DATE_SUB(NOW(), INTERVAL $intvl DAY) and concat(version,'_',unica_type,'_',period)='$unicaversion' order by last_update_time desc"; done

MYSQL_PWD=root@123 mysql -uroot  unica_dashbrd -H -e "select concat(version,'_',unica_type,'_',period) Unica, informatica_time as Informatica_Completed_Time, unica_start_time as Unica_Started_Time, last_update_time as Unica_Completed_Time  from last_updated_time where last_update_time>=DATE_SUB(NOW(), INTERVAL $intvl  DAY) and concat(version,'_',unica_type,'_',period)='$unicaversion' order by last_update_time desc;"; done

;;

5)
##trigger_not_completed##
for unicaversion in `MYSQL_PWD=root@123 mysql -uroot  unica_dashbrd -N -s -e "select concat(version,'_',unica_type,'_',period) as Unica from unica_alert where executedate>=DATE_SUB(NOW(), INTERVAL $intvl DAY) and status=4 and concat(version,'_',unica_type,'_',period) is not NULL group by Unica order by concat(version,'_',unica_type,'_',period)"`; do
echo -en "<center><h2>$unicaversion</h2></center>"
MYSQL_PWD=root@123 mysql -uroot  unica_dashbrd -H -e "select concat(version,'_',unica_type,'_',period) as Unica, workflow_name as Workflow_Name, severity as Severity,starttime as Alert_Start_Time,endtime as Alert_End_Time,executedate as Execute_Date,remarks as Trigger_Not_Completed FROM unica_alert where executedate>=DATE_SUB(NOW(), INTERVAL $intvl DAY)  and status=4 and concat(version,'_',unica_type,'_',period)='$unicaversion' order by executedate desc"; done
;;


esac
else echo -e "Please use run the script as below:\n$0 [1-3]"; fi
