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
# Author: Arjan van der Gaag (script for Things 2)
# Author: Alexander Willner (updates for Things 3, added many more commands)
# Date: 2017-08-10
# License: Whatever. Use at your own risk.
#
# DEBUG INFORMATION
#
# status: 0=open, 2=cancelled, 3=repeating or done
# type: 0=normal, 2=heading


set -o errexit
set -o nounset

readonly PROGNAME=$(basename $0)
readonly ARGS="$@"
readonly DEFAULT_DB=~/Library/Containers/com.culturedcode.ThingsMac/Data/Library/Application\ Support/Cultured\ Code/Things/Things.sqlite3
readonly THINGSDB=${DB:-$DEFAULT_DB}

usage() {
  cat <<-EOF
usage: $PROGNAME [FOCUS]

List to do items from your Things database given a focus area.

FOCUS:
  inbox
  today
  upcoming
  next (now called 'anytime')
  someday
  completed
  nextAll (next actions also in someday projects)
  all (just count all todos and projects)
  stat (give an overview)
EOF
}

inbox() {
  sqlite3 "$THINGSDB" <<-SQL
SELECT title
FROM TMTask
WHERE trashed = 0 AND type=0
AND start =0
AND status = 0;
SQL
}

today() {
  sqlite3 "$THINGSDB" <<-SQL
SELECT title
FROM TMTask
WHERE trashed = 0 AND type=0
AND status = 0
AND startdate is not null
AND start = 1
ORDER BY startdate, todayIndex;
SQL
}

upcoming() {
  sqlite3 "$THINGSDB" <<-SQL
SELECT title
FROM TMTask
WHERE trashed = 0 AND type=0
AND status = 0 AND start = 2 AND startDate not null
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
WHERE trashed = 0 AND type=0
AND start = 1
AND status = 0
AND t.project in (select uuid from TMTask where uuid=t.project and start=1)
ORDER BY todayIndex;
SQL
}

someday() {
  sqlite3 "$THINGSDB" <<-SQL
SELECT title
FROM TMTask t
WHERE trashed = 0 AND type=0
AND start = 2
AND status = 0;
SQL
}

nextAll() {
  sqlite3 "$THINGSDB" <<-SQL
SELECT title
FROM TMTask
WHERE trashed = 0
AND start = 1
AND status = 0
AND type=0;
SQL
}

completed() {
  sqlite3 "$THINGSDB" <<-SQL
SELECT title
FROM TMTask
WHERE trashed = 0
AND status = 3
AND type=0;
SQL
}

all() {
  sqlite3 "$THINGSDB" <<-SQL
SELECT title
FROM TMTask
WHERE trashed = 0
AND status = 0
AND type=0;
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
	stat) stat;;
    *)     usage;;
  esac
}

main
