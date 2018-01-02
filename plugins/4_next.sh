#!/bin/bash

myPluginID=$(getNextPluginID)
myPlugin="plugin$myPluginID"
myPluginCommand='next'
myPluginDescription="Shows $limitBy next tasks ordered by '$orderBy'"
myPluginMethod='queryNext'

eval "$myPlugin=('$myPluginCommand' '$myPluginDescription' '$myPluginMethod')"

queryNext() {
  sqlite3 "$THINGSDB" "$(getNextQuery)"
}

getNextQuery() {
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
WHERE TASK.$ISNOTTRASHED AND TASK.$ISOPEN AND TASK.$ISTASK AND TASK.$ISSTARTED
AND (
  TASK.area NOT NULL
  OR
  TASK.project in (SELECT uuid FROM $TASKTABLE WHERE uuid=TASK.project AND $ISSTARTED AND $ISNOTTRASHED) 
  OR
  TASK.actionGroup in 
    (SELECT uuid FROM TMTask heading WHERE uuid=TASK.actionGroup 
      AND $ISSTARTED 
      AND $ISNOTTRASHED
      AND heading.project in (SELECT uuid FROM TMTask WHERE uuid=heading.project AND $ISSTARTED AND $ISNOTTRASHED)
    )
  )
ORDER BY TASK.todayIndex;
SQL
  echo "${query}"
}