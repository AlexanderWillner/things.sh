#!/bin/bash

myPluginID=$(getNextPluginID)
myPlugin="plugin$myPluginID"
myPluginCommand="old"
myPluginDescription="Shows $limitBy old tasks ordered by '$orderBy'"
myPluginMethod="queryOld"

eval "$myPlugin=('$myPluginCommand' '$myPluginDescription' '$myPluginMethod')"

queryOld() {
  sqlite3 "$THINGSDB" "$(getOldQuery)"
}

getOldQuery() {
    read -rd '' query <<-SQL || true
SELECT
  date(TASK.creationDate,"unixepoch"),
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
WHERE TASK.$ISNOTTRASHED AND TASK.$ISOPEN AND TASK.$ISTASK AND TASK.recurrenceRule IS NULL
ORDER BY TASK.$orderBy
LIMIT $limitBy
SQL
  echo "${query}"
}