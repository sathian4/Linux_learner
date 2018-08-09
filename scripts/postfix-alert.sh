for server in `grep -i 'mailer1\|mlfm\|mailer2\|cy2b' /etc/servers.txt | grep -v "CBS\|NEW"`
	do 
		hostname=`echo $server | awk -F '-' '{print $1}'`
		IP=`echo $server | awk -F '-' '{print $2}'`
		status=`ssh lamatri@$IP "sudo /etc/init.d/postfix status"` 
		sleep 3
#		echo "$hostname postfix $status"
		if [[ $status == *"running"* ]]; then
			echo "postfix is running in $hostname server"
		else
		
			(			
        			echo "From: serveralerts@consim.com"
        			echo "To: tier2_support@matrimony.com"
        			echo "Subject: [Alert] POSTFIX IS NOT RUNNING"
        			echo -e  "Dear Team,\n"
        			echo -e "CHECK POSTFIX service in $hostname server.\n"
        			echo  "Problem"
        			echo  "--------"
        			echo	$status
        			echo " "
        			echo "Solution"
        			echo  "--------"
        			echo  "1. Check postfix service status (/etc/init.d/postfix status)"
        			echo  "2. If postfix service please start the service(/etc/init.d/postfix start)" 
        			echo  "3. If unable to start means, kill all postfix process (ps -ef | grep -i postfix | awk '{print $2}' | xargs -9 kill)"
        			echo  "4. If mails are delivering with normal speed, leave it else take action based on the error in /var/log/indimail/deliver.25/current"
        			echo " "        
        			echo  "Script Information"
        			echo  "--------------------"
        			echo  "Server                   : $HOSTNAME"
        			echo  "Script Name              : $0"
        			echo  "Cron Scheduled User      : `whoami`" 
        			echo -e  "\nRegards,\nSEDBM Team"
			) | /usr/sbin/sendmail -t
		fi         
	done
