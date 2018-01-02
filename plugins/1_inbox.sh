#!/bin/bash

myPluginID=$(getNextPluginID)
myPlugin="plugin$myPluginID"
myPluginCommand='inbox'
myPluginDescription="Shows $limitBy inbox tasks ordered by '$orderBy'"
myPluginMethod='queryInbox'

eval "$myPlugin=('$myPluginCommand' '$myPluginDescription' '$myPluginMethod')"

queryInbox() {
  sqlite3 "$THINGSDB" "$(getInboxQuery)"
}

getInboxQuery() {
    read -rd '' query <<-SQL || true
SELECT title
FROM $TASKTABLE TASK
WHERE $ISNOTTRASHED AND $ISTASK AND $ISNOTSTARTED AND $ISOPEN
ORDER BY TASK.$orderBy
LIMIT $limitBy
SQL
  echo "${query}"
}