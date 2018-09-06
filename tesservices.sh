#! /bin/bash
##Local IP address info###
for i in `cat /tmp/ip.txt`
do
##Prelim ssh key test##
sshpass -p 'Gre@tv1ct0ry' ssh -l lamatri $i exit
if test $? -ne 0
then
echo "There is a issue with key authentication with this $i server, Kindly add key and try again!"
exit 1
fi
##Copying info script to remote server##
sshpass -p 'Gre@tv1ct0ry' scp /tmp/Eofscript.sh lamatri@$i:/tmp/
##Executing the script in the remote server##
sshpass -p ' ' ssh -l lamatri $i "/bin/bash /tmp/Eofscript.sh"
if test $? -ne 0
then
echo "There might be a authorization issue with this $i server. "
exit 1
fi
##Text validation##
val=`sshpass -p ' ' ssh -l lamatri $i "hostname"`
sizeval1=`sshpass -p ' ' ssh -l lamatri $i "ls -ltra /tmp/$val.txt"`
sizval2=`echo $sizeval1 | awk '{print $5}'`
if [ $sizval2 -gt 0 ]
then
echo -e "File exists in remote server i\.e $sizeval1"
##Saving the server info in 3.30 /home/lamatri/localserverinfo folder##
rsync --rsh="sshpass -p 'Gre@tv1ct0ry' ssh -l lamatri" $i:/tmp/$val.txt /home/lamatri/localserverinfo
cd /home/lamatri/localserverinfo
mv $val.txt $i.txt
else
echo "Script not completed kindly check for auth key, permission issue etc"
fi
done

