mysqldump -uroot -proot@123 unica_dashbrd unica_v11_uat_wf_details > /tmp/unica_v11_uat_wf_details_newtest.sql
sed -i 's#unica_v11_uat_wf_details#unica_v12_uat_wf_details#g' /tmp/unica_v11_uat_wf_details_newtest.sql
mysql -uroot -proot@123 unica_dashbrd < /tmp/unica_v11_uat_wf_details_newtest.sql
cp -ap /tmp/unica_v11_uat_1am_wf_details /tmp/unica_v12_uat_1am_wf_details
select * from unica_v12_uat_wf_details where date(executedate)=curdate() and period='1AM' and workflow_name in ('Photography','CCP');
update unica_v12_uat_wf_details set status=NULL where date(executedate)=curdate() and period='1AM' and workflow_name in ('Photography','CCP');

Photography
CCP
