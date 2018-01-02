#!/bin/bash

myPluginID=$(getNextPluginID)
myPlugin="plugin$myPluginID"
myPluginCommand="mostClosed"
myPluginDescription="Shows $limitBy days on which most tasks were closed"
myPluginMethod="queryMostClosed"
eval "$myPlugin=('$myPluginCommand' '$myPluginDescription' '$myPluginMethod')"

myPluginID=$(getNextPluginID)
myPlugin="plugin$myPluginID"
myPluginCommand="mostCancelled"
myPluginDescription="Shows $limitBy days on which most tasks were cancelled"
myPluginMethod="queryMostCancelled"
eval "$myPlugin=('$myPluginCommand' '$myPluginDescription' '$myPluginMethod')"

myPluginID=$(getNextPluginID)
myPlugin="plugin$myPluginID"
myPluginCommand="mostTrashed"
myPluginDescription="Shows $limitBy days on which most tasks were trashed"
myPluginMethod="queryMostTrashed"
eval "$myPlugin=('$myPluginCommand' '$myPluginDescription' '$myPluginMethod')"

myPluginID=$(getNextPluginID)
myPlugin="plugin$myPluginID"
myPluginCommand="mostCreated"
myPluginDescription="Shows $limitBy days on which most tasks were created"
myPluginMethod="queryMostCreated"
eval "$myPlugin=('$myPluginCommand' '$myPluginDescription' '$myPluginMethod')"

myPluginID=$(getNextPluginID)
myPlugin="plugin$myPluginID"
myPluginCommand="mostTasks"
myPluginDescription="Shows $limitBy projects that have most tasks"
myPluginMethod="queryMostTasks"
eval "$myPlugin=('$myPluginCommand' '$myPluginDescription' '$myPluginMethod')"

myPluginID=$(getNextPluginID)
myPlugin="plugin$myPluginID"
myPluginCommand="mostCharacters"
myPluginDescription="Shows $limitBy tasks that have most characters"
myPluginMethod="queryMostCharacters"
eval "$myPlugin=('$myPluginCommand' '$myPluginDescription' '$myPluginMethod')"

queryMostCharacters() {
  sqlite3 "$THINGSDB" "$(getMostCharacters)"
}

queryMostTasks() {
  sqlite3 "$THINGSDB" "$(getMostTasks)"
}

queryMostClosed() {
  sqlite3 "$THINGSDB" "$(getMostClosed)"
}

queryMostCancelled() {
  sqlite3 "$THINGSDB" "$(getMostCancelled)"
}

queryMostCreated() {
  sqlite3 "$THINGSDB" "$(getMostCreated)"
}

queryMostTrashed() {
  sqlite3 "$THINGSDB" "$(getMostTrashed)"
}

getMostCharacters() {
  read -rd '' query <<-SQL || true
SELECT LENGTH(title), title
FROM $TASKTABLE
WHERE $ISNOTTRASHED AND $ISTASK AND $ISOPEN
ORDER BY LENGTH(title) DESC
LIMIT $limitBy
SQL
  echo "${query}"
}

getMostTasks() {
  read -rd '' query <<-SQL || true
SELECT COUNT(TASK.title) AS Tasks, PROJECT.title
FROM $TASKTABLE TASK
LEFT OUTER JOIN $TASKTABLE PROJECT ON TASK.project = PROJECT.uuid
WHERE TASK.$ISTASK AND TASK.$ISNOTTRASHED AND TASK.$ISOPEN AND PROJECT.title IS NOT NULL
GROUP BY PROJECT.title
ORDER BY Tasks DESC
LIMIT $limitBy
SQL
  echo "${query}"
}


getMostClosed() {
  read -rd '' query <<-SQL || true
SELECT COUNT(title) AS TasksDone, date(stopDate,"unixepoch") AS DAY
FROM $TASKTABLE
WHERE DAY NOT NULL AND $ISCOMPLETED
GROUP BY DAY
ORDER BY TasksDone DESC
LIMIT $limitBy
SQL
  echo "${query}"
}

getMostCancelled() {
  read -rd '' query <<-SQL || true
SELECT COUNT(title) AS TasksDone, date(stopDate,"unixepoch") AS DAY
FROM $TASKTABLE
WHERE DAY NOT NULL AND $ISCANCELLED
GROUP BY DAY
ORDER BY TasksDone DESC
LIMIT $limitBy
SQL
  echo "${query}"
}

getMostTrashed() {
  read -rd '' query <<-SQL || true
SELECT COUNT(title) AS TasksDone, date(userModificationDate,"unixepoch") AS DAY
FROM $TASKTABLE
WHERE DAY NOT NULL AND $ISTRASHED
GROUP BY DAY
ORDER BY TasksDone DESC
LIMIT $limitBy
SQL
  echo "${query}"
}

getMostCreated() {
  read -rd '' query <<-SQL || true
SELECT COUNT(title) AS TasksCreated, date(creationDate,"unixepoch") AS DAY
FROM $TASKTABLE
WHERE DAY NOT NULL
GROUP BY DAY
ORDER BY TasksCreated DESC
LIMIT $limitBy
SQL
  echo "$query"
}
