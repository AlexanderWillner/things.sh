#!/bin/bash

myPluginID="$(getNextPluginID)"
myPlugin="plugin$myPluginID"
myPluginCommand="trashed"
myPluginDescription="Shows $LIMIT_BY trashed tasks ordered by '$ORDER_BY'"
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
ORDER BY $ORDER_BY
LIMIT $LIMIT_BY
SQL
  echo "$query"
}
