#!/bin/bash
#This script is used to update a dns record that's hosted on digital ocean. Mainly used as a quick-and-easy ddns client.

domain=""
dns_record_id=""
api_key=""
api_url="https://api.digitalocean.com/v2/domains/$domain/records/$dns_record_id"
ip=$(curl ifcfg.me)

#exit if we weren't able to get our external IP
if [ ${#ip} -lt 8 ]; then
  exit 1
fi

#Update DNS with our ip address
curl -X PUT -H 'Content-Type: application/json' -H "Authorization: Bearer $api_key" -d '{"data":"'"$ip"'"}' $api_url
