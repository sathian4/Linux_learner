
vi /tmp/v11_1.txt
clear
echo -en "########################################################\n"
IFS=$'\n';  for u in `cat /home/sakthi/unica_v11_excel.txt | egrep "^[0-9]|^# #$"| awk '{print $2}'`; do grep $u /tmp/v11_1.txt > /dev/null && grep $u /tmp/v11_1.txt | grep -v Running > /dev/null; us=$?; if [ "$u" == "#"  ]; then echo -e ""; elif [ ! "$us" == "0" ]; then echo -e "";else cat /tmp/v11_1.txt |egrep "$u" | grep "Run Succeeded"| awk '{print $1" "$7" "$12}' | tail -1;fi; done
echo -en "########################################################\n"

