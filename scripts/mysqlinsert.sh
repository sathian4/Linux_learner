#!/bin/bash

read -p "Enter the email id to create: " usremail
read -p "Enter the requestor name: " usrreqst
read -p "Enter your name: " usrself
read -p "What is the purpose? (min.50 characters): " usrpurp

echo "insert into custom_email_creation (EmailId,RequestedBy,CreatedBy,Purpose) values ('$usremail','$usrreqst','$usrself','$usrpurp')" | mysql -uroot -proot@123 unica_dashbrd