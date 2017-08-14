# Things 3 CLI

## Overview

Simple read-only comand-line interface to your Things 3 database. Since Things uses a SQLite database (which should come pre-installed on your Mac) we can simply query it straight from the command line. We only do read operations since we don't want to mess up your data.

## Instructions

To install, put this file somewhere in your ```$PATH``` and make it executable. E.g. by running: 

```
curl -sL https://raw.githubusercontent.com/AlexanderWillner/things.sh/master/things.sh \
  -o /usr/local/bin/things.sh && \
  chmod +x /usr/local/bin/things.sh
```


Note that you could override the location of the database used by setting the THINGSDB environment variable. For usage information, run the script with no arguments or with "help":

```
$ things.sh help
usage: things.sh [COMMAND]

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
```

Example output:

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
 * Author	: Alexander Willner (updates for Things 3, added many more commands)
 * License	: Whatever. Use at your own risk.
 * https://github.com/AlexanderWillner/things.sh

