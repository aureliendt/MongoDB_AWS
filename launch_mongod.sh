#!/bin/bash

path_to_key="/Users/baptistepannier/Documents/NoSQL/Projet/Projet_INF730.pem "

# Launch mongod
MASTER_LIST=$(grep "MASTER" $1 | awk '{print $2}')
for l in $MASTER_LIST
do
    DNS=$(aws ec2 describe-instances --instance-id $l | grep ASSOCIATION | head -1 | awk '{print $3}')
    ssh -o StrictHostKeyChecking=no -i $path_to_key ubuntu@$DNS "sh -c 'nohup mongod --config /etc/mongod.conf > /dev/null 2>&1 & '"
done

SLAVE_LIST=$(grep "SLAVE" $1 | awk '{print $2}')
for l in $SLAVE_LIST
do
    DNS=$(aws ec2 describe-instances --instance-id $l | grep ASSOCIATION | head -1 | awk '{print $3}')
    ssh -o StrictHostKeyChecking=no -i $path_to_key ubuntu@$DNS "sh -c 'nohup mongod --config /etc/mongod.conf > /dev/null 2>&1 & '"
done

CONFIG=$(grep "CONFIG" $1 | awk '{print $2}')
for l in $CONFIG
do
    DNS=$(aws ec2 describe-instances --instance-id $l | grep ASSOCIATION | head -1 | awk '{print $3}')
    ssh -o StrictHostKeyChecking=no -i $path_to_key ubuntu@$DNS "sh -c 'nohup mongod --config /etc/mongod.conf > /dev/null 2>&1 & '"
done



# INIT MASTER
MASTER_LIST=$(grep "MASTER" $1 | awk '{print $2}')
echo $MASTER_LIST
for l in $MASTER_LIST
do
    DNS=$(aws ec2 describe-instances --instance-id $l | grep ASSOCIATION | head -1 | awk '{print $3}')
    IP_PRIVATE=$(aws ec2 describe-instances --instance-id $l | grep "INSTANCES" | awk '{print $13}')
    RS_ID=$(grep $l $1 | head -c 6 | tail -c 1)

    mystring="rs.initiate()"
    ssh -o StrictHostKeyChecking=no -i $path_to_key ubuntu@$DNS mongo --eval "'$mystring'"
    SLAVE_LIST=$(grep "SHARD"$RS_ID"_SLAVE" $1 | awk '{print $2}')

    mystring="config = {_id: \"rs$RS_ID\", members: [{ _id: 1, host : \"$IP_PRIVATE\" }]}; rs.reconfig(config, {force : true})"
    ssh -o StrictHostKeyChecking=no -i $path_to_key ubuntu@$DNS mongo --eval "'$mystring'"

    for m in $SLAVE_LIST
    do
        DNS_SLAVE=$(aws ec2 describe-instances --instance-id $m | grep ASSOCIATION | head -1 | awk '{print $3}')
        echo $DNS_SLAVE
        mystring="rs.add(\"$DNS_SLAVE\")"
        ssh -o StrictHostKeyChecking=no -i $path_to_key ubuntu@$DNS mongo --eval "'$mystring'"
        sleep 1
    done
done

# INIT CONF
CONFIG=$(grep "CONFIG" $1 | awk '{print $2}')
for l in $CONFIG
do
    DNS=$(aws ec2 describe-instances --instance-id $l | grep ASSOCIATION | head -1 | awk '{print $3}')
    IP_PRIVATE=$(aws ec2 describe-instances --instance-id $l | grep "INSTANCES" | awk '{print $13}')

    mystring="rs.initiate()"
    ssh -o StrictHostKeyChecking=no -i $path_to_key ubuntu@$DNS mongo --eval "'$mystring'"

    mystring="config = {_id: \"rs_config\", configsvr:true, members: [{ _id: 1, host : \"$IP_PRIVATE\"}]}; rs.reconfig(config, {force : true})"
    ssh -o StrictHostKeyChecking=no -i $path_to_key ubuntu@$DNS mongo --eval "'$mystring'"
done


# mongos --config /etc/mongod.conf
# sh.addShard( “rs1/ec2-54-237-193-41.compute-1.amazonaws.com:27017,ec2-54-158-75-229.compute-1.amazonaws.com:27017,iec2-54-167-20-198.compute-1.amazonaws.com:27017”)

# DRIVER=$(grep "DRIVER" $1 | awk '{print $2}')
# DNS_DRIVER=$(aws ec2 describe-instances --instance-id $DRIVER | grep ASSOCIATION | head -1 | awk '{print $3}')

# MASTER_LIST=$(grep "MASTER" $1 | awk '{print $2}')
# for l in $MASTER_LIST
# do
#     DNS=$(aws ec2 describe-instances --instance-id $l | grep ASSOCIATION | head -1 | awk '{print $3}')
#     IP_PRIVATE=$(aws ec2 describe-instances --instance-id $l | grep "INSTANCES" | awk '{print $13}')
#     RS_ID=$(grep $l $1 | head -c 6 | tail -c 1)

#     mystring="sh.addShard(\"rs$RS_ID/$IP_PRIVATE:27017\")"
#     echo $mystring
#     # ssh -o StrictHostKeyChecking=no -i $path_to_key ubuntu@$DNS_DRIVER mongo --eval "'$mystring'"
# done


# nohup mongoimport --db gdelt --collection export --type tsv --fields "GlobalEventID,Day,MonthYear,Year,FractionDate,Actor1Code,Actor1Name,Actor1CountryCode,Actor1KnownGroupCode,Actor1EthnicCode,Actor1Religion1Code,Actor1Religion2Code,Actor1Type1Code,Actor1Type2Code,Actor1Type3Code,Actor2Code,Actor2Name,Actor2CountryCode,Actor2KnownGroupCode,Actor2EthnicCode,Actor2Religion1Code,Actor2Religion2Code,Actor2Type1Code,Actor2Type2Code,Actor2Type3Code,IsRootEvent,EventCode,EventBaseCode,EventRootCode,QuadClass,GoldsteinScale,NumMentions,NumSources,NumArticles,AvgTone,Actor1Geo_Type,Actor1Geo_Fullname,Actor1Geo_CountryCode,Actor1Geo_ADM1Code,Actor1Geo_ADM2Code,Actor1Geo_Lat,Actor1Geo_Long,Actor1Geo_FeatureID,Actor2Geo_Type,Actor2Geo_Fullname,Actor2Geo_CountryCode,Actor2Geo_ADM1Code,Actor2Geo_ADM2Code,Actor2Geo_Lat,Actor2Geo_Long,Actor2Geo_FeatureID,Action_Type,Action_Fullname,Action_CountryCode,Action_ADM1Code,Action_ADM2Code,Action_Lat,Action_Long,Action_FeatureID,DATEADDED,SOURCEURL" --ignoreBlanks --drop --file /home/ubuntu/data/export.csv &

# echo "GlobalEventID,Day,MonthYear,Year,FractionDate,Actor1Code,Actor1Name,Actor1CountryCode,Actor1KnownGroupCode,Actor1EthnicCode,Actor1Religion1Code,Actor1Religion2Code,Actor1Type1Code,Actor1Type2Code,Actor1Type3Code,Actor2Code,Actor2Name,Actor2CountryCode,Actor2KnownGroupCode,Actor2EthnicCode,Actor2Religion1Code,Actor2Religion2Code,Actor2Type1Code,Actor2Type2Code,Actor2Type3Code,IsRootEvent,EventCode,EventBaseCode,EventRootCode,QuadClass,GoldsteinScale,NumMentions,NumSources,NumArticles,AvgTone,Actor1Geo_Type,Actor1Geo_Fullname,Actor1Geo_CountryCode,Actor1Geo_ADM1Code,Actor1Geo_ADM2Code,Actor1Geo_Lat,Actor1Geo_Long,Actor1Geo_FeatureID,Actor2Geo_Type,Actor2Geo_Fullname,Actor2Geo_CountryCode,Actor2Geo_ADM1Code,Actor2Geo_ADM2Code,Actor2Geo_Lat,Actor2Geo_Long,Actor2Geo_FeatureID,Action_Type,Action_Fullname,Action_CountryCode,Action_ADM1Code,Action_ADM2Code,Action_Lat,Action_Long,Action_FeatureID,DATEADDED,SOURCEURL" | awk -F ',' '{print $1}'


# nohup mongoimport --db gdelt --collection mentions --type tsv --fields "GlobalEventID,EventTimeDate,MentionTimeDate,MentionType, MentionSourceName,MentionIdentifier,SentenceID,Actor1CharOffset,Actor2CharOffset,ActionCharOffset,InRawText,Confidence,MentionDocLen,MentionDocTone,MentionDocTranslationInfo,Extras" --ignoreBlanks --drop --file /home/ubuntu/data/mention.csv &


# db.export.findOne({ Actor1Name: "TRUMP" })
