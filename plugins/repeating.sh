#!/bin/bash

myPluginID=$(getNextPluginID)
myPlugin="plugin$myPluginID"
myPluginCommand="repeating"
myPluginDescription="Shows $LIMIT_BY repeating tasks ordered by '$ORDER_BY'"
myPluginMethod="queryRepeating"

eval "$myPlugin=('$myPluginCommand' '$myPluginDescription' '$myPluginMethod')"

queryRepeating() {
  sqlite3 "$THINGSDB" "$(getRepeatingQuery)"
}

getRepeatingQuery() {
    read -rd '' query <<-SQL || true
SELECT title
FROM $TASKTABLE
WHERE $ISNOTTRASHED AND $ISOPEN AND $ISPOSTPONED
AND recurrenceRule NOT NULL
ORDER BY $ORDER_BY
LIMIT $LIMIT_BY
SQL
  echo "${query}"
}
