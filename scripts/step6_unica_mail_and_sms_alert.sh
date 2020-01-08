#!/bin/bash

dt=0
t=`date +"%H"`
#t=2
smstime=`date +"%d%b%Y_%H:%M"`
IFS=$'\n';for i in `MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "select start_time,end_time,Username,ServerIP,Syntax,logfile,period,type,ID,informatica_url from unica_servers where Active_status=1"`;
do echo $i | awk '{print "s="$1"\t""e="$2"\tuser="$3"\tip="$4"\tsyntax="$5"\tlogfile="$6"\tperiod="$7"\ttype="$8"\tid="$9"\turl="$10}' > /tmp/source
. /tmp/source ;
version=`echo $logfile | cut -d '_' -f2`
srctable=`echo "$logfile" | sed 's#/tmp/##g' | cut -d '_' -f1,2,3,5`
table=`echo "$logfile" | sed 's#/tmp/##g' | cut -d '_' -f1,2,3,5,6`
#srctable="unica_v12_uat_wf"
if [ $t -ge $s ] && [ $t -le $e ]; then

where_is=$(MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "select workflow_name from $srctable where alert!=1 and period='$period'" | xargs | sed "s# #','#g;s#^#('#g;s#\$#')#g")

if [ -z $where_is ] ; then where_is="('')"; fi

crontime="`crontab -l | grep "step1_unica_campaign_status_get_script.sh" | awk '{print $1}' | sed 's#*##g;s#/##g;s#,##g'`"

##status code number##
##status=0 issue fixed##
##status=1 long_running##
##status=2 not_yet_started##
##status=3 run_failed##
##status=4 trigger_not_completed##

pagerduty_time_fun()
{
##Example: log_type="{starttime}_{interval}_{log_code}"##
##Note: For SMS please don't change the interval time##
echo '#
long_running="15_5_1"
not_yet_started="15_5_5"
run_failed="5_5_3"
trigger_not_completed="5_5_5"
#'  > /tmp/source_pagerduty

pagerduty_log_fun()
{
echo "log_type_val=\"\`echo \$$1\`\"" >> /tmp/source_pagerduty
. /tmp/source_pagerduty

log_type=$1
pager_duty_start="`echo $log_type_val | cut -d '_' -f1`"
pager_duty_interval="`echo $log_type_val | cut -d '_' -f2`"
log_code=`echo $log_type_val | cut -d '_' -f3`
}

pagerduty_log_fun $log_type

}

for log_type  in long_running not_yet_started run_failed trigger_not_completed; do

smstime=`date +"%d%b%Y_%H:%M"`

pagerduty_time_fun $log_type

log_type_upper="`echo $log_type | tr [:lower:] [:upper:]`"

severity_start=$(( pager_duty_start / crontime ))
severity_intvl=$(( pager_duty_interval / crontime ))

if [ $severity_start -ge 2 ]; then email_severity=$(( severity_start - 1  )); else email_severity=$severity_start; fi

#echo "crontime - $crontime log_type $log_type pager_duty_start $pager_duty_start pager_duty_interval $pager_duty_interval severity_start $severity_start severity_intvl $severity_intvl log_code $log_code log_type_upper $log_type_upper email_severity $email_severity "


##Mail ALERT##
> /tmp/${log_type}.err ; 
MYSQL_PWD=root@123 mysql -uroot -N -s  unica_dashbrd  -e "select concat('echo -e \"\n\nWorkflow_Name=',workflow_name,'\nPeriod=',period,'\nSeverity=',severity,'\nType=${log_type_upper}','\nVersion=',version,'_',unica_type,'\nAvg_Time='),remarks,concat('\"') from unica_alert where severity>=${email_severity} and date(executedate)=curdate() and status=${log_code} and alert_now=1 and period='${period}' and unica_type='${type}' and version='$version' and workflow_name not in ${where_is}" | sed 's#\t##g' | sh > /tmp/${log_type}.err ; if [ -s /tmp/${log_type}.err ] ; then sed -i "1s/^/Dear Team,\nPlease find below the Workflow Details for ${log_type_upper}/" /tmp/${log_type}.err ; echo "/usr/bin/mutt -s \"Unica_${log_type_upper}_Details_in_${version}_${type}_${period}\" sedbm.matrimony@gmail.com < /tmp/${log_type}.err" ; fi


##SMS ALERT##
smscontent=""
smscontent=`MYSQL_PWD=root@123 mysql -uroot -N -s  unica_dashbrd  -e "select concat('echo -e \"\n\nWorkflow_Name=',workflow_name,'\nSeverity=',severity,'\nType=${log_type_upper}','\nVersion=',version,'_',unica_type,'_',period,'\nAvg_Time='),remarks,concat('\"') from unica_alert where severity>=${severity_start} and date(executedate)=curdate() and status=${log_code} and alert_now=1 and period='${period}' and unica_type='${type}' and version='$version' and workflow_name not in ${where_is}" | sed 's#\t##g' | sh | sed 's#\t##g' |  sed 's# #%20#g;s#$#%0a#g' | xargs | sed 's# ##g;s#^%0a%0a##g'`

##IF CONTENT AVAILABLE, THEN TRIGGER SMS##
if [ ! -z "$smscontent" ]; then
for mnumber in `MYSQL_PWD=root@123 mysql -uroot -N -s  unica_dashbrd  -e "SELECT mobile from mobile_number where trigger_sms=1"` ; do 
echo "curl \"http://172.23.1.195:8802/axiomdbrec/pushlistener?dcode=1&subuid=acltest&pwd=4PEMstHV&ctype=1&sender=FROMBM&pno=${mnumber}&msgtxt=${smscontent}From%20SEDBM.%0a${smstime}&intflag=1&msgtype=S&alert=0&langid=en\"" | sh ; done ;fi


done
fi
done
