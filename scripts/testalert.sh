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


sleep 2s

echo -e "server is $server\ndetails is $details\nclient is $client\nalert is $alert"
