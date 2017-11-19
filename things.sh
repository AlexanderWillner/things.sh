#!/bin/bash
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
# Author	: Arjan van der Gaag (script for Things 2)
# Author	: Alexander Willner (updates for Things 3, added many more commands)
# Date		: 2017-08-14
# License	: Whatever. Use at your own risk.
# Source	: https://github.com/AlexanderWillner/things.sh
#

set -o errexit
set -o nounset

limitBy="20"
waitingTag="Waiting for"
orderBy="creationDate"

readonly PROGNAME=$(basename $0)
readonly DEFAULT_DB=~/Library/Containers/com.culturedcode.ThingsMac/Data/Library/Application\ Support/Cultured\ Code/Things/Things.sqlite3
readonly THINGSDB=${DB:-$DEFAULT_DB}

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
  all		(show all tasks)
  nextish	(show $limitBy next tasks that are also in someday projects)
  old		(show $limitBy tasks ordered by '$orderBy')
  due		(show $limitBy tasks ordered by due date)
  waiting	(show $limitBy tasks with the tag '$waitingTag' ordered by '$orderBy')
  repeating	(show $limitBy repeating tasks orderd by '$orderBy')
  subtasks	(show $limitBy subtasks)
  projects	(show $limitBy projects ordered by creation date)
  headings	(show $limitBy headings ordered by creation date)
  notes		(show $limitBy notes as <headings>: <notes> ordered by creation date)
  csv		(export all tasks as semicolon seperated values incl. notes)
  stat		(provide an overview of the numbers of tasks)
  search	(provide details about specific tasks)
  feedback	(give feedback, request and propose changes)

OPTIONS:
  -l|--limitBy <number>		Limit output by <number> of results
  -w|--waitingTag <tag>		Set waiting tag to <tag>
  -o|--orderBy <column>		Sort output by <column> (e.g. 'userModificationDate' or 'creationDate')
  -s|--string <string>		String <string> to search for
EOF
}

inbox() {
  sqlite3 "$THINGSDB" <<-SQL
SELECT title
FROM $TASKTABLE
WHERE $ISNOTTRASHED AND $ISTASK
AND $ISNOTSTARTED AND $ISOPEN;
SQL
}

today() {
  sqlite3 "$THINGSDB" <<-SQL
SELECT title
FROM $TASKTABLE
WHERE $ISNOTTRASHED AND $ISOPEN AND $ISTASK
AND $ISSTARTED
AND startdate is NOT NULL
ORDER BY startdate, todayIndex;
SQL
}

upcoming() {
  sqlite3 "$THINGSDB" <<-SQL
SELECT date(startDate,'unixepoch'), title
FROM $TASKTABLE
WHERE $ISNOTTRASHED AND $ISOPEN AND $ISTASK
AND $ISPOSTPONED AND (startDate NOT NULL OR recurrenceRule NOT NULL)
ORDER BY startdate, todayIndex;
SQL
}

anytime() {
  next
}

next() {
  sqlite3 "$THINGSDB" <<-SQL
SELECT title
FROM $TASKTABLE t
WHERE $ISNOTTRASHED AND $ISTASK AND $ISOPEN
AND $ISSTARTED
AND (
  t.area NOT NULL
  OR
  t.project in (SELECT uuid FROM $TASKTABLE WHERE uuid=t.project AND $ISSTARTED)
  )
ORDER BY todayIndex;
SQL
}

someday() {
  sqlite3 "$THINGSDB" <<-SQL
SELECT title
FROM $TASKTABLE t
WHERE $ISNOTTRASHED AND $ISTASK
AND $ISPOSTPONED AND $ISOPEN;
SQL
}

completed() {
  sqlite3 "$THINGSDB" <<-SQL
SELECT title
FROM $TASKTABLE
WHERE $ISNOTTRASHED AND $ISTASK
AND $ISCOMPLETED;
SQL
}

nextish() {
  sqlite3 "$THINGSDB" <<-SQL
SELECT title
FROM $TASKTABLE
WHERE $ISNOTTRASHED AND $ISSTARTED AND $ISOPEN AND $ISTASK
LIMIT $limitBy;
SQL
}

all() {
  sqlite3 "$THINGSDB" <<-SQL
SELECT title
FROM $TASKTABLE
WHERE $ISNOTTRASHED AND $ISOPEN AND $ISTASK;
SQL
}

subtasks() {
  sqlite3 "$THINGSDB" <<-SQL
SELECT T1.title
FROM TMChecklistItem T1
LEFT OUTER JOIN $TASKTABLE T2 ON T1.task = T2.uuid
WHERE T1.status=0 AND T2.status=0 AND T2.trashed=0
LIMIT $limitBy;
SQL
}

waiting() {
  sqlite3 "$THINGSDB" <<-SQL
SELECT T2.title
FROM TMTaskTag T1
LEFT JOIN $TASKTABLE T2 ON T1.tasks = T2.uuid
WHERE $ISNOTTRASHED AND $ISOPEN
AND T1.tags=(SELECT uuid FROM $TAGTABLE WHERE title='$waitingTag')
ORDER BY $orderBy
LIMIT $limitBy;
SQL
}


old() {
  sqlite3 "$THINGSDB" <<-SQL
SELECT date(creationDate,'unixepoch'), title
FROM $TASKTABLE
WHERE $ISNOTTRASHED AND $ISOPEN AND $ISSTARTED AND $ISTASK
ORDER BY $orderBy
LIMIT $limitBy;
SQL
}


due() {
  sqlite3 "$THINGSDB" <<-SQL
SELECT date(dueDate,'unixepoch'), title
FROM $TASKTABLE
WHERE $ISNOTTRASHED AND $ISOPEN
AND dueDate NOT NULL
ORDER BY dueDate
LIMIT $limitBy;
SQL
}

repeating() {
  sqlite3 "$THINGSDB" <<-SQL
SELECT title
FROM $TASKTABLE
WHERE $ISNOTTRASHED AND $ISOPEN AND $ISPOSTPONED
AND recurrenceRule NOT NULL
ORDER BY $orderBy
LIMIT $limitBy;
SQL
}

projects() {
  sqlite3 "$THINGSDB" <<-SQL
SELECT title
FROM $TASKTABLE
WHERE $ISNOTTRASHED AND $ISOPEN
AND $ISPROJECT
ORDER BY $orderBy
LIMIT $limitBy;
SQL
}

headings() {
  sqlite3 "$THINGSDB" <<-SQL
SELECT title
FROM $TASKTABLE
WHERE $ISNOTTRASHED AND $ISOPEN
AND $ISHEADING
ORDER BY $orderBy
LIMIT $limitBy;
SQL
}

cancelled() {
  sqlite3 "$THINGSDB" <<-SQL
SELECT title
FROM $TASKTABLE
WHERE $ISNOTTRASHED AND $ISCANCELLED AND $ISTASK
ORDER BY $orderBy;
SQL
}

trashed() {
  sqlite3 "$THINGSDB" <<-SQL
SELECT title
FROM $TASKTABLE
WHERE $ISTRASHED AND $ISTASK
ORDER BY $orderBy;
SQL
}

averageCompleteTime() {
  sqlite3 "$THINGSDB" <<-SQL
SELECT ROUND(AVG(JULIANDAY(stopDate,'unixepoch')-JULIANDAY(creationDate,'unixepoch')))
FROM $TASKTABLE
WHERE $ISNOTTRASHED AND $ISTASK
AND $ISCOMPLETED;
SQL
}

notes() {
  sqlite3 "$THINGSDB" <<-SQL
.mode list
.separator ": "
SELECT
  title,
  notes
FROM $TASKTABLE
WHERE $ISNOTTRASHED AND $ISOPEN
ORDER BY $orderBy;
SQL
}

csv() {
# fix Excel import by running ```iconv -f UTF-8 -t WINDOWS-1252```
echo 'Title;"Creation Date";"Modification Date";"Due Date";"Start Date";Project;Area;Subtask;Notes'

sqlite3 "$THINGSDB" <<-SQL
.mode csv
.separator ";"
SELECT 
  T1.title, 
  date(T1.creationDate,'unixepoch'),
  date(T1.userModificationDate,'unixepoch'),
  date(T1.dueDate,'unixepoch'),
  date(T1.startDate,'unixepoch'),
  T2.title,
  T3.title,
  "",
  REPLACE(T1.notes, CHAR(10), ', ')
FROM $TASKTABLE T1
LEFT OUTER JOIN $TASKTABLE T2 ON T1.project = T2.uuid
LEFT OUTER JOIN $AREATABLE T3 ON T1.area = T3.uuid
WHERE T1.trashed = 0 AND T1.status = 0 AND T1.type = 0;
SQL

sqlite3 "$THINGSDB" <<-SQL
.mode csv
.separator ";"
SELECT 
  T2.title,
  date(T1.creationDate,'unixepoch'),
  date(T1.userModificationDate,'unixepoch'),
  ""
  "",
  "",
  "",
  "",
  T1.title
FROM TMChecklistItem T1
LEFT OUTER JOIN $TASKTABLE T2 ON T1.task = T2.uuid
WHERE T1.status=0 AND T2.status=0 AND T2.trashed=0;
SQL
}


stat() {
	echo -n "Inbox		:"; inbox|wc -l
	echo ""
    echo -n "Today		:"; today|wc -l
    echo -n "Upcoming	:"; upcoming|wc -l
    echo -n "Next		:"; next|wc -l
    echo -n "Someday		:"; someday|wc -l
   	echo ""
   	echo -n "Completed	:"; completed|wc -l
    echo -n "Cancelled	:"; cancelled|wc -l
    echo -n "Trashed		:"; trashed|wc -l
   	echo ""
    echo -n "Tasks		:"; all|wc -l
    echo -n "Subtasks	:"; subtasks|wc -l
    echo -n "Waiting		:"; waiting|wc -l
    echo -n "Projects	:"; projects|wc -l	
    echo -n "Repeating	:"; repeating|wc -l	
    echo -n "Nextish		:"; nextish|wc -l
    echo -n "Headings	:"; headings|wc -l
    echo ""
    echo -n "Oldest     	: "; limitBy="1" old
    echo -n "Farest     	: "; orderBy="startDate DESC" upcoming|tail -n1
    echo -n "Days/Task	: "; averageCompleteTime
}

search() {
  sqlite3 "$THINGSDB" <<-SQL
.mode line
SELECT 
  T1.title as "Title", 
  date(T1.creationDate,'unixepoch') as "Created",
  date(T1.userModificationDate,'unixepoch') as "Modified",
  date(T1.dueDate,'unixepoch') as "Due",
  date(T1.startDate,'unixepoch') as "Start",
  date(T1.stopDate,'unixepoch') as "Stopped",
  T2.title as "Project",
  T3.title as "Area"
FROM $TASKTABLE T1
LEFT OUTER JOIN $TASKTABLE T2 ON T1.project = T2.uuid
LEFT OUTER JOIN $AREATABLE T3 ON T1.area = T3.uuid
WHERE T1.trashed = 0 AND T1.type = 0
AND (T1.title LIKE "%$string%" OR T2.title LIKE "%$string%");
SQL

sqlite3 "$THINGSDB" <<-SQL
.mode line
SELECT 
  T2.title as "Title",
  date(T1.creationDate,'unixepoch') as "Created",
  date(T1.userModificationDate,'unixepoch') as "Modified",
  date(T1.stopDate,'unixepoch') as "Stopped",
  T1.title as "Task"
FROM TMChecklistItem T1
LEFT OUTER JOIN $TASKTABLE T2 ON T1.task = T2.uuid
WHERE T2.trashed=0
AND T1.title LIKE "%$string%";
SQL
}

require_sqlite3() {
  command -v sqlite3 > /dev/null 2>&1 || {
    echo >&2 "ERROR: SQLite3 is required but could not be found."
    exit 1
  }
}

require_db() {
  test -r "$THINGSDB" -a -f "$THINGSDB" || {
  echo >&2 "ERROR: Things database not found at $THINGSDB."
  exit 2
  }
}

require_sqlite3
require_db

while [[ $# -gt 1 ]]; do
  key="$1"
  case $key in
    -l|--limitBy) limitBy="$2";shift;;
    -w|--waitingTag) waitingTag="$2";shift;;
    -o|--orderBy) orderBy="$2";shift;;
    -s|--string) string="$2";shift;;
  	*) ;;
  esac
  shift
done

command=${1:-}

if [[ -n $command ]]; then
  case $1 in
    inbox) inbox;;
    today) today;;
    upcoming) upcoming;;
    next)  next;;
    anytime)  anytime;;
    someday)  someday;;
    all) all;;
    nextish) nextish;;
	completed) completed;;
	old) old;;
	due) due;;
	repeating) repeating;;
	subtasks) subtasks;;
	projects) projects;;
	headings) headings;;
	cancelled) cancelled;;
	trashed) trashed;;
	waiting) waiting;;
  	notes) notes;;
	csv) csv;;
	stat) limitBy="999999" stat;;
	search) search;;
	feedback) open https://github.com/AlexanderWillner/things.sh/issues/;;
    *)     usage;;
  esac
else
	usage;
fi
