#!/bin/bash

> /tmp/unica_start_time_update.out
type="uat"
period="7PM"

for i in {1..80}; do unica_start_time="`MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "SELECT min(starttime) from unica_v11_${type}_wf_details where date(executedate)=curdate()-INTERVAL $i day and period='$period'"`"; MYSQL_PWD=root@123 mysql -uroot -v -N -s unica_dashbrd -e "update last_updated_time set unica_start_time='$unica_start_time' where version='v11' and unica_type='${type}' and period='$period' and date(informatica_time)=curdate()-interval $i day" >> /tmp/unica_start_time_update.out;  done

if [ -s /tmp/unica_start_time_update.out ]; then echo -e "Please find below log\n/tmp/unica_start_time_update.out"; fi
