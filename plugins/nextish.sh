#!/bin/bash

myPluginID="$(getNextPluginID)"
myPlugin="plugin$myPluginID"
myPluginCommand="nextish"
myPluginDescription="Shows $LIMIT_BY nextish tasks ordered by '$ORDER_BY'"
myPluginMethod="queryNextish"

eval "$myPlugin=('$myPluginCommand' '$myPluginDescription' '$myPluginMethod')"

queryNextish() {
  sqlite3 "$THINGSDB" "$(getNextishQuery)"
}

getNextishQuery() {
  read -rd '' query <<-SQL || true
SELECT
  CASE 
    WHEN AREA.title IS NOT NULL THEN AREA.title 
    WHEN PROJECT.title IS NOT NULL THEN PROJECT.title
    WHEN HEADING.title IS NOT NULL THEN HEADING.title
    ELSE "(No Context)"
  END,
  TASK.title,
  "things:///show?id=" || TASK.uuid
FROM $TASKTABLE TASK
LEFT OUTER JOIN $TASKTABLE PROJECT ON TASK.project = PROJECT.uuid
LEFT OUTER JOIN $AREATABLE AREA ON TASK.area = AREA.uuid
LEFT OUTER JOIN $TASKTABLE HEADING ON TASK.heading = HEADING.uuid
WHERE TASK.$ISNOTTRASHED AND TASK.$ISSTARTED AND TASK.$ISOPEN AND TASK.$ISTASK
ORDER BY TASK.$ORDER_BY
LIMIT $LIMIT_BY
SQL
  echo "$query"
}
