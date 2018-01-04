#!/bin/bash

myPluginID=$(getNextPluginID)
myPlugin="plugin$myPluginID"
myPluginCommand="statcsv"
myPluginDescription="Exports some statistics as semicolon separated values for $EXPORT_RANGE"
myPluginMethod="queryStatCSV"

eval "$myPlugin=('$myPluginCommand' '$myPluginDescription' '$myPluginMethod')"

queryStatCSV() {
  echo '"Date";"Created";"Closed";"Cancelled";"Trashed"'
  sqlite3 -csv -separator ';' "$THINGSDB" "$(getStatCSVQuery)"
}

getStatCSVQuery() {
  read -rd '' query <<-SQL || true
WITH RECURSIVE
  timeseries(x) AS (
     SELECT 0
     UNION ALL
     SELECT x+1 FROM timeseries
      LIMIT (SELECT ((julianday("now") - julianday("now", "$EXPORT_RANGE"))) + 1)
  )

SELECT 
  date(julianday("now", "$EXPORT_RANGE"), "+" || x || " days") as date,
  CREATED.TasksCreated,
  CLOSED.TasksDone,
  CANCELLED.TasksDone,
  TRASHED.TasksDone
FROM timeseries
  LEFT JOIN ($(getMostCreated)) AS CREATED ON CREATED.DAY = date
  LEFT JOIN ($(getMostTrashed)) AS TRASHED ON TRASHED.DAY = date
  LEFT JOIN ($(getMostClosed)) AS CLOSED ON CLOSED.DAY = date
  LEFT JOIN ($(getMostCancelled)) AS CANCELLED ON CANCELLED.DAY = date    
SQL
  echo "${query}"
}
