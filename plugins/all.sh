#!/bin/bash

myPluginID=$(getNextPluginID)
myPlugin="plugin$myPluginID"
myPluginCommand="all"
myPluginDescription="Shows $limitBy tasks ordered by '$orderBy'"
myPluginMethod="queryAll"

eval "$myPlugin=('$myPluginCommand' '$myPluginDescription' '$myPluginMethod')"

queryAll() {
  sqlite3 "$THINGSDB" "$(getAllQuery)"
}

getAllQuery() {
    read -rd '' query <<-SQL || true
SELECT 
  CASE 
    WHEN AREA.title IS NOT NULL THEN AREA.title 
    WHEN PROJECT.title IS NOT NULL THEN PROJECT.title
    WHEN HEADING.title IS NOT NULL THEN HEADING.title
    ELSE "(No Context)"
  END,
TASK.title
FROM $TASKTABLE TASK
LEFT OUTER JOIN $TASKTABLE PROJECT ON TASK.project = PROJECT.uuid
LEFT OUTER JOIN $AREATABLE AREA ON TASK.area = AREA.uuid
LEFT OUTER JOIN $TASKTABLE HEADING ON TASK.actionGroup = HEADING.uuid
WHERE TASK.$ISNOTTRASHED AND TASK.$ISOPEN AND TASK.$ISTASK
ORDER BY TASK.$orderBy
LIMIT $limitBy
SQL
  echo "${query}"
}