#!/bin/bash

myPluginID="$(getNextPluginID)"
myPlugin="plugin$myPluginID"
myPluginCommand="cancelled"
myPluginDescription="Shows $LIMIT_BY cancelled tasks ordered by cancel date"
myPluginMethod="queryCancelled"

eval "$myPlugin=('$myPluginCommand' '$myPluginDescription' '$myPluginMethod')"

queryCancelled() {
  sqlite3 "$THINGSDB" "$(getCancelledQuery)"
}

getCancelledQuery() {
  read -rd '' query <<-SQL || true
SELECT
  date(TASK.stopDate,"unixepoch") AS StopDate,
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
LEFT OUTER JOIN $TASKTABLE HEADING ON TASK.heading = HEADING.uuid
WHERE TASK.$ISNOTTRASHED AND TASK.$ISCANCELLED AND TASK.$ISTASK
ORDER BY StopDate
LIMIT $LIMIT_BY
SQL
  echo "$query"
}
