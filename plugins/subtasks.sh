#!/bin/bash

myPluginID=$(getNextPluginID)
myPlugin="plugin$myPluginID"
myPluginCommand="subtasks"
myPluginDescription="Shows $limitBy subtasks ordered by '$orderBy'"
myPluginMethod="querySubtasks"

eval "$myPlugin=('$myPluginCommand' '$myPluginDescription' '$myPluginMethod')"

querySubtasks() {
  sqlite3 "$THINGSDB" "$(getSubtasksQuery)"
}

getSubtasksQuery() {
    read -rd '' query <<-SQL || true
SELECT 
  TASK.title,
  CHECKLIST.title
FROM TMChecklistItem CHECKLIST
LEFT OUTER JOIN $TASKTABLE TASK ON CHECKLIST.task = TASK.uuid
WHERE TASK.$ISOPEN AND TASK.$ISNOTTRASHED
ORDER BY CHECKLIST.$orderBy
LIMIT $limitBy
SQL
  echo "${query}"
}