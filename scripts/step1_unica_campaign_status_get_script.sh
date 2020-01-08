#!/bin/bash 
dt=0
t=`date +"%H"`
#t=15
if [ ! -f /tmp/step1.lock ]; then

touch /tmp/step1.lock


table_fun()
{
#if [ "$type" == "PROD" ] ; then table="unica_v11_prod_wf_details"; elif [ "$type" == "UAT" ]; then table="unica_v11_uat_wf_details"; fi
table=`echo "$logfile" | sed 's#/tmp/##g' | cut -d '_' -f1,2,3,5,6`

}

IFS=$'\n';for i in `MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "select start_time,end_time,Username,ServerIP,Syntax,logfile,period,type,ID,informatica_url from unica_servers where Active_status=1"`; 
do echo $i | awk '{print "s="$1"\t""e="$2"\tuser="$3"\tip="$4"\tsyntax="$5"\tlogfile="$6"\tperiod="$7"\ttype="$8"\tid="$9"\turl="$10}' > /tmp/source
. /tmp/source ; 
version=`echo $logfile | cut -d '_' -f2`
if [ $t -ge $s ] && [ $t -le $e ]; then
inf_cnt=`MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "select count(1) from last_updated_time WHERE date(informatica_time)=curdate()-$dt and period='$period' and unica_type='$type' and informatica_status='completed'"`

if [ $inf_cnt -eq 0 ] ; then 
infrm_time=''

idt=`date +"%Y-%m-%d"`;cbs="$period CBS<"; wget "$url" -O /tmp/output.html -o /dev/null ; cat /tmp/output.html | sed -n -e "/$cbs/,/<\/tr>/ p" | grep "Finished" > /dev/null && infrm_time=`cat /tmp/output.html | sed -n -e "/$cbs/,/<\/tr>/ p" | grep "<td>$idt" | tail -1 | sed 's#<td>##g;s#</td>##g'`

inf_cur_status="`wget "$url" -O /tmp/output.html -o /dev/null ; cat /tmp/output.html | sed -n -e "/$cbs/,/<\/tr>/ p" | egrep "Job Running|Finished|Error" | cut -d '"' -f2`"

if [ ! -z $infrm_time ]; then  
inf_update=`MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "select count(1) from last_updated_time WHERE date(informatica_time)=curdate()-$dt and period='$period' and unica_type='$type'"`
if [ $inf_update -ne 0 ] ; then 
MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "update last_updated_time set informatica_status='completed', informatica_time='$infrm_time' where date(informatica_time)=curdate()-$dt and period='$period' and unica_type='$type'"
else
MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "insert into last_updated_time (version,unica_type,period,informatica_time,informatica_status) values ('$version','$type','$period','$infrm_time','completed')"
fi
fi
fi
fi
inf_cnt=`MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "select count(1) from last_updated_time WHERE date(informatica_time)=curdate()-$dt and period='$period' and unica_type='$type' and informatica_status='completed'"`


p="BePr0@ctivE"

if [ $t -ge $s ] && [ $t -le $e ] && [ $inf_cnt -eq 1 ] 
#if [ $inf_cnt -eq 1 ] 
then table_fun;  

dst=`MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "select count(1) from $table where period='$period' and status='completed' and date(executedate)=curdate()"`

src_table=`echo $table | sed 's#_details##g'`

src=`MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "select count(1) from $src_table where period='$period' and status=1"`

if [ ${dst} -lt ${src} ]; then 

> $logfile

for l in `echo $syntax | sed 's#,#\n#g'`; do /usr/bin/sshpass -p ${p} ssh ${user}@${ip} "campaignstatus $l" >> $logfile ;sleep 1s; done 

if [ -s $logfile ]; then /bin/bash /home/sakthi/unica_dash/step2_unica_mysql_update_script.sh $id ;fi

elif [ ${dst} -eq ${src} ]; then 

/bin/bash /home/sakthi/unica_dash/step2_unica_mysql_update_script.sh $id 1

fi; fi ; done
rm -f /tmp/step1.lock
else echo "already running at `date`" ;fi 

already_cnt=`cat /tmp/unica_step1.log | grep -c 'already running at'`
if [ $already_cnt -ge 3 ] ;then echo "#######################################################" >> /home/sakthi/unica_dash/unica_step1_log.dump; date >> /home/sakthi/unica_dash/unica_step1_log.dump; cat /tmp/unica_step1.log >> /home/sakthi/unica_dash/unica_step1_log.dump; > /tmp/unica_step1.log ; rm -fv /tmp/step1.lock >> /home/sakthi/unica_dash/unica_step1_log.dump; fi

/bin/bash /home/sakthi/unica_dash/step6_unica_mail_and_sms_alert.sh &>/tmp/unica_step6.log

/bin/bash /home/sakthi/unica_dash/step6_1_unica_pagerduty_alert.sh &>>/tmp/unica_pagerduty_alert.log

ctime=`date +"%H"`

if [ $ctime -eq 00 ]; then /bin/bash /home/sakthi/unica_dash/step8_update_for_alert_enable.sh &>>/home/sakthi/unica_dash/unica_step8_update_output.log; fi
