#!/bin/bash

myPluginID="$(getNextPluginID)"
myPlugin="plugin$myPluginID"
myPluginCommand='ical'
myPluginDescription="Shows $LIMIT_BY tasks ordered by due date as iCal"
myPluginMethod='queryIcal'

eval "$myPlugin=('$myPluginCommand' '$myPluginDescription' '$myPluginMethod')"

queryIcal() {
  IFS=$'\n'
  echo "BEGIN:VCALENDAR"
  echo "VERSION:2.0"
  sqlite3 "$THINGSDB" "$(getIcalQuery)"| awk '{gsub("<[^>]*>", "")}1' | (iconv -c -f UTF-8 -t "${ENCODING:-UTF-8}" || true)  | while read -r a; do
    echo "BEGIN:VEVENT"
    IFS='|' read -ra ADDR <<< "$a"
    duedate="${ADDR[0]}"
    title="${ADDR[1]:-}"
    url="${ADDR[2]:-}"
    notes="${ADDR[3]:-}"
    echo "DTSTART;VALUE=DATE:${duedate//-}"
    echo "SUMMARY:$title"
    echo "DESCRIPTION:$notes - $url"
    echo "END:VEVENT"
  done
  echo "END:VCALENDAR"
}

getIcalQuery() {
  read -rd '' query <<-SQL || true
SELECT
  date(TASK.startdate,"unixepoch"),
  "" || TASK.title,
  "things:///show?id=" || TASK.uuid,
  "" || REPLACE(REPLACE(TASK.notes, CHAR(13), ', '), CHAR(10), ', ')
FROM $TASKTABLE as TASK
LEFT OUTER JOIN $TASKTABLE PROJECT ON TASK.project = PROJECT.uuid
LEFT OUTER JOIN $AREATABLE AREA ON TASK.area = AREA.uuid
LEFT OUTER JOIN $TASKTABLE HEADING ON TASK.heading = HEADING.uuid
WHERE TASK.$ISNOTTRASHED AND TASK.$ISOPEN
AND TASK.startdate NOT NULL
AND (
  TASK.project in (SELECT uuid FROM $TASKTABLE WHERE uuid=TASK.project AND $ISNOTTRASHED) 
  OR
  TASK.heading in 
    (SELECT uuid FROM TMTask heading WHERE uuid=TASK.heading 
      AND $ISNOTTRASHED
      AND heading.project in (SELECT uuid FROM TMTask WHERE uuid=heading.project AND $ISNOTTRASHED)
    )
  )
ORDER BY TASK.startdate
LIMIT $LIMIT_BY
SQL
  echo "$query"
}
