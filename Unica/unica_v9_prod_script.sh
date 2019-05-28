#for i in {1..5}; do vi /tmp/v11_${i}; done

echo -en "Please type V9 - Macro/FC : "
read mfcs

mfc=$(echo $mfcs | tr '[:upper:]' '[:lower:]')

vi /tmp/v09_1.txt



if [ "$mfc" == "fc" ]; then
echo -en "###################################################################\n"

IFS=$'\n';  for u in `cat /home/sakthi/unica_v9_prod_excel.txt`; do grep $u /tmp/v09_1.txt > /dev/null && grep $u /tmp/v09_1.txt | grep -v "Running" >/dev/null; us=$?; if [ "$u" == "# #" ]; then echo -e "";elif [ ! "$us" == "0" ] ; then echo -e "" ; else echo -en "`cat /tmp/v09_1.txt | grep  "Run Succeeded" |grep -w ${u} | awk -F 'Run Succeeded' '{print $1}'| tail -1` #`cat /tmp/v09_1.txt | grep  "Run Succeeded" |grep -w ${u} | awk -F 'Run Succeeded' '{print $2}' | awk '{print $4" "$9}' | tail -1`\n"; fi; done | grep -v "^ #$"
echo -en "###################################################################\n"

elif [ "$mfc" == "macro" ]; then

echo -en "###################################################################\n"

IFS=$'\n';  for u in `cat /home/sakthi/unica_v9_prod_excel_macro.txt`; do grep $u /tmp/v09_1.txt > /dev/null && grep $u /tmp/v09_1.txt | grep -v "Running" >/dev/null; us=$?; if [ "$u" == "#" ];then echo -e "";elif [ ! "$us" == "0" ] ; then echo -e "" ; else echo -en "`cat /tmp/v09_1.txt | grep  "Run Succeeded" |grep -w ${u} | awk -F 'Run Succeeded' '{print $1}' | tail -1` #`cat /tmp/v09_1.txt | grep  "Run Succeeded" |grep -w ${u} | awk -F 'Run Succeeded' '{print $2}' | awk '{print $4" "$9}' | tail -1`\n"; fi; done | grep -v "^ #$"

echo -en "###################################################################\n"
else echo -en  "Please specify correctly\n\n"; fi

