#!/bin/bash
> /tmp/step9_alert_disable_list.txt
for table in `MYSQL_PWD=root@123 mysql -uroot  -N -s unica_dashbrd -e "select logfile from unica_servers where Active_status=1 group by logfile;" | cut -d '_' -f1,2,3 | sort | uniq | sed 's#/tmp/##g;s#$#_wf#g'` 
do alert_disable_cnt=`MYSQL_PWD=root@123 mysql -uroot unica_dashbrd -N -s -e "select count(1) from $table where status=1 and alert=0"`
if [ $alert_disable_cnt -gt 0 ]; then 
echo "<center><h2>`echo $table | cut -d '_' -f2,3 | tr '[:lower:]' '[:upper:]'`</h></center>"
MYSQL_PWD=root@123 mysql -uroot unica_dashbrd -H -e "select workflow_name as Workflow_Name,period as Period,category as Category from $table where status=1 and alert=0";fi ; done > /tmp/step9_alert_disable_list.txt


if [ -s  /tmp/step9_alert_disable_list.txt ]; then cat /tmp/step9_alert_disable_list.txt; else echo "<center><h2>All Alerts Are Enabled</h></center>"; fi
