#!/usr/bin/env bash

readonly CLI="THINGSDB=test/Things.sqlite3 ./things.sh -l 10 -w 'Waiting'"

testToday() {
  command="today"
  expected="Today Project|Today Todo"
  runSimpleTest "$command" "$expected"
}

testNext() {
  command="next"
  expected="Todo under Heading"
  runSimpleTest "$command" "$expected"
}

testWaiting() {
  command="waiting"
  expected="Waiting for Todo"
  runSimpleTest "$command" "$expected"
}

testStat() {
  command="stat"
  output=$(eval "$CLI" "$command")
  output=${output// /}
  output=${output//	/}
  expected="Inbox:1"
  (echo "$output"|grep "$expected" > /dev/null 2>&1); result=$?
  assertTrue "Command '$command' should contain '$expected' in '\n$output'" $result
  expected="Today:1"
  (echo "$output"|grep "$expected" > /dev/null 2>&1); result=$?
  assertTrue "Command '$command' should contain '$expected' in '\n$output'" $result
  expected="Upcoming:3"
  (echo "$output"|grep "$expected" > /dev/null 2>&1); result=$?
  assertTrue "Command '$command' should contain '$expected' in '\n$output'" $result
  expected="Next:6"
  (echo "$output"|grep "$expected" > /dev/null 2>&1); result=$?
  assertTrue "Command '$command' should contain '$expected' in '\n$output'" $result
  expected="Someday:4"
  (echo "$output"|grep "$expected" > /dev/null 2>&1); result=$?
  assertTrue "Command '$command' should contain '$expected' in '\n$output'" $result
  expected="Completed:1"
  (echo "$output"|grep "$expected" > /dev/null 2>&1); result=$?
  assertTrue "Command '$command' should contain '$expected' in '\n$output'" $result
  expected="Cancelled:1"
  (echo "$output"|grep "$expected" > /dev/null 2>&1); result=$?
  assertTrue "Command '$command' should contain '$expected' in '\n$output'" $result
  expected="Trashed:3"
  (echo "$output"|grep "$expected" > /dev/null 2>&1); result=$?
  assertTrue "Command '$command' should contain '$expected' in '\n$output'" $result
  expected="Tasks:11"
  (echo "$output"|grep "$expected" > /dev/null 2>&1); result=$?
  assertTrue "Command '$command' should contain '$expected' in '\n$output'" $result
  expected="Subtasks:2"
  (echo "$output"|grep "$expected" > /dev/null 2>&1); result=$?
  assertTrue "Command '$command' should contain '$expected' in '\n$output'" $result
  expected="Waiting:1"
  (echo "$output"|grep "$expected" > /dev/null 2>&1); result=$?
  assertTrue "Command '$command' should contain '$expected' in '\n$output'" $result
  expected="Projects:4"
  (echo "$output"|grep "$expected" > /dev/null 2>&1); result=$?
  assertTrue "Command '$command' should contain '$expected' in '\n$output'" $result
  expected="Repeating:2"
  (echo "$output"|grep "$expected" > /dev/null 2>&1); result=$?
  assertTrue "Command '$command' should contain '$expected' in '\n$output'" $result
  expected="Nextish:6"
  (echo "$output"|grep "$expected" > /dev/null 2>&1); result=$?
  assertTrue "Command '$command' should contain '$expected' in '\n$output'" $result
  expected="Headings:2"
  (echo "$output"|grep "$expected" > /dev/null 2>&1); result=$?
  assertTrue "Command '$command' should contain '$expected' in '\n$output'" $result
  expected="Oldest:2017-12-27|TodayProject|TodayTodo"
  (echo "$output"|grep "$expected" > /dev/null 2>&1); result=$?
  assertTrue "Command '$command' should contain '$expected' in '\n$output'" $result
  expected="Farest:2045-05-13|(NoContext)|NextTodo"
  (echo "$output"|grep "$expected" > /dev/null 2>&1); result=$?
  assertTrue "Command '$command' should contain '$expected' in '\n$output'" $result
}

testCSV() {
  command="csv"
  expected="Checklist Done"
  runSimpleTest "$command" "$expected"
}

testSearch() {
  command="-s 'Today Todo' search"
  expected="Today Todo"
  runSimpleTest "$command" "$expected"
}

testDue() {
  command="due"
  expected="Next Project|Due Todo"
  runSimpleTest "$command" "$expected"
}

runSimpleTest() {
  command="$1" 
  expected="$2"	
  output=$(eval "$CLI" "$command")
  (echo "$output"|grep "$expected" > /dev/null 2>&1); result=$?
  assertTrue "Command '$command' should contain '$expected' in '\n$output'" $result
}