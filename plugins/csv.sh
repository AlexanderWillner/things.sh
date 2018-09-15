#!/bin/bash

myPluginID="$(getNextPluginID)"
myPlugin="plugin$myPluginID"
myPluginCommand="csv"
myPluginDescription="Exports all tasks as semicolon seperated values incl. notes and Excel friendly"
myPluginMethod="exportCSV"

eval "$myPlugin=('$myPluginCommand' '$myPluginDescription' '$myPluginMethod')"

exportCSV() {
  echo '"Title"'"${SEP:-;}"'"Type"'"${SEP:-;}"'"URI"'"${SEP:-;}"'"Creation Date"'"${SEP:-;}"'"Modification Date"'"${SEP:-;}"'"Due Date"'"${SEP:-;}"'"Start Date"'"${SEP:-;}"'"Completion Date"'"${SEP:-;}"'"Recurring"'"${SEP:-;}"'"Heading"'"${SEP:-;}"'"Project"'"${SEP:-;}"'"Area"'"${SEP:-;}"'"Subtask"'"${SEP:-;}"'"Notes"'"${SEP:-;}"'"Tags"'
  sqlite3 -csv -separator "${SEP:-;}" "$THINGSDB" "$(getCSVQueryTasks)" | awk '{gsub("<[^>]*>", "")}1' | iconv -c -f UTF-8 -t "${ENCODING:-WINDOWS-1252//TRANSLIT}" || true
  sqlite3 -csv -separator "${SEP:-;}" "$THINGSDB" "$(getCSVQueryChecklists)" | awk '{gsub("<[^>]*>", "")}1' | iconv -c -f UTF-8 -t "${ENCODING:-WINDOWS-1252//TRANSLIT}" || true
}

getCSVQueryTasks() {
  read -rd '' query <<-SQL || true
SELECT
  T1.title,
  T1.type,
  'things:///show?id='||T1.uuid,
  date(T1.creationDate,"unixepoch"),
  date(T1.userModificationDate,"unixepoch"),
  date(T1.dueDate,"unixepoch"),
  date(T1.startDate,"unixepoch"),
  date(T1.stopDate,"unixepoch"),
  CASE WHEN T1.recurrenceRule IS NULL THEN 'False' ELSE 'True' END,
  HEADING.title,
  PROJECT.title,
  AREA.title,
  "",
  REPLACE(REPLACE(T1.notes, CHAR(13), ', '), CHAR(10), ', '),
  GROUP_CONCAT(TAG.title)
FROM $TASKTABLE T1
LEFT OUTER JOIN $TASKTABLE PROJECT ON T1.project = PROJECT.uuid
LEFT OUTER JOIN $AREATABLE AREA ON T1.area = AREA.uuid
LEFT OUTER JOIN $TASKTABLE HEADING ON T1.actionGroup = HEADING.uuid
LEFT OUTER JOIN $TASKTAGTABLE TAGS ON T1.uuid = TAGS.tasks
LEFT OUTER JOIN $TAGTABLE TAG ON TAGS.tags = TAG.uuid
WHERE T1.$ISNOTTRASHED AND (T1.$ISOPEN OR T1.$ISCOMPLETED)
GROUP BY T1.title
SQL
  echo "$query"
}

getCSVQueryChecklists() {
  read -rd '' query <<-SQL || true
SELECT
  T2.title,
  T2.type,
  'thingstodo://show?uuid='||T2.uuid,
  date(T1.creationDate,"unixepoch"),
  date(T1.userModificationDate,"unixepoch"),
  "",
  "",
  date(T1.stopDate,"unixepoch"),
  "",
  "",
  "",
  "",
  "",
  T1.title,
  ""
FROM TMChecklistItem T1
LEFT OUTER JOIN $TASKTABLE T2 ON T1.task = T2.uuid
WHERE (T2.$ISOPEN OR T2.$ISCOMPLETED) AND T2.$ISNOTTRASHED;
SQL
  echo "$query"
}
