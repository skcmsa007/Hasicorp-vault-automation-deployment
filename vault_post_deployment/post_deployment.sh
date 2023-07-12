#!/bin/sh
profile=$1
secret_json=$2
curl -s --request POST --data '{"secret_shares": 4, "secret_threshold": 2}' http://0.0.0.0:8200/v1/sys/init -o response.json
modresponse=$(sed -e 's/:/ /g' -e 's/{/ /g' -e 's/}/ /g' -e 's/\[/ /g' -e 's/\]/ /g' -e 's/"/ /g' -e 's/,/ /g' response.json) 
echo $modresponse
key_1=$(echo $modresponse | grep -oP "(?<=keys )[^ ]+")
echo "key 1 is " $key_1

key_2=$(echo $modresponse | grep -oP "(?<=$key_1 )[^ ]+")
echo "key 2 is " $key_2

token=$(echo $modresponse | grep -oP "(?<=root_token )[^ ]+")

echo "Token is : "$token

docker exec -et prodvault vault operator unseal $key_1
docker exec -et prodvault vault operator unseal $key_2
docker exec -et prodvault vault login $token

container_id=$(docker ps -aqf "name=prodvault")
docker cp  ./$secret_json $container_id:/xlrt_secrets.json

docker exec -et prodvault vault secrets enable -path=secret kv
docker exec -et prodvault vault write -format=json secret/$profile @xlrt_secrets.json