#!/bin/bash

# Custom parameters
path_to_key="/Users/auredt7892/Desktop/MSTelecom/Projet_INF730/Projet_INF730.pem"
master_id=$2

# slave_id=\
# "i-0d258f0134f7a2288
# djfal;jsdj
# fkal;jfladsfj
# jfl;adjf;d"

# for element in $comp_id
# do
#         echo "element =" $element
# done


if [ $1 = "start" ]; then

# Start the server
echo "Used Master id: " $master_id
echo "Starting the Master..."
aws ec2 start-instances --instance-ids $master_id > /dev/null 2>&1

# Wait for the server to be running
bool=1
while [ "$bool" -ne 0 ]
do
aws ec2 describe-instances --instance-id $master_id | grep $'STATE\t' | head -1 | awk '{print $3}'
state=$(aws ec2 describe-instances --instance-id $master_id | grep $'STATE\t' | head -1 | awk '{print $3}')
if [ $state = "running" ]; then
bool=0
fi
sleep 2
done

echo "The master server is now running !"

# Get the DNS public of the Master server
DNS=$(aws ec2 describe-instances --instance-id $master_id | grep ASSOCIATION | head -1 | awk '{print $3}')
echo "DNS used for the Master: " $DNS

# Connection file to the Master
bool=1
while [ "$bool" -ne 0 ]
do
nmap -Pn 22 $DNS | grep 'Host is up'
test=$(echo $?)
if [[ $test == 0 ]]
then
bool=0
fi
sleep 1
done

echo ssh -o StrictHostKeyChecking=no -i $path_to_key -L 8157:127.0.0.1:8888 ubuntu@$DNS
sleep 1
ssh -o StrictHostKeyChecking=no -i $path_to_key -L 8157:127.0.0.1:8888 ubuntu@$DNS

elif [ $1 = "stop" ]; then
echo "Stopping the Master"
aws ec2 stop-instances --instance-ids $master_id > /dev/null 2>&1

else
echo "Unknown argument"
echo "Use start or stop"
fi

