#!/bin/bash

myPluginID=$(getNextPluginID)
myPlugin="plugin$myPluginID"
myPluginCommand="scheduleEvent"
myPluginDescription="Schedules an event by creating a number of tasks"
myPluginMethod="scheduleEvent"
eval "$myPlugin=('$myPluginCommand' '$myPluginDescription' '$myPluginMethod')"

scheduleEvent() {
  [[ ! -r  "${EXPORT_EVENTLIST}" ]] && (echo "Error: ${EXPORT_EVENTLIST} not readable."; exit 1;)
  while read -r line; do
    echo $line
    #things:///add-project?title=2018%20Travel%20X&area=Orga
    #things:///add?title=Two%20days%20before%3A%20Update%20ZEB%20%26%20Co&when=2018-03-12-1d&list=2018%20Travel%20X&heading=Preparation
  done < "${EXPORT_EVENTLIST}"
}

