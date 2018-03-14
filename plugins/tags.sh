#!/bin/bash

myPluginID=$(getNextPluginID)
myPlugin="plugin$myPluginID"
myPluginCommand="tag"
myPluginDescription="Shows $LIMIT_BY tasks with the tag \"$WAITING_TAG\" ordered by \"$ORDER_BY\""
myPluginMethod="queryWaiting"

eval "$myPlugin=('$myPluginCommand' '$myPluginDescription' '$myPluginMethod')"

myPluginID=$(getNextPluginID)
myPlugin="plugin$myPluginID"
myPluginCommand="tags"
myPluginDescription="Shows $LIMIT_BY tags ordered by their usage"
myPluginMethod="queryTags"

eval "$myPlugin=('$myPluginCommand' '$myPluginDescription' '$myPluginMethod')"

queryTags() {
  sqlite3 "$THINGSDB" "$(getTagsQuery)"
}

getTagsQuery() {
  read -rd '' query <<-SQL || true
SELECT 
  (SELECT 
     COUNT(*) 
   FROM 
     TMTaskTag T 
   WHERE
     T.tags = TAGS.uuid
     AND
     T.tasks IN (
     SELECT TASK.uuid
     FROM $TASKTABLE TASK
     WHERE TASK.$ISNOTTRASHED AND TASK.$ISOPEN AND (TASK.$ISTASK OR TASK.$ISPROJECT)
     )
   ) AS quantity,
   TAGS.title
FROM $TAGTABLE TAGS
ORDER BY quantity DESC
LIMIT $LIMIT_BY
SQL
  echo "${query}"
}
