#!/bin/bash

if [ $# -eq 4 ];  then 
version="$2"
types="$3"
period="$4"
active=1
file="$1"
	if [ -s $file ]; then 

	typesmall="`echo $types | tr '[:upper:]' '[:lower:]'`"
	versionsmall="`echo $version | tr '[:upper:]' '[:lower:]'`"

	for workflow_name in `MYSQL_PWD=root@123 mysql -uroot  unica_dashbrd -N -s -e "select workflow_name from unica_${versionsmall}_${typesmall}_wf where period='$period' and status=1"` ; do on_trigger=`cat $file | grep -i "$workflow_name" | awk -F',' -vwork="$workflow_name" '{if ($2==work) print $5}'`; successfull_trigger=`cat $file | awk -F',' -von_trigger="$on_trigger" -vworkflow_name="$workflow_name" '{if ($6==on_trigger) print $2}'`;echo "$workflow_name -- $on_trigger -- $successfull_trigger" ;  done > /tmp/output.log; cat /tmp/output.log | grep '\-\-' > /tmp/output.txt

		if [ -s /tmp/output.txt ] ; then
		sed -i "s# -- # #g;s#^#$period #g;s#^#$types #g;s#^#$version #g;s# #','#g;s#^#('#g;s#\$#',${active}),#g;1s/^/insert into workflow_trigger_dtls (version,type,period,workflow_name,on_trigger,successfull_trigger,active) values\n/" /tmp/output.txt

		cat /tmp/output.txt  | grep "''" -v > /tmp/output_${version}_${types}_${period}.sql

		sed -i '$s/,$/;/' /tmp/output_${version}_${types}_${period}.sql

		names_not_in=`cat /tmp/output.txt |grep "''" | awk -F ","  '{print $4,$6}' |sed "s#''#not_available#g;s#'##g" |awk -vq="'" '{if ($2 == "not_available") print $1}' | xargs | sed "s# #','#g;s#^#('#g"`

		workflow_names_not_in=`echo $names_not_in | sed "s/\$/')/g"`

		#echo "$workflow_names_not_in"
			if [ ! -z $workflow_names_not_in ]; then echo -e "\n\nBelow Workflows are not having ON_Trigger_Name or Successfull_Trigger_Name\n---------------------------------------------------------------------------\n\nPlease Validate the updated CSV file and then check with Campaign Team\n-----------------------------------------------------------------------\n" 

			cat /tmp/output.txt  | grep "''" 
			
			empty_trigger_workflow_count=`MYSQL_PWD=root@123 mysql -uroot unica_dashbrd -N -s -e "select count(1) from workflow_trigger_dtls where version='$version' and period='$period' and type='$types' and workflow_name in $workflow_names_not_in"`
			if [ $empty_trigger_workflow_count -ge 1 ]; then
			echo -e "\n\nAlready in DB\n--------------"

			MYSQL_PWD=root@123 mysql -uroot unica_dashbrd -e "select * from workflow_trigger_dtls where version='$version' and period='$period' and type='$types' and workflow_name in $workflow_names_not_in" ; fi
			
			yesorno_fun()
			{
			echo -en "Please type yes to proceed further or no to exit the script [yes/no]: "
			read yesorno
			}
			echo -e "\n"; 
			tput sc
			yesorno_fun
				until [ "$yesorno" == "yes" ] || [ "$yesorno" == "no" ] ; do tput rc;echo "                                                                                                 ";tput rc; yesorno_fun; done
				
				if [ "$yesorno" == "yes" ]; then 

				MYSQL_PWD=root@123 mysql -uroot unica_dashbrd -N -s -e "delete from workflow_trigger_dtls where version='$version' and period='$period' and type='$types' and workflow_name not in $workflow_names_not_in"

				MYSQL_PWD=root@123 mysql -uroot unica_dashbrd -N -s -e "delete from workflow_trigger_dtls where version='$version' and period='$period' and type='$types' and workflow_name in $workflow_names_not_in"

				MYSQL_PWD=root@123 mysql -uroot -vvv unica_dashbrd < /tmp/output_${version}_${types}_${period}.sql > /tmp/output_${version}_${types}_${period}.log

					if [ $? -eq 0 ]; then echo -e "#####################################################\n$1 populated in DB\nPFB the log file\n/tmp/output_${version}_${types}_${period}.log\n#####################################################"; fi

				else echo "The Script was exited"; exit 1; fi; fi

		else echo "No data found in excel"; fi ; else echo "Excel file $file - Not Available" ; fi

else echo -e "Please run as below\nsh $0 /tmp/filename.csv v11 UAT 1AM"; fi
