# Things 3 CLI

## Overview

Simple read-only comand-line interface to your Things 3 database (incl. CSV export). Since Things uses a SQLite database (which should come pre-installed on your Mac) we can simply query it straight from the command line. We only do read operations since we don't want to mess up your data.

[![Codacy Badge](https://api.codacy.com/project/badge/Grade/62336d873da240ac89188efdb9f50d8b)](https://app.codacy.com/app/AlexanderWillner/things.sh?utm_source=github.com&utm_medium=referral&utm_content=AlexanderWillner/things.sh&utm_campaign=Badge_Grade_Dashboard)
[![Build Status](https://travis-ci.org/AlexanderWillner/things.sh.svg?branch=master)](https://travis-ci.org/AlexanderWillner/things.sh) [![download](https://img.shields.io/github/downloads/AlexanderWillner/things.sh/total)](https://github.com/AlexanderWillner/things.sh/releases)

These scripts are `bash` based and a `python` based fork is available [at another repository](https://github.com/AlexanderWillner/KanbanView).

## Installation

You can use [brew](https://brew.sh) to install and later update the script:

- Prepare: ```brew tap AlexanderWillner/tap```
- Install: ```brew install things.sh```
- Upgrade: ```brew upgrade```
- Autocompletion: ```brew install bash-completion```. Then add to ```~/.bashrc```:

```bash
    if [ -f $(brew --prefix)/etc/bash_completion ]; then
      . $(brew --prefix)/etc/bash_completion
    fi
```

To uninstall just write `brew uninstall things.sh`.

## Example Graphs

These graphs have been generated based on the CSV export. For example: ```things.sh -r '-14 days' statcsv > lastTwoWeeks.csv && open lastTwoWeeks.csv``` (and then generating a ```Stacked Column``` graph).

![Tasks in the last 14 days](img/example3.jpg)

![Tasks in the last year](img/example1.jpg)

![Tasks since using Things](img/example2.jpg)

## Instructions

Note that you could override the location of the database used by setting the THINGSDB environment variable. For usage information, run the script with no arguments or with "help":

```bash
$ things.sh --limitBy 5 help
usage: things.sh <OPTIONS> [COMMAND]

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
  inbox                    Shows 5 inbox tasks ordered by creationDate
  today                    Shows 5 todays tasks ordered by index
  upcoming                 Shows 5 upcoming tasks ordered by date
  next                     Shows 5 next tasks ordered by creationDate
  someday                  Shows 5 someday tasks ordered by creationDate
  completed                Shows 5 completed tasks ordered by creationDate
  cancelled                Shows 5 cancelled tasks ordered by cancel date
  trashed                  Shows 5 trashed tasks ordered by creationDate
  feedback                 Opens the feedback web page to request and propose changes
  all                      Shows 5 tasks ordered by creationDate
  csv                      Exports all tasks as semicolon seperated values incl. notes and Excel friendly
  due                      Shows 5 tasks ordered by due date
  headings                 Shows 5 headings ordered by creationDate
  mostClosed               Shows 5 days on which most tasks were closed
  mostCancelled            Shows 5 days on which most tasks were cancelled
  mostTrashed              Shows 5 days on which most tasks were trashed
  mostCreated              Shows 5 days on which most tasks were created
  mostTasks                Shows 5 projects that have most tasks
  mostCharacters           Shows 5 tasks that have most characters
  nextish                  Shows 5 nextish tasks ordered by creationDate
  old                      Shows 5 old tasks ordered by creationDate
  projects                 Shows 5 projects ordered by creationDate
  repeating                Shows 5 repeating tasks ordered by creationDate
  schedule                 Schedule an event by creating a number of related tasks
  search                   Searches for a specific task
  stat                     Provides a number of statistics about all tasks
  statcsv                  Exports some statistics as semicolon separated values for -1 year
  subtasks                 Shows 5 subtasks ordered by creationDate
  tag                      Shows 5 tasks with the tag "Waiting for" ordered by "creationDate"
  tags                     Shows 5 tags ordered by their usage
  waiting                  Shows 5 tasks with the tag "Waiting for" ordered by "creationDate"
```

## Examples

### CSV export and open with Excel

```things.sh csv > Things3Export.csv && open Things3Export.csv```

Note that this command generates a file that is readable by Microsoft Excel in Europe, i.e., the default encoding is ```WINDOWS-1252``` and the separator is ```;```. If you want to import the file in another region, you can specify the according encoding using ```ENCODING="WINDOWS-1251//TRANSLIT" ./things.sh csv > Things3Export.csv```. Or to follow the standard use ```SEP="," ENCODING="UTF-8" ./things.sh csv > Things3Export.csv```.

### Statistics

```bash
$ things.sh stat
Inbox     : 0
Today     : 7
Upcoming  : 156
Next      : 15
Someday   : 822

Completed : 11976
Cancelled : 9250
Trashed   : 545

Tasks     : 968
Subtasks  : 56
Waiting   : 111
Projects  : 89
Repeating : 89
Nextish   : 146
Headings  : 53

Oldest    : 2010-09-28|XXX|XXX
Farest    : 2021-01-04|XXX|XXX
Longest   : 167|XXXXXXXXXXXXXX
Largest   : 128|XXXXXXXXXXXXXX

Created   : 147|2017-07-04
Closed    : 124|2017-12-30
Cancelled : 324|2017-12-30
Trashed   : 109|2017-08-02
Days/Task : 41.0
```

### Create Scheduled Event

[![Things.sh Scheduler](https://j.gifs.com/VPrxp9.gif)](https://youtu.be/npOYItkLuhU)

In case you have regularly to create projects based on a template (e.g., a business trip or family vacation), this can be automated using the following command:

```bash
$ things.sh --start 2018-03-20 --days 7 --event resources/exampleEvent.thingslist schedule
```

Note that you might have to ```Enable Things URLs``` in the Things preferences first.

## Other Information

### Things URL Helper

[![Things3 URL Helper](https://j.gifs.com/59VllB.gif)](https://youtu.be/6niSmdXanug)

Since Version 3.4 Things.app has its own [URL Scheme](https://support.culturedcode.com/customer/en/portal/articles/2803573). It replaces the application ```ThingsURLHelper.app``` that you can still find in the folder ```resources```. By using most of the commands (e.g., ```things.sh csv```) you can identify the according URL of each task and open it within any macOS application, such as spotlight. Above an example using a local web page. You can click on the links in Terminal.app by using CMD+DoupleClick.

### Markdown Clipboard to Things Workflow

[![Demo Markdown Clipbaord to Things3](https://j.gifs.com/gL8kx9.gif)](https://youtu.be/HTaxOkZb9S4)

You can use the service/workflow in the folder ```resources``` to automatically convert MarkDown todos into Things 3 tasks. Above an example using Bear.app. To install you have two options:

- [Alfred](https://www.alfredapp.com/blog/tips-and-tricks/tutorial-importing-and-setting-up-alfred-workflows/) Workflow: [Download](https://github.com/AlexanderWillner/things.sh/blob/master/resources/Markdown%20Clipboard%20to%20Things.alfredworkflow?raw=true) and double click on the workflow file
- [macOS](https://support.apple.com/kb/PH25241) Service: [Download](https://github.com/AlexanderWillner/things.sh/blob/master/resources/Markdown%20Clipboard%20to%20Things.workflow.zip?raw=true), unzip and copy the workflow file to ~/Library/Services (you may need to enable the service under System Preferences > Keyboard > Shortcuts > Services > General > Markdown Clipboard to Things)

### Count Minutes Planned Today

It has [some benefits](https://blog.amazingmarvin.com/5-benefits-of-using-time-estimates-in-your-to-do-list/) to use time estimates in your to-do list. In case you're using tags like ```XXmin``` (XX = number in minutes), then there is one script in this repository that can calculate the total minutes of planned to-dos in your ```Today``` view. To install, [download the service](https://github.com/AlexanderWillner/things.sh/blob/master/resources/MinutesTodayInThings.zip?raw=true), unzip it and copy the workflow file to ~/Library/Services (you may need to enable the service under System Preferences > Keyboard > Shortcuts > Services > General > Markdown Clipboard to Things).

![Minutes Planned Today in Things3](img/todayMinutes.png)

## CREDITS

- Author        : Arjan van der Gaag (script for Things 2)
- Author        : Alexander Willner (updates for Things 3, complete rewrite)
- License       : Whatever. Use at your own risk.
- Source        : [https://github.com/AlexanderWillner/things.sh](https://github.com/AlexanderWillner/things.sh)
- Shell checker : [https://github.com/koalaman/shellcheck](https://github.com/koalaman/shellcheck)
- Shell cleanup : [https://github.com/mvdan/sh/](https://github.com/mvdan/sh/)
- Shell tips    : [https://dev.to/thiht/shell-scripts-matter](https://dev.to/thiht/shell-scripts-matter)
- Shell tips    : [https://google.github.io/styleguide/shell.xml](https://google.github.io/styleguide/shell.xml)
- Shell tips    : [https://kvz.io/blog/2013/11/21/bash-best-practices/](https://kvz.io/blog/2013/11/21/bash-best-practices/)
- Shell tips    : [https://github.com/progrium/bashstyle](https://github.com/progrium/bashstyle)

## EZ Releases

* Rebase on upstream/master
* Run `./dist` to make new Things3Export.zip
* Add Release on github, tag x.y-ez
