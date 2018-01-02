#!/bin/bash

myPluginID=$(getNextPluginID)
myPlugin="plugin$myPluginID"
myPluginCommand='today'
myPluginDescription="Shows $LIMIT_BY todays tasks ordered by index"
myPluginMethod='queryToday'

eval "$myPlugin=('$myPluginCommand' '$myPluginDescription' '$myPluginMethod')"

queryToday() {
  sqlite3 "$THINGSDB" "$(getTodayQuery)"
}

getTodayQuery() {
  read -rd '' query <<-SQL || true
SELECT 
  CASE 
    WHEN AREA.title IS NOT NULL THEN AREA.title 
    WHEN PROJECT.title IS NOT NULL THEN PROJECT.title
    WHEN HEADING.title IS NOT NULL THEN HEADING.title
    ELSE "(No Context)"
  END,
  TASK.title
FROM $TASKTABLE as TASK
LEFT OUTER JOIN $TASKTABLE PROJECT ON TASK.project = PROJECT.uuid
LEFT OUTER JOIN $AREATABLE AREA ON TASK.area = AREA.uuid
LEFT OUTER JOIN $TASKTABLE HEADING ON TASK.actionGroup = HEADING.uuid
WHERE TASK.$ISNOTTRASHED AND TASK.$ISOPEN AND TASK.$ISTASK
AND TASK.$ISSTARTED
AND TASK.startdate is NOT NULL
ORDER BY TASK.startdate, TASK.todayIndex
LIMIT $LIMIT_BY
SQL
  echo "${query}"
}
