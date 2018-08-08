echo -n "Please enter the email address(s) :"

read email

echo $email >> /tmp/echoed.txt

if [[ $email =~ [a-zA-Z0-9_+-]+@[a-zA-Z0-9]+\.[a-zA-Z]+ ]]

then 
echo "this is valid email address"
else
echo "this is not valid email address"
fi

