#!/bin/bash

for table in `MYSQL_PWD=root@123 mysql -uroot  -N -s  unica_dashbrd -e "select logfile from unica_servers where Active_status=1" | awk -F '/tmp/' '{print $2}' | cut -d '_' -f1,2,3,5 | sort | uniq`; do cnt=`MYSQL_PWD=root@123 mysql -uroot  -N -s  unica_dashbrd -e "select count(1) from $table where alert=0"`; if [ $cnt -gt 0 ]; then 
echo -e "----------------------------------------------------------------------\n\t\t`date`\n"
MYSQL_PWD=root@123 mysql -uroot  -N -s  unica_dashbrd -v -e "select workflow_name from $table where alert=0"
MYSQL_PWD=root@123 mysql -uroot  -N -s  unica_dashbrd -vvv -e "update $table set alert=1 where alert=0"
echo -e "\n-----------------------------------------------------------------------\n"
fi; done
