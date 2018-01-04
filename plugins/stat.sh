#!/bin/bash

myPluginID=$(getNextPluginID)
myPlugin="plugin$myPluginID"
myPluginCommand="stat"
myPluginDescription="Provides a number of statistics about all tasks"
myPluginMethod="queryStatistics"

eval "$myPlugin=('$myPluginCommand' '$myPluginDescription' '$myPluginMethod')"

queryStatistics() {
  export LIMIT_BY=-1
  echo "Inbox     : $(queryInbox | wc -l)"
  echo "Today     : $(queryToday | wc -l)"
  echo "Upcoming  : $(queryUpcoming | wc -l)"
  echo "Next      : $(queryNext | wc -l)"
  echo "Someday   : $(querySomeday | wc -l)"
  echo ""
  echo "Completed : $(queryCompleted | wc -l)"
  echo "Cancelled : $(queryCancelled | wc -l)"
  echo "Trashed   : $(queryTrashed | wc -l)"
  echo ""
  echo "Tasks     : $(queryAll | wc -l)"
  echo "Subtasks  : $(querySubtasks | wc -l)"
  echo "Waiting   : $(queryWaiting | wc -l)"
  echo "Projects  : $(queryProjects | wc -l)"
  echo "Repeating : $(queryRepeating | wc -l)"
  echo "Nextish   : $(queryNextish | wc -l)"
  echo "Headings  : $(queryHeadings | wc -l)"
  echo ""
  echo "Oldest    : $(LIMIT_BY="1" queryOld)"
  echo "Farest    : $(queryUpcoming | tail -n1)"
  echo "Longest   : $(LIMIT_BY="1" queryMostCharacters)"
  echo "Largest   : $(LIMIT_BY="1" queryMostTasks)"
  echo ""
  echo "Created   : $(LIMIT_BY=1 queryMostCreated)"
  echo "Closed    : $(LIMIT_BY=1 queryMostClosed)"
  echo "Cancelled : $(LIMIT_BY=1 queryMostCancelled)"
  echo "Trashed   : $(LIMIT_BY=1 queryMostTrashed)"
  echo "Days/Task : $(queryAverageCompleteTime)"
}

queryAverageCompleteTime() {
  sqlite3 "$THINGSDB" "$(getAverageCompleteTimeQuery)"
}

getAverageCompleteTimeQuery() {
  read -rd '' query <<-SQL || true
SELECT ROUND(AVG(JULIANDAY(stopDate,"unixepoch")-JULIANDAY(creationDate,"unixepoch")))
FROM $TASKTABLE
WHERE $ISNOTTRASHED AND $ISTASK
AND $ISCOMPLETED;
SQL
  echo "${query}"
}
