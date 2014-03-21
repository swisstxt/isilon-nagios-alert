#!/bin/bash

# Copyright: SWISS TXT 2014
# Author: René Moser <rene.moser@swisstxt.ch>
# Date: 2014-03-21
# Version: 1.0.0

DEBUG=0
MSG="No events"
STATUS="OK"
EXIT=0

ALERT_HEADER="$(/usr/bin/isi alert | head -1)"

HEALTH=OK
if ! /usr/bin/isi status | head -2 | tail -1 | grep -q OK
then
  HEALTH=NOK
fi

debug() {
  if [[ $DEBUG -eq 1 ]]
  then
    echo DEBUG: $1
  fi
}

# if no events detected
if ! $(echo "$ALERT_HEADER" | grep -q ^ID)
then
  echo "$STATUS - $MSG"
  exit $EXIT
fi

# We have events, process them
/usr/bin/isi alert | tail -n+2 | {
while read line
do

  debug "$line"

# Severity field depends if we have a end time or not...
  if [[ "$(echo "$line" | awk '{print $4}')" == "--" ]]
  then
    SEVERITY_FIELD="$(echo $line | awk '{print $5}')"
    MSG="$(echo $line | cut -d " " -f 7-)"
  else
    SEVERITY_FIELD="$(echo $line | awk '{print $6}')"
    MSG="$(echo $line | cut -d " " -f 8-)"
  fi

  # CRITICAL alert.
  if [[ "$SEVERITY_FIELD" == "C" ]]
  then
    if [[ "$HEALTH" == "OK" ]]
    then
      STATUS="WARNING"
      MSG="Health is OK, but critical event: $MSG"
      EXIT=1
    else 
      STATUS="CRITICAL"
      EXIT=2
    fi
    debug "$SEVERITY_FIELD: $STATUS - $MSG"
    break # it does not get worse
  fi

  # WARNING alert.
  if [[ "$SEVERITY_FIELD" == "W" ]]
  then
    STATUS="WARNING"
    EXIT=1
    debug "$SEVERITY_FIELD: $STATUS - $MSG"
    continue
  fi

  # INFORMATION alert.
  if [[ "$SEVERITY_FIELD" == "I" ]]
  then
    if [[ "$SEVERITY_FIELD" != "W" ]]
    then
      STATUS="INFORMATION"
    fi
    debug "$SEVERITY_FIELD: $STATUS - $MSG"
    continue
  fi

  # if we reach here, something looks weird...
  STATUS="CRITICAL"
  EXIT=2
  MSG="$0 script does not work as expected."
  break
done

debug "$SEVERITY_FIELD: $STATUS - $MSG"

echo "$STATUS - $MSG"
exit $EXIT
}
