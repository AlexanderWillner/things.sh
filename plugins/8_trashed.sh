#!/bin/bash

myPluginID=$(getNextPluginID)
myPlugin="plugin$myPluginID"
myPluginCommand="trashed"
myPluginDescription="Shows $limitBy trashed tasks ordered by '$orderBy'"
myPluginMethod="queryTrashed"

eval "$myPlugin=('$myPluginCommand' '$myPluginDescription' '$myPluginMethod')"

queryTrashed() {
  sqlite3 "$THINGSDB" "$(getTrashedQuery)"
}

getTrashedQuery() {
    read -rd '' query <<-SQL || true
SELECT title
FROM $TASKTABLE TASK
WHERE $ISTRASHED AND $ISTASK
ORDER BY $orderBy
LIMIT $limitBy
SQL
  echo "${query}"
}