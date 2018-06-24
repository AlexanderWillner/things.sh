#!/bin/bash

myPluginID="$(getNextPluginID)"
myPlugin="plugin$myPluginID"
myPluginCommand='hours'
myPluginDescription="Shows how many hours of work have been planned for today"
myPluginMethod='queryMinutes'

eval "$myPlugin=('$myPluginCommand' '$myPluginDescription' '$myPluginMethod')"

queryMinutes() {
  sqlite3 "$THINGSDB" "$(getTodayHours)"
}

getTodayHours() {
  read -rd '' query <<-SQL || true
SELECT
  ROUND(SUM(REPLACE(TAG.title,"min",""))/60.,1)
FROM $TASKTABLE TASK
LEFT JOIN TMTaskTag TAGS ON TAGS.tasks = TASK.uuid
LEFT JOIN TMTag TAG ON TAGS.tags = TAG.uuid
WHERE
  TASK.$ISNOTTRASHED AND TASK.$ISOPEN AND TASK.$ISTASK
  AND TASK.$ISSTARTED AND TASK.startdate is NOT NULL
  AND TAGS.tags IN (SELECT TAGS.uuid FROM $TAGTABLE TAGS WHERE TAGS.title GLOB '[0-9]*min')
LIMIT $LIMIT_BY
SQL
  echo "$query"
}
