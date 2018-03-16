#!/bin/bash
getNextPluginID() {
  idx=0
  plugin="plugin$idx"
  while [[ -n ${!plugin:-} ]]; do
    idx=$((idx + 1))
    plugin="plugin$idx"
  done
  echo $idx
}

getPluginHelp() {
  idx=0
  plugin="plugin$idx"
  while [[ -n ${!plugin:-} ]]; do
    command="plugin$idx[0]"
    description="plugin$idx[1]"
    method="plugin$idx[2]"
    cmd=${!command}
    line='                       '
    if [[ -n ${!description} ]]; then
      printf "  %s %s ${!description}\\n" "$cmd" "${line:${#cmd}}"
    fi
    idx=$((idx + 1))
    plugin="plugin$idx"
  done
}

getCommands() {
  idx=0
  plugin="plugin$idx"
  while [[ -n ${!plugin:-} ]]; do
    command="plugin$idx[0]"
    echo -n "${!command} "
    idx=$((idx + 1))
    plugin="plugin$idx"
  done
}

invokePlugin() {
  idx=0
  plugin="plugin$idx"
  while [[ -n ${!plugin:-} ]]; do
    command="plugin$idx[0]"
    description="plugin$idx[1]"
    method="plugin$idx[2]"
    if [[ ${!command} == "$1" ]]; then
      eval "${!method}"
    fi
    idx=$((idx + 1))
    plugin="plugin$idx"
  done
}

hasPlugin() {
  idx=0
  plugin="plugin$idx"
  while [[ -n ${!plugin:-} ]]; do
    command="plugin$idx[0]"
    description="plugin$idx[1]"
    method="plugin$idx[2]"
    if [[ ${!command} == "$1" ]]; then
      return 0
    fi
    idx=$((idx + 1))
    plugin="plugin$idx"
  done
  return 1
}
