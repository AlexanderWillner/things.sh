#!/bin/bash

myPluginID="$(getNextPluginID)"
myPlugin="plugin$myPluginID"
myPluginCommand="subtasks"
myPluginDescription="Shows $LIMIT_BY subtasks ordered by '$ORDER_BY'"
myPluginMethod="querySubtasks"

eval "$myPlugin=('$myPluginCommand' '$myPluginDescription' '$myPluginMethod')"

querySubtasks() {
  sqlite3 "$THINGSDB" "$(getSubtasksQuery)"
}

getSubtasksQuery() {
  read -rd '' query <<-SQL || true
SELECT 
  TASK.title,
  CHECKLIST.title,
  "things:///show?id=" || TASK.uuid
FROM TMChecklistItem CHECKLIST
LEFT OUTER JOIN $TASKTABLE TASK ON CHECKLIST.task = TASK.uuid
WHERE TASK.$ISOPEN AND TASK.$ISNOTTRASHED
ORDER BY CHECKLIST.$ORDER_BY
LIMIT $LIMIT_BY
SQL
  echo "$query"
}
