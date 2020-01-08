#/bin/bash /home/lamatri/bin/new/trigger_pagerduty_uislavedelay.sh -a "CRITICAL: Production DB ${snames} Process List Reached Threshold" -c "mysqluislave" -s ProdDB -d '{ "Message": "CRITICAL: Production DB Process List Reached Threshold"}'



#/bin/bash /home/sakthi/unica_dash/pager_duty_script.sh -a "Testing" -c "Mailer alert" -s UnicaDash -d '{ "Message": "Long Running in Unica uat test"}'


#/bin/bash /home/sakthi/unica_dash/pager_duty_script.sh -a "Long_Running_UAT_1AM" -c "Mailer alert" -s Long_Running -d "{ \"Message\": \"Long Running - ${workflow_name}\"}"


sh testalert.sh -a "Long_Running_UAT_1AM" -c "Mailer alert" -s "Long Running" -d "{ \"Message\": \"Long Running - ${workflow_name}\"}"
