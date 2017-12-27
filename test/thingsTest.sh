#! /bin/sh
# file: examples/equality_test.sh

cli="THINGSDB=test/Things.sqlite3 ./things.sh -l 10 -w 'Waiting'"

testToday() {
  command="today"
  expectedString="Today"
  output=$(eval "$cli" "$command")
  (echo $output|grep "$expectedString" 2>&1 > /dev/null); result=$?
  assertEquals "Command '$command' should contain '$expectedString'" 0 $result
}

testNext() {
  command="next"
  expectedString="Todo under Heading"
  output=$(eval "$cli" "$command")
  (echo $output|grep "$expectedString" 2>&1 > /dev/null); result=$?
  assertEquals "Command '$command' should contain '$expectedString'" 0 $result
}

testWaiting() {
  command="waiting"
  expectedString="Waiting for Todo"
  output=$(eval "$cli" "$command")
  (echo $output|grep "$expectedString" 2>&1 > /dev/null); result=$?
  assertEquals "Command '$command' should contain '$expectedString'" 0 $result
}

testStat() {
  command="stat"
  expectedString="2017-12-27|Today Todo"
  output=$(eval "$cli" "$command")
  (echo $output|grep "$expectedString" 2>&1 > /dev/null); result=$?
  assertEquals "Command '$command' should contain '$expectedString'" 0 $result
}

testCSV() {
  command="csv"
  expectedString="Checklist Done"
  output=$(eval "$cli" "$command")
  (echo $output|grep "$expectedString" 2>&1 > /dev/null); result=$?
  assertEquals "Command '$command' should contain '$expectedString'" 0 $result
}

