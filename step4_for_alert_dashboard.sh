#!/bin/bash
> /tmp/unica_dash.txt
> /tmp/unica_dash1.txt
t=`date +"%H"`
dt=`date +"%Y-%m-%d"`
#t=2

#dt="2019-08-06"
notstarted="Please Ensure the Informatica Sync Entry. Currently No Unica Process will run at `date +"%H:%M:%S"`"
table_fun()

{
#if [ "$type" == "PROD" ] ; then table="unica_v11_prod_wf_details"; elif [ "$type" == "UAT" ]; then table="unica_v11_uat_wf_details"; fi

table=`echo "$logfile" | sed 's#/tmp/##g' | cut -d '_' -f1,2,3,5,6`

}

IFS=$'\n';for i in `MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "select start_time,end_time,Username,ServerIP,Syntax,logfile,period,type,ID from unica_servers where Active_status=1"`;
do echo $i | awk '{print "s="$1"\t""e="$2"\tuser="$3"\tip="$4"\tsyntax="$5"\tlogfile="$6"\tperiod="$7"\ttype="$8"\tid="$9}' > /tmp/source
. /tmp/source ;

types=`echo $logfile | sed 's#/tmp/##g' | cut -d '_' -f3`
version=`echo $logfile | sed 's#/tmp/##g' | cut -d '_' -f2`

last_update_fun()
{
table_name=`echo $table | cut -d . -f2`
cnt=`MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "SELECT count(1) FROM last_updated_time where period='$period' AND unica_type='$types' and version='$version' and date(informatica_time)=curdate() and informatica_status='completed'"`
if [ $cnt -ge 1 ]; then
echo -en "<h3><center>`MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "SELECT concat('Last Updated Time - ',last_update_time,'\nInformatica Completed Time --> ',informatica_time) FROM last_updated_time where period='$period' AND unica_type='$types' and version='$version' and date(last_update_time)=curdate()"`</center></h3>"
#echo "<center>Server Current Time - `date +"%d-%b-%Y %H:%M:%S"`</center>"
else
echo -en "<h3><center>`MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "SELECT concat('Yesterday Last Updated Time - ',last_update_time,'\nInformatica is Currently Running Now') FROM last_updated_time where period='$period' AND unica_type='$types' and version='$version' and last_update_time>DATE_SUB(NOW(), INTERVAL 1 DAY) and status='completed'"`</center></h3>"
#echo "<center>Server Current Time - `date +"%d-%b-%Y %H:%M:%S"`</center>"
fi
}

p="V@nakk@Ma2z"

if [ $t -ge $s ] && [ $t -le $e ];
#if [ $t -ge $s ]
then table_fun;

#echo -en " <center><h2>${period} --> ${type}</h2> </center>" ;

total_count=`MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "select count(1) from ${table} where date(executedate)='${dt}' and period='$period'"`

completed=`MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e  "select count(1) from ${table} where date(executedate)='${dt}' and period='$period' and status='completed'"`

running=`MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e  "select count(1) from ${table} where date(executedate)='${dt}' and period='$period' and status='running'"`

not_started=`MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd  -e "select count(1) from ${table} where date(executedate)='${dt}' and period='$period' and status='not_started'"`

error=`MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "select count(1) from ${table} where date(executedate)='${dt}' and period='$period' and status in ('inactive','run_failed')"`

long_running=`MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "select count(1) from ${table} where date(executedate)='${dt}' and period='$period' and status in ('long_running')"`

not_yet_started=`MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "select count(1) from ${table} where date(executedate)='${dt}' and period='$period' and status in ('not_yet_started')"`

types=`echo $type | tr [:upper:] [:lower:]`
period=`echo $period | tr [:upper:] [:lower:]`
periods=`echo $period | tr  [:lower:] [:upper:]`
reflink="<a href="v11${types}_${period}.php">"
if [ $completed -gt 0 ]; then c="#4CAF50"; else c=""; fi
if [ $running -gt 0 ]; then  ru="#e6e600"; else ru=""; fi
if [ $not_started -gt 0 ]; then n="#ffb3b3" ; else n=""; fi
if [ $error -gt 0 ]; then e="#e60000" ; else e=""; fi
if [ $long_running -gt 0 ]; then lr="#808b96" ; else lr=""; fi
if [ $not_yet_started -gt 0 ]; then nys="#d35400" ; else nys=""; fi

last_update_fun >> /tmp/unica_dash.txt

echo -en "<center><h2>${reflink}${periods} --> ${type}</a></h2></center>" >> /tmp/unica_dash.txt

echo "<TABLE BORDER=10><TH bgcolor=#99ffff>Total_Count</TH><TH  bgcolor=${c}>Total_Completed</TH><TH bgcolor=${ru}>Total_Running</TH><TH bgcolor=${n}>Total_Not_Started</TH><TH bgcolor=${nys}>Total_Not_Yet_Started</TH><TH bgcolor=${lr}>Total_Long_Running</TH><TH bgcolor=${e}>Total_Error</TH></TR><TR><TD border: 2px solid black bgcolor=#99ffff>${total_count}</TD><TD bgcolor=${c}>${completed}</TD><TD bgcolor=${ru}>${running}</TD><TD bgcolor=${n}>${not_started}</TD><TD bgcolor=${nys}>${not_yet_started}</TD><TD bgcolor=${lr}>${long_running}</TD><TD  bgcolor=${e}>${error}</TD></TABLE>" >> /tmp/unica_dash.txt

else 
count=`MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "SELECT COUNT(1) FROM last_updated_time where period='$period' AND unica_type='$types' and version='$version' and date(last_update_time)=curdate() and status='completed'"`
completed_time=`MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "SELECT last_update_time FROM last_updated_time where period='$period' AND unica_type='$types' and version='$version' and date(last_update_time)=curdate() and status='completed'"`

if [ $count -ge 1 ] ; then echo "$period $type completed - $completed_time" >> /tmp/unica_dash1.txt; else echo "$period $type will start at $s" >> /tmp/unica_dash1.txt;  fi

fi
done


#else echo "${notstarted}" ;fi; done | grep -v "${notstarted}" > /tmp/unica_dash.txt 

if [ -s /tmp/unica_dash.txt ]; then cat /tmp/unica_dash.txt > /tmp/unica_dash.out 
sed -i "1s#^#<center>Server Current Time - `date +"%d-%b-%Y %H:%M:%S"`</center>\n#" /tmp/unica_dash.out
echo "<center><h4>`cat /tmp/unica_dash1.txt | sed 's#$#:00@@#g' | xargs | sed 's#@@#\t#g'`</h4></center>" >> /tmp/unica_dash.out; fi
sed -i '1d' /tmp/unica_dash.out
sed -i "1s#^#<center>Server Current Time - `date +"%d-%b-%Y %H:%M:%S"`</center>\n#" /tmp/unica_dash.out
cat /tmp/unica_dash.out | uniq
