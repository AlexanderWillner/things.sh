#!/bin/bash

myPluginID="$(getNextPluginID)"
myPlugin="plugin$myPluginID"
myPluginCommand="schedule"
myPluginDescription="Schedule an event by creating a number of related tasks"
myPluginMethod="scheduleEvent"
eval "$myPlugin=('$myPluginCommand' '$myPluginDescription' '$myPluginMethod')"

scheduleEvent() {
  [[ ! -r "${EVENTLIST:-}" ]] && (
    echo "Error: '${EVENTLIST:-}' not readable."
    exit 1
  )

  local -r today="$(date +%F)"
  local -r eventStart="${EVENTSTART:-$today}"
  local -r eventDays="${EVENTDURATION:-3}"
  local project=""

  IFS=';'

  while read -r -a array; do
    if [ -z "${array:-}" ]; then continue; fi

    #todo: add input validation, e.g., "$addition" should include "+/-"
    local position="${array[0]}"
    local addition="${array[1]}"
    local type="${array[2]}"
    local startDate=""
    local title=""

    title="$(python3 -c 'import urllib.parse, sys; print (urllib.parse.quote(sys.argv[1]))' "${array[3]}")"

    if [[ "$position" == "E" ]]; then
      startDate="$(date -j -f '%Y-%m-%d' -v"$addition" -v"+${eventDays}d" "$eventStart" +%Y-%m-%d)"
    else
      startDate="$(date -j -f '%Y-%m-%d' -v"$addition" "$eventStart" +%Y-%m-%d)"
    fi
    if [[ "$type" == "Project" ]]; then
      open "things:///add-project?title=$title&when=$startDate"
      project="$title"
    fi
    if [[ "$type" == "Task" ]]; then
      open "things:///add?title=$title&when=$startDate&list=$project"
    fi
  done <"$EVENTLIST"
}
