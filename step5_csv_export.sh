#!/bin/bash

types=$1
period=$2
startdate=$3
enddate=$4
table="unica_v11_${types}_wf"
if [ $# -ge 2 ]; then
if [ -z $4 ]; then where_date="date(executedate)='$3'"; else where_date="date(executedate)>='$3' and date(executedate)<='$4'"; fi
if [ -z $3 ]; then where_date="date(executedate)='`date +"%Y-%m-%d"`'"; fi
i=2
sudo rm -f /var/lib/mysql-files/outputfile.xlsx


for category in `MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "select category from ${table} where period='${period}' group by category"`; do echo "$category" >> /tmp/output_$$_1.xlsx; MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "select workflow_name from ${table} where period='${period}' and category='$category'"; done >>  /tmp/output_$$_1.xlsx; 


for dt in `MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "select executedate from ${table}_details where $where_date group by executedate;"` ;do 

#echo -e "Start_Time\tEnd_Time\tTotal_Time" >> /tmp/output_$$_${i}.xlsx;
for category in `MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "select category from ${table} where period='${period}' group by category"`; do workflow_names=`MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "select workflow_name from ${table} where period='${period}' and category='$category'"`; workflow_name=$(echo $workflow_names | sed "s#^#('#g;s#\$#')#g;s# #','#g"); 
echo -e "Start_Time\tEnd_Time\tTotal_Time"  >> /tmp/output_$$_${i}.xlsx;
MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "select concat(starttime,',',endtime,',',total_time_taken) as name from ${table}_details where workflow_name in $workflow_name and period='${period}' and date(executedate)='$dt'" | sed 's#,#\t#g';done >> /tmp/output_$$_${i}.xlsx

let i++
done
paste /tmp/output_$$_*.xlsx > /home/sakthi/httpd/output.xlsx
else echo "sh $0 uat 1am 2019-07-20 2019-07-22"; fi

rm -f /tmp/output_$$_*.xlsx
