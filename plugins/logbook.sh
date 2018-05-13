#!/bin/bash

myPluginID=$(getNextPluginID)
myPlugin="plugin$myPluginID"
myPluginCommand='logbook'
myPluginDescription="Shows $LIMIT_BY completed tasks ordered by '$ORDER_BY'"
myPluginMethod='queryLogbook'

eval "$myPlugin=('$myPluginCommand' '$myPluginDescription' '$myPluginMethod')"

queryLogbook() {
  sqlite3 "$THINGSDB" "$(getLogbookQuery)"
  date +'%Y-%m-%d'
}

getLogbookQuery() {
  read -rd '' query <<-SQL || true
SELECT TASK.title, GROUP_CONCAT(TAG.title)
FROM $TASKTABLE TASK
LEFT  JOIN 
  $TASKTAGTABLE TAGS ON TASK.uuid = TAGS.tasks
LEFT JOIN
   $TAGTABLE TAG ON TAGS.tags = TAG.uuid
WHERE date(TASK.stopDate,"unixepoch") = "$(date +%Y-%m-%d)"
GROUP BY TASK.title
ORDER BY TASK.$ORDER_BY
LIMIT $LIMIT_BY
SQL
  echo "${query}"
}
