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
# CREDITS
#
# Author  : Arjan van der Gaag (script for Things 2)
# Author  : Alexander Willner (updates for Things 3, complete rewrite)
# License : Whatever. Use at your own risk.
# Source  : https://github.com/AlexanderWillner/things.sh
###############################################################################

# Robust shell code ###########################################################
set -o errexit
set -o nounset
set -o pipefail
[[ "${TRACE:-}" ]] && set -x
###############################################################################

# Core parameters #############################################################
realpath() {
  OURPWD=$PWD
  cd "$(dirname "$1")"
  LINK=$(readlink "$(basename "$1")")
  while [ "$LINK" ]; do
    cd "$(dirname "$LINK")"
    LINK=$(readlink "$(basename "$1")")
  done
  REALPATH="$PWD/$(basename "$1")"
  cd "$OURPWD"
  echo "$REALPATH"
}
readonly PROGNAME=$(basename "$0")
readonly PATHNAME="$(dirname "$(realpath "$0")")"
readonly DEFAULT_DB=~/Library/Containers/com.culturedcode.ThingsMac/Data/Library/Application\ Support/Cultured\ Code/Things/Things.sqlite3
readonly THINGSDB=${THINGSDB:-$DEFAULT_DB}
readonly PLUGINDIR="${PATHNAME}/plugins"
###############################################################################

# Things database structure ###################################################
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
###############################################################################

# Use defined parameters ######################################################
export LIMIT_BY="all"
export WAITING_TAG="Waiting for"
export ORDER_BY="creationDate"
export EXPORT_RANGE="-1 year"
export SEARCH_STRING=""
export EVENTLIST="$HOME/.trip.thingslist"
export EVENTSTART=""
export EVENTDURATION=""
###############################################################################

# Define methods ##############################################################
main() {
  require_sqlite3
  require_db
  parse "${@}"
}

require_sqlite3() {
  command -v sqlite3 >/dev/null 2>&1 || {
    echo >&2 "ERROR: SQLite3 is required but could not be found."
    exit 1
  }
}

require_db() {
  test -r "${THINGSDB}" -a -f "${THINGSDB}" || {
    echo >&2 "ERROR: Things database not found at '${THINGSDB}'."
    echo >&2 "HINT: You might need to install Things from https://culturedcode.com/things/"
    exit 2
  }
}

load_plugins() {
  for plugin in "${PLUGINDIR}"/*; do
    # shellcheck source=/dev/null
    source "${plugin}"
  done
}

parse() {
  while [[ ${#} -gt 1 ]]; do
    local key="${1}"
    case $key in
    -l | --limitBy)
      LIMIT_BY="${2}"
      shift
      ;;
    -w | --waitingTag)
      WAITING_TAG="${2}"
      shift
      ;;
    -o | --orderBy)
      ORDER_BY="${2}"
      shift
      ;;
    -s | --string)
      SEARCH_STRING="${2}"
      shift
      ;;
    -r | --range)
      EXPORT_RANGE="${2}"
      shift
      ;;
    -e | --event)
      EVENTLIST="${2}"
      shift
      ;;
    -d | --duration)
      EVENTDURATION="${2}"
      shift
      ;;
    -t | --start)
      EVENTSTART="${2}"
      shift
      ;;
    *) ;;
    esac
    shift
  done

  load_plugins
  [[ ${LIMIT_BY} == "all" ]] && export LIMIT_BY="-1"

  local command=${1:-}

  if [[ -n ${command} ]]; then
    if hasPlugin "${1}"; then
      invokePlugin "${1}"
    else
      usage
    fi
  else
    usage
  fi
}

usage() {
  cat <<-EOF
usage: ${PROGNAME} <OPTIONS> [COMMAND]

OPTIONS:
  -l|--limitBy <number>    Limit output by <number> of results
  -w|--waitingTag <tag>    Set waiting/filter tag to <tag>
  -o|--orderBy <column>    Sort output by <column> (e.g. 'userModificationDate' or 'creationDate')
  -s|--string <string>     String <string> to search for
  -r|--range <string>      Limit CSV statistic export by <string>
  -e|--event <filename>    Event: <filename> that contains a list of tasks
  -t|--start <date>        Event: starts at <date>
  -d|--duration <days>     Event: ends after <days>
  
COMMANDS:
EOF
  getPluginHelp
}

cleanup() {
  local err="${1:-}"
  local line="${2:-}"
  local linecallfunc="${3:-}"
  local command="${4:-}"
  local funcstack="${5:-}"
  if [[ ${err} -ne "0" ]]; then
    echo 2>&1 "ERROR: line ${line} - command '${command}' exited with status: ${err}."
    echo 2>&1 "ERROR: In ${funcstack} called at line ${linecallfunc}."
    echo 2>&1 "DEBUG: From function ${funcstack[0]} (line ${linecallfunc})."
  fi
}
###############################################################################

# Run script ##################################################################
[[ ${BASH_SOURCE[0]} == "${0}" ]] && trap 'cleanup "${?}" "${LINENO}" "${BASH_LINENO}" "${BASH_COMMAND}" $(printf "::%s" ${FUNCNAME[@]:-})' EXIT && main "${@}"
###############################################################################
