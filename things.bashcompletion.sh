#!/usr/bin/env bash

_things_complete() {
  local cur_word option_list command_list

  # COMP_WORDS is an array of words in the current command line.
  # COMP_CWORD is the index of the current word (the one the cursor is
  # in). So COMP_WORDS[COMP_CWORD] is the current word; we also record
  # the previous word here, although this specific script doesn't
  # use it yet.
  cur_word="${COMP_WORDS[COMP_CWORD]}"

  # Ask things.sh to generate a list of types it supports
  option_list=$(things.sh show-options)
  command_list=$(things.sh show-commands)

  # Perform completion of commands and options.
  if [[ ${cur_word} == -* ]]; then
    # shellcheck disable=SC2207
    COMPREPLY=($(compgen -W "${option_list}" -- "${cur_word}"))
  else
    # shellcheck disable=SC2207
    COMPREPLY=($(compgen -W "${command_list}" -- "${cur_word}"))
  fi
  return 0
}
complete -F _things_complete things.sh
