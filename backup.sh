#!/bin/bash

#auth
AUTH_TOKEN=

#utils
CURL="`which curl`"

#check utils
if [ -z "$CURL" ]; then
    echo "no curl plz install first"
exit 1
fi

timestamp=$(date +"%d.%m.%Y.%T")
#testarray=(178734 197594)

list(){
local temp_file
temp_file=`mktemp /tmp/.list.XXXXX`
${CURL} --silent "https://api.vscale.io/v1/scalets" -H "X-Token: ${AUTH_TOKEN}"  1>${temp_file}
response=`cat "${temp_file}" | jq '.[] | .ctid'`
array=($response)
echo "${array[@]}"
rm -f "{temp_file}"
}

makebackups(){
for z in "${array[@]}"
do
    ${CURL} --silent "https://api.vscale.io/v1/scalets/$z/backup" -X POST --data-binary '{"name":"auto_ctid2_'$z-$timestamp'"}' -H "X-Token: ${AUTH_TOKEN}" -H "Content-Type: application/json;charset=UTF-8"
done
}

perserv() {
local temp_file_ps
temp_file_ps=`mktemp /tmp/.perserv.XXXXX`
for u in "${array[@]}"
do
    ${CURL} --silent "https://api.vscale.io/v1/scalets/$u" -H "X-Token: ${AUTH_TOKEN}" 1>>${temp_file_ps}
done
}

getbackupsid() {
local temp_file_backups
temp_file_backups=`mktemp /tmp/.backupsid.XXXXX`
${CURL} --silent "https://api.vscale.io/v1/backups" -H "X-Token: ${AUTH_TOKEN}"  1>${temp_file_backups}
list_backups=`cat "${temp_file_backups}" | jq 'def older(days): (now - (strptime("%d.%m.%Y %T") | mktime)) > (days*24*3600); .[] | select ( .created | older(2) ) | .id' | sed 's/"//g'`
array_backups_id=($list_backups)
echo "${array_backups_id[@]}"
rm -f "${temp_file_backups}"
}

deletebackups() {
local temp_file_backups_delete
temp_file_backups_delete=`mktemp /tmp/.backups_delete.XXXXX`
for l in "${array_backups_id[@]}"
do
    ${CURL} --silent "https://api.vscale.io/v1/backups/$l" -X DELETE -H "X-Token: ${AUTH_TOKEN}" -H "Content-Type: application/json;charset=UTF-8" 1>>${temp_file_backups_delete}
done
#list_backups_date=`cat "${temp_file_backups_delete}" | jq '.created' | sed 's/"//g'`
#echo $list_backups_date
rm -f "${temp_file_backups_delete}"
}

list
makebackups
#perserv
getbackupsid
deletebackups
