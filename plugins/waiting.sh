#!/bin/bash

myPluginID=$(getNextPluginID)
myPlugin="plugin$myPluginID"
myPluginCommand="waiting"
myPluginDescription="Shows $LIMIT_BY tasks with the tag '$WAITING_TAG' ordered by '$ORDER_BY'"
myPluginMethod="queryWaiting"

eval "$myPlugin=('$myPluginCommand' '$myPluginDescription' '$myPluginMethod')"

queryWaiting() {
  sqlite3 "$THINGSDB" "$(getWaitingQuery)"
}

getWaitingQuery() {
    read -rd '' query <<-SQL || true
SELECT 
  CASE 
    WHEN AREA.title IS NOT NULL THEN AREA.title 
    WHEN PROJECT.title IS NOT NULL THEN PROJECT.title
    WHEN HEADING.title IS NOT NULL THEN HEADING.title
    ELSE "(No Context)"
  END,
  TASK.title
FROM TMTaskTag TAGS
LEFT JOIN $TASKTABLE TASK ON TAGS.tasks = TASK.uuid
LEFT OUTER JOIN $TASKTABLE PROJECT ON TASK.project = PROJECT.uuid
LEFT OUTER JOIN $AREATABLE AREA ON TASK.area = AREA.uuid
LEFT OUTER JOIN $TASKTABLE HEADING ON TASK.actionGroup = HEADING.uuid
WHERE TASK.$ISNOTTRASHED AND TASK.$ISOPEN
AND TAGS.tags=(SELECT uuid FROM $TAGTABLE WHERE title='$WAITING_TAG')
ORDER BY TASK.$ORDER_BY
LIMIT $LIMIT_BY
SQL
  echo "${query}"
}
