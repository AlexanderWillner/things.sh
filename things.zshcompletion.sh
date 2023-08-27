#compdef things.sh

_things_complete() {
  local cur_word
  local -a option_list
  local -a command_list

  cur_word="$words[$CURRENT]"
  option_list=(${(s: :)"$(things.sh show-options)"})
  command_list=(${(s: :)"$(things.sh show-commands)"})

  if [[ "$cur_word" == -* ]]; then
    compadd -a option_list
  else
    compadd -a command_list
  fi
  return 0
}

compdef _things_complete things.sh
