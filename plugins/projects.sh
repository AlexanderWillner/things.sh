#!/bin/bash

myPluginID="$(getNextPluginID)"
myPlugin="plugin$myPluginID"
myPluginCommand="projects"
myPluginDescription="Shows $LIMIT_BY projects ordered by '$ORDER_BY'"
myPluginMethod="queryProjects"

eval "$myPlugin=('$myPluginCommand' '$myPluginDescription' '$myPluginMethod')"

queryProjects() {
  sqlite3 "$THINGSDB" "$(getProjectsQuery)"
}

getProjectsQuery() {
  read -rd '' query <<-SQL || true
SELECT
  CASE 
    WHEN AREA.title IS NOT NULL THEN AREA.title 
    WHEN PROJECT.title IS NOT NULL THEN PROJECT.title
    WHEN HEADING.title IS NOT NULL THEN HEADING.title
    ELSE "(No Context)"
  END,
  TASK.title,
  "things:///show?id=" || TASK.uuid
FROM $TASKTABLE as TASK
LEFT OUTER JOIN $TASKTABLE PROJECT ON TASK.project = PROJECT.uuid
LEFT OUTER JOIN $AREATABLE AREA ON TASK.area = AREA.uuid
LEFT OUTER JOIN $TASKTABLE HEADING ON TASK.heading = HEADING.uuid
WHERE TASK.$ISNOTTRASHED AND TASK.$ISOPEN AND TASK.$ISPROJECT
ORDER BY TASK.$ORDER_BY
LIMIT $LIMIT_BY
SQL
  echo "$query"
}
