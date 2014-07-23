#!/bin/bash
# 
# DESCRIPTION
#
# Simple read-only comand-line interface to your Things 2 database. Since
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
# Author: Arjan van der Gaag
# Date: 2014-07-23
# License: Whatever. Use at your own risk.

set -o errexit
set -o nounset

readonly PROGNAME=$(basename $0)
readonly ARGS="$@"
readonly DEFAULT_DB=~/Library/Containers/com.culturedcode.things/Data/Library/Application\ Support/Cultured\ Code/Things/ThingsLibrary.db
readonly THINGSDB=${DB:-$DEFAULT_DB}

usage() {
  cat <<-EOF
usage: $PROGNAME [FOCUS]

List to do items from your Things database given a focus area.

FOCUS:
  today
  next
  inbox

EXAMPLES:
  List all items scheduled for today:
  $PROGNAME today

  List all next items:
  $PROGNAME next

  List all inbox items:
  $PROGNAME inbox
EOF
}

today() {
  sqlite3 "$THINGSDB" <<-SQL
SELECT ztitle
FROM zthing
WHERE ztrashed = 0
AND z_ent = 13
AND zstatus = 0
AND zscheduler = 1
AND zstartdate is not null
AND zstart = 1;
SQL
}

next() {
  sqlite3 "$THINGSDB" <<-SQL
SELECT ztitle
FROM zthing
WHERE ztrashed = 0
AND z_ent = 13
AND zstatus = 0;
SQL
}

inbox() {
  sqlite3 "$THINGSDB" <<-SQL
SELECT ztitle
FROM zthing
WHERE z_ent = 13
AND ztrashed = 0
AND zstart =0
AND zstatus = 0;
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

main() {
  require_sqlite3
  require_db
  case $ARGS in
    today) today;;
    next)  next;;
    inbox) inbox;;
    *)     usage;;
  esac
}

main