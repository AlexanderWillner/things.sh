#!/bin/bash

myPluginID=$(getNextPluginID)
myPlugin="plugin$myPluginID"
myPluginCommand='show-commands'
myPluginDescription=""
myPluginMethod='getCommands'
eval "$myPlugin=('$myPluginCommand' '$myPluginDescription' '$myPluginMethod')"

myPluginID=$(getNextPluginID)
myPlugin="plugin$myPluginID"
myPluginCommand='show-options'
myPluginDescription=""
myPluginMethod='getOptions'
eval "$myPlugin=('$myPluginCommand' '$myPluginDescription' '$myPluginMethod')"

getOptions() {
  echo -n "-r --range -s --string -o --orderBy -w -waitingTag -l --limitBy"
}
