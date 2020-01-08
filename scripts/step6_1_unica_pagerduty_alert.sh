#!/bin/bash
#log_type=$1
dt=0
t=`date +"%H"`
#t=2

##Alert_time_parameter: "starttime_interval" eg:starttime 15mins##
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
echo '#
long_running="20_15_1"
not_yet_started="200_300_2"
run_failed="5_15_3"
trigger_not_completed="500_200_5"
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

#pagerduty_time_fun $type


#severity_start=$(( pager_duty_start / crontime ))
#severity_intvl=$(( pager_duty_interval / crontime ))

#echo "crontime - $crontime log_type $log_type pager_duty_start $pager_duty_start pager_duty_interval $pager_duty_interval severity_start $severity_start severity_intvl $severity_intvl log_code $log_code"

for log_type  in long_running not_yet_started run_failed trigger_not_completed; do

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

pagerduty_time_fun $log_type

severity_start=$(( pager_duty_start / crontime ))
severity_intvl=$(( pager_duty_interval / crontime ))


#cat /tmp/test | awk -vpdi=2 -vpds=3 '{if (pds == $2) print $0; else if (($2-pds) >= pdi) print $1,($2-pds)/pdi}' | grep -v '[0-9]\.[0-9]'

pagerdutycall="`MYSQL_PWD=root@123 mysql -uroot -N -s  unica_dashbrd  -e "select workflow_name,severity from unica_alert where severity>=${severity_start} and date(executedate)=curdate() and status=${log_code} and alert_now=1 and period='${period}' and unica_type='${type}' and version='$version' and workflow_name not in ${where_is}" | awk -vpdi="${severity_intvl}" -vpds="${severity_start}" '{if (pds == $2) print $0; else if (($2-pds) >= pdi) print $1,($2-pds)/pdi}' | grep -v '[0-9]\.[0-9]' | awk '{print $1}' | xargs`"


#MYSQL_PWD=root@123 mysql -uroot -N -s  unica_dashbrd  -e "select workflow_name,severity from unica_alert where severity>=${severity_start} and date(executedate)=curdate() and status=${log_code} and alert_now=0 and period='${period}' and unica_type='${type}' and version='$version' and workflow_name not in ${where_is}" | awk -vpdi="${severity_intvl}" -vpds="${severity_start}" '{if (pds == $2) print $0; else if ($2 >= pds) print $1,$2/pdi,$2}'


#echo "crontime - $crontime log_type $log_type pager_duty_start $pager_duty_start pager_duty_interval $pager_duty_interval severity_start $severity_start severity_intvl $severity_intvl log_code $log_code"

if [ ! -z $pagerdutycall ]; then 

/bin/bash /home/sakthi/unica_dash/pager_duty_script.sh -a "${log_type}_${type}_${period} - ${pagerdutycall}" -c "Mailer alert" -s $log_type -d "{ \"Message\": \"${log_type} - ${pagerdutycall}\" }"

MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd  -e "insert into pagerduty_call_log (workflow_name,version,executetime) values ('${pagerdutycall}','${log_type}_${type}_${period}_${version}',now())"

#/bin/bash /tmp/asdf.txt  "${log_type}_${type}_${period}" "Mailer alert" $log_type "{ \"Message\": \"${log_type} - ${pagerdutycall}\" }" 

fi 


fi
done
done
exit

