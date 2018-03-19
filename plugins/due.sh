#!/bin/bash

myPluginID=$(getNextPluginID)
myPlugin="plugin$myPluginID"
myPluginCommand='due'
myPluginDescription="Shows $LIMIT_BY tasks ordered by due date"
myPluginMethod='queryDue'

eval "$myPlugin=('$myPluginCommand' '$myPluginDescription' '$myPluginMethod')"

queryDue() {
  sqlite3 "$THINGSDB" "$(getDueQuery)"
}

getDueQuery() {
  read -rd '' query <<-SQL || true
SELECT
  date(TASK.dueDate,"unixepoch"),
  CASE 
    WHEN AREA.title IS NOT NULL THEN AREA.title 
    WHEN PROJECT.title IS NOT NULL THEN PROJECT.title
    WHEN HEADING.title IS NOT NULL THEN HEADING.title
    ELSE "(No Context)"
  END,
  TASK.title,
  "things:///show?id=" || TASK.uuid
FROM $TASKTABLE as TASK
LEFT OUTER JOIN $TASKTABLE PROJECT ON TASK.project = PROJECT.uuid
LEFT OUTER JOIN $AREATABLE AREA ON TASK.area = AREA.uuid
LEFT OUTER JOIN $TASKTABLE HEADING ON TASK.actionGroup = HEADING.uuid
WHERE TASK.$ISNOTTRASHED AND TASK.$ISOPEN
AND TASK.dueDate NOT NULL
ORDER BY TASK.dueDate
LIMIT $LIMIT_BY
SQL
  echo "${query}"
}
