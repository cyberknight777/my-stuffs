#!/usr/bin/bash

set -euo pipefail

TOKEN=""

log() {
	local response
	response=$(curl -sX POST https://api.telegram.org/bot"${TOKEN}"/sendMessage \
		-d chat_id="${CHATID}" \
		-d parse_mode=Markdown \
		-d disable_web_page_preview=true \
		-d text="$1")

	if ! echo "$response" | grep -q '"ok":true'; then
		local err
		err=$(echo "$response" | sed -n 's/.*"description":"\([^"]*\)".*/\1/p')
		echo -e "\n\e[1;31m[✗] log(): Failed to send message: ${err:-Unknown error}\e[0m" >&2
		exit 1
	fi
}

serv() {
	systemctl "${1}" --user rustbin.service
	systemctl "${1}" --user cf-knight.service
}

SERV_STOPPED=false

cleanup() {
	if [[ $SERV_STOPPED == true ]]; then
		systemctl start --user rustbin.service || true
		systemctl start --user cf-knight.service || true
	fi
}

trap cleanup EXIT

# Get current date.
CURDATE=$(date '+%Y%m%d')

# File containing the exact date and time of the last run.
TIMESTAMP="/home/$USER/.last_run"

# Interval in which this script is expected to run which is every 48 hours.
INTERVAL=$((48 * 60 * 60))

# Current Epoch time
CURTIME=$(date +%s)

log "*[Rustbin Backup - ${CURDATE}]*"

log "*[Rustbin Backup - ${CURDATE}]* Check rustbin.service status"
# Check if service is active; if inactive, start it.
rbin=$(systemctl --user is-active rustbin.service)
if [[ ${rbin} == "active" ]]; then
	log "*[Rustbin Backup - ${CURDATE}]* rustbin.service is active"
else
	log "*[Rustbin Backup - ${CURDATE}]* rustbin.service is inactive, restarting."
	systemctl start --user rustbin.service
fi

log "*[Rustbin Backup - ${CURDATE}]* Check cf-knight.service status"
# Check if service is active; if inactive, start it.
cf=$(systemctl --user is-active cf-knight.service)
if [[ ${cf} == "active" ]]; then
	log "*[Rustbin Backup - ${CURDATE}]* cf-knight.service is active"
else
	log "*[Rustbin Backup - ${CURDATE}]* cf-knight.service is inactive, restarting."
	systemctl start --user cf-knight.service
fi

# Check if the .last_run file exists otherwise set PREVTIME to 0.
if [[ -f ${TIMESTAMP} ]]; then
	PREVTIME=$(cat "${TIMESTAMP}")
else
	PREVTIME=0
fi

# If it is indeed the next 48 hour run, continue through the script.
if [[ $((CURTIME - PREVTIME)) -ge ${INTERVAL} ]]; then

	log "*[Rustbin Backup - ${CURDATE}]* Start backup procedure"

	log "*[Rustbin Backup - ${CURDATE}]* Stop rustbin.service and cf-knight.service"
	# Stop the services.
	SERV_STOPPED=true
	serv stop

	log "*[Rustbin Backup - ${CURDATE}]* Compress and backup the database"
	# Compress and backup the database.
	gzip -c /home/$USER/rustbin/rustbin.db >/home/$USER/rbin-backup/rustbin-"${CURDATE}".db.gz

	log "*[Rustbin Backup - ${CURDATE}]* Start rustbin.service and cf-knight.service"
	# Start the services again.
	serv start
	SERV_STOPPED=false

	# Overwrite current timestamp to .last_run file.
	echo "$CURTIME" >"$TIMESTAMP"

	log "*[Rustbin Backup - ${CURDATE}]* Backup procedure completed"

else
	log "*[Rustbin Backup - ${CURDATE}]* Skip backup procedure"

fi
