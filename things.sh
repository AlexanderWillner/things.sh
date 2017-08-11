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
# Date		: 2017-08-11
# License	: Whatever. Use at your own risk.
# Source	: https://gist.github.com/AlexanderWillner/dad8bb7cead74eb7679b553e8c37f477

set -o errexit
set -o nounset

readonly PROGNAME=$(basename $0)
readonly ARGS="$@"
readonly DEFAULT_DB=~/Library/Containers/com.culturedcode.ThingsMac/Data/Library/Application\ Support/Cultured\ Code/Things/Things.sqlite3
readonly THINGSDB=${DB:-$DEFAULT_DB}

readonly ISNOTTRASHED="trashed = 0"
readonly ISOPEN="status = 0"
readonly ISACTIVE="start = 1"
readonly ISNOTACTIVE="start = 2"
readonly ISTASK="type = 0"
readonly ISPROJECT="type = 1"

usage() {
  cat <<-EOF
usage: $PROGNAME [FOCUS]

List to do items from your Things database given a focus area.

FOCUS:
  inbox
  today
  upcoming
  next		(now called 'anytime')
  someday
  completed
  nextAll	(next actions also in someday projects)
  all		(just count all todos and projects)
  old	(show 20 todos ordered by creation date)
  due		(show 20 todos ordered by due date)
  projects	(show all projects ordered by creation date)
  stat		(give an overview)
EOF
}

inbox() {
  sqlite3 "$THINGSDB" <<-SQL
SELECT title
FROM TMTask
WHERE $ISNOTTRASHED AND type=0
AND start =0
AND $ISOPEN;
SQL
}

today() {
  sqlite3 "$THINGSDB" <<-SQL
SELECT title
FROM TMTask
WHERE $ISNOTTRASHED AND $ISOPEN AND $ISTASK
AND startdate is not null
AND $ISACTIVE
ORDER BY startdate, todayIndex;
SQL
}

upcoming() {
  sqlite3 "$THINGSDB" <<-SQL
SELECT title
FROM TMTask
WHERE $ISNOTTRASHED AND $ISOPEN AND $ISTASK
AND $ISNOTACTIVE AND (startDate NOT NULL OR recurrenceRule NOT NULL)
ORDER BY startdate, todayIndex;
SQL
}

anytime() {
  next
}

next() {
  sqlite3 "$THINGSDB" <<-SQL
SELECT title
FROM TMTask t
WHERE $ISNOTTRASHED AND $ISTASK AND $ISOPEN
AND $ISACTIVE
AND (
  t.area NOT NULL
  OR
  t.project in (SELECT uuid FROM TMTask WHERE uuid=t.project AND $ISACTIVE)
  )
ORDER BY todayIndex;
SQL
}

someday() {
  sqlite3 "$THINGSDB" <<-SQL
SELECT title
FROM TMTask t
WHERE $ISNOTTRASHED AND $ISTASK
AND $ISNOTACTIVE
AND $ISOPEN;
SQL
}

completed() {
  sqlite3 "$THINGSDB" <<-SQL
SELECT title
FROM TMTask
WHERE $ISNOTTRASHED
AND status = 3
AND type=0;
SQL
}

nextAll() {
  sqlite3 "$THINGSDB" <<-SQL
SELECT title
FROM TMTask
WHERE $ISNOTTRASHED
AND $ISACTIVE
AND $ISOPEN
AND $ISTASK;
SQL
}

all() {
  sqlite3 "$THINGSDB" <<-SQL
SELECT title
FROM TMTask
WHERE $ISNOTTRASHED AND $ISOPEN AND $ISTASK;
SQL
}

old() {
  sqlite3 "$THINGSDB" <<-SQL
SELECT date(creationDate,'unixepoch'), title
FROM TMTask
WHERE $ISNOTTRASHED AND $ISOPEN AND $ISACTIVE 
ORDER BY creationDate
LIMIT 20;
SQL
}

due() {
  sqlite3 "$THINGSDB" <<-SQL
SELECT date(dueDate,'unixepoch'), title
FROM TMTask
WHERE $ISNOTTRASHED AND $ISOPEN
AND dueDate NOT NULL
ORDER BY dueDate
LIMIT 20;
SQL
}

projects() {
  sqlite3 "$THINGSDB" <<-SQL
SELECT title
FROM TMTask
WHERE $ISNOTTRASHED AND $ISOPEN
AND $ISPROJECT
ORDER BY creationDate;
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
   	echo ""
    echo -n "All		:"; all|wc -l
    echo -n "NextAll		:"; nextAll|wc -l
    echo -n "Projects	:"; projects|wc -l	
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
    nextAll) nextAll;;
	completed) completed;;
	old) old;;
	due) due;;
	projects) projects;;
	stat) stat;;
    *)     usage;;
  esac
}

main
