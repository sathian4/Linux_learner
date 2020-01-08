#!/bin/bash

if [ $# -eq 3 ]; then

t=`date +"%H"`
dt=`date +"%Y-%m-%d"`

#IFS=$'\n';for i in `MYSQL_PWD=root@123 mysql -uroot -N -s unica_dashbrd -e "select start_time,end_time,Username,ServerIP,Syntax,logfile,period,type,ID from unica_servers where Active_status=1"`;
#do echo $i | awk '{print "s="$1"\t""e="$2"\tuser="$3"\tip="$4"\tsyntax="$5"\tlogfile="$6"\tperiod="$7"\ttype="$8"\tid="$9}' > /tmp/source

#. /tmp/source 


table="unica_${2}_wf"
period="$1"
workflow_name="$3"

MYSQL_PWD=root@123 mysql -uroot  -N -s  unica_dashbrd -e "update $table set alert=0 where period='$period' and workflow_name='$workflow_name'" && echo "<center><h2>Alert Disabled for $workflow_name in ${2}_${period}</h></center>" 


else echo "<center><h2>Wrong Argument</h></center>" ; fi
