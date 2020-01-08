#!/bin/bash

# Sample invocation:
# ------------------
# trigger_pagerduty_alert -a "More than 2 New Relic processes running" -c "New Relic process monitor" -s Web6 -p "New Relic daemon" -d '{ "program": "newrelic-daemon", "memory used": "1500 MB", "thread count": 8, "load avg": 0.75 }'
#
# Description of parameters:
# --------------------------
# Alert description [mandatory] :
#     Brief description of the alert.
#     Eg: "More than 2 New Relic processes running"
# Client monitor id [mandatory] :
#     Name for the monitor program.
#     Eg: "New Relic process monitor"
# Server [mandatory] :
#     Server name or IP address.
#     Eg: "Web6"
# Process [optional] :
#     Name of the process.
#     Eg: "New Relic daemon"
# Details JSON [optional] :
#     Additional details that need to be logged in the alert.
#     [Important: must be in JSON format]
#     Eg: { "program": "newrelic-daemon", "memory used": "1500 MB", "thread count": 8, "load avg": 0.75 }

function usage () {
    cat <<EOF
Usage: $0 -h -a <alert description> -c <client monitor id> -d <details as JSON> -s <server name> -p <process>
    or $0 --help --alert <alert description> --client <client monitor id> --details <details as JSON> --server <server name> --process <process>
EOF
    exit 0
}
 
PARSED_OPTIONS=$(getopt -n "$0" -o ha:c:d:s:p: --long "help,alert:,client:,details:,server:,process:" -- "$@")
if [ $? -ne 0 ];
then
    exit 1
fi
 
eval set -- "$PARSED_OPTIONS"
 
while true; do
    case "$1" in

    -h|--help)
      usage;;
 
    -a|--alert)
      if [ -n "$2" ]; then
          alert="$2"
      fi
      shift 2;;
 
    -c|--client)
      if [ -n "$2" ]; then
          client="$2"
      fi
      shift 2;;
 
    -d|--details)
      if [ -n "$2" ]; then
          details="$2"
      fi
      shift 2;;
 
    -s|--server)
      if [ -n "$2" ]; then
          server="$2"
      fi
      shift 2;;
 
    -p|--process)
      if [ -n "$2" ]; then
          process="$2"
      fi
      shift 2;;
 
    --)
      shift
      break;;
    esac
done

if [ -z "$alert" ]; then
    echo "Error: Alert description is missing."
    exit 1
fi
if [ -z "$server" ]; then
    echo "Error: Server name is missing."
    exit 1
fi
if [ -z "$client" ]; then
    echo "Error: Client monitor id is missing."
    exit 1
fi

API_TOKEN="bxb5yxrvfiESUFiq2kuw"

# List of Service Keys. Change accordingly for the different services.
# Refer to the Pager Duty console (https://sedbm.pagerduty.com/) for the 
# latest values.
#
# Custom Service ----------------- 6941a940f9de4d57aaae73c333fe18f2
# Icinga2 APP Support ------------ e26a8c8e631c416680417af01c12d59f
# Icinga2 APP Support Immediate -- 5d73079a8bf0418d81cfba971ee7b0db
# Icinga2 DB Support ------------- a72c729613554824b6b469d2a9ac1761
# Icinga2 DB Support Immediate --- b5eab49a090e4c65af9850e5c9f8abd4

SERVICE_KEY="9173adb682fe4bc1a95043d3c784457a"

PAYLOAD="{ \"service_key\": \"$SERVICE_KEY\", \"event_type\": \"trigger\", \"description\": \"$alert\", \"client\": \"$client\""
if [ -n "$details" ]; then
    PAYLOAD+=", \"details\": $details }" 
fi

# Sample request.
# curl -X POST --header 'Authorization: Token token='"$API_TOKEN" --header 'Content-Type: application/json' --header 'Accept: application/json' -d '{ "service_key": "'"$SERVICE_KEY"'", "event_type": "trigger", "description": "IGNORE: Test alert on machine srv01.matri.com", "client": "Sample Monitoring Service", "client_url": "https://monitoring.service.com", "details": { "tested by": "kiran", "ping time": "1500ms", "thread count": 8, "load avg": 0.75 } }' 'https://events.pagerduty.com/generic/2010-04-15/create_event.json'

curl -s -o /dev/null --header 'Authorization: Token token='"$API_TOKEN" --header 'Content-Type: application/json' --header 'Accept: application/json' -d "$PAYLOAD" 'https://events.pagerduty.com/generic/2010-04-15/create_event.json'



