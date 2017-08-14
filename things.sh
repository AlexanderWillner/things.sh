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
# Source	: https://gist.github.com/AlexanderWillner/dad8bb7cead74eb7679b553e8c37f477
#
# EXAMPLE OUTPUT
#
# $ things.sh stat
# Inbox		: 3
# 
# Today		: 7
# Upcoming	: 212
# Next		: 32
# Someday	: 1167
# 
# Completed	: 10973
# 
# Tasks		: 1333
# Subtasks	: 34
# Projects	: 98
# Repeating	: 83
# Nextish	: 166
# 
# Oldest   	: 2016-01-22
# Farest   	: 2021-01-04
# 

set -o errexit
set -o nounset

readonly PROGNAME=$(basename $0)
readonly ARGS="$@"
readonly DEFAULT_DB=~/Library/Containers/com.culturedcode.ThingsMac/Data/Library/Application\ Support/Cultured\ Code/Things/Things.sqlite3
readonly THINGSDB=${DB:-$DEFAULT_DB}

readonly TASKTABLE="TMTask"
readonly AREATABLE="TMArea"
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
usage: $PROGNAME [COMMAND]

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
  nextish	(show next tasks that are also in someday projects)
  old		(show 20 tasks ordered by creation date)
  due		(show 20 tasks ordered by due date)
  repeating	(show all repeating tasks)
  subtasks	(show all subtasks)
  projects	(show all projects ordered by creation date)
  headings	(show all headings ordered by creation date)
  csv		(show all tasks as semicolon seperated values)
  stat		(show an overview of the numbers of tasks)
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
SELECT title
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
AND $ISPOSTPONED
AND $ISOPEN;
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
WHERE $ISNOTTRASHED
AND $ISSTARTED
AND $ISOPEN
AND $ISTASK;
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
WHERE T1.status=0 AND T2.status=0 AND T2.trashed=0;
SQL
}

old() {
  sqlite3 "$THINGSDB" <<-SQL
SELECT date(creationDate,'unixepoch'), title
FROM $TASKTABLE
WHERE $ISNOTTRASHED AND $ISOPEN AND $ISSTARTED 
ORDER BY creationDate
LIMIT 20;
SQL
}

oldest() {
  sqlite3 "$THINGSDB" <<-SQL
.mode tabs
SELECT date(creationDate,'unixepoch'), title
FROM $TASKTABLE
WHERE $ISNOTTRASHED AND $ISOPEN AND $ISSTARTED 
ORDER BY creationDate
LIMIT 1;
SQL
}

future() {
  sqlite3 "$THINGSDB" <<-SQL
.mode tabs
SELECT date(startDate,'unixepoch'), title
FROM $TASKTABLE
WHERE $ISNOTTRASHED AND $ISOPEN
AND startDate NOT NULL
ORDER BY startDate DESC
LIMIT 1;
SQL
}


due() {
  sqlite3 "$THINGSDB" <<-SQL
SELECT date(dueDate,'unixepoch'), title
FROM $TASKTABLE
WHERE $ISNOTTRASHED AND $ISOPEN
AND dueDate NOT NULL
ORDER BY dueDate
LIMIT 20;
SQL
}

repeating() {
  sqlite3 "$THINGSDB" <<-SQL
SELECT title
FROM $TASKTABLE
WHERE $ISNOTTRASHED AND $ISOPEN AND $ISPOSTPONED
AND recurrenceRule NOT NULL
ORDER BY creationDate;
SQL
}

projects() {
  sqlite3 "$THINGSDB" <<-SQL
SELECT title
FROM $TASKTABLE
WHERE $ISNOTTRASHED AND $ISOPEN
AND $ISPROJECT
ORDER BY creationDate;
SQL
}

headings() {
  sqlite3 "$THINGSDB" <<-SQL
SELECT title
FROM $TASKTABLE
WHERE $ISNOTTRASHED AND $ISOPEN
AND $ISHEADING
ORDER BY creationDate;
SQL
}

cancelled() {
  sqlite3 "$THINGSDB" <<-SQL
SELECT title
FROM $TASKTABLE
WHERE $ISNOTTRASHED AND $ISCANCELLED AND $ISTASK
ORDER BY creationDate;
SQL
}

trashed() {
  sqlite3 "$THINGSDB" <<-SQL
SELECT title
FROM $TASKTABLE
WHERE $ISTRASHED AND $ISTASK
ORDER BY creationDate;
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

csv() {
# fix Excel import by running ```iconv -f UTF-8 -t WINDOWS-1252```
echo 'Title;"Creation Date";"Modification Date";"Due Date";"Start Date";Project;Area;Subtask'

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
  ""
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
    echo -n "Projects	:"; projects|wc -l	
    echo -n "Repeating	:"; repeating|wc -l	
    echo -n "Nextish		:"; nextish|wc -l
    echo -n "Headings	:"; headings|wc -l
    echo ""
    echo -n "Oldest     	: "; oldest
    echo -n "Farest     	: "; future
    echo -n "Days/Task	: "; averageCompleteTime
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

main() {
  require_sqlite3
  require_db
  case $ARGS in
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
	csv) csv;;
	stat) stat;;
    *)     usage;;
  esac
}

main
