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
  
  expected="Inbox		:       0"
  (echo "$output"|grep "$expected" > /dev/null 2>&1); result=$?
  assertTrue "Command '$command' should contain '$expected' in '\n$output'" $result
  expected="Today		:       1"
  (echo "$output"|grep "$expected" > /dev/null 2>&1); result=$?
  assertTrue "Command '$command' should contain '$expected'" $result
  expected="Upcoming	:       3"
  (echo "$output"|grep "$expected" > /dev/null 2>&1); result=$?
  assertTrue "Command '$command' should contain '$expected'" $result
  expected="Next		:       6"
  (echo "$output"|grep "$expected" > /dev/null 2>&1); result=$?
  assertTrue "Command '$command' should contain '$expected'" $result
  expected="Someday		:       4"
  (echo "$output"|grep "$expected" > /dev/null 2>&1); result=$?
  assertTrue "Command '$command' should contain '$expected'" $result
  expected="Completed	:       1"
  (echo "$output"|grep "$expected" > /dev/null 2>&1); result=$?
  assertTrue "Command '$command' should contain '$expected'" $result
  expected="Cancelled	:       1"
  (echo "$output"|grep "$expected" > /dev/null 2>&1); result=$?
  assertTrue "Command '$command' should contain '$expected'" $result
  expected="Trashed		:       3"
  (echo "$output"|grep "$expected" > /dev/null 2>&1); result=$?
  assertTrue "Command '$command' should contain '$expected'" $result
  expected="Tasks		:      11"
  (echo "$output"|grep "$expected" > /dev/null 2>&1); result=$?
  assertTrue "Command '$command' should contain '$expected'" $result
  expected="Subtasks	:       2"
  (echo "$output"|grep "$expected" > /dev/null 2>&1); result=$?
  assertTrue "Command '$command' should contain '$expected'" $result
  expected="Waiting		:       1"
  (echo "$output"|grep "$expected" > /dev/null 2>&1); result=$?
  assertTrue "Command '$command' should contain '$expected'" $result
  expected="Projects	:       4"
  (echo "$output"|grep "$expected" > /dev/null 2>&1); result=$?
  assertTrue "Command '$command' should contain '$expected'" $result
  expected="Repeating	:       2"
  (echo "$output"|grep "$expected" > /dev/null 2>&1); result=$?
  assertTrue "Command '$command' should contain '$expected'" $result
  expected="Nextish		:       6"
  (echo "$output"|grep "$expected" > /dev/null 2>&1); result=$?
  assertTrue "Command '$command' should contain '$expected'" $result
  expected="Headings	:       2"
  (echo "$output"|grep "$expected" > /dev/null 2>&1); result=$?
  assertTrue "Command '$command' should contain '$expected'" $result
  expected="Oldest     	: 2017-12-27|Today Project|Today Todo"
  (echo "$output"|grep "$expected" > /dev/null 2>&1); result=$?
  assertTrue "Command '$command' should contain '$expected'" $result
  expected="Farest     	: 2045-05-13|(No Context)|Next Todo"
  (echo "$output"|grep "$expected" > /dev/null 2>&1); result=$?
  assertTrue "Command '$command' should contain '$expected'" $result
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
  expectedString="$2"	
  output=$(eval "$CLI" "$command")
  (echo "$output"|grep "$expectedString" > /dev/null 2>&1); result=$?
  assertEquals "Command '$command' should contain '$expectedString'" 0 $result
}