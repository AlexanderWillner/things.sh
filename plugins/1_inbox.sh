#!/bin/bash

myPluginID=$(getNextPluginID)
myPlugin="plugin$myPluginID"
myPluginCommand='inbox'
myPluginDescription="Shows $LIMIT_BY inbox tasks ordered by '$ORDER_BY'"
myPluginMethod='queryInbox'

eval "$myPlugin=('$myPluginCommand' '$myPluginDescription' '$myPluginMethod')"

queryInbox() {
  sqlite3 "$THINGSDB" "$(getInboxQuery)"
}

getInboxQuery() {
  read -rd '' query <<-SQL || true
SELECT title, "things:///show?id=" || TASK.uuid
FROM $TASKTABLE TASK
WHERE $ISNOTTRASHED AND $ISTASK AND $ISNOTSTARTED AND $ISOPEN
ORDER BY TASK.$ORDER_BY
LIMIT $LIMIT_BY
SQL
  echo "${query}"
}
