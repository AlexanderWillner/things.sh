#!/usr/bin/env bash
#
# DESCRIPTION
#
# Simple read-only comand-line interface to your Things 3 database. Since
# Things uses a SQLite database (which should come pre-installed on your Mac)
# we can simply query it straight from the command line.
#
# We only do read operations since we don't want to mess up your data.
#
# INSTALLATION
#
# Put this file somewhere in your $PATH and make it executable.
#
# INSTRUCTIONS
#
# Note that you could override the location of the database used by setting the
# THINGSDB environment variable.
#
# For usage information, run the script with no arguments or with "help".
#
# CREDITS
#
# Author  : Arjan van der Gaag (script for Things 2)
# Author  : Alexander Willner (updates for Things 3, added many more commands)
# License : Whatever. Use at your own risk.
# Source  : https://github.com/AlexanderWillner/things.sh
#

set -o errexit
set -o nounset
set -eo pipefail
[[ "${TRACE:-}" ]] && set -x

limitBy="20"
waitingTag="Waiting for"
orderBy="creationDate"

readonly PROGNAME=$(basename "$0")
readonly DEFAULT_DB=~/Library/Containers/com.culturedcode.ThingsMac/Data/Library/Application\ Support/Cultured\ Code/Things/Things.sqlite3
readonly THINGSDB=${THINGSDB:-$DEFAULT_DB}

readonly TASKTABLE="TMTask"
readonly AREATABLE="TMArea"
readonly TAGTABLE="TMTag"
readonly ISNOTTRASHED="trashed = 0"
readonly ISTRASHED="trashed = 1"
readonly ISOPEN="status = 0"
readonly ISNOTSTARTED="start = 0"
readonly ISCANCELLED="status = 2"
readonly ISCOMPLETED="status = 3"
readonly ISSTARTED="start = 1"
readonly ISPOSTPONED="start = 2"
readonly ISTASK="type = 0"
readonly ISPROJECT="type = 1"
readonly ISHEADING="type = 2"

usage() {
  cat <<-EOF
usage: $PROGNAME <OPTIONS> [COMMAND]

List to do items from your Things database given a focus area.

COMMAND:
  inbox
  today
  upcoming
  next / anytime
  someday
  completed
  cancelled
  trashed
  all        (show all tasks)
  nextish    (show $limitBy next tasks that are also in someday projects)
  old        (show $limitBy tasks ordered by '$orderBy')
  due        (show $limitBy tasks ordered by due date)
  waiting    (show $limitBy tasks with the tag '$waitingTag' ordered by '$orderBy')
  repeating  (show $limitBy repeating tasks orderd by '$orderBy')
  subtasks   (show $limitBy subtasks)
  projects   (show $limitBy projects ordered by creation date)
  headings   (show $limitBy headings ordered by creation date)
  notes      (show $limitBy notes as <headings>: <notes> ordered by creation date)
  csv        (export all tasks as semicolon seperated values incl. notes and Excel friendly)
  stat       (provide an overview of the numbers of tasks)
  closed     (show $limitBy days on which most tasks were closed)
  created    (show $limitBy days on which most tasks were created)
  search     (provide details about specific tasks)
  feedback   (give feedback, request and propose changes)

OPTIONS:
  -l|--limitBy <number>    Limit output by <number> of results
  -w|--waitingTag <tag>    Set waiting tag to <tag>
  -o|--orderBy <column>    Sort output by <column> (e.g. 'userModificationDate' or 'creationDate')
  -s|--string <string>     String <string> to search for
EOF
}

inbox() {
  read -rd '' query <<-SQL || true
SELECT title
FROM $TASKTABLE
WHERE $ISNOTTRASHED AND $ISTASK
AND $ISNOTSTARTED AND $ISOPEN;
SQL
  sqlite3 "$THINGSDB" "${query}"
}

today() {
  read -rd '' query <<-SQL || true
SELECT 
  CASE 
    WHEN AREA.title IS NOT NULL THEN AREA.title 
    WHEN PROJECT.title IS NOT NULL THEN PROJECT.title
    WHEN HEADING.title IS NOT NULL THEN HEADING.title
    ELSE "(No Context)"
  END,
  TASK.title
FROM $TASKTABLE as TASK
LEFT OUTER JOIN $TASKTABLE PROJECT ON TASK.project = PROJECT.uuid
LEFT OUTER JOIN $AREATABLE AREA ON TASK.area = AREA.uuid
LEFT OUTER JOIN $TASKTABLE HEADING ON TASK.actionGroup = HEADING.uuid
WHERE TASK.$ISNOTTRASHED AND TASK.$ISOPEN AND TASK.$ISTASK
AND TASK.$ISSTARTED
AND TASK.startdate is NOT NULL
ORDER BY TASK.startdate, TASK.todayIndex;
SQL
  sqlite3 "$THINGSDB" "${query}"
}

upcoming() {
  read -rd '' query <<-SQL || true
SELECT 
  CASE 
    WHEN TASK.startDate IS NULL THEN "0000-00-00" 
    ELSE date(TASK.startDate,"unixepoch")
  END,
  CASE 
    WHEN AREA.title IS NOT NULL THEN AREA.title 
    WHEN PROJECT.title IS NOT NULL THEN PROJECT.title
    WHEN HEADING.title IS NOT NULL THEN HEADING.title
    ELSE "(No Context)"
  END,
  TASK.title
FROM $TASKTABLE as TASK
LEFT OUTER JOIN $TASKTABLE PROJECT ON TASK.project = PROJECT.uuid
LEFT OUTER JOIN $AREATABLE AREA ON TASK.area = AREA.uuid
LEFT OUTER JOIN $TASKTABLE HEADING ON TASK.actionGroup = HEADING.uuid
WHERE TASK.$ISNOTTRASHED AND TASK.$ISOPEN AND TASK.$ISTASK
AND TASK.$ISPOSTPONED AND (TASK.startDate NOT NULL OR TASK.recurrenceRule NOT NULL)
ORDER BY TASK.startdate, TASK.todayIndex;
SQL
  sqlite3 "$THINGSDB" "${query}"
}

anytime() {
  next
}

next() {
  read -rd '' query <<-SQL || true
SELECT
  CASE 
    WHEN AREA.title IS NOT NULL THEN AREA.title 
    WHEN PROJECT.title IS NOT NULL THEN PROJECT.title
    WHEN HEADING.title IS NOT NULL THEN HEADING.title
    ELSE "(No Context)"
  END,
  TASK.title
FROM $TASKTABLE TASK
LEFT OUTER JOIN $TASKTABLE PROJECT ON TASK.project = PROJECT.uuid
LEFT OUTER JOIN $AREATABLE AREA ON TASK.area = AREA.uuid
LEFT OUTER JOIN $TASKTABLE HEADING ON TASK.actionGroup = HEADING.uuid
WHERE TASK.$ISNOTTRASHED AND TASK.$ISOPEN AND TASK.$ISTASK AND TASK.$ISSTARTED
AND (
  TASK.area NOT NULL
  OR
  TASK.project in (SELECT uuid FROM $TASKTABLE WHERE uuid=TASK.project AND $ISSTARTED AND $ISNOTTRASHED) 
  OR
  TASK.actionGroup in 
    (SELECT uuid FROM TMTask heading WHERE uuid=TASK.actionGroup 
      AND $ISSTARTED 
      AND $ISNOTTRASHED
      AND heading.project in (SELECT uuid FROM TMTask WHERE uuid=heading.project AND $ISSTARTED AND $ISNOTTRASHED)
    )
  )
ORDER BY TASK.todayIndex;
SQL
  sqlite3 "$THINGSDB" "${query}"
}

someday() {
  read -rd '' query <<-SQL || true
SELECT
  CASE 
    WHEN AREA.title IS NOT NULL THEN AREA.title 
    WHEN PROJECT.title IS NOT NULL THEN PROJECT.title
    WHEN HEADING.title IS NOT NULL THEN HEADING.title
    ELSE "(No Context)"
  END,
TASK.title
FROM $TASKTABLE as TASK
LEFT OUTER JOIN $TASKTABLE PROJECT ON TASK.project = PROJECT.uuid
LEFT OUTER JOIN $AREATABLE AREA ON TASK.area = AREA.uuid
LEFT OUTER JOIN $TASKTABLE HEADING ON TASK.actionGroup = HEADING.uuid
WHERE TASK.$ISNOTTRASHED AND TASK.$ISTASK
AND TASK.$ISPOSTPONED AND TASK.$ISOPEN;
SQL
  sqlite3 "$THINGSDB" "${query}"
}

completed() {
  read -rd '' query <<-SQL || true
SELECT
  CASE 
    WHEN AREA.title IS NOT NULL THEN AREA.title 
    WHEN PROJECT.title IS NOT NULL THEN PROJECT.title
    WHEN HEADING.title IS NOT NULL THEN HEADING.title
    ELSE "(No Context)"
  END,
TASK.title
FROM $TASKTABLE as TASK
LEFT OUTER JOIN $TASKTABLE PROJECT ON TASK.project = PROJECT.uuid
LEFT OUTER JOIN $AREATABLE AREA ON TASK.area = AREA.uuid
LEFT OUTER JOIN $TASKTABLE HEADING ON TASK.actionGroup = HEADING.uuid
WHERE TASK.$ISNOTTRASHED AND TASK.$ISTASK
AND TASK.$ISCOMPLETED;
SQL
  sqlite3 "$THINGSDB" "${query}"
}

nextish() {
  read -rd '' query <<-SQL || true
SELECT
  CASE 
    WHEN AREA.title IS NOT NULL THEN AREA.title 
    WHEN PROJECT.title IS NOT NULL THEN PROJECT.title
    WHEN HEADING.title IS NOT NULL THEN HEADING.title
    ELSE "(No Context)"
  END,
TASK.title
FROM $TASKTABLE as TASK
LEFT OUTER JOIN $TASKTABLE PROJECT ON TASK.project = PROJECT.uuid
LEFT OUTER JOIN $AREATABLE AREA ON TASK.area = AREA.uuid
LEFT OUTER JOIN $TASKTABLE HEADING ON TASK.actionGroup = HEADING.uuid
WHERE TASK.$ISNOTTRASHED AND TASK.$ISSTARTED AND TASK.$ISOPEN AND TASK.$ISTASK
LIMIT $limitBy;
SQL
  sqlite3 "$THINGSDB" "${query}"
}

all() {
  read -rd '' query <<-SQL || true
SELECT 
  CASE 
    WHEN AREA.title IS NOT NULL THEN AREA.title 
    WHEN PROJECT.title IS NOT NULL THEN PROJECT.title
    WHEN HEADING.title IS NOT NULL THEN HEADING.title
    ELSE "(No Context)"
  END,
TASK.title
FROM $TASKTABLE as TASK
LEFT OUTER JOIN $TASKTABLE PROJECT ON TASK.project = PROJECT.uuid
LEFT OUTER JOIN $AREATABLE AREA ON TASK.area = AREA.uuid
LEFT OUTER JOIN $TASKTABLE HEADING ON TASK.actionGroup = HEADING.uuid
WHERE TASK.$ISNOTTRASHED AND TASK.$ISOPEN AND TASK.$ISTASK;
SQL
  sqlite3 "$THINGSDB" "${query}"
}

subtasks() {
  read -rd '' query <<-SQL || true
SELECT 
  TASK.title,
  CHECKLIST.title
FROM TMChecklistItem CHECKLIST
LEFT OUTER JOIN $TASKTABLE TASK ON CHECKLIST.task = TASK.uuid
WHERE TASK.$ISOPEN AND TASK.$ISNOTTRASHED
LIMIT $limitBy;
SQL
  sqlite3 "$THINGSDB" "${query}"
}

waiting() {
  read -rd '' query <<-SQL || true
SELECT 
  CASE 
    WHEN AREA.title IS NOT NULL THEN AREA.title 
    WHEN PROJECT.title IS NOT NULL THEN PROJECT.title
    WHEN HEADING.title IS NOT NULL THEN HEADING.title
    ELSE "(No Context)"
  END,
  TASK.title
FROM TMTaskTag TAGS
LEFT JOIN $TASKTABLE TASK ON TAGS.tasks = TASK.uuid
LEFT OUTER JOIN $TASKTABLE PROJECT ON TASK.project = PROJECT.uuid
LEFT OUTER JOIN $AREATABLE AREA ON TASK.area = AREA.uuid
LEFT OUTER JOIN $TASKTABLE HEADING ON TASK.actionGroup = HEADING.uuid
WHERE TASK.$ISNOTTRASHED AND TASK.$ISOPEN
AND TAGS.tags=(SELECT uuid FROM $TAGTABLE WHERE title='$waitingTag')
ORDER BY TASK.$orderBy
LIMIT $limitBy;
SQL
  sqlite3 "$THINGSDB" "${query}"
}

old() {
  read -rd '' query <<-SQL || true
SELECT
  date(TASK.creationDate,"unixepoch"),
  CASE 
    WHEN AREA.title IS NOT NULL THEN AREA.title 
    WHEN PROJECT.title IS NOT NULL THEN PROJECT.title
    WHEN HEADING.title IS NOT NULL THEN HEADING.title
    ELSE "(No Context)"
  END,
  TASK.title
FROM $TASKTABLE as TASK
LEFT OUTER JOIN $TASKTABLE PROJECT ON TASK.project = PROJECT.uuid
LEFT OUTER JOIN $AREATABLE AREA ON TASK.area = AREA.uuid
LEFT OUTER JOIN $TASKTABLE HEADING ON TASK.actionGroup = HEADING.uuid
WHERE TASK.$ISNOTTRASHED AND TASK.$ISOPEN AND TASK.$ISTASK AND TASK.recurrenceRule IS NULL
ORDER BY TASK.$orderBy
LIMIT $limitBy;
SQL
  sqlite3 "$THINGSDB" "${query}"
}

due() {
  read -rd '' query <<-SQL || true
SELECT
  date(TASK.dueDate,"unixepoch"),
  CASE 
    WHEN AREA.title IS NOT NULL THEN AREA.title 
    WHEN PROJECT.title IS NOT NULL THEN PROJECT.title
    WHEN HEADING.title IS NOT NULL THEN HEADING.title
    ELSE "(No Context)"
  END,
  TASK.title
FROM $TASKTABLE as TASK
LEFT OUTER JOIN $TASKTABLE PROJECT ON TASK.project = PROJECT.uuid
LEFT OUTER JOIN $AREATABLE AREA ON TASK.area = AREA.uuid
LEFT OUTER JOIN $TASKTABLE HEADING ON TASK.actionGroup = HEADING.uuid
WHERE TASK.$ISNOTTRASHED AND TASK.$ISOPEN
AND TASK.dueDate NOT NULL
ORDER BY TASK.dueDate
LIMIT $limitBy;
SQL
  sqlite3 "$THINGSDB" "${query}"
}

repeating() {
  read -rd '' query <<-SQL || true
SELECT title
FROM $TASKTABLE
WHERE $ISNOTTRASHED AND $ISOPEN AND $ISPOSTPONED
AND recurrenceRule NOT NULL
ORDER BY $orderBy
LIMIT $limitBy;
SQL
  sqlite3 "$THINGSDB" "${query}"
}

projects() {
  read -rd '' query <<-SQL || true
SELECT
  CASE 
    WHEN AREA.title IS NOT NULL THEN AREA.title 
    WHEN PROJECT.title IS NOT NULL THEN PROJECT.title
    WHEN HEADING.title IS NOT NULL THEN HEADING.title
    ELSE "(No Context)"
  END,
  TASK.title
FROM $TASKTABLE as TASK
LEFT OUTER JOIN $TASKTABLE PROJECT ON TASK.project = PROJECT.uuid
LEFT OUTER JOIN $AREATABLE AREA ON TASK.area = AREA.uuid
LEFT OUTER JOIN $TASKTABLE HEADING ON TASK.actionGroup = HEADING.uuid
WHERE TASK.$ISNOTTRASHED AND TASK.$ISOPEN AND TASK.$ISPROJECT
ORDER BY TASK.$orderBy
LIMIT $limitBy;
SQL
  sqlite3 "$THINGSDB" "${query}"
}

headings() {
  read -rd '' query <<-SQL || true
SELECT
  CASE 
    WHEN AREA.title IS NOT NULL THEN AREA.title 
    WHEN PROJECT.title IS NOT NULL THEN PROJECT.title
    WHEN HEADING.title IS NOT NULL THEN HEADING.title
    ELSE "(No Context)"
  END,
  TASK.title
FROM $TASKTABLE as TASK
LEFT OUTER JOIN $TASKTABLE PROJECT ON TASK.project = PROJECT.uuid
LEFT OUTER JOIN $AREATABLE AREA ON TASK.area = AREA.uuid
LEFT OUTER JOIN $TASKTABLE HEADING ON TASK.actionGroup = HEADING.uuid
WHERE TASK.$ISNOTTRASHED AND TASK.$ISOPEN AND TASK.$ISHEADING
ORDER BY TASK.$orderBy
LIMIT $limitBy;
SQL
  sqlite3 "$THINGSDB" "${query}"
}

cancelled() {
  read -rd '' query <<-SQL || true
SELECT
  CASE 
    WHEN AREA.title IS NOT NULL THEN AREA.title 
    WHEN PROJECT.title IS NOT NULL THEN PROJECT.title
    WHEN HEADING.title IS NOT NULL THEN HEADING.title
    ELSE "(No Context)"
  END,
TASK.title
FROM $TASKTABLE as TASK
LEFT OUTER JOIN $TASKTABLE PROJECT ON TASK.project = PROJECT.uuid
LEFT OUTER JOIN $AREATABLE AREA ON TASK.area = AREA.uuid
LEFT OUTER JOIN $TASKTABLE HEADING ON TASK.actionGroup = HEADING.uuid
WHERE TASK.$ISNOTTRASHED AND TASK.$ISCANCELLED AND TASK.$ISTASK
ORDER BY TASK.$orderBy;
SQL
  sqlite3 "$THINGSDB" "${query}"
}

trashed() {
  read -rd '' query <<-SQL || true
SELECT title
FROM $TASKTABLE
WHERE $ISTRASHED AND $ISTASK
ORDER BY $orderBy;
SQL
  sqlite3 "$THINGSDB" "${query}"
}

averageCompleteTime() {
  read -rd '' query <<-SQL || true
SELECT ROUND(AVG(JULIANDAY(stopDate,"unixepoch")-JULIANDAY(creationDate,"unixepoch")))
FROM $TASKTABLE
WHERE $ISNOTTRASHED AND $ISTASK
AND $ISCOMPLETED;
SQL
  sqlite3 "$THINGSDB" "${query}"
}

longestDescription() {
  read -rd '' query <<-SQL || true
SELECT LENGTH(title), title
FROM $TASKTABLE
WHERE $ISNOTTRASHED AND $ISTASK AND $ISOPEN
ORDER BY LENGTH(title) DESC
LIMIT 1
SQL
  sqlite3 "$THINGSDB" "${query}"
}

mostClosed() {
  read -rd '' query <<-SQL || true
SELECT COUNT(title) AS TasksDone, date(stopDate,"unixepoch") AS DAY
FROM $TASKTABLE
WHERE DAY NOT NULL
GROUP BY DAY
ORDER BY TasksDone DESC
LIMIT $limitBy;
SQL
  sqlite3 "$THINGSDB" "${query}"
}

mostCreated() {
  read -rd '' query <<-SQL || true
SELECT COUNT(title) AS TasksCreated, date(creationDate,"unixepoch") AS DAY
FROM $TASKTABLE
WHERE DAY NOT NULL
GROUP BY DAY
ORDER BY TasksCreated DESC
LIMIT $limitBy;
SQL
  sqlite3 "$THINGSDB" "${query}"
}

notes() {
  read -rd '' query <<-SQL || true
SELECT
  title,
  notes
FROM $TASKTABLE
WHERE $ISNOTTRASHED AND $ISOPEN AND notes NOT NULL
ORDER BY $orderBy;
SQL
  sqlite3 -list -separator ': ' "$THINGSDB" "${query}"
}

csv() {
  echo 'Title;"Creation Date";"Modification Date";"Due Date";"Start Date";"Completion Date";"Recurring";Project;Area;Subtask;Notes'

  read -rd '' query <<-SQL || true
SELECT 
  T1.title, 
  date(T1.creationDate,"unixepoch"),
  date(T1.userModificationDate,"unixepoch"),
  date(T1.dueDate,"unixepoch"),
  date(T1.startDate,"unixepoch"),
  date(T1.stopDate,"unixepoch"),
  CASE WHEN T1.recurrenceRule IS NULL THEN 'False' ELSE 'True' END,
  PROJECT.title,
  AREA.title,
  "",
  REPLACE(REPLACE(T1.notes, CHAR(13), ', '), CHAR(10), ', ')
FROM $TASKTABLE T1
LEFT OUTER JOIN $TASKTABLE PROJECT ON T1.project = PROJECT.uuid
LEFT OUTER JOIN $AREATABLE AREA ON T1.area = AREA.uuid
WHERE T1.$ISNOTTRASHED AND (T1.$ISOPEN OR T1.$ISCOMPLETED) AND T1.$ISTASK;
SQL
  sqlite3 -list -separator ';' "$THINGSDB" "${query}"

  read -rd '' query <<-SQL || true
SELECT 
  T2.title,
  date(T1.creationDate,"unixepoch"),
  date(T1.userModificationDate,"unixepoch"),
  "",
  "",
  date(T1.stopDate,"unixepoch"),
  "",
  "",
  "",
  "",
  T1.title
FROM TMChecklistItem T1
LEFT OUTER JOIN $TASKTABLE T2 ON T1.task = T2.uuid
WHERE (T2.$ISOPEN OR T2.$ISCOMPLETED) AND T2.$ISNOTTRASHED;
SQL
  sqlite3 -list -separator ';' "$THINGSDB" "${query}"
}

stat() {
  echo "Inbox     : $(inbox | wc -l)"
  echo "Today     : $(today | wc -l)"
  echo "Upcoming  : $(upcoming | wc -l)"
  echo "Next      : $(next | wc -l)"
  echo "Someday   : $(someday | wc -l)"
  echo ""
  echo "Completed : $(completed | wc -l)"
  echo "Cancelled : $(cancelled | wc -l)"
  echo "Trashed   : $(trashed | wc -l)"
  echo ""
  echo "Tasks     : $(all | wc -l)"
  echo "Subtasks  : $(subtasks | wc -l)"
  echo "Waiting   : $(waiting | wc -l)"
  echo "Projects  : $(projects | wc -l)"
  echo "Repeating : $(repeating | wc -l)"
  echo "Nextish   : $(nextish | wc -l)"
  echo "Headings  : $(headings | wc -l)"
  echo ""
  echo "Oldest    : $(limitBy="1" old)"
  echo "Farest    : $(orderBy='startDate DESC' upcoming | tail -n1)"
  echo "Longest   : $(longestDescription)"
  echo "Closed    : $(mostClosed | head -n1)"
  echo "Created   : $(mostCreated | head -n1)"
  echo "Days/Task : $(averageCompleteTime)"
}

search() {
  [[ -z "${string:-}" ]] && echo "HINT: Use '-s' to set search string first" && exit 1
  read -rd '' query <<-SQL || true
SELECT 
  T1.title as "Title", 
  date(T1.creationDate,"unixepoch") as "Created",
  date(T1.userModificationDate,"unixepoch") as "Modified",
  date(T1.dueDate,"unixepoch") as "Due",
  date(T1.startDate,"unixepoch") as "Start",
  date(T1.stopDate,"unixepoch") as "Stopped",
  T2.title as "Project",
  T3.title as "Area"
FROM $TASKTABLE T1
LEFT OUTER JOIN $TASKTABLE T2 ON T1.project = T2.uuid
LEFT OUTER JOIN $AREATABLE T3 ON T1.area = T3.uuid
WHERE T1.$ISNOTTRASHED AND T1.$ISTASK
AND (T1.title LIKE "%$string%" OR T2.title LIKE "%$string%");
SQL
  sqlite3 "$THINGSDB" "${query}"

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
AND T1.title LIKE "%$string%";
SQL
  sqlite3 "$THINGSDB" "${query}"
}

require_sqlite3() {
  command -v sqlite3 >/dev/null 2>&1 || {
    echo >&2 "ERROR: SQLite3 is required but could not be found."
    exit 1
  }
}

require_db() {
  test -r "$THINGSDB" -a -f "$THINGSDB" || {
    echo >&2 "ERROR: Things database not found at '$THINGSDB'."
    echo >&2 "HINT: You might need to install Things from https://culturedcode.com/things/"
    exit 2
  }
}

main() {
  require_sqlite3
  require_db

  while [[ $# -gt 1 ]]; do
    local key="$1"
    case $key in
    -l | --limitBy)
      limitBy="$2"
      shift
      ;;
    -w | --waitingTag)
      waitingTag="$2"
      shift
      ;;
    -o | --orderBy)
      orderBy="$2"
      shift
      ;;
    -s | --string)
      string="$2"
      shift
      ;;
    *) ;;
    esac
    shift
  done

  local command=${1:-}

  if [[ -n $command ]]; then
    case $1 in
    inbox) inbox ;;
    today) today ;;
    upcoming) upcoming ;;
    closed) mostClosed ;;
    created) mostCreated ;;
    next) next ;;
    anytime) anytime ;;
    someday) someday ;;
    all) all ;;
    nextish) nextish ;;
    completed) completed ;;
    old) old ;;
    due) due ;;
    repeating) repeating ;;
    subtasks) subtasks ;;
    projects) projects ;;
    headings) headings ;;
    cancelled) cancelled ;;
    trashed) trashed ;;
    waiting) waiting ;;
    notes) notes ;;
    csv) csv | awk '{gsub("<[^>]*>", "")}1' | iconv -c -f UTF-8 -t WINDOWS-1252//TRANSLIT ;;
    stat) limitBy="999999" stat ;;
    search) search ;;
    feedback) open https://github.com/AlexanderWillner/things.sh/issues/ ;;
    *) usage ;;
    esac
  else
    usage
  fi
}

cleanup() {
  : # nothing to clean up
  # echo "$(date) $(hostname) $0: EXIT on line $2 (exit status $1)"
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && trap 'cleanup $? $LINENO' EXIT && main "$@"
