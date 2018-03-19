#!/bin/bash

myPluginID=$(getNextPluginID)
myPlugin="plugin$myPluginID"
myPluginCommand="search"
myPluginDescription="Searches for a specific task"
myPluginMethod="querySearch"

eval "$myPlugin=('$myPluginCommand' '$myPluginDescription' '$myPluginMethod')"

querySearch() {
  [[ -z ${SEARCH_STRING:-} ]] && echo 2>&1 "ERROR: Use '-s' to set search string first" && exit 1
  sqlite3 "$THINGSDB" "$(getSearchQuery1)"
  sqlite3 "$THINGSDB" "$(getSearchQuery2)"
}

getSearchQuery1() {
  read -rd '' query <<-SQL || true
SELECT 
  T1.title as "Title", 
  date(T1.creationDate,"unixepoch") as "Created",
  date(T1.userModificationDate,"unixepoch") as "Modified",
  date(T1.dueDate,"unixepoch") as "Due",
  date(T1.startDate,"unixepoch") as "Start",
  date(T1.stopDate,"unixepoch") as "Stopped",
  T2.title as "Project",
  T3.title as "Area",
  "things:///show?id=" || T1.uuid
FROM $TASKTABLE T1
LEFT OUTER JOIN $TASKTABLE T2 ON T1.project = T2.uuid
LEFT OUTER JOIN $AREATABLE T3 ON T1.area = T3.uuid
WHERE T1.$ISNOTTRASHED AND T1.$ISTASK
AND (T1.title LIKE "%$SEARCH_STRING%" OR T2.title LIKE "%$SEARCH_STRING%")
LIMIT $LIMIT_BY
SQL
  echo "${query}"
}

getSearchQuery2() {
  read -rd '' query <<-SQL || true
SELECT 
  T2.title as "Title",
  date(T1.creationDate,"unixepoch") as "Created",
  date(T1.userModificationDate,"unixepoch") as "Modified",
  date(T1.stopDate,"unixepoch") as "Stopped",
  T1.title as "Task"
FROM TMChecklistItem T1
LEFT OUTER JOIN $TASKTABLE T2 ON T1.task = T2.uuid
WHERE T2.$ISNOTTRASHED
AND T1.title LIKE "%$SEARCH_STRING%"
LIMIT $LIMIT_BY
SQL
  echo "${query}"
}
