#!/bin/bash

myPluginID=$(getNextPluginID)
myPlugin="plugin$myPluginID"
myPluginCommand='upcoming'
myPluginDescription="Shows $LIMIT_BY upcoming tasks ordered by date"
myPluginMethod='queryUpcoming'

eval "$myPlugin=('$myPluginCommand' '$myPluginDescription' '$myPluginMethod')"

queryUpcoming() {
  sqlite3 "$THINGSDB" "$(getUpcomingQuery)"
}

getUpcomingQuery() {
    read -rd '' query <<-SQL || true
SELECT 
  CASE 
    WHEN TASK.startDate IS NULL THEN "0000-00-00" 
    ELSE date(TASK.startDate,"unixepoch")
  END,
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
AND TASK.$ISPOSTPONED AND (TASK.startDate NOT NULL OR TASK.recurrenceRule NOT NULL)
ORDER BY TASK.startdate, TASK.todayIndex
LIMIT $LIMIT_BY
SQL
  echo "${query}"
}
