# Things 3 CLI

## Overview

Simple read-only comand-line interface to your Things 3 database (incl. CSV export). Since Things uses a SQLite database (which should come pre-installed on your Mac) we can simply query it straight from the command line. We only do read operations since we don't want to mess up your data.

[![Build Status](https://travis-ci.org/AlexanderWillner/things.sh.svg?branch=master)](https://travis-ci.org/AlexanderWillner/things.sh)

## Installation

You can use [brew](https://brew.sh) to install and later update the script:

```brew install AlexanderWillner/tap/things.sh```

## Instructions

Note that you could override the location of the database used by setting the THINGSDB environment variable. For usage information, run the script with no arguments or with "help":

```
$ things.sh --limitBy 5 help
usage: things.sh <OPTIONS> [COMMAND]

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
  nextish	(show 5 next tasks that are also in someday projects)
  old		(show 5 tasks ordered by 'creationDate')
  due		(show 5 tasks ordered by due date)
  waiting	(show 5 tasks with the tag 'Waiting for' ordered by 'creationDate')
  repeating	(show 5 repeating tasks orderd by 'creationDate')
  subtasks	(show 5 subtasks)
  projects	(show 5 projects ordered by creation date)
  headings	(show 5 headings ordered by creation date)
  notes		(show 5 notes as <headings>: <notes> ordered by creation date)
  csv		(export all tasks as semicolon seperated values incl. notes and Excel friendly)
  stat		(provide an overview of the numbers of tasks)
  search	(provide details about specific tasks)
  feedback	(give feedback, request and propose changes)

OPTIONS:
  -l|--limitBy <number>		Limit output by <number> of results
  -w|--waitingTag <tag>		Set waiting tag to <tag>
  -o|--orderBy <column>		Sort output by <column> (e.g. 'userModificationDate' or 'creationDate')
  -s|--string <string>		String <string> to search for
```

## Examples 

### CSV export and open with Excel

```things.sh csv > Things3Export.csv ; open Things3Export.csv```

### Statistics

```
$ things.sh stat
Inbox		:       0

Today		:      18
Upcoming	:     195
Next		:       8
Someday		:    1146

Completed	:   10981
Cancelled	:    8506
Trashed		:     500

Tasks		:    1329
Subtasks	:      15
Projects	:      99
Repeating	:      84
Nextish		:     183
Headings	:      24

Oldest     	: 2016-01-22
Farest     	: 2021-01-04
Days/Task	: 39.0
```



## CREDITS
 * Author	: Arjan van der Gaag (script for Things 2)
 * Author	: Alexander Willner (updates for Things 3, added many more commands, a lot refactoring)
 * License	: Whatever. Use at your own risk.
 * https://github.com/AlexanderWillner/things.sh
