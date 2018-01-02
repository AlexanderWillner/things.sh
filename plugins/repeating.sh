#!/bin/bash

myPluginID=$(getNextPluginID)
myPlugin="plugin$myPluginID"
myPluginCommand="repeating"
myPluginDescription="Shows $limitBy repeating tasks ordered by '$orderBy'"
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
ORDER BY $orderBy
LIMIT $limitBy
SQL
  echo "${query}"
}