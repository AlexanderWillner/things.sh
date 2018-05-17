#!/bin/bash

myPluginID="$(getNextPluginID)"
myPlugin="plugin$myPluginID"
myPluginCommand="feedback"
myPluginDescription="Opens the feedback web page to request and propose changes"
myPluginMethod="openFeedback"

eval "$myPlugin=('$myPluginCommand' '$myPluginDescription' '$myPluginMethod')"

openFeedback() {
  open https://github.com/AlexanderWillner/things.sh/issues/
}
